
module tb;

    timeunit 1ns;
    timeprecision 1ps;

    localparam TDATA_WIDTH = 32;
    localparam DEPTH       = 32;

    logic clk;
    logic resetn;
    //
    logic [31:0]            axil_araddr;
    logic                   axil_arvalid;
    logic                   axil_arready;
    logic [31:0]            axil_rdata;
    logic [1:0]             axil_rresp;
    logic                   axil_rvalid;
    logic                   axil_rready;
    //
    logic [TDATA_WIDTH-1:0] s_axis_tdata;
    logic                   s_axis_tlast;
    logic                   s_axis_tvalid;
    logic                   s_axis_tready;
    //
    logic [TDATA_WIDTH-1:0] m0_axis_tdata;
    logic                   m0_axis_tlast;
    logic                   m0_axis_tvalid;
    logic                   m0_axis_tready;
    //
    logic [TDATA_WIDTH-1:0] m1_axis_tdata;
    logic                   m1_axis_tlast;
    logic                   m1_axis_tvalid;
    logic                   m1_axis_tready;

    typedef logic [TDATA_WIDTH-1:0] packet_t [];

    initial begin
        clk = 0;
        forever clk = #10 ~clk;
    end

    initial begin
        resetn = 0;
        repeat (50) @ (posedge clk);
        resetn = 1;
        repeat (100000) @ (posedge clk);
        $finish;
    end

    axis_bfm_master source (.clk(clk), .m_axis_tdata(s_axis_tdata),  .m_axis_tlast(s_axis_tlast),  .m_axis_tvalid(s_axis_tvalid),  .m_axis_tready(s_axis_tready));
    axis_bfm_slave  even   (.clk(clk), .s_axis_tdata(m0_axis_tdata), .s_axis_tlast(m0_axis_tlast), .s_axis_tvalid(m0_axis_tvalid), .s_axis_tready(m0_axis_tready));
    axis_bfm_slave  odd    (.clk(clk), .s_axis_tdata(m1_axis_tdata), .s_axis_tlast(m1_axis_tlast), .s_axis_tvalid(m1_axis_tvalid), .s_axis_tready(m1_axis_tready));
    axilite_bfm_master axilite (.clk(clk), .m_axil_araddr(axil_araddr),
                                           .m_axil_arvalid(axil_arvalid),
                                           .m_axil_arready(axil_arready),
                                           .m_axil_rdata(axil_rdata),
                                           .m_axil_rresp(axil_rresp),
                                           .m_axil_rvalid(axil_rvalid),
                                           .m_axil_rready(axil_rready));
    packet_router #(
        .TDATA_WIDTH(32),
        .DEPTH      (32)
    ) dut (
       .clk             (clk),
       .resetn          (resetn),
       //
       .s_axil_araddr   (axil_araddr),
       .s_axil_arvalid  (axil_arvalid),
       .s_axil_arready  (axil_arready),
       .s_axil_rdata    (axil_rdata),
       .s_axil_rresp    (axil_rresp),
       .s_axil_rvalid   (axil_rvalid),
       .s_axil_rready   (axil_rready),
       //
       .s_axis_tdata    (s_axis_tdata),
       .s_axis_tlast    (s_axis_tlast),
       .s_axis_tvalid   (s_axis_tvalid),
       .s_axis_tready   (s_axis_tready),
       //
       .m0_axis_tdata   (m0_axis_tdata),
       .m0_axis_tlast   (m0_axis_tlast),
       .m0_axis_tvalid  (m0_axis_tvalid),
       .m0_axis_tready  (m0_axis_tready),
       //
       .m1_axis_tdata   (m1_axis_tdata),
       .m1_axis_tlast   (m1_axis_tlast),
       .m1_axis_tvalid  (m1_axis_tvalid),
       .m1_axis_tready  (m1_axis_tready)
    );

    initial begin
        logic [31:0] packet [];
        logic [31:0] data;
        even.configure_backpressure(12);
        odd.configure_backpressure(2);
        repeat (1000) @(posedge clk);

        packet = generate_even_packet(10);
        source.send(packet);

        packet = generate_odd_packet(10);
        source.send(packet);
        packet = generate_odd_packet(10);
        source.send(packet);

        packet = generate_even_packet(321);
        source.send(packet);
        packet = generate_odd_packet(1000);
        source.send(packet);
        packet = generate_even_packet(1);
        source.send(packet);

        repeat (1000) @(posedge clk);
        axilite.read(0, data);
        axilite.read(4, data);
        axilite.read(8, data);
    end

    initial begin
        if ($test$plusargs ("vcd")) begin
            string vcdfile;
            int res;
            res = $value$plusargs("vcd+%s", vcdfile);
            $dumpfile(vcdfile);
            $dumpvars();
        end
    end

    function packet_t generate_even_packet(integer length);
        logic [31:0] packet [];
        packet = new[length];
        foreach (packet[i]) packet[i] = $urandom & 'hFFFF_FFFE;
        return packet;
    endfunction

    function packet_t generate_odd_packet(integer length);
        logic [31:0] packet [];
        packet = new[length];
        foreach (packet[i]) packet[i] = $urandom | 'h0000_0001;
        return packet;
    endfunction

endmodule
