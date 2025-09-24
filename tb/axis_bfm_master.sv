
module axis_bfm_master #(
    parameter integer TDATA_WIDTH = 32
) (
    input  logic                   clk,

    output logic [TDATA_WIDTH-1:0]   m_axis_tdata,
    output logic                     m_axis_tlast,
    output logic                     m_axis_tvalid,
    input  logic                     m_axis_tready
);

    integer stall;
    initial begin
        stall = 0;
        m_axis_tdata = 0;
        m_axis_tlast = 0;
        m_axis_tvalid = 0;
    end

    task send(logic [TDATA_WIDTH-1:0] content []);
        integer number_cycles_tvalid_should_stall;

        if (stall < 0) number_cycles_tvalid_should_stall = $urandom % 10; // random stalls
        else           number_cycles_tvalid_should_stall = stall;         // fixed cycles of stalls
        for (integer i=0; i < content.size(); i++) begin
            m_axis_tdata = content[i];
            m_axis_tlast = (i == content.size()-1);
            m_axis_tvalid = 1;
            @ (posedge clk);
            m_axis_tvalid = 0;
            repeat (number_cycles_tvalid_should_stall) @ (posedge clk);
            m_axis_tvalid = 1;
        end
        @ (posedge clk);
        m_axis_tvalid = 0;
    endtask


endmodule