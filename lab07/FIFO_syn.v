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
wire [$clog2(WORDS):0] wptr;
wire [$clog2(WORDS):0] rptr;


reg w_ptr_counts,r_ptr_counts;
reg wen;


// rdata
//  Add one more register stage to rdata
always @(posedge rclk) begin
    if(rinc)
        rdata <= rdata_q;
end

reg[6:0] wptr_real_gray,rptr_real_gray,wptr_real_gray_d2,rptr_real_gray_d2;
reg[5:0] wptr_sram_addr,rptr_sram_addr;
wire[6:0] rptr_d2;
wire[6:0] wptr_d2;

always @(*)
begin
    // wptrs
    wptr_real_gray = REAL_GRAY_CODE(wptr);
    wptr_real_gray_d2 = REAL_GRAY_CODE(wptr_d2);
    wptr_sram_addr = wptr_real_gray[5:0];

    // Convert to Real Gray code then perform comparison
    if((wptr[6] != rptr_d2[6]) && (wptr_real_gray == rptr_real_gray_d2))
        wfull = 1'b1;
    else
        wfull = 1'b0;

    if(wfull == 1'b1)
    begin
        w_ptr_counts = 1'b0;
        wen = 1'b1;
    end
    else
    begin
        w_ptr_counts = winc;
        wen          = ~winc;
    end
end

always @(*)
begin
    //rptr controls
    rptr_real_gray    = REAL_GRAY_CODE(rptr);
    rptr_real_gray_d2 = REAL_GRAY_CODE(rptr_d2);
    rptr_sram_addr = rptr_real_gray[5:0];

    if((wptr_d2[6] == rptr[6])  && (wptr_d2 == rptr))
        rempty= 1'b1;
    else
        rempty = 1'b0;

    if(rempty == 1'b1)
    begin
        r_ptr_counts = 1'b0;
    end
    else
    begin
        r_ptr_counts = rinc;
    end
end


reg[6:0] wptr_bin;
always @(posedge wclk or negedge rst_n) begin
    if(~rst_n) wptr_bin <= 0;
    else if(w_ptr_counts) wptr_bin <= wptr_bin + 1;
end
assign wptr = bin2gray(wptr_bin);


reg[6:0] rptr_bin;
always @(posedge rclk or negedge rst_n) begin
    if(~rst_n) rptr_bin <= 0;
    else if(r_ptr_counts) rptr_bin <= rptr_bin + 1;
end
assign rptr = bin2gray(rptr_bin);

// Synchronizers
NDFF_BUS_syn #(.WIDTH(7)) rptr_d2_ff(.D(rptr), .Q(rptr_d2), .clk(wclk), .rst_n(rst_n));
NDFF_BUS_syn #(.WIDTH(7)) wptr_d2_ff(.D(wptr), .Q(wptr_d2), .clk(rclk), .rst_n(rst_n));

DUAL_64X32X1BM1 u_dual_sram (
    .CKA(wclk),
    .CKB(rclk),
    .WEAN(wen),
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


function [6:0] REAL_GRAY_CODE;
    input[6:0] gray_code;
    begin
        // Full signal
        if(gray_code[6] == 1'b1)
        begin
            REAL_GRAY_CODE = {~gray_code[6],~gray_code[5],gray_code[4:0]};
        end
        else
        begin
            REAL_GRAY_CODE = gray_code;
        end
    end
endfunction

function [6:0] bin2gray;
    input[6:0] bin;
    begin
        bin2gray = bin ^ (bin >> 1);
    end
endfunction

endmodule


module gray2bin #(parameter SIZE = 7)(
input [SIZE-1:0] gray,
output reg[SIZE-1:0] bin
);
 integer i;
 always@*
   for(i=0;i<SIZE;i = i+1)
     bin[i] = ^(gray >> i);

endmodule
