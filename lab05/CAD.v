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
reg[4:0] p_cur_st, p_next_st;
localparam  P_IDLE        = 4'b0001;
localparam  P_RD_DATA     = 4'b0010;
localparam  P_WAIT_IDX    = 4'b0100;
localparam  P_PROCESSING  = 4'b1000;

wire ST_P_IDLE          = p_cur_st[0];
wire ST_P_RD_DATA       = p_cur_st[1];
wire ST_P_WAIT_IDX      = p_cur_st[2];
wire ST_P_PROCESSING    = p_cur_st[3];

reg[14:0] rd_cnt;
reg[7:0] kernal_idx_ff,img_idx_ff;

reg[5:0] img_num_cnt,kernal_num_cnt;
reg[8:0] img_xptr,img_yptr,k_xptr,k_yptr;
reg valid,valid_d1,valid_d2,valid_d3;
reg[14:0] read_img_upper_bound;
reg[2:0] mp_window_x_cnt ,mp_window_y_cnt,mp_window_x_cnt_d1 ,mp_window_y_cnt_d1,mp_window_x_cnt_d2
,mp_window_y_cnt_d2,mp_window_x_cnt_d3 ,mp_window_y_cnt_d3;
reg[5:0] output_cnt;

reg[5:0] idx_x,idx_y;
reg[5:0] idx_x_d1,idx_y_d1,idx_x_d2,idx_y_d2;

//---------------------------------------------------------------------
//      REGs and FFs
//---------------------------------------------------------------------
reg[2:0] mode_ff;
reg[7:0] matrix_size_ff;

//---------------------------------------------------------------------
//      flags
//---------------------------------------------------------------------
wire rd_data_done_f  = rd_cnt == read_img_upper_bound;
wire idx_read_done_f = rd_cnt == 1;
wire img_processed_f = (img_xptr == (matrix_size_ff - 5)) && (img_yptr == (matrix_size_ff - 5)) && ST_P_PROCESSING;
wire img_read_f     = (img_xptr == (matrix_size_ff - 1)) && (img_yptr == (matrix_size_ff - 1)) && ST_P_RD_DATA;
wire img16_read_f   = (img_num_cnt ==  15) &&(img_xptr == (matrix_size_ff - 1))
&& (img_yptr == (matrix_size_ff - 1)) && ST_P_RD_DATA;

wire kernal_read_f  = (k_xptr == 4) && (k_yptr == 4) && ST_P_RD_DATA;
wire kernal16_read_f = (kernal_num_cnt == 15) &&(k_xptr == 4) && (k_yptr == 4) && ST_P_RD_DATA;

wire proecssed_16_imgs_f = img_num_cnt == 15 && ST_P_PROCESSING;

wire output_stall_f =  (out_valid == 1) && output_cnt < 15 && (mode_ff == 1) && ST_P_PROCESSING;


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

reg read_img_done_ff;
//---------------------------------------------------------------------
//      SUB CTRS
//---------------------------------------------------------------------
integer i,j;
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
      img_xptr <= 0;
      img_yptr <= 0;
      k_xptr   <= 0;
      k_yptr   <= 0;
      read_img_done_ff <= 0;

      img_idx_ff    <= 0;
      kernal_idx_ff <= 0;
      matrix_size_ff <= 0;
      rd_cnt <= 0;
      img_num_cnt <= 0;
      kernal_num_cnt <= 0;
      read_img_upper_bound <= 0;
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
        rd_cnt   <= 1;
      end
      else
      begin
        img_xptr <= 0;
        img_yptr <= 0;
        k_xptr   <= 0;
        k_yptr   <= 0;

        img_idx_ff    <= 0;
        kernal_idx_ff <= 0;
        matrix_size_ff <= 0;
        img_num_cnt <= 0;
        kernal_num_cnt <= 0;
        read_img_done_ff <= 0;
      end
    end
    else if(ST_P_RD_DATA)
    begin
      case(matrix_size_ff)
      'd8:  read_img_upper_bound <= 1423;
      'd16:  read_img_upper_bound <= 4495;
      'd32:  read_img_upper_bound <= 16783;
      endcase

      if(rd_data_done_f)
        rd_cnt <= 0;
      else
        rd_cnt <= rd_cnt + 1;

      if(rd_data_done_f)
      begin
        img_xptr <= 0;
        img_yptr <= 0;
      end
      else if(img16_read_f)
      begin
        img_xptr <= img_xptr;
        img_yptr <= img_yptr;
        read_img_done_ff <= 1;
      end
      else if(img_read_f)
      begin
        img_xptr <= 0;
        img_yptr <= 0;
        img_num_cnt <= img_num_cnt + 1;
      end
      else if(img_xptr == matrix_size_ff-1)
      begin
        img_xptr <= 0;
        img_yptr <= img_yptr + 1;
      end
      else
      begin
        img_xptr <= img_xptr + 1;
      end

      if(rd_data_done_f)
      begin
          k_xptr <= 0;
          k_yptr <= 0;
      end
      else if(read_img_done_ff)
      begin
        if(kernal16_read_f)
        begin
          k_xptr <= 0;
          k_yptr <= 0;
        end
        else if(kernal_read_f)
        begin
          k_xptr <= 0;
          k_yptr <= 0;
          kernal_num_cnt <= kernal_num_cnt + 1;
        end
        else if(k_xptr == 4)
        begin
          k_xptr <= 0;
          k_yptr <= k_yptr + 1;
        end
        else
        begin
          k_xptr <= k_xptr+1;
        end
      end
    end
    else if(ST_P_WAIT_IDX)
    begin
      if(in_valid2 && rd_cnt == 0)
      begin
        mode_ff <= mode;
        img_idx_ff <= matrix_idx;
      end
      else
      begin
        kernal_idx_ff <= matrix_idx;
      end
    end
    else if(ST_P_PROCESSING)
    begin

    end
end

//==============================================//
//               DATAPATH                       //
//==============================================//
//================//
// Delay lines    //
//================//
always @(posedge clk or negedge rst_n)
begin
  if(~rst_n)
  begin
    valid_d1 <= 0;
    valid_d2 <= 0;
    valid_d3 <= 0;

    mp_window_x_cnt_d1 <= 0 ;
    mp_window_x_cnt_d2 <= 0 ;
    mp_window_x_cnt_d3 <= 0 ;

    mp_window_y_cnt_d1 <= 0 ;
    mp_window_y_cnt_d2 <= 0 ;
    mp_window_y_cnt_d3 <= 0 ;

    idx_x_d1  <= 0;
    idx_y_d1  <= 0;
  end
  else
  begin
    valid_d1 <= valid;
    valid_d2 <= valid_d1;
    valid_d3 <= valid_d2;

    mp_window_x_cnt_d1 <= mp_window_x_cnt;
    mp_window_x_cnt_d2 <= mp_window_x_cnt_d1;
    mp_window_x_cnt_d3 <= mp_window_x_cnt_d2;

    mp_window_y_cnt_d1 <= mp_window_y_cnt;
    mp_window_y_cnt_d2 <= mp_window_y_cnt_d1;
    mp_window_y_cnt_d3 <= mp_window_y_cnt_d2;

    idx_x_d1  <= idx_x;
    idx_y_d1  <= idx_y;
  end
end

always @(*)
begin
  if(mode_ff == 0)
  begin
    idx_x = img_yptr+mp_window_y_cnt;
    idx_y = img_xptr+mp_window_x_cnt;
  end
  else
  begin
    idx_x = img_yptr+mp_window_y_cnt;
    idx_y = img_xptr+mp_window_x_cnt;
  end
end

//---------------------------------------------------------------------
//      Output CTR
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
  if(~rst_n)
  begin
    out_value <= 0;
    out_valid <= 0;
  end
end


//---------------------------------------------------------------------
//      SRAM ADDR CALCULATOR
//---------------------------------------------------------------------
reg[7:0] img_sram_num;
reg[7:0] k_sram_num;
reg[7:0] kernal_sram_addr[0:4];

reg[15:0] conv_img_access_addr[0:4];
reg[15:0] conv_sram_num [0:4];
reg[15:0] conv_img_block_num[0:4];
reg[15:0] conv_img_offset_in_block[0:4];

reg[7:0] block_num;
reg[15:0] addr_in_sram;

reg wen_0,wen_1, wen_2, wen_3,wen_4;
reg wen_k0,wen_k1, wen_k2, wen_k3, wen_k4;

reg[11:0] s0_addr, s1_addr, s2_addr,s3_addr,s4_addr;
reg[7:0] s0_in_data, s1_in_data, s2_in_data,s3_in_data,s4_in_data,k_sram_in_data;
reg[8:0]  k_sram_addr;
wire signed[7:0] s0_out_data, s1_out_data, s2_out_data,s3_out_data,s4_out_data;
wire signed[7:0] k0_out_data, k1_out_data, k2_out_data,k3_out_data,k4_out_data;
reg[19:0] deconv_out_data;
reg k_sram_en;
reg[15:0] offset_in_block;

always @(*)
begin
  wen_0 = 1;
  wen_1 = 1;
  wen_2 = 1;
  wen_3 = 1;
  wen_4 = 1;

  wen_k0 = 1;
  wen_k1 = 1;
  wen_k2 = 1;
  wen_k3 = 1;
  wen_k4 = 1;

  s0_addr = 0;
  s1_addr = 0;
  s2_addr = 0;
  s3_addr = 0;
  s4_addr = 0;

  s0_in_data = 0;
  s1_in_data = 0;
  s2_in_data = 0;
  s3_in_data  =0;
  s4_in_data = 0;

  for(i=0;i<5;i=i+1) // Initilization
  begin
    conv_img_access_addr[i] = 0;
    conv_img_block_num[i] = 0;
    conv_img_offset_in_block[i] = 0;
    conv_sram_num[i] = 0;
  end

  if(ST_P_IDLE || ST_P_RD_DATA)
  begin
    img_sram_num        = img_xptr % 5;
    block_num           = img_xptr / 5;
    offset_in_block     = block_num * matrix_size_ff + img_yptr;
  end
  else if(ST_P_PROCESSING)
  begin
    for(i=0;i<5;i=i+1)
    begin
      if(mode_ff == 0)
      begin
        conv_img_access_addr[i]         = (idx_x + i) % 5;
        conv_img_block_num[i]           = (idx_x + i) / 5;
        conv_img_offset_in_block[i]     = conv_img_block_num * matrix_size_ff + (idx_y + k_yptr);
      end
      else
      begin
        conv_img_access_addr[i]        = (img_xptr + i - 4) % 5;
        conv_img_block_num[i]          = (img_xptr + i - 4) / 5;
        conv_img_offset_in_block[i]    = conv_img_block_num * matrix_size_ff + (idx_y-4);
      end
    end
  end

  if(img_sram_num == 0 || img_sram_num == 1)
  begin
    if(ST_P_IDLE || ST_P_RD_DATA)
      addr_in_sram = offset_in_block + img_num_cnt * 224;
    else
      addr_in_sram = offset_in_block + img_idx_ff * 224;
  end
  else
  begin
    if(ST_P_IDLE || ST_P_RD_DATA)
      addr_in_sram =  offset_in_block + img_num_cnt * 192;
    else
      addr_in_sram = offset_in_block + img_idx_ff * 192;
  end

  if(in_valid && (ST_P_RD_DATA || ST_P_IDLE) && ~read_img_done_ff)
  begin
    case(img_sram_num)
    'd0:
    begin
      wen_0 = 0;
      s0_in_data = matrix;
      s0_addr = addr_in_sram;
    end
    'd1:
    begin
      wen_1 = 0;
      s1_in_data = matrix;
      s1_addr = addr_in_sram;
    end
    'd2:
    begin
      wen_2 = 0;
      s2_in_data = matrix;
      s2_addr = addr_in_sram;
    end
    'd3:
    begin
      wen_3 = 0;
      s3_in_data = matrix;
      s3_addr = addr_in_sram;
    end
    'd4:
    begin
      wen_4 = 0;
      s4_in_data = matrix;
      s4_addr = addr_in_sram;
    end
    endcase
  end
  else
  begin
    s0_addr = conv_img_access_addr[0];
    s1_addr = conv_img_access_addr[1];
    s2_addr = conv_img_access_addr[2];
    s3_addr = conv_img_access_addr[3];
    s4_addr = conv_img_access_addr[4];
  end

  // KERNALS ADDRS
  if(in_valid && (ST_P_IDLE || ST_P_RD_DATA))
  begin
    kernal_sram_addr   = k_yptr + 5 * kernal_num_cnt;
    k_sram_num = k_xptr;
  end
  else if(ST_P_PROCESSING)
  begin
    if(mode_ff == 0)
    begin
      k_sram_num = k_xptr;
      kernal_sram_addr = k_yptr + 5 * kernal_idx_ff;
    end
    else
    begin
      // Reversed kernals
      k_sram_num = 4-k_xptr;
      kernal_sram_addr =  (4-k_yptr)  + 5 * kernal_idx_ff;
    end
  end

  if(in_valid && read_img_done_ff && (ST_P_IDLE || ST_P_RD_DATA))
  begin
    case(k_sram_num)
    'd0:
    begin
      wen_k0 = 0;
    end
    'd1:
    begin
      wen_k1 = 0;
    end
    'd2:
    begin
      wen_k2 = 0;
    end
    'd3:
    begin
      wen_k3 = 0;
    end
    'd4:
    begin
      wen_k4 = 0;
    end
    endcase
  end
end


//==============================================//
//               5 x SRAMs 1 KERNAL SRAM        //
//==============================================//
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
            .DI6(s1_in_data[6]),.DI7(s1_in_data[7]),.CK(clk),.WEB(wen_1),.OE(1'b1),.CS(1'b1));

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


SRAM_5x16 u_K0(.A0(kernal_sram_addr[0][0]),.A1(kernal_sram_addr[0][1]),.A2(kernal_sram_addr[0][2]),
.A3(kernal_sram_addr[0][3]),.A4(kernal_sram_addr[0][4]),.A5(kernal_sram_addr[0][5]),
.A6(kernal_sram_addr[0][6]),
            .DO0(k0_out_data[0]),.DO1(k0_out_data[1]),.DO2(k0_out_data[2]),.DO3(k0_out_data[3]),
            .DO4(k0_out_data[4]),.DO5(k0_out_data[5]),.DO6(k0_out_data[6]),
            .DO7(k0_out_data[7]),.DI0(matrix[0]),.DI1(matrix[1]),.DI2(matrix[2]),
                  .DI3(matrix[3]),.DI4(matrix[4]),.DI5(matrix[5]),
                  .DI6(matrix[6]),.DI7(matrix[7]),.CK(clk),.WEB(wen_k0),.OE(1'b1),.CS(1'b1));

SRAM_5x16 u_K1(.A0(kernal_sram_addr[1][0]),.A1(kernal_sram_addr[1][1]),.A2(kernal_sram_addr[1][2]),
.A3(kernal_sram_addr[1][3]),.A4(kernal_sram_addr[1][4]),.A5(kernal_sram_addr[1][5]),
.A6(kernal_sram_addr[1][6]),.DO0(k1_out_data[0]),.DO1(k1_out_data[1]),.DO2(k1_out_data[2]),.DO3(k1_out_data[3]),
.DO4(k1_out_data[4]),.DO5(k1_out_data[5]),.DO6(k1_out_data[6]),.
                  DO7(k1_out_data[7]),.DI0(matrix[0]),.DI1(matrix[1]),.DI2(matrix[2]),
                  .DI3(matrix[3]),.DI4(matrix[4]),.DI5(matrix[5]),
                  .DI6(matrix[6]),.DI7(matrix[7]),.CK(clk),.WEB(wen_k1),.OE(1'b1),.CS(1'b1));

SRAM_5x16 u_K2(.A0(kernal_sram_addr[2][0]),.A1(kernal_sram_addr[2][1]),.A2(kernal_sram_addr[2][2]),
.A3(kernal_sram_addr[2][3]),.A4(kernal_sram_addr[2][4]),.A5(kernal_sram_addr[2][5]),
.A6(kernal_sram_addr[2][6]),.DO0(k2_out_data[0]),.DO1(k2_out_data[1]),.DO2(k2_out_data[2]),.DO3(k2_out_data[3]),
                  .DO4(k2_out_data[4]),.DO5(k2_out_data[5]),.DO6(k2_out_data[6]),
                  .DO7(k2_out_data[7]),
                  .DI0(matrix[0]),.DI1(matrix[1]),.DI2(matrix[2]),
                  .DI3(matrix[3]),.DI4(matrix[4]),.DI5(matrix[5]),
                  .DI6(matrix[6]),.DI7(matrix[7]),.CK(clk),.WEB(wen_k2),.OE(1'b1),.CS(1'b1));

SRAM_5x16 u_K3(.A0(kernal_sram_addr[3][0]),.A1(kernal_sram_addr[3][1]),.A2(kernal_sram_addr[3][2]),
.A3(kernal_sram_addr[3][3]),.A4(kernal_sram_addr[3][4]),.A5(kernal_sram_addr[3][5]),
.A6(kernal_sram_addr[3][6]),.DO0(k3_out_data[0]),.DO1(k3_out_data[1]),.DO2(k3_out_data[2]),.DO3(k3_out_data[3]),
              .DO4(k3_out_data[4]),.DO5(k3_out_data[5]),.DO6(k3_out_data[6]),
              .DO7(k3_out_data[7]),.DI0(matrix[0]),.DI1(matrix[1]),.DI2(matrix[2]),.DI3(matrix[3]),
                  .DI4(matrix[4]),.DI5(matrix[5]),.DI6(matrix[6]),.DI7(matrix[7]),.CK(clk),.WEB(wen_k3),.OE(1'b1),.CS(1'b1));

SRAM_5x16 u_K4(.A0(kernal_sram_addr[4][0]),.A1(kernal_sram_addr[4][1]),.A2(kernal_sram_addr[4][2]),
.A3(kernal_sram_addr[4][3]),.A4(kernal_sram_addr[4][4]),.A5(kernal_sram_addr[4][5]),
.A6(kernal_sram_addr[4][6]),.DO0(k4_out_data[0]),.DO1(k4_out_data[1]),.DO2(k4_out_data[2]),
                  .DO3(k4_out_data[3]),.DO4(k4_out_data[4]),.DO5(k4_out_data[5]),.DO6(k4_out_data[6]),
                  .DO7(k4_out_data[7]),.DI0(matrix[0]),.DI1(matrix[1]),.DI2(matrix[2]),
                  .DI3(matrix[3]),.DI4(matrix[4]),.DI5(matrix[5]),
                  .DI6(matrix[6]),.DI7(matrix[7]),.CK(clk),.WEB(wen_k4),.OE(1'b1),.CS(1'b1));

endmodule