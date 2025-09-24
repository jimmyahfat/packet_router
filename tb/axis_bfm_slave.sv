
module axis_bfm_slave #(
    parameter integer TDATA_WIDTH = 32
) (
    input  logic                   clk,

    input  logic [TDATA_WIDTH-1:0]   s_axis_tdata,
    input  logic                     s_axis_tlast,
    input  logic                     s_axis_tvalid,
    output logic                     s_axis_tready
);

    integer backpressure;
    initial begin
        s_axis_tready = 1;
        backpressure = 0;
        forever begin
            @ (posedge clk);
            if (s_axis_tready & s_axis_tvalid) begin
                integer number_cycles_tready_should_backpressure;

                if (backpressure < 0) number_cycles_tready_should_backpressure = $urandom % 10; // random backpressure
                else                  number_cycles_tready_should_backpressure = backpressure;  // fixed cycles of back pressure
                @ (posedge clk);
                s_axis_tready = 0;
                repeat (number_cycles_tready_should_backpressure) @ (posedge clk);
                s_axis_tready = 1;
            end
        end
    end

    function void configure_backpressure(integer number_of_cycles);
        backpressure = number_of_cycles;
    endfunction


endmodule