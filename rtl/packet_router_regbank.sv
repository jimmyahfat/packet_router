
// Copyrights
//
// AXI Lite register bank
// Address 0x0:     Num packets sent to Output 0
// Address 0x4:     Num packets sent to Output 1
// Address 0x8:     Num packets dropped

`default_nettype none

module packet_router_regbank (
    input  logic                   clk,
    input  logic                   resetn,
    //
    input  logic [31:0]            s_axil_araddr,
    input  logic                   s_axil_arvalid,
    output logic                   s_axil_arready,
    output logic [31:0]            s_axil_rdata,
    output logic [1:0]             s_axil_rresp,
    output logic                   s_axil_rvalid,
    input  logic                   s_axil_rready,
    //
    input  logic [31:0]            num_packets_sent_to_output_0,
    input  logic [31:0]            num_packets_sent_to_output_1,
    input  logic [31:0]            num_packets_dropped
);
    //
    typedef enum { AR, R } state_t;
    state_t current_state, next_state;
    logic [31:0] current_data, next_data;
    logic [1:0]  current_resp, next_resp;

    always_ff @ (posedge clk or negedge resetn) begin
        if (resetn == 1'b0) begin
            current_state <= AR;
            current_data  <= 0;
            current_resp  <= 2'b00;
        end else begin
            current_state <= next_state;
            current_data  <= next_data;
            current_resp  <= next_resp;
        end
    end

    always_comb begin
        next_state = current_state;
        next_data  = current_data;
        next_resp  = current_resp;
        case (current_state)
        AR: begin
            if (s_axil_arvalid == 1'b1)
                next_state = R;
                 if (s_axil_araddr == 'd0) next_data = num_packets_sent_to_output_0;
            else if (s_axil_araddr == 'd4) next_data = num_packets_sent_to_output_1;
            else if (s_axil_araddr == 'd8) next_data = num_packets_dropped;
            else                           next_resp = 2'b11;
            next_resp  = 2'b00;
        end
        R: begin
            if (s_axil_rready == 1'b1) next_state = AR;
        end
        endcase
    end

    assign s_axil_arready = (current_state == AR);
    assign s_axil_rvalid = (current_state == R);
    assign s_axil_rdata = current_data;
    assign s_axil_rresp = current_resp;


endmodule

`default_nettype wire