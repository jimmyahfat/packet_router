
// Copyrights
//
// RTL to infer a bram

`default_nettype none

module bram #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4
)(
    input  logic clk,
    input  logic we,
    input  logic re,
    input  logic [ADDR_WIDTH-1:0] waddr,
    input  logic [ADDR_WIDTH-1:0] raddr,
    input  logic [DATA_WIDTH-1:0] wdata,
    output logic [DATA_WIDTH-1:0] rdata
);

    // Declare the BRAM memory array
    logic [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];

    // Read and Write operations
    always_ff @(posedge clk) begin
        if (we) begin
            mem[waddr] <= wdata;
        end

        if (re) begin
            rdata <= mem[raddr];
        end
    end

endmodule

`default_nettype wire
