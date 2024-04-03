`timescale 1ns / 1ps

module barrel_shift #(
    parameter WIDTH = 360,
    parameter SHIFT_VAL_WIDTH = 9,
    parameter [SHIFT_VAL_WIDTH-1:0] REG_EN = 'h124
)(
    clk,
    in,
    shift_val,
    out
);

input  wire clk;
input  wire [WIDTH-1:0]in;
input  wire [SHIFT_VAL_WIDTH-1:0]shift_val;
output wire [WIDTH-1:0]out;

wire [WIDTH-1:0]shift_in [0:SHIFT_VAL_WIDTH-1];
wire [WIDTH-1:0]shift_out[0:SHIFT_VAL_WIDTH-1];

assign shift_in[0] = in;
genvar i;
generate
    for(i=1;i<SHIFT_VAL_WIDTH;i=i+1) begin
        assign shift_in[i] = shift_out[i-1];
    end
endgenerate

generate
    for(i=0;i<SHIFT_VAL_WIDTH;i=i+1) begin
        barrel_shift_val #(
            .REG(REG_EN[i]),
            .WIDTH(WIDTH),
            .SHIFT_VAL(2**i)
        ) barrel_shift_val_u_inst(
            .clk (clk),
            .in  (shift_in[i]),
            .sel (shift_val[i]),
            .out (shift_out[i])
        );

    end
endgenerate

assign out = shift_out[SHIFT_VAL_WIDTH-1];

endmodule
