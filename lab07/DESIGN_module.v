module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
    seed_in,
    out_idle,
    out_valid,
    seed_out,

    sidle,
    clk1_handshake_flag2,
    sready,
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
input sidle;
input clk1_handshake_flag2;
output reg sready;
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
        sready    <= 0;
    end
    else if(st_IDLE)
    begin
        cur_state <= in_valid ? SEND_DATA : IDLE;
        seed_out  <= in_valid ? seed_in : seed_out;
        sready    <= in_valid ? 1 : 0;
    end
    else if(st_SEND_DATA)
    begin
        cur_state <=  sidle ? IDLE : SEND_DATA;
        sready    <=  sidle ? 0 : 1;
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
output out_valid;
output [31:0] rand_num;
output busy;

// You can change the input / output of the custom flag ports
input handshake_clk2_flag1;
input handshake_clk2_flag2;
output handshake_clk2_flag3;
output handshake_clk2_flag4;

input clk2_fifo_flag1;
input clk2_fifo_flag2;
output clk2_fifo_flag3;
output clk2_fifo_flag4;


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


endmodule