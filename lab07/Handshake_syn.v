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
output reg sidle;
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


wire src_hand_shaked_f = sreq && sack;
wire dst_hand_shaked_f = ~dreq && dack;
reg[31:0] src_ff,dst_ff;


// Src
always @(posedge sclk or negedge rst_n)
begin
    if(~rst_n)
        src_ff <= 0;
    else if(sready && ~sreq)
        src_ff <= din;
end

always @(posedge sclk or negedge rst_n)
begin
    if(~rst_n)
        sreq <= 0;
    else if(src_hand_shaked_f)
        sreq <= 0;
    else if(sready && ~sreq)
        sreq <= 1;
end

always @(*)
begin
    if(sreq && ~sack)
        sidle = 0;
    else if(~sreq && sready)
        sidle = 0;
    else
        sidle = 1;
end

// DST
always @(posedge dclk or negedge rst_n)
begin
    if(~rst_n)
        dst_ff <= 0;
    else if(dreq && dack)
        dst_ff <= src_ff;
end

always @(posedge dclk or negedge rst_n)
begin
    if(~rst_n)
        dack <= 0;
    else if(dbusy)
        dack <= dack;
    else
        dack <= dreq;
end

always @(*)
begin
    if(dbusy)
    begin
        dvalid = 0;
        dout   = dst_ff;
    end
    else if(dst_hand_shaked_f)
    begin
        dvalid = 1;
        dout   = dst_ff;
    end
    else
    begin
        dvalid = 0;
        dout   = dst_ff;
    end
end



// Synchronizers
NDFF_syn sreq_dreq(.D(sreq), .Q(dreq), .clk(dclk), .rst_n(rst_n));
NDFF_syn dack_sack(.D(dack), .Q(sack), .clk(sclk), .rst_n(rst_n));


endmodule