`timescale 1ns / 1ps

module barrel_shift_val #(
    parameter REG = 0,
    parameter WIDTH = 360,
    parameter SHIFT_VAL = 180
)(
    clk,
    in,
    sel,
    out
);
input wire clk;
input wire [WIDTH-1:0] in;
input wire sel;
input wire [WIDTH-1:0] out;

reg  [0:WIDTH-1]shift;
always@(*) begin
    shift = 0;
    shift = shift | (in >> SHIFT_VAL);
    shift = shift | (in << (WIDTH-SHIFT_VAL));
end

wire [WIDTH-1:0]out_pre = (sel == 1'b1)? shift: in;
reg  [WIDTH-1:0]out_ff;
always@(posedge clk) begin
    out_ff <= out_pre;
end

generate 
    if(REG == 1) begin
        assign out = out_ff;
    end else begin
        assign out = out_pre;
    end
endgenerate

endmodule
