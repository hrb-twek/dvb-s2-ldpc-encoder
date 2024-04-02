fp = fopen('../src/rtl/enc_tbl_64800.v', 'wt+');

fprintf(fp, "`timescale 1ns / 1ps\n");
fprintf(fp, "module enc_tbl_64800(\n");
fprintf(fp, "    clk,\n");
fprintf(fp, "    addr,\n");
fprintf(fp, "    dout\n");
fprintf(fp, ");\n");
fprintf(fp, "input wire clk;\n");
fprintf(fp, "input wire [13-1:0]addr;\n");
fprintf(fp, "output reg [20-1:0]dout;\n");
fprintf(fp, "always@(posedge clk) begin\n");
fprintf(fp, "    case(addr)\n");
fprintf(fp, "        default:  dout <= 0;\n");

run dvb_s2_64800_tables.m

addr = 0;
for k = 1:11
    switch k
        case 1
            single_tbl = tbl_b1;
        case 2
            single_tbl = tbl_b2;
        case 3
            single_tbl = tbl_b3;
        case 4
            single_tbl = tbl_b4;
        case 5
            single_tbl = tbl_b5;
        case 6
            single_tbl = tbl_b6;
        case 7
            single_tbl = tbl_b7;
        case 8
            single_tbl = tbl_b8;
        case 9
            single_tbl = tbl_b9;
        case 10
            single_tbl = tbl_b10;
        case 11
            single_tbl = tbl_b11;
    end
    row = size(single_tbl)*[1;0];
    col = size(single_tbl)*[0;1];
    q = 180 - row;
    for i = 1:row
        for j = 1:col
            if(j == col) % 一行的最后一个
                op = 2;
            else
                if(single_tbl(i, j+1) < 0) % 后一个小于0， 该位为该行的最后一个
                    op = 2;
                    if(i == row) % 整张表的最后一个
                        op = 3;
                    end
                else
                    op = 1;
                end
            end
            value = single_tbl(i, j);
            if(value < 0)
                break;
            end
            if((i == 1) && (j == 1))
                fprintf(fp, "        // Q=%d, BaseAddr=%d\n", q, addr);
                fprintf("Q=%d, BaseAddr=%d\n", q, addr);
            end
            tbl_addr = mod(value, q);
            shift_val = floor(value/q);
            fprintf(fp, "        'd%04d: dout <= { 2'd%1d, 8'd%03d, 10'd%03d }; \n", addr, op, tbl_addr, shift_val);
            addr = addr + 1;
        end
    end
end
fprintf(fp, "    endcase\n");
fprintf(fp, "end\n");
fprintf(fp, "endmodule\n");

fclose(fp);
