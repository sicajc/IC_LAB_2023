//############################################################################
//   2023 ICLAB Fall Course
//   Lab05       : CAD
//   Author      :
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : CAD.v
//   Module Name : CAD
//   Release version :
//############################################################################

module CAD(
  //Input Port
  clk,
  rst_n,
  in_valid,
  in_valid2,
  mode,
  matrix,
  matrix_idx,
  matrix_size,
  //Output Port
  out_valid,
  out_value
  );


//==============================================//
//                   PARAMETER                  //
//==============================================//

//==============================================//
//                   I/O PORTS                  //
//==============================================//
input       clk, rst_n, in_valid, in_valid2;
input       mode;
input [7:0] matrix;
input [3:0] matrix_idx;
input [1:0] matrix_size;
output reg  out_valid;
output reg  out_value;

//==============================================//
//            reg & wire declaration            //
//==============================================//


//==============================================//
//                  Input Block                 //
//==============================================//


//==============================================//
//                Output Block                  //
//==============================================//

//==============================================//
//                Output Block                  //
//==============================================//

//==============================================//
//                SRAMs                  //
//==============================================//
reg wen_0,wen_1, wen_2, wen_3,wen_4,deconv_wen;

reg[11:0] s0_addr, s1_addr, s2_addr,s3_addr,s4_addr,deconv_addr;
reg[7:0] s0_in_data, s1_in_data, s2_in_data,s3_in_data,s4_in_data,
reg[19:0] deconv_in_data;
wire signed[7:0] s0_out_data, s1_out_data, s2_out_data,s3_out_data,s4_out_data;
reg[19:0] deconv_out_data;


// SRAM_32x7x16 (A0,A1,A2,A3,A4,A5,A6,A7,A8,A9,A10,A11,DO0,DO1,DO2,
//                      DO3,DO4,DO5,DO6,DO7,DI0,DI1,DI2,DI3,DI4,DI5,
//                      DI6,DI7,CK,WEB,OE, CS);

SRAM_32x7x16 u_S0(.A0(s0_addr[0]),.A1(s0_addr[1]),.A2(s0_addr[2]),.A3(s0_addr[3]),
    .A4(s0_addr[4]),.A5(s0_addr[5]),.A6(s0_addr[6]),.A7(s0_addr[7]),
    .A8(s0_addr[8]),.A9(s0_addr[9]),.A10(s0_addr[10]),.A11(s0_addr[11]),
                     .DO0(s0_out_data[0]),.DO1(s0_out_data[1]),.DO2(s0_out_data[2]),
                     .DO3(s0_out_data[3]),.DO4(s0_out_data[4]),
                     .DO5(s0_out_data[5]),.DO6(s0_out_data[6]),.DO7(s0_out_data[7]),
                     .DI0(s0_in_data[0]),.DI1(s0_in_data[1]),.DI2(s0_in_data[2]),.DI3(s0_in_data[3]),
                     .DI4(s0_in_data[4]),.DI5(s0_in_data[5]),
                     .DI6(s0_in_data[6]),.DI7(s0_in_data[7]),.CK(clk),.WEB(wen_0),.OE(1'b1),.CS(1'b1)
                     );

SRAM_32x7x16 u_S1(.A0(s1_addr[0]),.A1(s1_addr[1]),.A2(s1_addr[2]),.A3(s1_addr[3]),.A4(s1_addr[4]),
                .A5(s1_addr[5]),.A6(s1_addr[6]),.A7(s1_addr[7]),
                .A8(s1_addr[8]),.A9(s1_addr[9]),.A10(s1_addr[10]),.A11(s1_addr[11]),
            .DO0(s1_out_data[0]),.DO1(s1_out_data[1]),.DO2(s1_out_data[2]),.DO3(s1_out_data[3]),
            .DO4(s1_out_data[4]),.DO5(s1_out_data[5]),.DO6(s1_out_data[6]),.DO7(s1_out_data[7]),
            .DI0(s1_in_data[0]),.DI1(s1_in_data[1]),.DI2(s1_in_data[2]),.DI3(s1_in_data[3]),
            .DI4(s1_in_data[4]),.DI5(s1_in_data[5]),
            .DI6(s1_in_data[6]),.DI7(s1_in_data[7]),.clk(clk),.WEB(wen_1),.OE(1'b1),.CS(1'b1));


// SRAM_32x6x16 (A0,A1,A2,A3,A4,A5,A6,A7,A8,A9,A10,A11,DO0,DO1,DO2,
//                      DO3,DO4,DO5,DO6,DO7,DI0,DI1,DI2,DI3,DI4,DI5,
//                      DI6,DI7,CK,WEB,OE, CS);

SRAM_32x6x16 u_S2(.A0(s2_addr[0]),.A1(s2_addr[1]),.A2(s2_addr[2]),
                  .A3(s2_addr[3]),.A4(s2_addr[4]),.A5(s2_addr[5]),
                  .A6(s2_addr[6]),.A7(s2_addr[7]),.A8(s2_addr[8]),
                  .A9(s2_addr[9]),.A10(s2_addr[10]),.A11(s2_addr[11]),
                  .DO0(s2_out_data[0]),.DO1(s2_out_data[1]),.DO2(s2_out_data[2]),
                  .DO3(s2_out_data[3]),.DO4(s2_out_data[4]),
                  .DO5(s2_out_data[5]),.DO6(s2_out_data[6]),.DO7(s2_out_data[7]),
                  .DI0(s2_in_data[0]),.DI1(s2_in_data[1]),
                  .DI2(s2_in_data[2]),.DI3(s2_in_data[3]),
                  .DI4(s2_in_data[4]),.DI5(s2_in_data[5]),
                  .DI6(s2_in_data[6]),.DI7(s2_in_data[7]),
                  .CK(clk),.WEB(wen_2),.OE(1'b1),.CS(1'b1));

SRAM_32x6x16 u_S3(.A0(s3_addr[0]),.A1(s3_addr[1]),.A2(s3_addr[2]),
                  .A3(s3_addr[3]),.A4(s3_addr[4]),.A5(s3_addr[5]),
                  .A6(s3_addr[6]),.A7(s3_addr[7]),.A8(s3_addr[8]),
                  .A9(s3_addr[9]),.A10(s3_addr[10]),.A11(s3_addr[11]),
                  .DO0(s3_out_data[0]),.DO1(s3_out_data[1]),.DO2(s3_out_data[2]),
                  .DO3(s3_out_data[3]),.DO4(s3_out_data[4]),
                  .DO5(s3_out_data[5]),.DO6(s3_out_data[6]),.DO7(s3_out_data[7]),
                  .DI0(s3_in_data[0]),.DI1(s3_in_data[1]),
                  .DI2(s3_in_data[2]),.DI3(s3_in_data[3]),
                  .DI4(s3_in_data[4]),.DI5(s3_in_data[5]),
                  .DI6(s3_in_data[6]),.DI7(s3_in_data[7]),.CK(clk),.WEB(wen_3),.OE(1'b1),.CS(1'b1));

SRAM_32x6x16 u_S4(.A0(s4_addr[0]),.A1(s4_addr[1]),.A2(s4_addr[2]),
                  .A3(s4_addr[3]),.A4(s4_addr[4]),.A5(s4_addr[5]),
                  .A6(s4_addr[6]),.A7(s4_addr[7]),.A8(s4_addr[8]),
                  .A9(s4_addr[9]),.A10(s4_addr[10]),.A11(s4_addr[11]),
                  .DO0(s4_out_data[0]),.DO1(s4_out_data[1]),.DO2(s4_out_data[2]),
                  .DO3(s4_out_data[3]),.DO4(s4_out_data[4]),
                  .DO5(s4_out_data[5]),.DO6(s4_out_data[6]),.DO7(s4_out_data[7]),
                  .DI0(s4_in_data[0]),.DI1(s4_in_data[1]),
                  .DI2(s4_in_data[2]),.DI3(s4_in_data[3]),
                  .DI4(s4_in_data[4]),.DI5(s4_in_data[5]),
                  .DI6(s4_in_data[6]),.DI7(s4_in_data[7]),
                  .CK(clk),.WEB(wen_4),.OE(1'b1),.CS(1'b1));


// SRAM_32x32x20 (A0,A1,A2,A3,A4,A5,A6,A7,A8,A9,DO0,DO1,DO2,DO3,DO4,
//                       DO5,DO6,DO7,DO8,DO9,DO10,DO11,DO12,DO13,DO14,
//                       DO15,DO16,DO17,DO18,DO19,DI0,DI1,DI2,DI3,
//                       DI4,DI5,DI6,DI7,DI8,DI9,DI10,DI11,DI12,DI13,
//                       DI14,DI15,DI16,DI17,DI18,DI19,CK,WEB,OE, CS);

SRAM_32x32x20 u_deCONV(.A0(deconv_addr[0]),.A1(deconv_addr[1]),.A2(deconv_addr[2]),
.A3(deconv_addr[3]),
.A4(deconv_addr[4]),.A5(deconv_addr[5]),.A6(deconv_addr[6]),
.A7(deconv_addr[7]),.A8(deconv_addr[8]),.A9(deconv_addr[9]),
.DO0(deconv_out_data[0]),.DO1(deconv_out_data[1]),.DO2(deconv_out_data[2]),.DO3(deconv_out_data[3]),.DO4(deconv_out_data[4]),
.DO5(deconv_out_data[5]),.DO6(deconv_out_data[6]),.DO7(deconv_out_data[7]),.DO8(deconv_out_data[8]),.DO9(deconv_out_data[9]),
.DO10(deconv_out_data[10]),.DO11(deconv_out_data[11]),.DO12(deconv_out_data[12]),.DO13(deconv_out_data[13]),.DO14(deconv_out_data[14]),
.DO15(deconv_out_data[15]),.DO16(deconv_out_data[16]),.DO17(deconv_out_data[17]),.DO18(deconv_out_data[18]),.DO19(deconv_out_data[19]),
.DI0(s5_in_data[0]),.DI1(s5_in_data[1]),.DI2(s5_in_data[2]),.DI3(s5_in_data[3]),
.DI4(s5_in_data[4]),.DI5(s5_in_data[5]),.DI6(s5_in_data[6]),.DI7(s5_in_data[7]),.DI8(s5_in_data[8]),
.DI9(s5_in_data[9]),.DI10(s5_in_data[10]),.DI11(s5_in_data[11]),.DI12(s5_in_data[12]),.DI13(s5_in_data[13]),
.DI14(s5_in_data[14]),.DI15(s5_in_data[15]),.DI16(s5_in_data[16]),.DI17(s5_in_data[17]),.DI18(s5_in_data[18]),
.DI19(s5_in_data[19]),
.CK(clk),.WEB(deconv_wen),.OE(1'b1),.CS(1'b1));


endmodule