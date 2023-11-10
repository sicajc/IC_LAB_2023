module Handshake_syn #(parameter WIDTH=32) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    clk1_handshake_flag1,
    clk1_handshake_flag2,
    clk1_handshake_flag3,
    clk1_handshake_flag4,

    handshake_clk2_flag1,
    handshake_clk2_flag2,
    handshake_clk2_flag3,
    handshake_clk2_flag4
);

input sclk, dclk;
input rst_n;
input sready;
input [WIDTH-1:0] din;
input dbusy;
output sidle;
output reg dvalid;
output reg [WIDTH-1:0] dout;

// You can change the input / output of the custom flag ports
input clk1_handshake_flag1;
input clk1_handshake_flag2;
output clk1_handshake_flag3;
output clk1_handshake_flag4;

input handshake_clk2_flag1;
input handshake_clk2_flag2;
output handshake_clk2_flag3;
output handshake_clk2_flag4;

// Remember:
//   Don't modify the signal name
reg sreq;
wire dreq;
reg dack;
wire sack;


localparam IDLE         = 3'b001;
localparam SENDING_DATA = 3'b010;
localparam OUTPUT       = 3'b100;

wire src_hand_shaked_f = sreq && sack;
wire dst_hand_shaked_f = ~dreq && dack;

reg[31:0] src_ff,dst_ff;

reg[2:0] src_cur_state,dst_cur_state;
wire st_src_IDLE = src_cur_state == IDLE;
wire st_src_SD   = src_cur_state == SENDING_DATA;
wire st_dst_IDLE = dst_cur_state == IDLE;
wire st_dst_SD   = dst_cur_state == SENDING_DATA;
wire st_dst_OUT   = dst_cur_state == OUTPUT;

wire sidle = st_src_IDLE;

// Src
always @(posedge sclk or negedge rst_n)
begin
    if(~rst_n)
    begin
        src_cur_state <= IDLE;
        sreq <= 0;
        src_ff <= 0;
    end
    else
    begin
        case (src_cur_state)
            IDLE:
            begin
                src_cur_state <= sready            ? SENDING_DATA : IDLE;
                sreq          <= sready ? 1 : 0;
                src_ff        <= din;
            end
            SENDING_DATA :
            begin
                src_cur_state <= src_hand_shaked_f ? IDLE         : SENDING_DATA;
                sreq          <= src_hand_shaked_f ? 0 : 1;
            end
        endcase
    end
end


// dst
always @(posedge dclk or negedge rst_n)
begin
    if(~rst_n)
    begin
        dst_cur_state <= IDLE;
        dst_ff <= 0;
        dack   <= 0;
        dout   <= 0;
        dvalid <= 0;
    end
    else
    begin
        case (dst_cur_state)
            IDLE:
            begin
                dst_cur_state <= (~dbusy && dreq )            ? SENDING_DATA : IDLE;
                dack          <= 0;
                dout          <= 0;
                dvalid        <= 0;
            end
            SENDING_DATA:
            begin
                dst_cur_state <= dst_hand_shaked_f ? OUTPUT         : SENDING_DATA;
                dack          <= dst_hand_shaked_f ? 0 : 1;
                dst_ff        <= dst_hand_shaked_f ? src_ff : dst_ff;
            end
            OUTPUT:
            begin
                dst_cur_state <= IDLE;
                dvalid        <= 1;
                dout          <= dst_ff;
            end
        endcase
    end
end

// Synchronizers
NDFF_syn sreq_dreq(.D(sreq), .Q(dreq), .clk(dclk), .rst_n(rst_n));
NDFF_syn dack_sack(.D(dack), .Q(sack), .clk(sclk), .rst_n(rst_n));


endmodule