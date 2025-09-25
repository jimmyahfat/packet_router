
// Copyrights
//
// Packet router.
//
// Accepts axi stream packets.
// A packet consists of a 64bits header followed by data and a tlast.
//
// If header[7:0] is even -> send whole packet to output M0
// If header[7:0] is odd  -> send whole packet to output M1

`default_nettype none

module packet_router (
    clk,
    resetn,
    //
    s_axil_araddr,
    s_axil_arvalid,
    s_axil_arready,
    s_axil_rdata,
    s_axil_rresp,
    s_axil_rvalid,
    s_axil_rready,
    //
    s_axis_tdata,
    s_axis_tlast,
    s_axis_tvalid,
    s_axis_tready,
    //
    m0_axis_tdata,
    m0_axis_tlast,
    m0_axis_tvalid,
    m0_axis_tready,
    //
    m1_axis_tdata,
    m1_axis_tlast,
    m1_axis_tvalid,
    m1_axis_tready
);

    parameter integer TDATA_WIDTH = 32;
    parameter integer DEPTH       = 32;

    input  logic                   clk;
    input  logic                   resetn;
    //
    input  logic [31:0]            s_axil_araddr;
    input  logic                   s_axil_arvalid;
    output logic                   s_axil_arready;
    output logic [31:0]            s_axil_rdata;
    output logic [1:0]             s_axil_rresp;
    output logic                   s_axil_rvalid;
    input  logic                   s_axil_rready;
    //
    input  logic [TDATA_WIDTH-1:0] s_axis_tdata;
    input  logic                   s_axis_tlast;
    input  logic                   s_axis_tvalid;
    output logic                   s_axis_tready;
    //
    output logic [TDATA_WIDTH-1:0] m0_axis_tdata;
    output logic                   m0_axis_tlast;
    output logic                   m0_axis_tvalid;
    input  logic                   m0_axis_tready;
    //
    output logic [TDATA_WIDTH-1:0] m1_axis_tdata;
    output logic                   m1_axis_tlast;
    output logic                   m1_axis_tvalid;
    input  logic                   m1_axis_tready;

    logic [TDATA_WIDTH-1:0]   rstg_dcsn_data,  dcsn_fifo_m0_data,    fifo_rstg_m0_data,  dcsn_fifo_m1_data,  fifo_rstg_m1_data;
    logic                     rstg_dcsn_valid, dcsn_fifo_m0_valid,   fifo_rstg_m0_valid, dcsn_fifo_m1_valid, fifo_rstg_m1_valid;
    logic                     rstg_dcsn_ready, dcsn_fifo_m0_ready,   fifo_rstg_m0_ready, dcsn_fifo_m1_ready, fifo_rstg_m1_ready;
    logic                     rstg_dcsn_last,  dcsn_fifo_m0_last,    fifo_rstg_m0_last,  dcsn_fifo_m1_last,  fifo_rstg_m1_last;
    logic                     rstg_dcsn_drop,  dcsn_fifo_m0_drop,    dcsn_fifo_m1_drop;
    logic                                      dcsn_fifo_m0_dropped, dcsn_fifo_m1_dropped;

    axis_register_stage #(
        .TDATA_WIDTH(TDATA_WIDTH)
    ) s_rstg (
        .clk            (clk),
        .resetn         (resetn),
        //
        .s_axis_tdata   (s_axis_tdata),
        .s_axis_tlast   (s_axis_tlast),
        .s_axis_tvalid  (s_axis_tvalid),
        .s_axis_tready  (s_axis_tready),
        //
        .m_axis_tdata   (rstg_dcsn_data),
        .m_axis_tlast   (rstg_dcsn_last),
        .m_axis_tvalid  (rstg_dcsn_valid),
        .m_axis_tready  (rstg_dcsn_ready)
    );

    // count the transfer index in an axi stream packet
    logic [3:0] rstg_dcsn_transfer_idx;
    always_ff @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            rstg_dcsn_transfer_idx <= 0;
        end else if (rstg_dcsn_valid == 1'b1 && rstg_dcsn_ready == 1'b1 && rstg_dcsn_last == 1'b1) begin
            rstg_dcsn_transfer_idx <= 0;
        end else if (rstg_dcsn_valid == 1'b1 && rstg_dcsn_ready == 1'b1 && rstg_dcsn_transfer_idx != '1) begin
            rstg_dcsn_transfer_idx <= rstg_dcsn_transfer_idx + 1;
        end
    end

    typedef enum { M0, M1} decision_t;
    decision_t decision, previous_decision;
    always_ff @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            previous_decision <= M0;
        end else if (rstg_dcsn_valid == 1'b1 && rstg_dcsn_ready == 1'b1 && rstg_dcsn_transfer_idx == 0) begin
            previous_decision <= decision;
        end
    end

    assign decision = (rstg_dcsn_valid == 1'b1 && rstg_dcsn_ready == 1'b1 && rstg_dcsn_transfer_idx == 0 && rstg_dcsn_data[0] == 1'b0) ? M0 :
                      (rstg_dcsn_valid == 1'b1 && rstg_dcsn_ready == 1'b1 && rstg_dcsn_transfer_idx == 0 && rstg_dcsn_data[0] == 1'b1) ? M1 :
                                                                                                                                         previous_decision;

    // drop the packet if it is less than 64bits.
    // When TDATA_WIDTH=32, this will happen on the first transfer
    generate if (TDATA_WIDTH == 32) begin
        assign rstg_dcsn_drop = (rstg_dcsn_transfer_idx == 0 && rstg_dcsn_last == 1'b1) ? 1'b1 : 1'b0;
    end
    endgenerate

    // When TDATA_WIDTH>=64, we cannot receive less than 64bits, so tie drop=0.
    generate if (TDATA_WIDTH == 64 || TDATA_WIDTH == 128 || TDATA_WIDTH == 256) begin
        assign rstg_dcsn_drop = 1'b0;
    end
    endgenerate

    always_comb begin
        dcsn_fifo_m0_data = 0;
        dcsn_fifo_m0_last = 0;
        dcsn_fifo_m0_drop = 0;
        dcsn_fifo_m0_valid = 0;
        rstg_dcsn_ready = 0;
        dcsn_fifo_m1_data = 0;
        dcsn_fifo_m1_last = 0;
        dcsn_fifo_m1_drop = 0;
        dcsn_fifo_m1_valid = 0;
        rstg_dcsn_ready = 0;
        if (decision == M0) begin
            dcsn_fifo_m0_data  = rstg_dcsn_data;
            dcsn_fifo_m0_last  = rstg_dcsn_last;
            dcsn_fifo_m0_drop  = rstg_dcsn_drop;
            dcsn_fifo_m0_valid = rstg_dcsn_valid;
            rstg_dcsn_ready    = dcsn_fifo_m0_ready;
        end else begin
            dcsn_fifo_m1_data  = rstg_dcsn_data;
            dcsn_fifo_m1_last  = rstg_dcsn_last;
            dcsn_fifo_m1_drop  = rstg_dcsn_drop;
            dcsn_fifo_m1_valid = rstg_dcsn_valid;
            rstg_dcsn_ready    = dcsn_fifo_m1_ready;
        end
    end

    // M0
    axis_packet_fifo #(
        .TDATA_WIDTH(TDATA_WIDTH),
        .DEPTH      (DEPTH)
    ) m0_packet_fifo (
        .clk                (clk),
        .resetn             (resetn),
        //
        .s_axis_tdata       (dcsn_fifo_m0_data),
        .s_axis_tlast       (dcsn_fifo_m0_last),
        .s_axis_tdrop       (dcsn_fifo_m0_drop),
        .s_axis_tvalid      (dcsn_fifo_m0_valid),
        .s_axis_tready      (dcsn_fifo_m0_ready),
        .s_axis_tdropped    (dcsn_fifo_m0_dropped),
        //
        .m_axis_tdata       (fifo_rstg_m0_data),
        .m_axis_tlast       (fifo_rstg_m0_last),
        .m_axis_tvalid      (fifo_rstg_m0_valid),
        .m_axis_tready      (fifo_rstg_m0_ready)
    );
    axis_register_stage #(
        .TDATA_WIDTH(TDATA_WIDTH)
    ) m0_rstg (
        .clk            (clk),
        .resetn         (resetn),
        //
        .s_axis_tdata   (fifo_rstg_m0_data),
        .s_axis_tlast   (fifo_rstg_m0_last),
        .s_axis_tvalid  (fifo_rstg_m0_valid),
        .s_axis_tready  (fifo_rstg_m0_ready),
        //
        .m_axis_tdata   (m0_axis_tdata),
        .m_axis_tlast   (m0_axis_tlast),
        .m_axis_tvalid  (m0_axis_tvalid),
        .m_axis_tready  (m0_axis_tready)
    );


    // M1
    axis_packet_fifo #(
        .TDATA_WIDTH(TDATA_WIDTH),
        .DEPTH      (DEPTH)
    ) m1_packet_fifo (
        .clk                (clk),
        .resetn             (resetn),
        //
        .s_axis_tdata       (dcsn_fifo_m1_data),
        .s_axis_tlast       (dcsn_fifo_m1_last),
        .s_axis_tdrop       (dcsn_fifo_m1_drop),
        .s_axis_tvalid      (dcsn_fifo_m1_valid),
        .s_axis_tready      (dcsn_fifo_m1_ready),
        .s_axis_tdropped    (dcsn_fifo_m1_dropped),
        //
        .m_axis_tdata       (fifo_rstg_m1_data),
        .m_axis_tlast       (fifo_rstg_m1_last),
        .m_axis_tvalid      (fifo_rstg_m1_valid),
        .m_axis_tready      (fifo_rstg_m1_ready)
    );
    axis_register_stage #(
        .TDATA_WIDTH(TDATA_WIDTH)
    ) m1_rstg (
        .clk            (clk),
        .resetn         (resetn),
        //
        .s_axis_tdata   (fifo_rstg_m1_data),
        .s_axis_tlast   (fifo_rstg_m1_last),
        .s_axis_tvalid  (fifo_rstg_m1_valid),
        .s_axis_tready  (fifo_rstg_m1_ready),
        //
        .m_axis_tdata   (m1_axis_tdata),
        .m_axis_tlast   (m1_axis_tlast),
        .m_axis_tvalid  (m1_axis_tvalid),
        .m_axis_tready  (m1_axis_tready)
    );

    // counters
    logic [31:0] num_packets_sent_to_output_0;
    logic [31:0] num_packets_sent_to_output_1;
    logic [31:0] num_packets_dropped;
    always_ff @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            num_packets_sent_to_output_0 <= 0;
            num_packets_sent_to_output_1 <= 0;
            num_packets_dropped <= 0;
        end else begin
            if (dcsn_fifo_m0_ready == 1'b1 && dcsn_fifo_m0_valid == 1'b1 && dcsn_fifo_m0_last == 1'b1 && dcsn_fifo_m0_dropped == 1'b0) begin
                num_packets_sent_to_output_0 <= num_packets_sent_to_output_0 + 1;
            end
            if (dcsn_fifo_m1_ready == 1'b1 && dcsn_fifo_m1_valid == 1'b1 && dcsn_fifo_m1_last == 1'b1 && dcsn_fifo_m1_dropped == 1'b0) begin
                num_packets_sent_to_output_1 <= num_packets_sent_to_output_1 + 1;
            end
            if (dcsn_fifo_m0_ready == 1'b1 && dcsn_fifo_m0_valid == 1'b1 && dcsn_fifo_m0_last == 1'b1 && dcsn_fifo_m0_dropped == 1'b1) begin
                num_packets_dropped <= num_packets_dropped + 1;
            end
            if (dcsn_fifo_m1_ready == 1'b1 && dcsn_fifo_m1_valid == 1'b1 && dcsn_fifo_m1_last == 1'b1 && dcsn_fifo_m1_dropped == 1'b1) begin
                num_packets_dropped <= num_packets_dropped + 1;
            end
            // synopsys translate_off
            // iverilog off
            // assert (((dcsn_fifo_m0_ready == 1'b1 && dcsn_fifo_m0_valid == 1'b1) && (dcsn_fifo_m1_ready == 1'b1 && dcsn_fifo_m1_valid == 1'b1)) == 1'b0)
            // else $error("It is not possible to have drive both M0 and M1 simultaneously");
            // iverilog on
            // synopsys translate_on
        end
    end

    // register bank
    packet_router_regbank u_packet_router_regbank (
        .clk                            (clk),
        .resetn                         (resetn),
        //
        .s_axil_araddr                  (s_axil_araddr),
        .s_axil_arvalid                 (s_axil_arvalid),
        .s_axil_arready                 (s_axil_arready),
        .s_axil_rdata                   (s_axil_rdata),
        .s_axil_rresp                   (s_axil_rresp),
        .s_axil_rvalid                  (s_axil_rvalid),
        .s_axil_rready                  (s_axil_rready),
        //
        .num_packets_sent_to_output_0   (num_packets_sent_to_output_0),
        .num_packets_sent_to_output_1   (num_packets_sent_to_output_1),
        .num_packets_dropped            (num_packets_dropped)
    );
endmodule

`default_nettype wire
