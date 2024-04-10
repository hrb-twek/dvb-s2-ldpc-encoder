`timescale 1ns / 1ps

module ldpc_enc_64800(
    clk,
    srst,

    rdy,

    in_sof,
    in_modcod,

    din,
    din_valid

);

input wire clk;
input wire srst;

output reg rdy;

input wire in_sof;
input wire [5-1:0]in_modcod;

input wire [8-1:0]din;
input wire din_valid;

reg  in_sof_prev;
wire in_sof_rise = &{ ~in_sof_prev, in_sof };
always@(posedge clk) begin
    in_sof_prev <= in_sof;
end

reg [4-1:0]sta=0;
reg [4-1:0]sta_next;
always@(posedge clk) begin
    if(srst == 1'b1) begin
        sta <= 0;
    end else begin
        sta <= sta_next;
    end
end

localparam [4-1:0]STA_0_RST        = 4'h0;
localparam [4-1:0]STA_1_CLR        = 4'h1; // 清空校验RAM
localparam [4-1:0]STA_2_WAIT_SOF   = 4'h2; // 等待SOF信号
localparam [4-1:0]STA_3_START_ENC  = 4'h3; // 开始编码，装载编码表
localparam [4-1:0]STA_4_WAIT_FIFO  = 4'h4; // 等待fifo的数据
localparam [4-1:0]STA_5_READ_FIFO  = 4'h5; // 从fifo中读取360个信息比特
localparam [4-1:0]STA_6_READ_RAM   = 4'h6; // 读取校验RAM
localparam [4-1:0]STA_7_XOR_DATA   = 4'h7; // 将信息比特移位后与校验RAM读出值做按位异或
localparam [4-1:0]STA_8_WR_BACK    = 4'h8; // 将异或结果写回校验RAM
localparam [4-1:0]STA_9_XOR_SUM0   = 4'h9; // 校验RAM内容在地址方向上做异或
localparam [4-1:0]STA_A_XOR_SUM1   = 4'ha;
localparam [4-1:0]STA_B_XOR_SUM2   = 4'hb;
localparam [4-1:0]STA_C_OUT0       = 4'hc; // 输出校验比特到行列变换模块
localparam [4-1:0]STA_D_OUT1       = 4'hd;
localparam [4-1:0]STA_E_OUT2       = 4'he;


reg  [26-1:0]rom;
wire [ 8-1:0]q_val         = rom[ 0+: 8];
wire [13-1:0]enc_base_addr = rom[ 8+:14];
wire [ 4-1:0]enc_rate_sel  = rom[22+: 4];
always@(posedge clk) begin
    if(in_sof_rise) begin
        case(in_modcod)
            default:                    rom <= { 4'h0, 14'd0000, 8'd135 }; // 1/4
            5'd2:                       rom <= { 4'h1, 14'd0270, 8'd120 }; // 1/3
            5'd3:                       rom <= { 4'h2, 14'd0630, 8'd108 }; // 2/5
            5'd4:                       rom <= { 4'h3, 14'd1062, 8'd090 }; // 1/2
            5'd5,  5'd12:               rom <= { 4'h4, 14'd1512, 8'd072 }; // 3/5
            5'd6,  5'd13, 5'd18:        rom <= { 4'h5, 14'd2160, 8'd060 }; // 2/3
            5'd7,  5'd14, 5'd19, 5'd24: rom <= { 4'h6, 14'd2640, 8'd045 }; // 3/4
            5'd8,         5'd20, 5'd25: rom <= { 4'h7, 14'd3180, 8'd036 }; // 4/5
            5'd9,  5'd15, 5'd21, 5'd26: rom <= { 4'h8, 14'd3756, 8'd030 }; // 5/6
            5'd10, 5'd16, 5'd22, 5'd27: rom <= { 4'h9, 14'd4356, 8'd020 }; // 8/9
            5'd11, 5'd17, 5'd23, 5'd28: rom <= { 4'ha, 14'd4856, 8'd018 }; // 9/10
        endcase
    end
end

always@(posedge clk) begin
    rdy <= (sta == STA_2_WAIT_SOF)? 1'b1: 1'b0;
end

reg [360-1:0]shift_360;
always@(posedge clk) begin
    if(din_valid) begin
        shift_360 <= { shift_360, din };
    end
end

reg [8-1:0]mv_in_cnt=0;
always@(posedge clk) begin
    if(in_sof_rise) begin
        if(din_valid) begin
            mv_in_cnt <= 1;
        end else begin
            mv_in_cnt <= 0;
        end
    end else begin
        if(mv_in_cnt >= (360/8)) begin
            if(din_valid) begin
                mv_in_cnt <= 1;
            end else begin
                mv_in_cnt <= 0;
            end
        end else begin
            if(din_valid) begin
                mv_in_cnt <= mv_in_cnt + 1;
            end
        end
    end
end

reg [360-1:0]shift_360_ff;
reg          shift_360_ff_valid;
always@(posedge clk) begin
    shift_360_ff <= shift_360;
    shift_360_ff_valid <= (mv_in_cnt == (360/8))? 1'b1: 1'b0;
end

wire fifo_rst = srst;
wire fifo_empty;
wire fifo_full;
reg  fifo_rd_en;
wire [360-1:0]fifo_dout;
wire fifo_dout_valid;
reg  [360-1:0]fifo_dout_keep;

xpm_fifo_sync #(
    .FIFO_MEMORY_TYPE("distributed"),
    .FIFO_READ_LATENCY(1),
    .FIFO_WRITE_DEPTH(256),
    .READ_DATA_WIDTH (360),
    .WRITE_DATA_WIDTH(360),
    .READ_MODE("std"),
    .USE_ADV_FEATURES("1000")
) xpm_fifo_sync_inst (
    .wr_clk      (clk),
    .rst         (fifo_rst),
    .empty       (fifo_empty),
    .full        (fifo_full),
    .wr_en       (shift_360_ff_valid),
    .din         (shift_360_ff),
    .rd_en       (fifo_rd_en),
    .data_valid  (fifo_dout_valid),
    .dout        (fifo_dout)
);

always@(posedge clk) begin
    if(fifo_dout_valid) begin
        fifo_dout_keep <= fifo_dout;
    end
end

always@(posedge clk) begin
    if(sta == STA_5_READ_FIFO) begin
        fifo_rd_en <= 1'b1;
    end else begin
        fifo_rd_en <= 1'b0;
    end
end

localparam RAM_ADDR_WID = 8;
reg  [RAM_ADDR_WID-1:0]ram_addr_w;
reg  [RAM_ADDR_WID-1:0]ram_addr_r;
reg  [360-1:0]ram_din;
reg           ram_we;
reg  [360-1:0]ram[0:(2**RAM_ADDR_WID)-1];
reg  [360-1:0]ram_dout_pre;
reg  [360-1:0]ram_dout;
wire [0:360-1]ram_dout_inv = ram_dout;
always@(posedge clk) begin
    if(ram_we) begin
        ram[ram_addr_w] <= ram_din;
    end
    ram_dout_pre <= ram[ram_addr_r];
    ram_dout <= ram_dout_pre;
end

reg [RAM_ADDR_WID-1:0]add_ram_addr;
always@(posedge clk) begin
    case(sta)
        default: begin
            add_ram_addr <= 0;
        end
        STA_1_CLR, STA_C_OUT0: begin
            add_ram_addr <= add_ram_addr + 1;
        end
    endcase
end


reg  [13-1:0]enc_tbl_addr;
wire [20-1:0]enc_tbl_out;
wire [ 9-1:0]enc_shift_val       = enc_tbl_out[ 0+:9];
wire [ 8-1:0]enc_parity_ram_addr = enc_tbl_out[10+:8];
wire [ 2-1:0]enc_next_op         = enc_tbl_out[18+:2];

enc_tbl_64800 u0_enc_tbl_64800(
    .clk (clk),
    .addr(enc_tbl_addr),
    .dout(enc_tbl_out)
);

always@(posedge clk) begin
    case(sta)
        STA_3_START_ENC: begin
            enc_tbl_addr <= enc_base_addr;
        end
        STA_8_WR_BACK: begin
            enc_tbl_addr <= enc_tbl_addr + 1;
        end
    endcase
end

wire [360-1:0]data_shifted;
barrel_shift #(
    .WIDTH(360),
    .SHIFT_VAL_WIDTH(9),
    .REG_EN(9'b100100100)
) barrel_shift_u0(
    .clk       (clk),
    .in        (fifo_dout_keep),
    .shift_val (enc_shift_val),
    .out       (data_shifted)
);

reg [RAM_ADDR_WID-1:0]xor_sum_addr;
always@(posedge clk) begin
    case(sta)
        STA_0_RST: begin
            xor_sum_addr <= 0;
        end
        STA_B_XOR_SUM2: begin
            xor_sum_addr <= xor_sum_addr + 1;
        end
    endcase
end

reg [0:0]exit_read_ram;
always@(posedge clk) begin
    if(sta == STA_6_READ_RAM) begin
        exit_read_ram <= { exit_read_ram, 1'b1 };
    end else begin
        exit_read_ram <= 0;
    end
end

always@(posedge clk) begin
    case(sta)
        default: begin
        end
        STA_6_READ_RAM: begin
            ram_addr_r <= enc_parity_ram_addr;
        end
        STA_9_XOR_SUM0: begin
            ram_addr_r <= xor_sum_addr;
        end
        STA_C_OUT0: begin
            ram_addr_r <= add_ram_addr;
        end
    endcase
end

reg [0:2-1]exit_xor_sum0;
always@(posedge clk) begin
    if(sta == STA_9_XOR_SUM0) begin
        exit_xor_sum0 <= { exit_xor_sum0, 1'b1 };
    end else begin
        exit_xor_sum0 <= 0;
    end
end

reg [360-1:0]xor_data;
always@(posedge clk) begin
    xor_data <= ram_dout ^ data_shifted;
end

reg  [360-1:0]xor_sum;
wire [0:360-1]xor_sum_inv = xor_sum;
always@(posedge clk) begin
    case(sta)
        default: begin
        end
        STA_0_RST: begin
            xor_sum <= 0;
        end
        STA_A_XOR_SUM1: begin
            xor_sum <= xor_sum ^ ram_dout;
        end
    endcase
end

reg  [0:360-1]xor_temp;
reg  [8-1:0]xor_h;
wire [  0:0]xor_temp_first_bit = ^xor_temp[0+:(8+1)];
always@(posedge clk) begin
    case(sta)
        STA_B_XOR_SUM2: begin
            xor_temp <= { 1'b0, xor_sum_inv[0+:359] };
        end
        STA_D_OUT1: begin
            xor_temp <= { xor_temp_first_bit, xor_temp[(8+1):359], 8'b0 };
        end
    endcase
end

always@(*) begin
    xor_h = {
        xor_temp[0:0],
        ^xor_temp[0:1],
        ^xor_temp[0:2],
        ^xor_temp[0:3],
        ^xor_temp[0:4],
        ^xor_temp[0:5],
        ^xor_temp[0:6],
        ^xor_temp[0:7] };
end

reg  [0:RAM_ADDR_WID*2-1]ram_addr_r_ff;
wire [RAM_ADDR_WID-1:0]ram_addr_r_dly = ram_addr_r_ff[0+:RAM_ADDR_WID];
always@(posedge clk) begin
    ram_addr_r_ff <= { ram_addr_r_ff, ram_addr_r };
end

reg  [0:3-1]ram_we_ff;
wire out_ram_we = ram_we_ff[0];
always@(posedge clk) begin
    if(sta == STA_C_OUT0) begin
        ram_we_ff <= { ram_we_ff, 1'b1 };
    end else begin
        ram_we_ff <= 0;
    end
end

always@(posedge clk) begin
    case(sta)
        default: begin
            ram_addr_w <= 0;
            ram_din <= 0;
            ram_we <= 0;
        end
        STA_1_CLR: begin
            ram_addr_w <= add_ram_addr;
            ram_din <= 0;
            ram_we <= 1'b1;
        end
        STA_8_WR_BACK: begin
            ram_addr_w <= enc_parity_ram_addr;
            ram_din <= xor_data;
            ram_we <= 1'b1;
        end
        STA_B_XOR_SUM2: begin
            ram_addr_w <= xor_sum_addr;
            ram_din <= xor_sum;
            ram_we <= 1'b1;
        end
        STA_C_OUT0: begin
            ram_addr_w <= ram_addr_r_dly;
            ram_din    <= ram_dout << 8;
            ram_we     <= out_ram_we;
        end
    endcase
end

localparam XOR_DATA_LATENCY = 3;
reg [0:XOR_DATA_LATENCY-1]exit_xor_data;
always@(posedge clk) begin
    if(sta == STA_7_XOR_DATA) begin
        exit_xor_data <= { exit_xor_data, 1'b1 };
    end else begin
        exit_xor_data <= 0;
    end
end

reg  [8-1:0]data_out;
reg         data_out_valid;
always@(posedge clk) begin
    data_out <= ram_dout_inv[0+:8] ^ xor_h;
    if(sta == STA_C_OUT0) begin
        data_out_valid <= out_ram_we;
    end else begin
        data_out_valid <= 0;
    end
end

reg [8-1:0]out_cnt;
always@(posedge clk) begin
    case(sta)
        STA_0_RST: begin
            out_cnt <= 0;
        end
        STA_D_OUT1: begin
            out_cnt <= out_cnt + 1;
        end
    endcase
end

always@(*) begin
    sta_next = sta;
    case(sta)
        default: begin
            sta_next = 0;
        end
        STA_0_RST: begin
            sta_next = STA_1_CLR;
        end
        STA_1_CLR: begin
            if(&{ ram_we, ram_addr_w }) begin
                sta_next = STA_2_WAIT_SOF;
            end
        end
        STA_2_WAIT_SOF: begin
            if(in_sof_rise) begin
                sta_next = STA_3_START_ENC;
            end
        end
        STA_3_START_ENC: begin
            sta_next = STA_4_WAIT_FIFO;
        end
        STA_4_WAIT_FIFO: begin
            if(~fifo_empty) begin
                sta_next = STA_5_READ_FIFO;
            end
        end
        STA_5_READ_FIFO: begin
            sta_next = STA_6_READ_RAM;
        end
        STA_6_READ_RAM: begin
            if(exit_read_ram[0]) begin
                sta_next = STA_7_XOR_DATA;
            end
        end
        STA_7_XOR_DATA: begin
            if(exit_xor_data[0]) begin
                sta_next = STA_8_WR_BACK;
            end
        end
        STA_8_WR_BACK: begin
            case(enc_next_op)
                default: begin
                    sta_next = STA_0_RST;
                end
                2'd1: begin
                    sta_next = STA_6_READ_RAM;
                end
                2'd2: begin
                    sta_next = STA_4_WAIT_FIFO;
                end
                2'd3: begin
                    sta_next = STA_9_XOR_SUM0;
                end
            endcase
        end
        STA_9_XOR_SUM0: begin
            if(exit_xor_sum0[0]) begin
                sta_next = STA_A_XOR_SUM1;
            end
        end
        STA_A_XOR_SUM1: begin
            sta_next = STA_B_XOR_SUM2;
        end
        STA_B_XOR_SUM2: begin
            if(xor_sum_addr >= (q_val-1)) begin
                sta_next <= STA_C_OUT0;
            end else begin
                sta_next <= STA_9_XOR_SUM0;
            end
        end
        STA_C_OUT0: begin
            if((out_ram_we == 1) && (ram_addr_r_dly == (q_val-1))) begin
                sta_next = STA_D_OUT1;
            end
        end
        STA_D_OUT1: begin
            if(out_cnt == ((360/8)-1)) begin
                sta_next = STA_E_OUT2;
            end else begin
                sta_next = STA_C_OUT0;
            end
        end
        STA_E_OUT2: begin
        end
    endcase
end



endmodule
