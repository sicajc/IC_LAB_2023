module FIFO_syn #(parameter WIDTH=32, parameter WORDS=64) (
    wclk,
    rclk,
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    clk2_fifo_flag1,
    clk2_fifo_flag2,
    clk2_fifo_flag3,
    clk2_fifo_flag4,

    fifo_clk3_flag1,
    fifo_clk3_flag2,
    fifo_clk3_flag3,
    fifo_clk3_flag4
);

input wclk, rclk;
input rst_n;
input winc;
input [WIDTH-1:0] wdata;
output reg wfull;
input rinc;
output reg [WIDTH-1:0] rdata;
output reg rempty;

// You can change the input / output of the custom flag ports
input clk2_fifo_flag1;
input clk2_fifo_flag2;
output clk2_fifo_flag3;
output clk2_fifo_flag4;

input fifo_clk3_flag1;
input fifo_clk3_flag2;
output fifo_clk3_flag3;
output fifo_clk3_flag4;

wire [WIDTH-1:0] rdata_q;

// Remember:
//   wptr and rptr should be gray coded
//   Don't modify the signal name
reg [$clog2(WORDS):0] wptr;
reg [$clog2(WORDS):0] rptr;

wire wptr_counts = winc & ~wfull;
wire rptr_counts = rinc & ~rempty;

reg[5:0] wptr_sram_addr,rptr_sram_addr;
wire[6:0] rptr_d2;
wire[6:0] wptr_d2;

reg[6:0] wptr_bin;
wire[6:0] wptr_bin_nxt   = wptr_bin + wptr_counts;
wire[6:0] wptr_gray_next = bin2gray(wptr_bin_nxt);

reg[6:0]  rptr_bin;
wire[6:0] rptr_bin_nxt   = rptr_bin + rptr_counts;
wire[6:0] rptr_gray_nxt  = bin2gray(rptr_bin_nxt);

reg rinc_delay;

// rdata
//  Add one more register stage to rdata
always @(posedge rclk)
begin
    if(rinc || rinc_delay)
        rdata <= rdata_q;
    else
        rdata <= rdata;
end

//----------------------------------------------
//      WR
//----------------------------------------------
always @(posedge wclk or negedge rst_n)
begin
    if(~rst_n)
    begin
        wptr <= 0;
    end
    else
    begin
        wptr     <= wptr_gray_next;
    end
end

always @(posedge wclk or negedge rst_n)
begin
    if(~rst_n)
    begin
        wptr_bin <= 0;
    end
    else
    begin
        wptr_bin <= wptr_bin_nxt;
    end
end

always @(posedge wclk or negedge rst_n)
begin
    if(~rst_n)
        wfull <= 1'b0;
    else
        wfull <= ({~rptr_d2[6],~rptr_d2[5],rptr_d2[4:0]} == wptr_gray_next);
end

// Receive rptr_d2 and decode it for full address determination
NDFF_BUS_syn #(.WIDTH(7)) syn_rptr_u1(.D(rptr), .Q(rptr_d2), .clk(wclk), .rst_n(rst_n));

//----------------------------------------------
//      RD
//----------------------------------------------
always @(posedge rclk or negedge rst_n)
begin
    if(~rst_n)
    begin
        rptr_bin <= 0;
    end
    else
    begin
        rptr_bin <= rptr_bin_nxt;
    end
end

always @(posedge rclk or negedge rst_n)
begin
    if(~rst_n)
    begin
        rptr <= 0;
    end
    else
    begin
        rptr <= rptr_gray_nxt;
    end
end

always @(posedge rclk or negedge rst_n)
begin
    if(~rst_n)
        rempty <= 1'b1;
    else
        rempty <= (wptr_d2 == rptr_gray_nxt);
end

// Synchronizers
NDFF_BUS_syn #(.WIDTH(7)) syn_wptr_u0(.D(wptr), .Q(wptr_d2), .clk(rclk), .rst_n(rst_n));


always @(posedge rclk)
begin
    if(~rst_n)
        rinc_delay <= 1'b0;
    else
        rinc_delay <= rinc;
end

//----------------------------------------------
//      SRAM addr
//----------------------------------------------
always @(*)
begin
    wptr_sram_addr = wptr_bin[5:0];
    rptr_sram_addr = rptr_bin[5:0];
end


DUAL_64X32X1BM1 u_dual_sram (
    .CKA(wclk),
    .CKB(rclk),
    .WEAN(~winc),
    .WEBN(1'b1),
    .CSA(1'b1),
    .CSB(1'b1),
    .OEA(1'b1),
    .OEB(1'b1),
    .A0(wptr_sram_addr[0]),
    .A1(wptr_sram_addr[1]),
    .A2(wptr_sram_addr[2]),
    .A3(wptr_sram_addr[3]),
    .A4(wptr_sram_addr[4]),
    .A5(wptr_sram_addr[5]),
    .B0(rptr_sram_addr[0]),
    .B1(rptr_sram_addr[1]),
    .B2(rptr_sram_addr[2]),
    .B3(rptr_sram_addr[3]),
    .B4(rptr_sram_addr[4]),
    .B5(rptr_sram_addr[5]),
    .DIA0(wdata[0]),
    .DIA1(wdata[1]),
    .DIA2(wdata[2]),
    .DIA3(wdata[3]),
    .DIA4(wdata[4]),
    .DIA5(wdata[5]),
    .DIA6(wdata[6]),
    .DIA7(wdata[7]),
    .DIA8(wdata[8]),
    .DIA9(wdata[9]),
    .DIA10(wdata[10]),
    .DIA11(wdata[11]),
    .DIA12(wdata[12]),
    .DIA13(wdata[13]),
    .DIA14(wdata[14]),
    .DIA15(wdata[15]),
    .DIA16(wdata[16]),
    .DIA17(wdata[17]),
    .DIA18(wdata[18]),
    .DIA19(wdata[19]),
    .DIA20(wdata[20]),
    .DIA21(wdata[21]),
    .DIA22(wdata[22]),
    .DIA23(wdata[23]),
    .DIA24(wdata[24]),
    .DIA25(wdata[25]),
    .DIA26(wdata[26]),
    .DIA27(wdata[27]),
    .DIA28(wdata[28]),
    .DIA29(wdata[29]),
    .DIA30(wdata[30]),
    .DIA31(wdata[31]),
    // .DIB0(),
    // .DIB1(),
    // .DIB2(),
    // .DIB3(),
    // .DIB4(),
    // .DIB5(),
    // .DIB6(),
    // .DIB7(),
    // .DIB8(),
    // .DIB9(),
    // .DIB10(),
    // .DIB11(),
    // .DIB12(),
    // .DIB13(),
    // .DIB14(),
    // .DIB15(),
    // .DIB16(),
    // .DIB17(),
    // .DIB18(),
    // .DIB19(),
    // .DIB20(),
    // .DIB21(),
    // .DIB22(),
    // .DIB23(),
    // .DIB24(),
    // .DIB25(),
    // .DIB26(),
    // .DIB27(),
    // .DIB28(),
    // .DIB29(),
    // .DIB30(),
    // .DIB31(),
    .DOB0(rdata_q[0]),
    .DOB1(rdata_q[1]),
    .DOB2(rdata_q[2]),
    .DOB3(rdata_q[3]),
    .DOB4(rdata_q[4]),
    .DOB5(rdata_q[5]),
    .DOB6(rdata_q[6]),
    .DOB7(rdata_q[7]),
    .DOB8(rdata_q[8]),
    .DOB9(rdata_q[9]),
    .DOB10(rdata_q[10]),
    .DOB11(rdata_q[11]),
    .DOB12(rdata_q[12]),
    .DOB13(rdata_q[13]),
    .DOB14(rdata_q[14]),
    .DOB15(rdata_q[15]),
    .DOB16(rdata_q[16]),
    .DOB17(rdata_q[17]),
    .DOB18(rdata_q[18]),
    .DOB19(rdata_q[19]),
    .DOB20(rdata_q[20]),
    .DOB21(rdata_q[21]),
    .DOB22(rdata_q[22]),
    .DOB23(rdata_q[23]),
    .DOB24(rdata_q[24]),
    .DOB25(rdata_q[25]),
    .DOB26(rdata_q[26]),
    .DOB27(rdata_q[27]),
    .DOB28(rdata_q[28]),
    .DOB29(rdata_q[29]),
    .DOB30(rdata_q[30]),
    .DOB31(rdata_q[31])
);

function [6:0] bin2gray;
    input[6:0] bin;
    begin
        bin2gray = bin ^ (bin >> 1);
    end
endfunction

endmodule