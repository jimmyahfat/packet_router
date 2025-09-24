
// Copyrights
//
// This is a fifo that buffers an AXI stream packet.
//
// If the fifo gets full midway through receiving a packet, it automatically
// drops the packet in question.
// There is also a 'drop' input. Drop can be asserted anytime through a packet
// and when asserted, the fifo will drop the whole packet being processed.
// When the fifo drops a packet, it ensure that no partial packets are sent out.
// The fifo outputs a 'dropped' signal. This signal is valid when tready == 1'b1
// and tvalid == 1'b1 and tlast == 1'b1. If asserted, this signifies that the
// packet was dropped.
//

`default_nettype none

module axis_packet_fifo #(
    parameter integer TDATA_WIDTH = 32,
    parameter integer DEPTH = 32
) (
    input  logic                     clk,
    input  logic                     resetn,
    //
    input  logic [TDATA_WIDTH-1:0]   s_axis_tdata,
    input  logic                     s_axis_tlast,
    input  logic                     s_axis_tdrop,
    input  logic                     s_axis_tvalid,
    output logic                     s_axis_tready,
    output logic                     s_axis_tdropped,
    //
    output logic [TDATA_WIDTH-1:0]   m_axis_tdata,
    output logic                     m_axis_tlast,
    output logic                     m_axis_tvalid,
    input  logic                     m_axis_tready

);

    localparam ADDR_WIDTH = $clog2(DEPTH) + 1;
    localparam DATA_WIDTH = TDATA_WIDTH + 1; // Extra bit for tlast

    // Internal signals
    // Note read and write pointers are one bit 'bigger' to make it easy to
    // generate the empty or full signals.
    // The fifo is empty when the (readptr[msb] == writeptr[msb]) & (readptr[lsbs] == writeptr[lsbs])
    // The fifo is full  when the (readptr[msb] != writeptr[msb]) & (readptr[lsbs] == writeptr[lsbs])
    logic [ADDR_WIDTH-1:0] wptr, rptr, last_good_wptr;
    logic [DATA_WIDTH-1:0] wdata, rdata;
    logic                  we, empty, full;

    assign we    = s_axis_tvalid & s_axis_tready & !dropping_packet;
    assign empty = (last_good_wptr == rptr);
    assign full  = (wptr[ADDR_WIDTH-1] != rptr[ADDR_WIDTH-1]) & (wptr[ADDR_WIDTH-2:0] == rptr[ADDR_WIDTH-2:0]);
    assign wdata = {s_axis_tlast, s_axis_tdata};


    // BRAM instance
    bram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_bram (
        .clk   (clk),
        .we    (we),
        .waddr (wptr),
        .wdata (wdata),
        .raddr (rptr),
        .rdata (rdata)
    );

    // Logic to keep track whether a drop signal was seen before, or whether the
    // fifo was full when we were supposed to accept data. If so, further
    // samples should be dropped.
    logic drop_seen, dropping_packet;
    always_ff @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            drop_seen <= 1'b0;
        end else if (s_axis_tvalid == 1'b1 && s_axis_tready == 1'b1 && s_axis_tlast == 1'b1) begin
            drop_seen <= 1'b0;
        end else if (s_axis_tvalid == 1'b1 && s_axis_tready == 1'b1 && (s_axis_tdrop == 1'b1 || full == 1'b1)) begin
            drop_seen <= 1'b1;
        end
    end

    // Signal to tell whether we should be dropping the rest of this packet
    assign dropping_packet = s_axis_tdrop | full | drop_seen;
    assign s_axis_tdropped = dropping_packet;

    // 'Write pointer' and the 'last good write pointer'.
    //
    // The 'write pointer' is incremented when we receive data and we are not dropping the packet.
    // The 'write pointer' is updated with the 'last good write pointer' value when we receive the last transfer of a packet we are dropping.
    //
    // If we receive the last transfer of a packet we are not dropping, we should update the 'last good write pointer'.
    always_ff @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            wptr <= 0;
            last_good_wptr <= 0;
        end else begin
            if (s_axis_tvalid == 1'b1 && s_axis_tready == 1'b1 && dropping_packet == 1'b0) begin
                wptr <= wptr + 1;
            end else if (s_axis_tvalid == 1'b1 && s_axis_tready == 1'b1 && s_axis_tlast == 1'b1 && dropping_packet == 1'b1) begin
                wptr <= last_good_wptr;
            end

            if (s_axis_tvalid == 1'b1 && s_axis_tready == 1'b1 && s_axis_tlast == 1'b1 && dropping_packet == 1'b0) begin
                last_good_wptr <= wptr + 1;
            end
        end
    end

    // 'read pointer'
    always_ff @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            rptr <= 0;
        end else if (m_axis_tvalid == 1'b1 && m_axis_tready == 1'b1) begin
            rptr <= rptr + 1;
        end
    end


    assign s_axis_tready = 1'b1;

    assign m_axis_tdata  = rdata[DATA_WIDTH-2:0];
    assign m_axis_tvalid = !empty;
    assign m_axis_tlast  = rdata[DATA_WIDTH-1];

endmodule

`default_nettype wire
