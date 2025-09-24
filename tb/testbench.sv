
module tb;


logic clk;
logic resetn;

    function axi_rd(logic [31:0] addr, output logic [31:0] data);
        s_axil_araddr = addr; s_axil_arvalid = 1; s_axil_rready = 0;
        @ (posedge clk);
        while (s_axil_arready != 1) @(posedge clk);
        s_axil_arvalid = 0;
        s_axil_rready = 1;
        while (s_axil_rvalid != 1) @(posedge clk);
        data = s_axil_rdata;
        @ (posedge clk);
        s_axil_rready = 0;
    endfunction

    function axis_send_random(logic [31:0] last);
        s_axis_tvalid = 1;
        s_axis_tdata = $random();
        s_axis_tlast = last;
        @ (posedge clk);
        while (s_axis_tready != 1) @(posedge clk);
        s_axis_tvalid = 0;
    endfunction

    function axis_send_even(logic [31:0] last);
        s_axis_tvalid = 1;
        s_axis_tdata = $random() & 32'hFFFFFFFE;
        s_axis_tlast = last;
        @ (posedge clk);
        while (s_axis_tready != 1) @(posedge clk);
        s_axis_tvalid = 0;
    endfunction

    function axis_send_odd(logic [31:0] last);
        s_axis_tvalid = 1;
        s_axis_tdata = $random() | 32'h00000001;
        s_axis_tlast = last;
        @ (posedge clk);
        while (s_axis_tready != 1) @(posedge clk);
        s_axis_tvalid = 0;
    endfunction
endmodule;
