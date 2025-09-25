
// Copyrights
// This module add a register stage on an axi stream bus by making sure all
// inputs and outputs are registered.

module axis_register_stage (
    clk,
    resetn,
    //
    s_axis_tdata,
    s_axis_tlast,
    s_axis_tvalid,
    s_axis_tready,
    //
    m_axis_tdata,
    m_axis_tlast,
    m_axis_tvalid,
    m_axis_tready
);
    parameter integer TDATA_WIDTH = 32;

    input  logic                     clk;
    input  logic                     resetn;
    //
    input  logic [TDATA_WIDTH-1:0]   s_axis_tdata;
    input  logic                     s_axis_tlast;
    input  logic                     s_axis_tvalid;
    output logic                     s_axis_tready;
    //
    output logic [TDATA_WIDTH-1:0]   m_axis_tdata;
    output logic                     m_axis_tlast;
    output logic                     m_axis_tvalid;
    input  logic                     m_axis_tready;

    logic [TDATA_WIDTH-1:0] temp_tdata;
    logic                   temp_tlast;
    logic                   temp_tvalid;
    logic                   output_buffer_can_accept_data;

    // Cut the tready return path by adding a flipflop.
    // However this means that s_axis_tready will be delayed by 1 clk and this
    // means it will take 1 clk cycle for a downstream tready deassert to reach
    // upstream.
    always_ff @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            s_axis_tready <= 1'b1;
        end else begin
            s_axis_tready <= output_buffer_can_accept_data;
        end
    end

    // Therefore we should store the datapath in a temporary buffer when our
    // output buffer cannot accept data anymore
    always_ff @(posedge clk) begin
        if (s_axis_tready == 1'b1 && output_buffer_can_accept_data == 1'b0) begin
            temp_tdata  <= s_axis_tdata;
            temp_tlast  <= s_axis_tlast;
            temp_tvalid <= s_axis_tvalid;
        end
    end

    // output buffer can accept data when there is no valid data in the buffer
    // OR when downstream is ready to process the data anyway
    assign output_buffer_can_accept_data = !m_axis_tvalid | m_axis_tready;

    // Add registers on the output.
    // Depending on whether the output buffer can now accept data, we drive
    // the output either with contents of the temporary buffer or directly from
    // the input.
    always_ff @(posedge clk) begin
        if (s_axis_tready == 1'b0 && output_buffer_can_accept_data == 1'b1) begin
            m_axis_tdata <= temp_tdata;
            m_axis_tlast <= temp_tlast;
        end else if (s_axis_tready == 1'b1 && output_buffer_can_accept_data == 1'b1) begin
            m_axis_tdata <= s_axis_tdata;
            m_axis_tlast <= s_axis_tlast;
        end
    end
    always_ff @(posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            m_axis_tvalid <= 1'b0;
        end else if (s_axis_tready == 1'b0 && output_buffer_can_accept_data == 1'b1) begin
            m_axis_tvalid <= temp_tvalid;
        end else if (s_axis_tready == 1'b1 && output_buffer_can_accept_data == 1'b1) begin
            m_axis_tvalid <= s_axis_tvalid;
        end
    end
endmodule
