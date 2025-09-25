
module axilite_bfm_master (
    input  logic                   clk,

    output logic [31:0]            m_axil_araddr,
    output logic                   m_axil_arvalid,
    input  logic                   m_axil_arready,
    input  logic [31:0]            m_axil_rdata,
    input  logic [1:0]             m_axil_rresp,
    input  logic                   m_axil_rvalid,
    output logic                   m_axil_rready
);

    initial begin
        m_axil_araddr = 0;
        m_axil_arvalid = 0;
        m_axil_rready = 0;
    end

    task read(logic [31:0] addr, output logic [31:0] data);
        m_axil_araddr = addr; m_axil_arvalid = 1; m_axil_rready = 0;
        while (m_axil_arready != 1) @(posedge clk);
        @(posedge clk);
        m_axil_arvalid = 0;
        m_axil_rready = 1;
        while (m_axil_rvalid != 1) @(posedge clk);
        data = m_axil_rdata;
        @ (posedge clk);
        m_axil_rready = 0;
    endtask

endmodule