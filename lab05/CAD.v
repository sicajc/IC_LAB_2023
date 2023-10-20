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
parameter DATA_WIDTH = 8;


//==============================================//
//                  States                      //
//==============================================//
reg[2:0] p_cur_st, p_next_st;
localparam  P_IDLE        = 4'b0001;
localparam  P_RD_DATA     = 4'b0010;
localparam  P_WAIT_IDX    = 4'b0100;
localparam  P_PROCESSING  = 4'b1000;

wire ST_P_IDLE = p_cur_st[0];
wire ST_P_RD_DATA = p_cur_st[1];
wire ST_P_WAIT_IDX = p_cur_st[2];
wire ST_P_PROCESSING = p_cur_st[3];

reg[14:0] rd_cnt;
reg[7:0] kernal_idx_ff,img_idx_ff;

reg[5:0] img_num_cnt;
reg[8:0] img_xptr,img_yptr,k_xptr,k_yptr;
reg valid;
reg[14:0] read_img_upper_bound;
reg[2:0] mp_window_x_cnt ,mp_window_y_cnt;
reg[5:0] output_cnt;


//---------------------------------------------------------------------
//      REGs and FFs
//---------------------------------------------------------------------
reg[2:0] mode_ff;
reg[7:0] matrix_size_ff;
reg[DATA_WIDTH-1:0] kernal_rf[0:4][0:4];

//---------------------------------------------------------------------
//      flags
//---------------------------------------------------------------------
wire rd_data_done_f  = rd_cnt == read_img_upper_bound;
wire idx_read_done_f = rd_cnt == 1;
wire img_processed_f = (img_xptr == (matrix_size_ff - 5)) && (img_yptr == (matrix_size_ff - 5));
wire proecssed_16_imgs_f = img_num_cnt == 15;

wire output_stall_f = output_cnt < 15 && (mode_ff == 1);



//---------------------------------------------------------------------
//      MAIN FSM
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        p_cur_st <= P_IDLE;
    end
    else
    begin
        p_cur_st <= p_next_st;
    end
end

always @(*)
begin
    p_next_st = p_cur_st;
    case(p_cur_st)
    P_IDLE:
    begin
        if(in_valid) p_next_st = P_RD_DATA;
    end
    P_RD_DATA:
    begin
        if(rd_data_done_f) p_next_st = P_WAIT_IDX;
    end
    P_WAIT_IDX:
    begin
        if(idx_read_done_f) p_next_st = P_PROCESSING;
    end
    P_PROCESSING:
    begin
        if(img_processed_f)
        begin
          if(proecssed_16_imgs_f)
            p_next_st = P_IDLE;
          else
            p_next_st = P_WAIT_IDX;
        end
    end
    endcase
end

//---------------------------------------------------------------------
//      SUB CTRS
//---------------------------------------------------------------------
integer i,j;
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
      for(i=0;i<5;i=i+1)
        for(j=0;j<5;j=j+1)
          kernal_rf[i][j] <= 0;

      img_xptr <= 0;
      img_yptr <= 0;
      k_xptr   <= 0;
      k_yptr   <= 0;

      img_idx_ff    <= 0;
      kernal_idx_ff <= 0;
      matrix_size_ff <= 0;
    end
    else if(ST_P_IDLE)
    begin
      if(in_valid)
      begin
        case(matrix_size)
        'd0: matrix_size_ff <= 8;
        'd1: matrix_size_ff <= 16;
        'd2: matrix_size_ff <= 32;
        endcase

        img_xptr <= 1;
      end
      else
      begin

        for(i=0;i<5;i=i+1)
          for(j=0;j<5;j=j+1)
            kernal_rf[i][j] <= 0;

        img_xptr <= 0;
        img_yptr <= 0;
        k_xptr   <= 0;
        k_yptr   <= 0;

        img_idx_ff    <= 0;
        kernal_idx_ff <= 0;
        matrix_size_ff <= 0;
      end
    end
    else if(ST_P_WAIT_IDX)
    begin

    end
    else if(ST_P_PROCESSING)
    begin

    end
end


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



endmodule