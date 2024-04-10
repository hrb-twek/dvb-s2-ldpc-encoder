`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/07 20:27:14
// Design Name: 
// Module Name: ldpc_enc_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ldpc_enc_tb();

parameter PERIOD = 2;
reg clk;
always begin
    clk = 1'b0;
    #(PERIOD/2) clk = 1'b1;
    #(PERIOD/2);
end

wire rdy;
reg [4-1:0]sta=0;
reg [16-1:0]delay_cnt=0;
always@(posedge clk) begin
    case(sta)
        0: begin
            delay_cnt <= delay_cnt + 1;
            if(delay_cnt == 32) begin
                sta <= 1;
            end
        end
        1: begin
            delay_cnt <= 0;
            if(rdy) sta <= 2;
        end
        2: begin
            sta <= 3;
        end
        3: begin
            delay_cnt <= delay_cnt + 1; 
        end
    endcase
end

ldpc_enc_64800 ldpc_enc_64800(
    .clk       (clk),
    .srst      (sta == 0),
    .rdy       (rdy),
    .in_sof    (sta == 2),
    .in_modcod (1),
    .din       (delay_cnt),
    .din_valid (sta == 3)
);

endmodule
