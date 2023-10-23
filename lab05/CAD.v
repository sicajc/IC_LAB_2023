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

wire ST_P_IDLE               = p_cur_st[0];
wire ST_P_RD_IMG             = p_cur_st[1];
wire ST_P_RD_KERNEL          = p_cur_st[2];
wire ST_P_WAIT_IDX           = p_cur_st[3];
wire ST_P_PROCESSING         = p_cur_st[4];
wire ST_P_MOVE_KERNAL_IMG    = p_cur_st[5];

wire ST_OUTPUT_IDLE   = out_cur_st[0];
wire ST_OUTPUT_MODE0   = out_cur_st[1];
wire ST_OUTPUT_MODE1_STALL   = out_cur_st[2];
wire ST_OUTPUT_MODE1   = out_cur_st[3];

reg[9:0] rd_cnt;
reg[3:0] kernal_idx_ff;
reg[3:0] img_idx_ff;
reg[3:0] img_num_cnt;
reg[3:0] kernal_num_cnt;

reg[5:0] img_xptr,img_yptr,
img_xptr_d0,img_yptr_d0,img_xptr_d1,img_yptr_d1,img_xptr_d2,img_yptr_d2,img_xptr_d3,img_yptr_d3;

reg[5:0] k_xptr,k_yptr,k_yptr_d0,k_xptr_d1,k_yptr_d1,k_yptr_d2,k_yptr_d3;

reg[2:0] mp_window_x_cnt ,mp_window_y_cnt,mp_window_x_cnt_d0,mp_window_y_cnt_d0,mp_window_x_cnt_d1
,mp_window_y_cnt_d1,mp_window_x_cnt_d2,mp_window_y_cnt_d2,mp_window_x_cnt_d3 ,mp_window_y_cnt_d3;

reg[5:0] output_cnt;
reg[8:0] idx_x[0:4];
reg[8:0] idx_y;

//---------------------------------------------------------------------
//      REGs and FFs
//---------------------------------------------------------------------
reg[2:0] mode_ff;
reg[5:0] img_size_ff;

reg[13:0] img_mem_addr;
reg[8:0] kernal_mem_addr;

wire signed[7:0] img_mem_data_out,kernal_data_out;
reg signed[7:0] img_mem_data_in,kernal_data_in;
reg[15:0] lower_bound0,lower_bound1,lower_bound2,lower_bound3;
reg signed[19:0] conv_ff;
wire conv_accumulated_d2 = (k_yptr_d2 == 4);

integer x,y,i,j;

reg[3:0] sram_num;
reg[14:0] sram_addr;
reg k_wen[0:4];
wire[7:0] img_data_out[0:4];
reg img_wen[0:4];

reg[6:0] kernal_sram_addr;
wire[7:0] k_out_data[0:4];
reg kernal_wen[0:4];

reg[11:0] s0_img_mem_addr;
reg[11:0] s1_img_mem_addr;
reg[11:0] s2_img_mem_addr;
reg[11:0] s3_img_mem_addr;
reg[11:0] s4_img_mem_addr;
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


reg img_processed_d0, img_processed_d1,img_processed_d2,img_processed_d3;
reg[4:0] processed_num_cnt;

wire deconv_img_processed_f=(img_xptr==(img_size_ff+3)) && (img_yptr==(img_size_ff+3))&&
(k_yptr == 4) && ST_P_PROCESSING;

reg deconv_img_processed_d0,deconv_img_processed_d1, deconv_img_processed_d2,deconv_img_processed_d3;

reg signed[19:0] temp_max_ff;
reg[4:0] mp_cnt;
wire mp_done_d2 = mp_window_x_cnt_d2 == 1 && mp_window_y_cnt_d2 == 1 && conv_accumulated_d2;
reg st_p_move_d1;
reg[4:0] local_conv_processed_cnt;

always @(posedge clk or negedge rst_n)
begin
  if(~rst_n)
  begin
    img_processed_d0 <= 0;
    img_processed_d1 <= 0;
    img_processed_d2 <= 0;
    img_processed_d3 <= 0;

    img_xptr_d0  <= 0;
    img_xptr_d1  <= 0;
    img_xptr_d2  <= 0;
    img_xptr_d3  <= 0;

    img_yptr_d0  <= 0;
    img_yptr_d1  <= 0;
    img_yptr_d2  <= 0;
    img_yptr_d3  <= 0;

    mp_window_x_cnt_d0 <= 0;
    mp_window_x_cnt_d1 <= 0;
    mp_window_x_cnt_d2 <= 0;
    mp_window_x_cnt_d3 <= 0;

    mp_window_y_cnt_d0 <= 0;
    mp_window_y_cnt_d1 <= 0;
    mp_window_y_cnt_d2 <= 0;
    mp_window_y_cnt_d3 <= 0;

    deconv_img_processed_d0 <= 0;
    deconv_img_processed_d1 <= 0;
    deconv_img_processed_d2 <= 0;
    deconv_img_processed_d3 <= 0;

    k_yptr_d0 <= 0;
    k_yptr_d1 <= 0;
    k_yptr_d2 <= 0;
  end
  else
  begin
    img_processed_d0 <= img_processed_f;
    img_processed_d1 <= img_processed_d0;
    img_processed_d2 <= img_processed_d1;
    img_processed_d3 <= img_processed_d2;

    img_xptr_d0  <= img_xptr;
    img_xptr_d1  <= img_xptr_d0;
    img_xptr_d2  <= img_xptr_d1;
    img_xptr_d3  <= img_xptr_d2;

    img_yptr_d0  <= img_yptr;
    img_yptr_d1  <= img_yptr_d0;
    img_yptr_d2  <= img_yptr_d1;
    img_yptr_d3  <= img_yptr_d2;

    mp_window_x_cnt_d0 <= mp_window_x_cnt;
    mp_window_x_cnt_d1 <= mp_window_x_cnt_d0;
    mp_window_x_cnt_d2 <= mp_window_x_cnt_d1;
    mp_window_x_cnt_d3 <= mp_window_x_cnt_d2;

    mp_window_y_cnt_d0 <= mp_window_y_cnt;
    mp_window_y_cnt_d1 <= mp_window_y_cnt_d0;
    mp_window_y_cnt_d2 <= mp_window_y_cnt_d1;
    mp_window_y_cnt_d3 <= mp_window_y_cnt_d2;

    deconv_img_processed_d0 <= deconv_img_processed_f;
    deconv_img_processed_d1 <= deconv_img_processed_d0;
    deconv_img_processed_d2 <= deconv_img_processed_d1;
    deconv_img_processed_d3 <= deconv_img_processed_d2;


    k_yptr_d0 <= k_yptr;
    k_yptr_d1 <= k_yptr_d0;
    k_yptr_d2 <= k_yptr_d1;
  end
end

wire processed_four_times_f = (local_conv_processed_cnt == 3) && local_kernal_processed_f && ST_P_PROCESSING;
reg[5:0] rd_img_cnt;
reg[4:0] wr_img_xptr,wr_img_yptr;
reg[2:0] wr_k_xptr,wr_k_yptr;
wire processed_16_img_f = img_num_cnt == 15 && ST_P_PROCESSING;
wire one_img_rd_f = rd_cnt == ((img_size_ff * img_size_ff) -1);
wire rd_img_done_f      = one_img_rd_f && (img_num_cnt == 15);

wire one_kernal_read_f  = (rd_cnt == 24);
wire rd_kernal_done_f   = one_kernal_read_f && (img_num_cnt == 15);

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
        if(idx_read_done_f) p_next_st = P_PROCESSING;
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
      rd_img_cnt <= 0;
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

          if(in_valid)
            wr_img_xptr <= 1;

          wr_img_yptr <= 0;

          wr_k_xptr <= 0;
          wr_k_yptr <= 0;
      end
      P_RD_IMG:
      begin
          rd_cnt <= one_img_rd_f ? 0 : rd_cnt + 1;
          img_num_cnt <= rd_img_done_f ? 0 : (one_img_rd_f ? img_num_cnt + 1 : img_num_cnt);

          if((wr_img_xptr == img_size_ff - 1) && (wr_img_yptr == img_size_ff - 1))
          begin
            wr_img_xptr <= 0;
            wr_img_yptr <= 0;
          end
          else if((wr_img_xptr == img_size_ff - 1))
          begin
            wr_img_xptr <= 0;
            wr_img_yptr <= wr_img_yptr + 1;
          end
          else
          begin
            wr_img_xptr <= wr_img_xptr + 1;
          end
      end
      P_RD_KERNEL:
      begin
          rd_cnt <= one_kernal_read_f ? 0 : rd_cnt + 1;
          img_num_cnt <= rd_kernal_done_f ? 0 : (one_kernal_read_f ? img_num_cnt + 1 : img_num_cnt);

          if((wr_img_xptr == 4) && (wr_img_yptr == 4))
          begin
            wr_img_xptr <= 0;
            wr_img_yptr <= 0;
          end
          else if((wr_img_xptr == 4))
          begin
            wr_img_xptr <= 0;
            wr_img_yptr <= wr_img_yptr + 1;
          end
          else
          begin
            wr_img_xptr <= wr_img_xptr + 1;
          end
      end
      P_WAIT_IDX:
      begin
        if(rd_cnt == 1)
          rd_cnt <= 0;
        else if(in_valid2)
          rd_cnt <= rd_cnt + 1;

        if(mode_ff==1 && rd_cnt == 1 && in_valid2)
        begin
          k_yptr <= 3;
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
  lower_bound0 = img_size_ff + 4;
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

reg zero_pad_d1[0:4];
always @(posedge clk)
begin
  for(x=0;x<5;x=x+1)
    zero_pad_d1[x] <= zero_pad_f[x];
end

//============================//
//          Mults in          //
//============================//
reg signed[DATA_WIDTH-1:0] mult_in0_d1[0:4];
reg signed[DATA_WIDTH-1:0] mult_in1_d1[0:4];
reg[11:0] mult_in0_sram_num[0:4];
reg[11:0] mult_in0_sram_addr[0:4];
genvar x_idx;

reg[11:0] offsets[0:4];

reg[8:0] div5s_in[0:4];
wire[8:0] div5s_out[0:4];

reg[8:0] mod5s_in[0:4];
wire[8:0] mod5s_out[0:4];

generate
  for(x_idx = 0; x_idx < 5; x_idx = x_idx + 1)
  begin
    assign div5s_out[x_idx] = div5s_in[x_idx] / 5;
    assign mod5s_out[x_idx] = mod5s_in[x_idx] % 5;
  end
endgenerate

always @(*)
begin
  for(x = 0; x < 5; x=x+1)
  begin
    div5s_in[x] = 0;
    mod5s_in[x] = 0;
  end

  if(mode_ff == 0)
  begin
    for(x=0;x<5;x=x+1)
    begin
      div5s_in[x] = (idx_x[x] + x);
      mod5s_in[x] = (idx_x[x] + x);


      mult_in0_sram_num[x]  =  mod5s_out[x];
      mult_in0_sram_addr[x] = div5s_out[x]*img_size_ff + (idx_y + k_yptr) + (img_idx_ff * 224);
    end
  end
  else
  begin
    for(x=0;x<5;x=x+1)
    begin
      if(zero_pad_f[x])
      begin
        mult_in0_sram_num[x]  = 5;
        mult_in0_sram_addr[x] = 0;
      end
      else
      begin
         offsets[x] = (idx_x[x] - 4);
          div5s_in[x] = offsets[x];
          mod5s_in[x] = offsets[x];
         mult_in0_sram_num[x] =  mod5s_out[x];
         mult_in0_sram_addr[x]= div5s_out[x] * img_size_ff + (idx_y - 4) + img_idx_ff * 224;
      end
    end
  end
end

reg[7:0] mult_in0_sram_num_d0[0:4];
reg[7:0] kernal_sram_num[0:4];

always @(posedge clk)
begin
  for(x=0;x<5;x=x+1)
  begin
    mult_in0_sram_num_d0[x] <= mult_in0_sram_num[x];
  end
end

generate
  for(x_idx=0;x_idx<5;x_idx=x_idx+1)
    always @(posedge clk)
    begin
        if(mode_ff == 0)
        begin
          mult_in1_d1[x_idx] <= k_out_data[x_idx];

          case(mult_in0_sram_num_d0[x_idx])
          'd0:mult_in0_d1[x_idx] <= img_data_out[0];
          'd1:mult_in0_d1[x_idx] <= img_data_out[1];
          'd2:mult_in0_d1[x_idx] <= img_data_out[2];
          'd3:mult_in0_d1[x_idx] <= img_data_out[3];
          'd4:mult_in0_d1[x_idx] <= img_data_out[4];
          default:mult_in0_d1[x_idx] <= 0;
          endcase
        end
        else
        begin

        case(mult_in0_sram_num_d0[x_idx])
          'd0: mult_in0_d1[x_idx] <= zero_pad_d1[x_idx] ? 0 : img_data_out[0];
          'd1: mult_in0_d1[x_idx] <= zero_pad_d1[x_idx] ? 0 : img_data_out[1];
          'd2: mult_in0_d1[x_idx] <= zero_pad_d1[x_idx] ? 0 : img_data_out[2];
          'd3: mult_in0_d1[x_idx] <= zero_pad_d1[x_idx] ? 0 : img_data_out[3];
          'd4: mult_in0_d1[x_idx] <= zero_pad_d1[x_idx] ? 0 : img_data_out[4];
          default: mult_in0_d1[x_idx] <= 0;
        endcase

        mult_in1_d1[x_idx] <= zero_pad_d1[x_idx] ? 0 : k_out_data[4-x_idx];

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
    result_buf2 <= 0;
  end
  else if(mode_ff == 0)
  begin
    result_buf1 <= mp_done_d2 ? ((conv_ff + mac_result_d2) > temp_max_ff)?(conv_ff + mac_result_d2):
    temp_max_ff:result_buf1;
    result_buf2 <= temp_max_ff;
  end
  else if(mode_ff == 1)
  begin
    result_buf1 <= conv_accumulated_d2 ? (conv_ff + mac_result_d2) : result_buf1;
    result_buf2 <= conv_accumulated_d2 ? (conv_ff + mac_result_d2) : result_buf1;
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
  sram_num   = 0;
  kernal_data_in = 0;
  sram_num  = 0;
  sram_addr = 0;
  s0_img_mem_addr = 0;
  s1_img_mem_addr = 0;
  s2_img_mem_addr = 0;
  s3_img_mem_addr = 0;
  s4_img_mem_addr = 0;
  kernal_sram_addr = 0;

  for(x=0;x<5;x=x+1)
  begin
    img_wen[x] = 1;
    k_wen[x] = 1;
  end

  if(ST_P_RD_IMG)
  begin
    sram_num  = wr_img_xptr % 5;
    sram_addr = (wr_img_xptr / 5)*img_size_ff + wr_img_yptr + img_num_cnt * 224;
  end
  if(ST_P_RD_KERNEL)
  begin
    sram_num  = wr_img_xptr % 5;
    sram_addr = (wr_img_xptr / 5) + wr_img_yptr + img_num_cnt * 5;
  end

  if(ST_P_IDLE || ST_P_RD_IMG)
  begin
    if(in_valid)
      img_wen[sram_num] = 0;

    s0_img_mem_addr = sram_addr;
    s1_img_mem_addr = sram_addr;
    s2_img_mem_addr = sram_addr;
    s3_img_mem_addr = sram_addr;
    s4_img_mem_addr = sram_addr;
  end

  if(ST_P_RD_KERNEL)
  begin
    if(in_valid)
      k_wen[sram_num] = 0;

    kernal_sram_addr = sram_addr;
  end

  if(ST_P_PROCESSING)
  begin
    for(x=0;x<5;x=x+1)
      case(mult_in0_sram_num[x])
      'd0:s0_img_mem_addr = mult_in0_sram_addr[x];
      'd1:s1_img_mem_addr = mult_in0_sram_addr[x];
      'd2:s2_img_mem_addr = mult_in0_sram_addr[x];
      'd3:s3_img_mem_addr = mult_in0_sram_addr[x];
      'd4:s4_img_mem_addr = mult_in0_sram_addr[x];
      endcase

    if(mode_ff == 0)
    begin
      kernal_sram_addr = k_yptr + kernal_idx_ff * 5;
    end
    else
    begin
      kernal_sram_addr = 4 + kernal_idx_ff * 5 - k_yptr;
    end
  end
end

//==============================================//
//             10 SRAMS                          //
//==============================================//
SRAM_32x7x16 u_S0(.A0(s0_img_mem_addr[0]),.A1(s0_img_mem_addr[1]),.A2(s0_img_mem_addr[2]),.A3(s0_img_mem_addr[3]),
    .A4(s0_img_mem_addr[4]),.A5(s0_img_mem_addr[5]),.A6(s0_img_mem_addr[6]),.A7(s0_img_mem_addr[7]),
    .A8(s0_img_mem_addr[8]),.A9(s0_img_mem_addr[9]),.A10(s0_img_mem_addr[10]),.A11(s0_img_mem_addr[11]),
                     .DO0(img_data_out[0][0]),.DO1(img_data_out[0][1]),.DO2(img_data_out[0][2]),
                     .DO3(img_data_out[0][3]),.DO4(img_data_out[0][4]),
                     .DO5(img_data_out[0][5]),.DO6(img_data_out[0][6]),.DO7(img_data_out[0][7]),
                     .DI0(matrix[0]),.DI1(matrix[1]),.DI2(matrix[2]),.DI3(matrix[3]),
                     .DI4(matrix[4]),.DI5(matrix[5]),
                     .DI6(matrix[6]),.DI7(matrix[7]),.CK(clk),.WEB(img_wen[0]),.OE(1'b1),.CS(1'b1)
                     );

SRAM_32x7x16 u_S1(.A0(s1_img_mem_addr[0]),.A1(s1_img_mem_addr[1]),.A2(s1_img_mem_addr[2]),.A3(s1_img_mem_addr[3]),
    .A4(s1_img_mem_addr[4]),.A5(s1_img_mem_addr[5]),.A6(s1_img_mem_addr[6]),.A7(s1_img_mem_addr[7]),
    .A8(s1_img_mem_addr[8]),.A9(s1_img_mem_addr[9]),.A10(s1_img_mem_addr[10]),.A11(s1_img_mem_addr[11]),
                     .DO0(img_data_out[1][0]),.DO1(img_data_out[1][1]),.DO2(img_data_out[1][2]),
                     .DO3(img_data_out[1][3]),.DO4(img_data_out[1][4]),
                     .DO5(img_data_out[1][5]),.DO6(img_data_out[1][6]),.DO7(img_data_out[1][7]),
                     .DI0(matrix[0]),.DI1(matrix[1]),.DI2(matrix[2]),.DI3(matrix[3]),
                     .DI4(matrix[4]),.DI5(matrix[5]),
                     .DI6(matrix[6]),.DI7(matrix[7]),.CK(clk),.WEB(img_wen[1]),.OE(1'b1),.CS(1'b1)
                     );

SRAM_32x7x16 u_S2(.A0(s2_img_mem_addr[0]),.A1(s2_img_mem_addr[1]),.A2(s2_img_mem_addr[2]),.A3(s2_img_mem_addr[3]),
    .A4(s2_img_mem_addr[4]),.A5(s2_img_mem_addr[5]),.A6(s2_img_mem_addr[6]),.A7(s2_img_mem_addr[7]),
    .A8(s2_img_mem_addr[8]),.A9(s2_img_mem_addr[9]),.A10(s2_img_mem_addr[10]),.A11(s2_img_mem_addr[11]),
                     .DO0(img_data_out[2][0]),.DO1(img_data_out[2][1]),.DO2(img_data_out[2][2]),
                     .DO3(img_data_out[2][3]),.DO4(img_data_out[2][4]),
                     .DO5(img_data_out[2][5]),.DO6(img_data_out[2][6]),.DO7(img_data_out[2][7]),
                     .DI0(matrix[0]),.DI1(matrix[1]),.DI2(matrix[2]),.DI3(matrix[3]),
                     .DI4(matrix[4]),.DI5(matrix[5]),
                     .DI6(matrix[6]),.DI7(matrix[7]),.CK(clk),.WEB(img_wen[2]),.OE(1'b1),.CS(1'b1)
                     );

SRAM_32x7x16 u_S3(.A0(s3_img_mem_addr[0]),.A1(s3_img_mem_addr[1]),.A2(s3_img_mem_addr[2]),.A3(s3_img_mem_addr[3]),
    .A4(s3_img_mem_addr[4]),.A5(s3_img_mem_addr[5]),.A6(s3_img_mem_addr[6]),.A7(s3_img_mem_addr[7]),
    .A8(s3_img_mem_addr[8]),.A9(s3_img_mem_addr[9]),.A10(s3_img_mem_addr[10]),.A11(s3_img_mem_addr[11]),
                     .DO0(img_data_out[3][0]),.DO1(img_data_out[3][1]),.DO2(img_data_out[3][2]),
                     .DO3(img_data_out[3][3]),.DO4(img_data_out[3][4]),
                     .DO5(img_data_out[3][5]),.DO6(img_data_out[3][6]),.DO7(img_data_out[3][7]),
                     .DI0(matrix[0]),.DI1(matrix[1]),.DI2(matrix[2]),.DI3(matrix[3]),
                     .DI4(matrix[4]),.DI5(matrix[5]),
                     .DI6(matrix[6]),.DI7(matrix[7]),.CK(clk),.WEB(img_wen[3]),.OE(1'b1),.CS(1'b1)
                     );

SRAM_32x7x16 u_S4(.A0(s4_img_mem_addr[0]),.A1(s4_img_mem_addr[1]),.A2(s4_img_mem_addr[2]),.A3(s4_img_mem_addr[3]),
    .A4(s4_img_mem_addr[4]),.A5(s4_img_mem_addr[5]),.A6(s4_img_mem_addr[6]),.A7(s4_img_mem_addr[7]),
    .A8(s4_img_mem_addr[8]),.A9(s4_img_mem_addr[9]),.A10(s4_img_mem_addr[10]),.A11(s4_img_mem_addr[11]),
                     .DO0(img_data_out[4][0]),.DO1(img_data_out[4][1]),.DO2(img_data_out[4][2]),
                     .DO3(img_data_out[4][3]),.DO4(img_data_out[4][4]),
                     .DO5(img_data_out[4][5]),.DO6(img_data_out[4][6]),.DO7(img_data_out[4][7]),
                     .DI0(matrix[0]),.DI1(matrix[1]),.DI2(matrix[2]),.DI3(matrix[3]),
                     .DI4(matrix[4]),.DI5(matrix[5]),
                     .DI6(matrix[6]),.DI7(matrix[7]),.CK(clk),.WEB(img_wen[4]),.OE(1'b1),.CS(1'b1)
                     );

SRAM_5x16 u_K0(.A0(kernal_sram_addr[0]),.A1(kernal_sram_addr[1]),.A2(kernal_sram_addr[2]),
.A3(kernal_sram_addr[3]),.A4(kernal_sram_addr[4]),.A5(kernal_sram_addr[5]),
.A6(kernal_sram_addr[6]),
            .DO0(k_out_data[0][0]),.DO1(k_out_data[0][1]),.DO2(k_out_data[0][2]),.DO3(k_out_data[0][3]),
            .DO4(k_out_data[0][4]),.DO5(k_out_data[0][5]),.DO6(k_out_data[0][6]),
            .DO7(k_out_data[0][7]),.DI0(matrix[0]),.DI1(matrix[1]),.DI2(matrix[2]),
                  .DI3(matrix[3]),.DI4(matrix[4]),.DI5(matrix[5]),
                  .DI6(matrix[6]),.DI7(matrix[7]),.CK(clk),.WEB(k_wen[0]),.OE(1'b1),.CS(1'b1));

SRAM_5x16 u_K1(.A0(kernal_sram_addr[0]),.A1(kernal_sram_addr[1]),.A2(kernal_sram_addr[2]),
.A3(kernal_sram_addr[3]),.A4(kernal_sram_addr[4]),.A5(kernal_sram_addr[5]),
.A6(kernal_sram_addr[6]),.DO0(k_out_data[1][0]),.DO1(k_out_data[1][1]),.DO2(k_out_data[1][2]),.DO3(k_out_data[1][3]),
.DO4(k_out_data[1][4]),.DO5(k_out_data[1][5]),.DO6(k_out_data[1][6]),.
                  DO7(k_out_data[1][7]),.DI0(matrix[0]),.DI1(matrix[1]),.DI2(matrix[2]),
                  .DI3(matrix[3]),.DI4(matrix[4]),.DI5(matrix[5]),
                  .DI6(matrix[6]),.DI7(matrix[7]),.CK(clk),.WEB(k_wen[1]),.OE(1'b1),.CS(1'b1));

SRAM_5x16 u_K2(.A0(kernal_sram_addr[0]),.A1(kernal_sram_addr[1]),.A2(kernal_sram_addr[2]),
.A3(kernal_sram_addr[3]),.A4(kernal_sram_addr[4]),.A5(kernal_sram_addr[5]),
.A6(kernal_sram_addr[6]),.DO0(k_out_data[2][0]),.DO1(k_out_data[2][1]),.DO2(k_out_data[2][2]),.DO3(k_out_data[2][3]),
                  .DO4(k_out_data[2][4]),.DO5(k_out_data[2][5]),.DO6(k_out_data[2][6]),
                  .DO7(k_out_data[2][7]),
                  .DI0(matrix[0]),.DI1(matrix[1]),.DI2(matrix[2]),
                  .DI3(matrix[3]),.DI4(matrix[4]),.DI5(matrix[5]),
                  .DI6(matrix[6]),.DI7(matrix[7]),.CK(clk),.WEB(k_wen[2]),.OE(1'b1),.CS(1'b1));

SRAM_5x16 u_K3(.A0(kernal_sram_addr[0]),.A1(kernal_sram_addr[1]),.A2(kernal_sram_addr[2]),
.A3(kernal_sram_addr[3]),.A4(kernal_sram_addr[4]),.A5(kernal_sram_addr[5]),
.A6(kernal_sram_addr[6]),.DO0(k_out_data[3][0]),.DO1(k_out_data[3][1]),.DO2(k_out_data[3][2]),.DO3(k_out_data[3][3]),
              .DO4(k_out_data[3][4]),.DO5(k_out_data[3][5]),.DO6(k_out_data[3][6]),
              .DO7(k_out_data[3][7]),.DI0(matrix[0]),.DI1(matrix[1]),.DI2(matrix[2]),.DI3(matrix[3]),
                  .DI4(matrix[4]),.DI5(matrix[5]),.DI6(matrix[6]),.DI7(matrix[7]),.CK(clk),.WEB(k_wen[3]),.OE(1'b1),.CS(1'b1));

SRAM_5x16 u_K4(.A0(kernal_sram_addr[0]),.A1(kernal_sram_addr[1]),.A2(kernal_sram_addr[2]),
.A3(kernal_sram_addr[3]),.A4(kernal_sram_addr[4]),.A5(kernal_sram_addr[5]),
.A6(kernal_sram_addr[6]),.DO0(k_out_data[4][0]),.DO1(k_out_data[4][1]),.DO2(k_out_data[4][2]),
                  .DO3(k_out_data[4][3]),.DO4(k_out_data[4][4]),.DO5(k_out_data[4][5]),.DO6(k_out_data[4][6]),
                  .DO7(k_out_data[4][7]),.DI0(matrix[0]),.DI1(matrix[1]),.DI2(matrix[2]),
                  .DI3(matrix[3]),.DI4(matrix[4]),.DI5(matrix[5]),
                  .DI6(matrix[6]),.DI7(matrix[7]),.CK(clk),.WEB(k_wen[4]),.OE(1'b1),.CS(1'b1));



endmodule