module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
    seed_in,
    out_idle,
    out_valid,
    seed_out,

    clk1_handshake_flag1,
    clk1_handshake_flag2,
    clk1_handshake_flag3,
    clk1_handshake_flag4
);

input clk;
input rst_n;
input in_valid;
input [31:0] seed_in;
input out_idle;
output reg out_valid;
output reg [31:0] seed_out;

// You can change the input / output of the custom flag ports
input clk1_handshake_flag1;
input clk1_handshake_flag2;
output clk1_handshake_flag3;
output clk1_handshake_flag4;


reg[1:0] cur_state;

localparam IDLE = 2'b01;
localparam SEND_DATA = 2'b10;

wire st_IDLE = cur_state == IDLE;
wire st_SEND_DATA = cur_state == SEND_DATA;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
    begin
        cur_state <= IDLE;
        seed_out  <= 0;
        out_valid <= 0;
    end
    else if(st_IDLE)
    begin
        cur_state <= in_valid ? SEND_DATA : IDLE;
        seed_out  <= in_valid ? seed_in : seed_out;
        out_valid <= in_valid ? 1 : 0;
    end
    else if(st_SEND_DATA)
    begin
        cur_state <=  out_idle ? IDLE : SEND_DATA;
        out_valid <=  out_idle ? 0 : 1;
    end
end


endmodule

module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    seed,
    out_valid,
    rand_num,
    busy,

    handshake_clk2_flag1,
    handshake_clk2_flag2,
    handshake_clk2_flag3,
    handshake_clk2_flag4,

    clk2_fifo_flag1,
    clk2_fifo_flag2,
    clk2_fifo_flag3,
    clk2_fifo_flag4
);

input clk;
input rst_n;
input in_valid;
input fifo_full;
input [31:0] seed;
output reg out_valid;
output reg[31:0] rand_num;
output reg busy;

// You can change the input / output of the custom flag ports
input handshake_clk2_flag1;
input handshake_clk2_flag2;
output handshake_clk2_flag3;
output handshake_clk2_flag4;

input clk2_fifo_flag1;
input clk2_fifo_flag2;
output clk2_fifo_flag3;
output clk2_fifo_flag4;

reg[1:0] cur_state;
reg[1:0] cnt;
reg[5:0] rand_num_cnt;
localparam RD_DATA      = 2'b01;
localparam CAL_RAND_NUM = 2'b10;
localparam OUTPUT       = 2'b11;

wire st_RD_DATA       = cur_state == RD_DATA;
wire st_CAL_RAND_NUM  = cur_state == CAL_RAND_NUM;
wire st_OUTPUT        = cur_state == OUTPUT;

wire cal_done_f = cnt == 3;
wire fin_processing_f = rand_num_cnt == 255;

localparam a = 13;
localparam b = 17;
localparam c = 5;
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        cur_state <= RD_DATA;
        rand_num  <= 0;
        rand_num_cnt <= 0;
        cnt <= 0;
        busy <= 0;
        out_valid <= 0;
    end
    else
    begin
        case(cur_state)
        RD_DATA:
        begin
            cur_state <= in_valid ? CAL_RAND_NUM : RD_DATA;
            rand_num  <= in_valid ? seed : rand_num;
            rand_num_cnt <= 0;
            cnt <= 0;
            busy <= in_valid ? 1 : 0;
            out_valid <= 0;
        end
        CAL_RAND_NUM:
        begin
            cur_state    <= cal_done_f ? OUTPUT : CAL_RAND_NUM;
            cnt          <= cal_done_f ? 0 : cnt + 1;
            out_valid    <= 0;
            case(cnt)
            0:
            begin
                rand_num <= rand_num ^ (rand_num << a);
            end
            1:
            begin
                rand_num <= rand_num ^ (rand_num >> b);
            end
            2:
            begin
                rand_num <= rand_num ^ (rand_num << c);
            end
            endcase
        end
        OUTPUT:
        begin
            rand_num_cnt <= fifo_full ? rand_num_cnt : rand_num_cnt+1;
            cur_state    <= fifo_full ? OUTPUT : (fin_processing_f ? RD_DATA : CAL_RAND_NUM);
            out_valid    <= fifo_full ? 0 : 1;
            busy         <= fin_processing_f ? 0 : 1;
        end
        endcase
    end
end


endmodule

module CLK_3_MODULE (
    clk,
    rst_n,
    fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    rand_num,

    fifo_clk3_flag1,
    fifo_clk3_flag2,
    fifo_clk3_flag3,
    fifo_clk3_flag4
);

input clk;
input rst_n;
input fifo_empty;
input [31:0] fifo_rdata;
output fifo_rinc;
output reg out_valid;
output reg [31:0] rand_num;

// You can change the input / output of the custom flag ports
input fifo_clk3_flag1;
input fifo_clk3_flag2;
output fifo_clk3_flag3;
output fifo_clk3_flag4;


always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        out_valid <= 0;
        rand_num  <= 0;
    end
    else
    begin

    end
end


endmodule