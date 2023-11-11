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
localparam WAIT_RESP = 2'b11;
localparam SEND_DATA = 2'b10;


wire st_IDLE = cur_state == IDLE;
wire st_SEND_DATA = cur_state == SEND_DATA;
wire st_WAIT_RESP = cur_state == WAIT_RESP;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
    begin
        cur_state <= IDLE;
        seed_out  <= 0;
        out_valid <= 0;
    end
    else if(st_IDLE)
    begin
        cur_state <= in_valid ? WAIT_RESP : IDLE;
        seed_out  <= in_valid ? seed_in : seed_out;
        out_valid <= in_valid ? 1 : 0;
    end
    else if(st_WAIT_RESP)
    begin
        cur_state <= SEND_DATA;
        out_valid <= 0;
        seed_out  <= 0;
    end
    else if(st_SEND_DATA)
    begin
        cur_state <=  out_idle ? IDLE : SEND_DATA;
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
reg[8:0] rand_num_cnt;

localparam RD_DATA      = 2'b01;
localparam OUTPUT       = 2'b11;

wire st_RD_DATA       = cur_state == RD_DATA;
wire st_OUTPUT        = cur_state == OUTPUT;

wire fin_processing_f = rand_num_cnt == 255;

localparam a = 13;
localparam b = 17;
localparam c = 5;

reg[31:0] rand_num_ff;

always @(*)
begin
    out_valid = fifo_full ? 0 : st_OUTPUT;
end

always @(*)
begin
    busy = st_OUTPUT;
end

always @(*)
begin
    rand_num = fifo_full ? 0 : (st_OUTPUT ? prng_xor(rand_num_ff) : 0);
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        cur_state <= RD_DATA;
        rand_num_ff  <= 0;
        rand_num_cnt <= 0;
    end
    else
    begin
        case(cur_state)
        RD_DATA:
        begin
            cur_state    <= in_valid ? OUTPUT:RD_DATA;
            rand_num_ff  <= in_valid ? seed  : rand_num;
            rand_num_cnt <= 0;
        end
        OUTPUT:
        begin
            cur_state    <= fin_processing_f ? RD_DATA : OUTPUT;
            rand_num_ff  <= fifo_full ?  rand_num_ff : prng_xor(rand_num_ff);
            rand_num_cnt <= fin_processing_f ? 0 : rand_num_cnt + 1;
        end
        endcase
    end
end

function [31:0] prng_xor;
    input[31:0] randnum_prev;
    localparam a = 13;
    localparam b = 17;
    localparam c = 5;
    reg[31:0] temp_num0,temp_num1,temp_num2;

    begin
        temp_num0 = randnum_prev ^ (randnum_prev << a);
        temp_num1 = temp_num0    ^ (temp_num0 >> b);
        prng_xor  = temp_num1    ^ (temp_num1 << c);
    end
endfunction

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
output reg fifo_rinc;
output reg out_valid;
output reg [31:0] rand_num;

// You can change the input / output of the custom flag ports
input fifo_clk3_flag1;
input fifo_clk3_flag2;
output fifo_clk3_flag3;
output fifo_clk3_flag4;

reg[8:0] cnt;


reg out_valid_d1,out_valid_d2,out_valid_d3;
reg fifo_empty_d2,fifo_empty_d1;

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        // out_valid <= 0;
        out_valid_d2 <= 0;
        out_valid_d3 <= 0;
        fifo_empty_d1 <= 1;
        fifo_empty_d2 <= 1;
    end
    else
    begin
        fifo_empty_d1 <= fifo_empty;
        fifo_empty_d2 <= fifo_empty_d1;
        out_valid_d2 <= out_valid_d1;
        out_valid_d3 <= out_valid_d2;
        // out_valid    <= out_valid_d3;
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        out_valid <= 0;
        rand_num  <= 0;
        fifo_rinc <= 0;
        out_valid_d1 <= 0;
    end
    else if(fifo_empty_d2)
    begin
        out_valid <= 0;
        rand_num  <= 0;
        fifo_rinc <= 0;
        out_valid_d1 <= 0;
    end
    else
    begin
        out_valid_d1 <= 1;
        out_valid    <= out_valid_d3;
        rand_num     <= out_valid_d3 ? fifo_rdata : 0;
        fifo_rinc    <= 1;
    end
end


endmodule