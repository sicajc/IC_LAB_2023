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
parameter  DATA_WIDTH = 8;
localparam OUTPUT_IDLE = 4'b0001;
localparam OUTPUT_MODE0 = 4'b0010;
localparam OUTPUT_MODE1_STALL = 4'b0100;
localparam OUTPUT_MODE1 = 4'b1000;

reg[3:0] out_cur_st;
reg[5:0] out_cnt;

//==============================================//
//                  States                      //
//==============================================//
reg[5:0] p_cur_st, p_next_st;
localparam  P_IDLE        = 6'b000001;
localparam  P_RD_IMG      = 6'b000010;
localparam  P_RD_KERNEL   = 6'b000100;
localparam  P_WAIT_IDX    = 6'b001000;
localparam  P_PROCESSING  = 6'b010000;
localparam  P_MOVE_KERNAL_IMG =6'b100000;

wire ST_P_IDLE          = p_cur_st[0];
wire ST_P_RD_IMG       = p_cur_st[1];
wire ST_P_RD_KERNEL       = p_cur_st[2];
wire ST_P_WAIT_IDX      = p_cur_st[3];
wire ST_P_PROCESSING    = p_cur_st[4];
wire ST_P_MOVE_KERNAL_IMG    = p_cur_st[5];

wire ST_OUTPUT_IDLE   = out_cur_st[0];
wire ST_OUTPUT_MODE0   = out_cur_st[1];
wire ST_OUTPUT_MODE1   = out_cur_st[3];
// wire ST_OUTPUT_MODE1_STALL   = out_cur_st[2];

reg[14:0] rd_cnt;
reg[7:0] kernal_idx_ff;
reg[7:0] img_idx_ff;
reg[5:0] img_num_cnt;
reg[5:0] kernal_num_cnt;

reg[8:0] img_xptr,img_yptr,img_xptr_d1,img_yptr_d1,img_xptr_d2,img_yptr_d2,img_xptr_d3,img_yptr_d3;
reg[8:0] k_xptr,k_yptr,k_xptr_d1,k_yptr_d1,k_yptr_d2,k_yptr_d3;
reg valid_d1,valid_d2;
reg[2:0] mp_window_x_cnt ,mp_window_y_cnt,mp_window_x_cnt_d1 ,mp_window_y_cnt_d1,mp_window_x_cnt_d2
,mp_window_y_cnt_d2,mp_window_x_cnt_d3 ,mp_window_y_cnt_d3;

reg[5:0] output_cnt;
reg[8:0] idx_x[0:4];
reg[8:0] idx_y;

//---------------------------------------------------------------------
//      REGs and FFs
//---------------------------------------------------------------------
reg[2:0] mode_ff;
reg[7:0] img_size_ff;
reg signed[7:0] img_rf[31:0][31:0];
reg signed[7:0] kernal_rf[0:4][0:4];

reg[15:0] offset;
reg      img_wen, kernal_wen;
reg[13:0] img_mem_addr;
reg[8:0] kernal_mem_addr;
wire signed[7:0] img_mem_data_out,kernal_data_out;
reg signed[7:0] img_mem_data_in,kernal_data_in;

reg[15:0] lower_bound0,lower_bound1,lower_bound2,lower_bound3;
reg signed[19:0] conv_ff;
wire conv_accumulated_d2 = (k_yptr_d2 == 4);

integer x,y,i,j;

//---------------------------------------------------------------------
//      flags
//---------------------------------------------------------------------
wire rd_data_done_f  = (img_xptr == (img_size_ff - 1)) && (img_yptr == (img_size_ff-1))
&& (img_num_cnt == 15) && ST_P_RD_IMG;
wire local_kernal_processed_f = k_yptr == 4;

wire idx_read_done_f = rd_cnt == 1 && ST_P_WAIT_IDX;

wire local_mp_processed_f =  local_kernal_processed_f & (mp_window_x_cnt == 1) && (mp_window_y_cnt == 1) && ST_P_PROCESSING;

wire img_processed_f = (img_xptr == (img_size_ff - 6)) && (img_yptr == (img_size_ff - 6))
&& local_mp_processed_f && ST_P_PROCESSING;


reg img_processed_d1,img_processed_d2,img_processed_d3;
reg[4:0] processed_num_cnt;

wire deconv_img_processed_f=(img_xptr==(img_size_ff+3)) && (img_yptr==(img_size_ff+3))&&
(k_yptr == 4) && ST_P_PROCESSING;

reg deconv_img_processed_d1, deconv_img_processed_d2,deconv_img_processed_d3;

reg signed[19:0] temp_max_ff;
reg[4:0] mp_cnt;
wire mp_done_d2 = mp_window_x_cnt_d2 == 1 && mp_window_y_cnt_d2 == 1 && conv_accumulated_d2;
reg st_p_move_d1;
reg[4:0] local_conv_processed_cnt;

always @(posedge clk or negedge rst_n)
begin
  if(~rst_n)
  begin
    img_processed_d1 <= 0;
    img_processed_d2 <= 0;
    img_processed_d3 <= 0;

    img_xptr_d1  <= 0;
    img_xptr_d2  <= 0;
    img_xptr_d3  <= 0;

    img_yptr_d1  <= 0;
    img_yptr_d2  <= 0;
    img_yptr_d3  <= 0;

    mp_window_x_cnt_d1 <= 0;
    mp_window_x_cnt_d2 <= 0;
    mp_window_x_cnt_d3 <= 0;

    mp_window_y_cnt_d1 <= 0;
    mp_window_y_cnt_d2 <= 0;
    mp_window_y_cnt_d3 <= 0;

    deconv_img_processed_d1 <= 0;
    deconv_img_processed_d2 <= 0;
    deconv_img_processed_d3 <= 0;

    k_yptr_d1 <= 0;
    k_yptr_d2 <= 0;
  end
  else
  begin
    img_processed_d1 <= img_processed_f;
    img_processed_d2 <= img_processed_d1;
    img_processed_d3 <= img_processed_d2;

    img_xptr_d1  <= img_xptr;
    img_xptr_d2  <= img_xptr_d1;
    img_xptr_d3  <= img_xptr_d2;

    img_yptr_d1  <= img_yptr;
    img_yptr_d2  <= img_yptr_d1;
    img_yptr_d3  <= img_yptr_d2;

    mp_window_x_cnt_d1 <= mp_window_x_cnt;
    mp_window_x_cnt_d2 <= mp_window_x_cnt_d1;
    mp_window_x_cnt_d3 <= mp_window_x_cnt_d2;

    mp_window_y_cnt_d1 <= mp_window_y_cnt;
    mp_window_y_cnt_d2 <= mp_window_y_cnt_d1;
    mp_window_y_cnt_d3 <= mp_window_y_cnt_d2;

    deconv_img_processed_d1 <= deconv_img_processed_f;
    deconv_img_processed_d2 <= deconv_img_processed_d1;
    deconv_img_processed_d3 <= deconv_img_processed_d2;

    k_yptr_d1 <= k_yptr;
    k_yptr_d2 <= k_yptr_d1;
  end
end
wire processed_four_times_f = (local_conv_processed_cnt == 3) && local_kernal_processed_f && ST_P_PROCESSING;

reg[8:0] wr_img_xptr,wr_img_yptr,wr_k_xptr,wr_k_yptr;
wire processed_16_img_f = img_num_cnt == 15 && ST_P_PROCESSING;
wire rd_img_done_f      = (rd_cnt == ((img_size_ff * img_size_ff*16) -1));
wire rd_kernal_done_f   = (rd_cnt == ((5*5*16) -1));

wire kernal_moved_f = wr_k_xptr == 4 && wr_k_yptr == 4 && ST_P_MOVE_KERNAL_IMG;
wire img_moved_f    = (wr_img_xptr == (img_size_ff-1)) && (wr_img_yptr == (img_size_ff-1)) && ST_P_MOVE_KERNAL_IMG;

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
        if(in_valid) p_next_st = P_RD_IMG;
    end
    P_RD_IMG:
    begin
       if(rd_img_done_f) p_next_st = P_RD_KERNEL;
    end
    P_RD_KERNEL:
    begin
       if(rd_kernal_done_f) p_next_st = P_WAIT_IDX;
    end
    P_WAIT_IDX:
    begin
        if(idx_read_done_f) p_next_st = P_MOVE_KERNAL_IMG;
    end
    P_MOVE_KERNAL_IMG:
    begin
      if(img_moved_f)  p_next_st = P_PROCESSING;
    end
    P_PROCESSING:
    begin
      if(mode_ff == 0)
      begin
        if(img_processed_f)
        begin
          if(processed_16_img_f)
            p_next_st = P_IDLE;
          else
            p_next_st = P_WAIT_IDX;
        end
      end
      else
      begin
        if(deconv_img_processed_f)
        begin
          if(processed_16_img_f)
            p_next_st = P_IDLE;
          else
            p_next_st = P_WAIT_IDX;
        end
      end
    end
    endcase
end



//---------------------------------------------------------------------
//      SUB CTRS
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
   if(~rst_n)
   begin
      img_xptr <= 0;
      img_yptr <= 0;
      k_xptr   <= 0;
      k_yptr   <= 0;
      rd_cnt <= 0;
      img_num_cnt <= 0;
      kernal_num_cnt <= 0;
      mp_window_x_cnt <= 0;
      mp_window_y_cnt <= 0;
      local_conv_processed_cnt <= 0;

      wr_img_xptr <= 0;
      wr_img_yptr <= 0;
      wr_k_xptr <= 0;
      wr_k_yptr <= 0;
    end
    else
    begin
      case(p_cur_st)
      P_IDLE:
      begin
        if(in_valid)
        begin
          rd_cnt   <= 1;
        end
        else
        begin
          rd_cnt    <= 0;
        end
          img_xptr <= 0;
          img_yptr <= 0;
          k_xptr   <= 0;
          k_yptr   <= 0;

          img_num_cnt <= 0;
          kernal_num_cnt <= 0;
          mp_window_x_cnt <= 0;
          mp_window_y_cnt <= 0;
          local_conv_processed_cnt <= 0;

          wr_img_xptr <= 0;
          wr_img_yptr <= 0;
          wr_k_xptr <= 0;
          wr_k_yptr <= 0;
      end
      P_RD_IMG:
      begin
          rd_cnt <=rd_img_done_f ? 0 : rd_cnt + 1;
      end
      P_RD_KERNEL:
      begin
        rd_cnt <= rd_kernal_done_f ? 0 : rd_cnt + 1;
      end
      P_WAIT_IDX:
      begin
        if(rd_cnt == 1)
          rd_cnt <= 0;
        else if(in_valid2)
          rd_cnt <= rd_cnt + 1;
      end
      P_MOVE_KERNAL_IMG:
      begin
        // Maximum 1024 cycles
        if(p_cur_st != p_next_st)
        begin
          wr_img_xptr <= 0;
          wr_img_yptr <= 0;
        end
        if(img_moved_f)
        begin
          wr_img_xptr <= 0;
          wr_img_yptr <= 0;
        end
        else
        begin
          if(wr_img_xptr == (img_size_ff-1))
          begin
            wr_img_yptr <= wr_img_yptr + 1;
            wr_img_xptr <= 0;
          end
          else if(st_p_move_d1)
          begin
            wr_img_xptr <=  wr_img_xptr + 1;
          end
        end

        if(p_cur_st!=p_next_st)
        begin
          wr_k_xptr <= 0;
          wr_k_yptr <= 0;
        end
        else if(kernal_moved_f)
        begin
          wr_k_xptr <= 0;
          wr_k_yptr <= 0;
        end
        else
        begin
          if(wr_k_xptr == 4)
          begin
            wr_k_yptr <= wr_k_yptr + 1;
            wr_k_xptr <= 0;
          end
          else if(st_p_move_d1)
          begin
            wr_k_xptr <= wr_k_xptr + 1;
          end
        end
      end
      P_PROCESSING:
      begin
        case(mode_ff)
        2'b0:
        begin
          // Convolutions, and max pooling
          if(img_processed_f)
          begin
            img_yptr <= 0;
            img_xptr <= 0;
            img_num_cnt <= img_num_cnt + 1;
          end
          else if((img_xptr == (img_size_ff - 6)) && local_mp_processed_f)
          begin
            img_yptr <= img_yptr + 2;
            img_xptr <= 0;
          end
          else if(local_mp_processed_f)
          begin
            img_xptr <= img_xptr + 2;
          end

          if(local_kernal_processed_f)
          begin
            k_yptr <= 0;
          end
          else
          begin
            k_yptr <= k_yptr + 1;
          end

          if(local_mp_processed_f)
          begin
            mp_window_x_cnt <= 0;
            mp_window_y_cnt <= 0;
          end
          else if(mp_window_x_cnt == 1 && local_kernal_processed_f)
          begin
            mp_window_x_cnt <= 0;
            mp_window_y_cnt <= 1;
          end
          else if(k_yptr == 4)
          begin
            mp_window_x_cnt <= mp_window_x_cnt+1;
          end
        end
        2'b1:
        begin
          // Transpoed Convolution
          if(deconv_img_processed_f)
          begin
            img_yptr <= 0;
            img_xptr <= 0;
            img_num_cnt <= img_num_cnt + 1;
          end
          else if((img_xptr == (img_size_ff+3)) && (k_yptr == 4)&& processed_four_times_f)
          begin
            img_yptr <= img_yptr + 1;
            img_xptr <= 0;
          end
          else if(local_kernal_processed_f && processed_four_times_f)
          begin
            img_xptr <= img_xptr + 1;
          end

          if(local_kernal_processed_f)
          begin
            k_yptr <= 0;
          end
          else
          begin
            k_yptr <= k_yptr + 1;
          end

          if(p_cur_st != p_next_st)
          begin
            local_conv_processed_cnt <= 0;
          end
          else if(processed_four_times_f)
          begin
            local_conv_processed_cnt <= 0;
          end
          else if(local_kernal_processed_f)
          begin
            local_conv_processed_cnt <= local_conv_processed_cnt + 1;
          end
        end
        endcase
      end
      endcase
    end
end

//==============================================//
//               DATAPATH                       //
//==============================================//
//============================//
//          Sizes and modes       //
//============================//
always @(posedge clk or negedge rst_n)
begin
  if(~rst_n)
  begin
      kernal_idx_ff <= 0;
      img_size_ff <= 0;
      mode_ff     <= 0;
  end
  else if(ST_P_IDLE)
  begin
    if(in_valid)
    begin
      case(matrix_size)
      'd0:  img_size_ff <= 8;
      'd1:  img_size_ff <= 16;
      'd2:  img_size_ff <= 32;
      endcase
    end
  end
  else if(ST_P_WAIT_IDX)
  begin
    if(in_valid2)
    begin
      if(rd_cnt == 0)
      begin
        mode_ff    <= mode;
        img_idx_ff <= matrix_idx;
      end
      else
      begin
        kernal_idx_ff <= matrix_idx;
      end
    end
  end
end

reg[8:0] wr_img_xptr_d1,wr_img_yptr_d1,wr_k_yptr_d1,wr_k_xptr_d1;
always @(posedge clk)
begin
  k_xptr_d1 <= k_xptr;
  img_yptr_d1 <= img_yptr;
  img_xptr_d1 <= img_xptr;

  wr_k_yptr_d1 <= wr_k_yptr;
  wr_k_xptr_d1 <= wr_k_xptr;
  wr_img_yptr_d1 <= wr_img_yptr;
  wr_img_xptr_d1 <= wr_img_xptr;
end

always @(posedge clk)
begin
  if(st_p_move_d1)
  begin
    kernal_rf[wr_k_yptr_d1][wr_k_xptr_d1]     <= kernal_data_out;
    img_rf[wr_img_yptr_d1][wr_img_xptr_d1]    <= img_mem_data_out;
  end

  st_p_move_d1 <= ST_P_MOVE_KERNAL_IMG;
end
//============================//
//          idx_X,idx_Y       //
//============================//
always @(*)
begin
  for(x=0;x<5;x=x+1)
  begin
    if(mode_ff == 0)
    begin
      //Convolution + MP
      idx_x[x] = img_xptr+mp_window_x_cnt;
      idx_y = img_yptr+mp_window_y_cnt;
    end
    else
    begin
      // Deconvolution
      idx_x[x] = img_xptr + x;
      idx_y = img_yptr+k_yptr;
    end
  end
end

//================================//
//          Sizes and modes       //
//================================//
// Zeropad flags
reg zero_pad_f[0:4];
always @(*)
begin
  lower_bo
  und0 = img_size_ff + 4;
  lower_bound1 = img_size_ff + 5;
  lower_bound2 = img_size_ff + 6;
  lower_bound3 = img_size_ff + 7;
  for(x=0;x<5;x=x+1)
  begin
    if(idx_x[x] == 0 || idx_x[x] == 1 || idx_x[x] == 2 || idx_x[x] == 3 || idx_y == 0 || idx_y == 1 || idx_y == 2||
    idx_y == 3 || idx_y == lower_bound0 || idx_y == lower_bound1 || idx_y == lower_bound2 || idx_y == lower_bound3||
    idx_x[x] == lower_bound0 || idx_x[x] == lower_bound1 || idx_x[x] == lower_bound2 || idx_x[x] == lower_bound3)
    begin
      zero_pad_f[x] = 1;
    end
    else
    begin
      zero_pad_f[x] = 0;
    end
  end
end

//============================//
//          Mults in          //
//============================//
reg signed[DATA_WIDTH-1:0] mult_in0_d1[0:4];
reg signed[DATA_WIDTH-1:0] mult_in1_d1[0:4];
genvar x_idx;

generate
  for(x_idx=0;x_idx<5;x_idx=x_idx+1)
    always @(posedge clk)
    begin
        if(mode_ff == 0)
        begin
          mult_in0_d1[x_idx] <= kernal_rf[k_yptr][x_idx];
          mult_in1_d1[x_idx] <= img_rf[idx_y + k_yptr][idx_x[x_idx] + x_idx];
        end
        else
        begin
          mult_in0_d1[x_idx] <= kernal_rf[4-k_yptr][4-x_idx];
          mult_in1_d1[x_idx] <= zero_pad_f[x_idx] ? 0 : img_rf[idx_y-4][idx_x[x_idx]-4];
        end
    end
endgenerate

//================//
// CONV MAC       //
//================//
reg signed[19:0] mac_result_d2;
always @(posedge clk or negedge rst_n)
begin
  if(~rst_n)
  begin
      mac_result_d2 <= 0;
  end
  else
  begin
      mac_result_d2 <= (mult_in0_d1[0] * mult_in1_d1[0]) + (mult_in0_d1[1] * mult_in1_d1[1]) + (mult_in0_d1[2] * mult_in1_d1[2])
      + (mult_in0_d1[3] * mult_in1_d1[3]) +(mult_in0_d1[4] * mult_in1_d1[4]);
  end
end


always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
      conv_ff <= 0;
    end
    else if(k_yptr_d2 == 0)
    begin
      conv_ff <= mac_result_d2;
    end
    else
    begin
      conv_ff <= mac_result_d2 + conv_ff;
    end
end

//===================//
// MAX POOLING       //
//===================//

always @(posedge clk or negedge rst_n)
begin
  if(~rst_n)
  begin
    temp_max_ff <= 0;
  end
  else if(conv_accumulated_d2 & ST_P_PROCESSING)
    if(mp_window_x_cnt_d2 == 0 && mp_window_y_cnt_d2 == 0)
      temp_max_ff <= mac_result_d2 + conv_ff;
    else
      temp_max_ff <=  ((mac_result_d2+conv_ff) > temp_max_ff) ? (mac_result_d2 + conv_ff) : temp_max_ff;
end
reg signed[19:0] result_buf1;
reg signed[19:0] result_buf2;
//===================//
// Result Buffer     //
//===================//
always @(posedge clk or negedge rst_n)
begin
  if(~rst_n)
  begin
    result_buf1 <= 0;
    // result_buf2 <= 0;
  end
  else if(mode_ff == 0)
  begin
    result_buf1 <= mp_done_d2 ? ((conv_ff + mac_result_d2) > temp_max_ff)?(conv_ff + mac_result_d2):
    temp_max_ff:result_buf1;
    // result_buf2 <= temp_max_ff;
  end
  else if(mode_ff == 1)
  begin
    result_buf1 <= conv_accumulated_d2 ? (conv_ff + mac_result_d2) : result_buf1;
    // result_buf2 <= conv_accumulated_d2 ? (conv_ff + mac_result_d2) : result_buf1;
  end
end

//---------------------------------------------------------------------
//      Output CTR
//---------------------------------------------------------------------
reg waiting_output_f ;
reg conv_done_d3;


always @(posedge clk or negedge rst_n)
begin
  if(~rst_n)
  begin
    out_cur_st <= OUTPUT_IDLE;
    out_value <= 0;
    out_valid <= 0;
    out_cnt <= 0;
    waiting_output_f <= 0;
  end
  else
  begin
    case(out_cur_st)
    OUTPUT_IDLE:
    begin
      if(mode_ff == 0 && mp_done_d2 && ST_P_PROCESSING)
      begin
        out_cur_st <= OUTPUT_MODE0;
      end
      else if(mode_ff == 1 && conv_accumulated_d2 && ST_P_PROCESSING)
      begin
        out_cur_st <= OUTPUT_MODE1;
      end
      out_valid <= 0;
      out_value <= 0;
      out_cnt <= 0;
      waiting_output_f <= 0;
    end
    OUTPUT_MODE0:
    begin
      waiting_output_f <= img_processed_d2 ? 1 : waiting_output_f;
      out_cur_st <= (out_cnt==19) && waiting_output_f ? OUTPUT_IDLE : OUTPUT_MODE0;
      out_valid  <= 1;
      out_value  <= result_buf1[out_cnt];
      out_cnt    <= (out_cnt == 19) ? 0 : out_cnt+1;
    end
    OUTPUT_MODE1:
    begin
      waiting_output_f <= deconv_img_processed_d2 ? 1 : waiting_output_f;
      if((out_cnt == 19) && waiting_output_f)
      begin
        out_cur_st <= OUTPUT_IDLE;
      end
      out_valid <= 1;
      out_value <= result_buf1[out_cnt];
      out_cnt <= (out_cnt == 19)  ? 0:out_cnt + 1;
    end
    endcase
  end
end

//---------------------------------------------------------------------
//      SRAM ADDR CALCULATOR
//---------------------------------------------------------------------
always @(*)
begin
  img_wen    = 1;
  kernal_wen = 1;
  offset     = img_size_ff * img_size_ff;
  img_mem_addr = 0;
  img_mem_data_in = 0;
  kernal_mem_addr = 0;
  kernal_data_in = 0;

  if(ST_P_IDLE || ST_P_RD_IMG)
  begin
    if(in_valid)
      img_wen = 0;

    img_mem_addr = rd_cnt;
    img_mem_data_in = matrix;
  end

  if(ST_P_RD_KERNEL)
  begin
    if(in_valid)
      kernal_wen = 0;

    kernal_mem_addr = rd_cnt;
    kernal_data_in  = matrix;
  end
  else if(ST_P_MOVE_KERNAL_IMG)
  begin
    img_mem_addr = wr_img_xptr + wr_img_yptr * img_size_ff + img_idx_ff * offset;
    kernal_mem_addr = wr_k_xptr + wr_k_yptr * 5 + kernal_idx_ff * 25;
  end
end

//==============================================//
//             2 SRAMS                          //
//==============================================//
SRAM_IMG u_IMG(.A0(img_mem_addr[0]),.A1(img_mem_addr[1]),.A2(img_mem_addr[2]),.A3(img_mem_addr[3]),
.A4(img_mem_addr[4]),.A5(img_mem_addr[5]),.A6(img_mem_addr[6]),
.A7(img_mem_addr[7]),.A8(img_mem_addr[8]),.A9(img_mem_addr[9]),.A10(img_mem_addr[10]),.A11(img_mem_addr[11]),.A12(img_mem_addr[12])
,.A13(img_mem_addr[13]),
.DO0(img_mem_data_out[0]),.DO1(img_mem_data_out[1]),.DO2(img_mem_data_out[2]),.DO3(img_mem_data_out[3]),.DO4(img_mem_data_out[4]),
.DO5(img_mem_data_out[5]),.DO6(img_mem_data_out[6]),.DO7(img_mem_data_out[7]),.DI0(img_mem_data_in[0]),.DI1(img_mem_data_in[1]),
.DI2(img_mem_data_in[2]),.DI3(img_mem_data_in[3]),.DI4(img_mem_data_in[4]),.DI5(img_mem_data_in[5]),.DI6(img_mem_data_in[6]),.DI7(img_mem_data_in[7]),
.CK(clk),.WEB(img_wen),.OE(1'b1),.CS(1'b1));


SRAM_KERNAL u_KERNAL(.A0(kernal_mem_addr[0]),.A1(kernal_mem_addr[1]),
.A2(kernal_mem_addr[2]),.A3(kernal_mem_addr[3]),
.A4(kernal_mem_addr[4]),.A5(kernal_mem_addr[5]),.A6(kernal_mem_addr[6]),
.A7(kernal_mem_addr[7]),.A8(kernal_mem_addr[8]),
.DO0(kernal_data_out[0]),.DO1(kernal_data_out[1]),.DO2(kernal_data_out[2]),.DO3(kernal_data_out[3]),.DO4(kernal_data_out[4]),
.DO5(kernal_data_out[5]),.DO6(kernal_data_out[6]),.DO7(kernal_data_out[7]),
.DI0(kernal_data_in[0]),.DI1(kernal_data_in[1]),.DI2(kernal_data_in[2]),.DI3(kernal_data_in[3]),
.DI4(kernal_data_in[4]),.DI5(kernal_data_in[5]),.DI6(kernal_data_in[6]),.DI7(kernal_data_in[7]),
                    .CK(clk),.WEB(kernal_wen),.OE(1'b1),.CS(1'b1));



endmodule