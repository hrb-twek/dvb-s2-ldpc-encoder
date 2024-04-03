`timescale 1ns / 1ps


module barrel_shift_tb();

parameter PERIOD = 2;
reg clk;
always begin
    clk = 1'b0;
    #(PERIOD/2) clk = 1'b1;
    #(PERIOD/2);
end

wire [360-1:0]in = 1<<0;

barrel_shift #(
    .WIDTH(360),
    .SHIFT_VAL_WIDTH(9),
    .REG_EN('h124)
) barrel_shift(
    .clk(clk),
    .in(in),
    .shift_val(1),
    .out()
);
    

endmodule
