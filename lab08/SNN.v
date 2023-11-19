//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Siamese Neural Network
//   Author     		: Hsien-Chi Peng (jhpeng2012@gmail.com)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SNN.v
//   Module Name : SNN
//   Release version : V1.0 (Release Date: 2023-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

// synopsys translate_off
`ifdef RTL
	`include "GATED_OR.v"
`else
	`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on


module SNN(
    //Input Port
    clk,
    rst_n,
    cg_en,
    in_valid,
    Img,
    Kernel,
	Weight,
    Opt,

    //Output Port
    out_valid,
    out
    );

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
localparam FP_ONE  = 32'h3f800000;

// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;

input rst_n, clk, in_valid;
input [inst_sig_width+inst_exp_width:0] Img, Kernel, Weight;
input [1:0] Opt;
input cg_en;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

parameter DATA_WIDTH = inst_sig_width + inst_exp_width + 1;

parameter en_ubr_flag  = 0;
parameter faithful_round = 0;

//---------------------------------------------------------------------
//      STATES
//---------------------------------------------------------------------
reg[2:0] p_cur_st, p_next_st;
reg[6:0] mm_cur_st,mm_next_st;

localparam  P_IDLE          = 3'b001;
localparam  P_RD_DATA       = 3'b010;
localparam  P_PROCESSING    = 3'b100;

localparam  MM_IDLE             =7'b000_0001;
localparam  MM_MAX_POOLING      =7'b000_0010;
localparam  MM_FC               =7'b000_0100;
localparam  MM_NORM_ACT         =7'b000_1000;
localparam  MM_WAIT_IMG1        =7'b001_0000;
localparam  MM_L1_DISTANCE      =7'b010_0000;
localparam  MM_DONE             =7'b100_0000;

wire ST_P_IDLE          = p_cur_st[0];
wire ST_P_RD_DATA       = p_cur_st[1];
wire ST_P_PROCESSING    = p_cur_st[2];

wire ST_MM_IDLE   = mm_cur_st[0];
wire ST_MM_MAX_POOLING   = mm_cur_st[1];
wire ST_MM_FC   = mm_cur_st[2];
wire ST_MM_NORM_ACT   = mm_cur_st[3];
wire ST_MM_WAIT_IMG1   = mm_cur_st[4];
wire ST_MM_L1_DISTANCE   = mm_cur_st[5];
wire ST_MM_DONE   = mm_cur_st[6];

reg[6:0] rd_cnt;
reg[2:0] mm_cnt,pixel_cnt;
reg  processing_f_ff;
reg  valid_d1,valid_d2,valid_d3,valid_d4;

reg img_num_cnt,img_num_cnt_d1,img_num_cnt_d2,img_num_cnt_d3,img_num_cnt_d4;
reg[DATA_WIDTH-1:0] x_min_ff,x_max_ff;

reg[1:0] kernal_num_cnt,kernal_num_cnt_d1,kernal_num_cnt_d2,kernal_num_cnt_d3,kernal_num_cnt_d4;

reg[1:0] process_xptr, process_yptr,process_xptr_d1, process_yptr_d1,process_xptr_d2,process_yptr_d2,process_xptr_d3,
process_yptr_d3,process_xptr_d4,process_yptr_d4;

reg[3:0] wr_img_xptr,wr_img_yptr;
reg mm_img_cnt;
reg[2:0] mm_cnt_d1,mm_cnt_d2,mm_cnt_d3,mm_cnt_d4;
reg norm_valid_d1;
reg[DATA_WIDTH-1:0] exp_pos_result_d3, exp_neg_result_d3, fp_sub2_act_d4,
fp_add3_act_d4;
reg[DATA_WIDTH-1:0] fp_mult_fc_d1[0:1];

reg[DATA_WIDTH-1:0] abs_in;
reg[DATA_WIDTH-1:0] abs_out_0_d1,abs_out_1_d1,abs_out_2_d1,abs_out_3_d1;

reg[DATA_WIDTH-1:0] negation_in;
reg[DATA_WIDTH-1:0] pos_exp_in;

wire[DATA_WIDTH-1:0] fp_mult_FC_out[0:1];
wire[DATA_WIDTH-1:0] fp_add0_out;


reg[DATA_WIDTH-1:0] fp_add0_in_a;
reg[DATA_WIDTH-1:0] fp_add0_in_b;

reg[DATA_WIDTH-1:0] fp_mult_fc_in_a[0:1];
reg[DATA_WIDTH-1:0] fp_mult_fc_in_b[0:1];

reg[DATA_WIDTH-1:0] fp_mult1_in_b;
reg[DATA_WIDTH-1:0] fp_mult1_in_a;
wire[DATA_WIDTH-1:0] fp_div0_out;

reg[DATA_WIDTH-1:0] fp_sub0_in_a;
reg[DATA_WIDTH-1:0] fp_sub0_in_b;
wire[DATA_WIDTH-1:0] fp_sub0_out;
reg[DATA_WIDTH-1:0] fp_norm_sub0_out_d1;

reg[DATA_WIDTH-1:0] fp_sub1_in_a;
reg[DATA_WIDTH-1:0] fp_sub1_in_b;
wire[DATA_WIDTH-1:0] fp_sub1_out;

reg[DATA_WIDTH-1:0] max_pooling_result_rf[0:1][0:1];
reg[DATA_WIDTH-1:0] fc_result_rf[0:3];
reg[DATA_WIDTH-1:0] norm_result_rf[0:3];
reg[DATA_WIDTH-1:0] activation_result_rf[0:3][0:1];
reg[DATA_WIDTH-1:0] l1_distance_ff;

wire[DATA_WIDTH-1:0] negation = {~negation_in[31],negation_in[30:0]};
wire[DATA_WIDTH-1:0] exp_neg_result;
wire[DATA_WIDTH-1:0] exp_pos_result;
reg[DATA_WIDTH-1:0]  activation_var_d2;

reg[DATA_WIDTH-1:0] fp_div1_in_a;
reg[DATA_WIDTH-1:0] fp_div1_in_b;
wire[DATA_WIDTH-1:0] fp_div1_out;

wire fp_cmp_results[0:1][0:1];

reg[DATA_WIDTH-1:0] min_max_diff_reci_ff;
reg[DATA_WIDTH-1:0] kernal_rf[0:2][0:2][0:2];
reg[DATA_WIDTH-1:0] img_rf[0:5][0:5];
reg[DATA_WIDTH-1:0] weight_rf[0:1][0:1];
wire start_processing_f = rd_cnt == 8;

reg[1:0]  wr_kernal_num_cnt,wr_img_channel_cnt;
reg       wr_img_num_cnt;
reg[1:0] opt_ff;
reg[1:0] wr_kernal_yptr,wr_kernal_xptr;
reg l1_valid_d1;

reg norm_act_d1,norm_act_d2,norm_act_d3,norm_act_d4;


localparam IMG_SIZE = 4;

integer i,j,k,c;

// One for img1, another for img2
reg[DATA_WIDTH-1:0] convolution_result_rf[0:3][0:3][0:1];

genvar idx,jdx;
//---------------------------------------------------------------------
//      Shared 4 SUM MAC
//---------------------------------------------------------------------
reg[DATA_WIDTH-1:0] pixels[0:8];
reg[DATA_WIDTH-1:0] kernals[0:8];
wire[DATA_WIDTH-1:0] mults_result[0:8];
wire[DATA_WIDTH-1:0] partial_sum[0:2];
wire[DATA_WIDTH-1:0] mac_result;
reg[DATA_WIDTH-1:0]  mults_result_pipe_d1[0:8];
reg[DATA_WIDTH-1:0] partial_sum_pipe_d2[0:2];
reg[3:0] eq_next_st;


//---------------------------------------------------------------------
//      flags
//---------------------------------------------------------------------
wire rd_data_done_f = rd_cnt == 95;
wire all_convolution_done_f = img_num_cnt_d3 == 1 && kernal_num_cnt_d3 == 2 && process_xptr_d3 == 3 && process_yptr_d3 == 3;
wire channel_processed_f = process_xptr == 3 && process_yptr == 3;
wire convolution_done_f     = kernal_num_cnt == 2 && channel_processed_f;
wire max_pooling_done_f     = mm_cnt == 2 && ST_MM_MAX_POOLING;
wire fc_done_f              = mm_cnt_d1 == 3 && ST_MM_FC;
wire activation_done_f      = mm_cnt_d4 == 3 && ST_MM_NORM_ACT;
wire l1_distance_cal_f      = l1_valid_d1 && ST_MM_L1_DISTANCE;
reg  convolution_done_f_d1,convolution_done_f_d2,convolution_done_f_d3,convolution_done_f_d4;

reg[DATA_WIDTH-1:0]  fp_addsub0_in_a,fp_addsub0_in_b,fp_addsub1_in_a,fp_addsub1_in_b;
reg[DATA_WIDTH-1:0]  fp_addsub2_in_a,fp_addsub2_in_b,fp_addsub3_in_a,fp_addsub3_in_b;
wire[DATA_WIDTH-1:0] fp_addsub0_out,fp_addsub1_out;
wire[DATA_WIDTH-1:0] fp_addsub2_out,fp_addsub3_out;
reg fp_addsub0_mode, fp_addsub1_mode;
reg fp_addsub2_mode, fp_addsub3_mode;

reg[DATA_WIDTH-1:0]  fp_add_tree_in_a[0:2];
reg[DATA_WIDTH-1:0]  fp_add_tree_in_b[0:2];
wire[DATA_WIDTH-1:0] fp_add_tree_out[0:2];
reg[DATA_WIDTH-1:0]  fp_add_tree_d3[0:1];


wire wr_boundary_reach_f = wr_img_yptr == 3 && ST_P_RD_DATA;
wire wr_channel_done_f   = wr_img_yptr == 3 && wr_img_xptr == 3 && ST_P_RD_DATA;
wire wr_img_done_f       = wr_channel_done_f && wr_img_channel_cnt == 2 && ST_P_RD_DATA;
wire wr_all_img_done_f   = wr_img_done_f && wr_img_num_cnt == 1 && ST_P_RD_DATA;

wire wr_kernal_bound_reach_f  = wr_kernal_yptr == 2  && ST_P_RD_DATA;
wire wr_kernal_done_f         = wr_kernal_yptr == 2 && wr_kernal_xptr == 2 && ST_P_RD_DATA;
wire wr_all_kernal_done_f     = wr_kernal_done_f && wr_kernal_num_cnt == 2 && ST_P_RD_DATA;

wire process_bound_reach_f = process_yptr == 3;

// Additional logic, early start of reading logic
reg l1_done_sig_f;
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
        l1_done_sig_f <= 0;
    else if(ST_MM_DONE)
        l1_done_sig_f <= 1;
    else if(ST_P_RD_DATA)
        l1_done_sig_f <= 0;
end

reg[3:0] eq_cur_st;
localparam  EQ_IDLE      = 4'b0001;
localparam  EQ_IMG_1     = 4'b0010;
localparam  EQ_WAIT_IMG_2= 4'b0100;
localparam  EQ_IMG2      = 4'b1000;
wire st_EQ_IDLE         = eq_cur_st[0];
wire st_EQ_IMG_1        = eq_cur_st[1];
wire st_EQ_WAIT_IMG_2   = eq_cur_st[2];
wire st_EQ_IMG2         = eq_cur_st[3];

//================================================================
//	GATED CLK
//================================================================
wire clk_conv,clk_eq,clk_fc,clk_norm_act,clk_l1_distance;

wire sleep_rd_data  = ~(p_next_st == P_RD_DATA || ST_P_IDLE || ST_P_RD_DATA);
wire sleep_conv     = ~processing_f_ff;
wire sleep_eq       = ~(st_EQ_IMG2 || st_EQ_IMG_1);

wire sleep_mp       = ~(ST_MM_MAX_POOLING || mm_next_st == MM_MAX_POOLING);
wire sleep_fc       = ~(ST_MM_FC);
wire sleep_norm_act = ~ST_MM_NORM_ACT;
wire sleep_l1       = ~ST_MM_L1_DISTANCE;

// GATED_OR GATED_RD_DATA( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_rd_data), .RST_N(rst_n), .CLOCK_GATED(clk_read_data));
// GATED_OR GATED_CONV( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_conv), .RST_N(rst_n), .CLOCK_GATED(clk_conv));
// GATED_OR GATED_EQ( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_eq), .RST_N(rst_n), .CLOCK_GATED(clk_eq));
GATED_OR GATED_MP( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_mp), .RST_N(rst_n), .CLOCK_GATED(clk_mp));
GATED_OR GATED_FC( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_fc), .RST_N(rst_n), .CLOCK_GATED(clk_fc));
GATED_OR GATED_NORM_ACT( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_norm_act), .RST_N(rst_n), .CLOCK_GATED(clk_norm_act));
GATED_OR GATED_L1( .CLOCK(clk), .SLEEP_CTRL(cg_en&&sleep_l1), .RST_N(rst_n), .CLOCK_GATED(clk_l1_distance));

//---------------------------------------------------------------------
//      RD DATA Domain
//---------------------------------------------------------------------
always @(posedge clk)
begin
    if(ST_P_IDLE && p_next_st == P_RD_DATA)
    begin
        if(Opt == 0 || Opt == 2)
        begin
            img_rf[0][0] <= Img;
            img_rf[0][1] <= Img;
            img_rf[1][0] <= Img;
            img_rf[1][1] <= Img;
        end
        else
        begin
            img_rf[1][1] <= Img;
        end
        kernal_rf[0][0][0] <= Kernel;
        weight_rf[0][0]    <= Weight;
    end
    else if(ST_P_IDLE)
    begin
        for(i=0;i<3;i=i+1)
            for(j=0;j<3;j=j+1)
                for(k=0;k<3;k=k+1)
                    kernal_rf[i][j][k] <= 0;

        for(i=0;i<6;i=i+1)
            for(j=0;j<6;j=j+1)
                img_rf[i][j] <= 0;
    end
    else if(ST_P_RD_DATA)
    begin
        case(rd_cnt)
        'd0: weight_rf[0][0] <= Weight;
        'd1: weight_rf[0][1] <= Weight;
        'd2: weight_rf[1][0] <= Weight;
        'd3: weight_rf[1][1] <= Weight;
        endcase

        // write kernals
        if(rd_cnt <= 26)
            kernal_rf[wr_kernal_xptr][wr_kernal_yptr][wr_kernal_num_cnt] <= Kernel;

        // Replication
        if(opt_ff == 0 || opt_ff == 2)
        begin
            if(wr_img_xptr == 0 && wr_img_yptr == 0)
            begin
                // (x,y,channel,img)
                img_rf[0][0] <= Img;
                img_rf[0][1] <= Img;
                img_rf[1][0] <= Img;
                img_rf[1][1] <= Img;
            end
            else if(wr_img_xptr == 0 && wr_img_yptr == IMG_SIZE-1)
            begin
                // (x,y,channel,img)
                img_rf[1][4] <= Img;
                img_rf[1][5] <= Img;
                img_rf[0][4] <= Img;
                img_rf[0][5] <= Img;
            end
            else if(wr_img_xptr == IMG_SIZE-1 && wr_img_yptr == 0)
            begin
                // (x,y,channel,img)
                img_rf[4][1] <= Img;
                img_rf[4][0] <= Img;
                img_rf[5][0] <= Img;
                img_rf[5][1] <= Img;
            end
            else if(wr_img_xptr == IMG_SIZE -1 && wr_img_yptr == IMG_SIZE-1)
            begin
                // (x,y,channel,img)
                img_rf[4][4] <= Img;
                img_rf[4][5] <= Img;
                img_rf[5][4] <= Img;
                img_rf[5][5] <= Img;
            end
            else if(wr_img_xptr == 0)
            begin
                img_rf[0][wr_img_yptr+1] <= Img;
                img_rf[1][wr_img_yptr+1] <= Img;
            end
            else if(wr_img_yptr == 0)
            begin
                img_rf[wr_img_xptr+1][0] <= Img;
                img_rf[wr_img_xptr+1][1] <= Img;
            end
            else if(wr_img_xptr == IMG_SIZE -1)
            begin
                img_rf[4][wr_img_yptr+1] <= Img;
                img_rf[5][wr_img_yptr+1] <= Img;
            end
            else if(wr_img_yptr == IMG_SIZE-1)
            begin
                img_rf[wr_img_xptr+1][4] <= Img;
                img_rf[wr_img_xptr+1][5] <= Img;
            end
            else
            begin
                img_rf[wr_img_xptr+1][wr_img_yptr+1] <= Img;
            end
        end
        else
        begin
            img_rf[wr_img_xptr+1][wr_img_yptr+1] <= Img;
        end
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
        opt_ff <= 0;
    else if(ST_P_IDLE)
        opt_ff <= in_valid ? Opt:opt_ff;
end

// Consider add clk to this control later
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        // Since padding, start from (1,1)
        wr_img_xptr <= 0;
        wr_img_yptr <= 0;
        wr_img_num_cnt <= 0;
        wr_img_channel_cnt <= 0;

        // Kernals
        wr_kernal_num_cnt <= 0;
        wr_kernal_yptr <= 0;
        wr_kernal_xptr <= 0;
        rd_cnt  <= 0;
    end
    else if(ST_P_IDLE && p_next_st == P_RD_DATA)
    begin
        wr_img_yptr <= wr_img_yptr + 1;
        wr_kernal_yptr <= wr_kernal_yptr + 1;
        rd_cnt <= rd_cnt + 1;
    end
    else if(ST_P_IDLE)
    begin
        // Since padding, start from (1,1)
        wr_img_xptr <= 0;
        wr_img_yptr <= 0;
        wr_img_num_cnt <= 0;
        wr_img_channel_cnt <= 0;

        // Kernals
        wr_kernal_num_cnt <= 0;
        wr_kernal_yptr <= 0;
        wr_kernal_xptr <= 0;
    end
    else if(ST_P_RD_DATA)
    begin
        rd_cnt <= wr_all_img_done_f ? 0 : rd_cnt + 1;

        // wr_ptrs
        if(wr_all_img_done_f)
        begin
            wr_img_xptr     <= 0;
            wr_img_yptr     <= 0;
            wr_img_num_cnt  <= 0;
            wr_img_channel_cnt <= 0;
        end
        else if(wr_img_done_f)
        begin
            wr_img_xptr <= 0;
            wr_img_yptr <= 0;
            wr_img_num_cnt <= wr_img_num_cnt + 1;
            wr_img_channel_cnt <= 0;
        end
        else if(wr_channel_done_f)
        begin
            wr_img_xptr <= 0;
            wr_img_yptr <= 0;
            wr_img_channel_cnt <= wr_img_channel_cnt + 1;
        end
        else if(wr_boundary_reach_f)
        begin
            wr_img_xptr <= wr_img_xptr + 1;
            wr_img_yptr <= 0;
        end
        else
        begin
            wr_img_yptr <= wr_img_yptr + 1;
        end

        //wr kernals
        if(wr_all_img_done_f)
        begin
            wr_kernal_xptr <= 0;
            wr_kernal_yptr <= 0;
            wr_kernal_num_cnt <= 0;
        end
        else if(wr_all_kernal_done_f)
        begin
            wr_kernal_xptr <= 0;
            wr_kernal_yptr <= 0;
            wr_kernal_num_cnt <= 2;
        end
        else if(wr_kernal_done_f)
        begin
            wr_kernal_xptr <= 0;
            wr_kernal_yptr <= 0;
            wr_kernal_num_cnt <= wr_kernal_num_cnt + 1;
        end
        else if(wr_kernal_bound_reach_f)
        begin
            wr_kernal_xptr <= wr_kernal_xptr + 1;
            wr_kernal_yptr <= 0;
        end
        else
        begin
            wr_kernal_yptr <= wr_kernal_yptr + 1;
        end
    end
end

//---------------------------------------------------------------------
//      Convolution
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
        processing_f_ff <= 0;
    else if(start_processing_f)
        processing_f_ff <= 1;
    else if(all_convolution_done_f)
        processing_f_ff <= 0;
end

wire[4:0] row_00 = process_xptr;
wire[4:0] row_01 = process_xptr;
wire[4:0] row_02 = process_xptr;
wire[4:0] row_10 = process_xptr + 1;
wire[4:0] row_11 = process_xptr + 1;
wire[4:0] row_12 = process_xptr + 1;
wire[4:0] row_20 = process_xptr + 2;
wire[4:0] row_21 = process_xptr + 2;
wire[4:0] row_22 = process_xptr + 2;

wire[4:0] col_00 = process_yptr;
wire[4:0] col_01 = process_yptr+1;
wire[4:0] col_02 = process_yptr+2;
wire[4:0] col_10 = process_yptr;
wire[4:0] col_11 = process_yptr + 1;
wire[4:0] col_12 = process_yptr + 2;
wire[4:0] col_20 = process_yptr;
wire[4:0] col_21 = process_yptr + 1;
wire[4:0] col_22 = process_yptr + 2;

always @(*) begin
    if(cg_en && sleep_conv)
    begin
        pixels[0]  = 0;
        pixels[1]  = 0;
        pixels[2]  = 0;
        pixels[3]  = 0;
        pixels[4]  = 0;
        pixels[5]  = 0;
        pixels[6]  = 0;
        pixels[7]  = 0;
        pixels[8]  = 0;

        kernals[0] = 0;
        kernals[1] = 0;
        kernals[2] = 0;
        kernals[3] = 0;
        kernals[4] = 0;
        kernals[5] = 0;
        kernals[6] = 0;
        kernals[7] = 0;
        kernals[8] = 0;
    end
    else
    begin
        pixels[0] = img_rf[row_00][col_00];
        pixels[1] = img_rf[row_01][col_01];
        pixels[2] = img_rf[row_02][col_02];
        pixels[3] = img_rf[row_10][col_10];
        pixels[4] = img_rf[row_11][col_11];
        pixels[5] = img_rf[row_12][col_12];
        pixels[6] = img_rf[row_20][col_20];
        pixels[7] = img_rf[row_21][col_21];
        pixels[8] = img_rf[row_22][col_22];

        kernals[0] = kernal_rf[0][0][kernal_num_cnt];
        kernals[1] = kernal_rf[0][1][kernal_num_cnt];
        kernals[2] = kernal_rf[0][2][kernal_num_cnt];
        kernals[3] = kernal_rf[1][0][kernal_num_cnt];
        kernals[4] = kernal_rf[1][1][kernal_num_cnt];
        kernals[5] = kernal_rf[1][2][kernal_num_cnt];
        kernals[6] = kernal_rf[2][0][kernal_num_cnt];
        kernals[7] = kernal_rf[2][1][kernal_num_cnt];
        kernals[8] = kernal_rf[2][2][kernal_num_cnt];
    end
end

generate
    for(idx = 0; idx < 9 ; idx = idx+1)
    begin:PARRALLEL_MULTS
        DW_fp_mult_DG_inst #(inst_sig_width,inst_exp_width,inst_ieee_compliance)
                        u_DW_fp_mult_inst(
                            .inst_a   ( pixels[idx]         ),
                            .inst_b   ( kernals[idx]        ),
                            .inst_rnd ( 3'b000              ),
                            .inst_DG_ctrl(cg_en ? processing_f_ff : 1'b1),
                            .z_inst   ( mults_result[idx]   ),
                            .status_inst  (   )
                        );
    end
endgenerate

always @(posedge clk)
begin
    if(cg_en == 1'b1)
    begin
        if(processing_f_ff)
            for(i=0;i<9;i=i+1)
                mults_result_pipe_d1[i] <= mults_result[i];
    end
    else
    begin
        for(i=0;i<9;i=i+1)
            mults_result_pipe_d1[i] <= mults_result[i];
    end
end

// 3x 3 inputs fp adders
DW_fp_sum3_DG_inst #(inst_sig_width,inst_exp_width,inst_ieee_compliance,inst_arch_type)
                u_DW_fp_sum3_inst1(
                    .inst_a   ( mults_result_pipe_d1[0]),
                    .inst_b   ( mults_result_pipe_d1[1]),
                    .inst_c   ( mults_result_pipe_d1[2]   ),
                    .inst_DG_ctrl(~sleep_conv),
                    .inst_rnd ( 3'b000 ),
                    .z_inst   ( partial_sum[0]   ),
                    .status_inst  (   )
                );

DW_fp_sum3_DG_inst #(inst_sig_width,inst_exp_width,inst_ieee_compliance,inst_arch_type)
                u_DW_fp_sum3_inst2(
                    .inst_a   ( mults_result_pipe_d1[3]),
                    .inst_b   ( mults_result_pipe_d1[4]),
                    .inst_c   ( mults_result_pipe_d1[5]   ),
                    .inst_DG_ctrl(~sleep_conv),
                    .inst_rnd ( 3'b000 ),
                    .z_inst   ( partial_sum[1]),
                    .status_inst  (   )
                );

DW_fp_sum3_DG_inst #(inst_sig_width,inst_exp_width,inst_ieee_compliance,inst_arch_type)
                u_DW_fp_sum3_inst3(
                    .inst_a   ( mults_result_pipe_d1[6]),
                    .inst_b   ( mults_result_pipe_d1[7]),
                    .inst_c   ( mults_result_pipe_d1[8]   ),
                    .inst_DG_ctrl(~sleep_conv),
                    .inst_rnd ( 3'b000 ),
                    .z_inst   ( partial_sum[2]),
                    .status_inst  (   )
                );

always @(posedge clk)
begin
    if(cg_en)
    begin
        if(valid_d1)
            for(i=0;i<3;i=i+1)
                partial_sum_pipe_d2[i]<=partial_sum[i];
    end
    else
    begin
        for(i=0;i<3;i=i+1)
            partial_sum_pipe_d2[i]<=partial_sum[i];
    end
end


//---------------------------------------------------------------------
//      Convolution CTRs
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

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        img_num_cnt_d1 <= 0;
        img_num_cnt_d2 <= 0;
        img_num_cnt_d3 <= 0;

        kernal_num_cnt_d1 <= 0;
        kernal_num_cnt_d2 <= 0;
        kernal_num_cnt_d3 <= 0;

        process_xptr_d1 <= 0;
        process_yptr_d1 <= 0;

        process_xptr_d2 <= 0;
        process_yptr_d2 <= 0;

        process_xptr_d3 <= 0;
        process_yptr_d3 <= 0;

        valid_d1 <= 0;
        valid_d2 <= 0;
        valid_d3 <= 0;

        convolution_done_f_d1 <= 0;
        convolution_done_f_d2 <= 0;
        convolution_done_f_d3 <= 0;
    end
    else if(all_convolution_done_f)
    begin
        img_num_cnt_d1 <= 0;
        img_num_cnt_d2 <= 0;
        img_num_cnt_d3 <= 0;

        kernal_num_cnt_d1 <= 0;
        kernal_num_cnt_d2 <= 0;
        kernal_num_cnt_d3 <= 0;

        process_xptr_d1 <= 0;
        process_xptr_d2 <= 0;
        process_xptr_d3 <= 0;

        process_yptr_d1 <= 0;
        process_yptr_d2 <= 0;
        process_yptr_d3 <= 0;

        valid_d1 <= 0;
        valid_d2 <= 0;
        valid_d3 <= 0;

        convolution_done_f_d1 <= 0;
        convolution_done_f_d2 <= 0;
        convolution_done_f_d3 <= 0;
    end
    else
    begin
        img_num_cnt_d1 <= img_num_cnt;
        img_num_cnt_d2 <= img_num_cnt_d1;
        img_num_cnt_d3 <= img_num_cnt_d2;

        kernal_num_cnt_d1 <= kernal_num_cnt;
        kernal_num_cnt_d2 <= kernal_num_cnt_d1;
        kernal_num_cnt_d3 <= kernal_num_cnt_d2;

        process_xptr_d1 <= process_xptr;
        process_xptr_d2 <= process_xptr_d1;
        process_xptr_d3 <= process_xptr_d2;

        process_yptr_d1 <= process_yptr;
        process_yptr_d2 <= process_yptr_d1;
        process_yptr_d3 <= process_yptr_d2;

        valid_d1 <= processing_f_ff;
        valid_d2 <= valid_d1;
        valid_d3 <= valid_d2;

        convolution_done_f_d1 <= convolution_done_f;
        convolution_done_f_d2 <= convolution_done_f_d1;
        convolution_done_f_d3 <= convolution_done_f_d2;
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
        if(rd_data_done_f) p_next_st = P_PROCESSING;
    end
    P_PROCESSING:
    begin
        if(all_convolution_done_f) p_next_st = P_IDLE;
    end
    endcase
end

//---------------------------------------------------------------------
//   pipelined 3 Adders
//---------------------------------------------------------------------
always @(posedge clk)
begin
    if(cg_en)
    begin
        if(valid_d2)
        begin
            fp_add_tree_d3[0] <= fp_add_tree_out[0];
            fp_add_tree_d3[1] <= fp_add_tree_out[1];
        end
    end
    else
    begin
        fp_add_tree_d3[0] <= fp_add_tree_out[0];
        fp_add_tree_d3[1] <= fp_add_tree_out[1];
    end
end

DW_fp_add_DG #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
          adder_tree0 (.DG_ctrl(cg_en?valid_d2||l1_valid_d1:1'b1), .a(fp_add_tree_in_a[0]), .b(fp_add_tree_in_b[0]), .rnd(3'b000), .z(fp_add_tree_out[0]), .status() );

DW_fp_add_DG #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
          adder_tree1 (.DG_ctrl(cg_en?valid_d2||l1_valid_d1:1'b1), .a(fp_add_tree_in_a[1]), .b(fp_add_tree_in_b[1]), .rnd(3'b000), .z(fp_add_tree_out[1]), .status() );

DW_fp_add_DG #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
          adder_tree2 (.DG_ctrl(cg_en?valid_d3||l1_valid_d1:1'b1), .a(fp_add_tree_in_a[2]), .b(fp_add_tree_in_b[2]), .rnd(3'b000), .z(fp_add_tree_out[2]), .status() );

//---------------------------------------------------------------------
//      CONTROLLERS
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        process_xptr <= 0;
        process_yptr <= 0;
        kernal_num_cnt <= 0;
        img_num_cnt <= 0;
    end
    else if(ST_P_IDLE && (p_cur_st != p_next_st))
    begin
        process_xptr <= 0;
        process_yptr <= 0;
        kernal_num_cnt <= 0;
        img_num_cnt <= 0;
    end
    else if(sleep_conv && cg_en)
    begin
        process_xptr   <= process_xptr;
        process_yptr   <= process_yptr;
        kernal_num_cnt <= kernal_num_cnt;
        img_num_cnt    <= img_num_cnt;
    end
    else if(ST_P_IDLE)
    begin
        process_xptr <= ~process_xptr;
        process_yptr <= ~process_yptr;
        kernal_num_cnt <= ~kernal_num_cnt;
        img_num_cnt <= ~img_num_cnt;
    end
    else if((ST_P_RD_DATA || ST_P_PROCESSING) && processing_f_ff)
    begin
        if(all_convolution_done_f)
        begin
            process_xptr <= 0;
            process_yptr <= 0;
            kernal_num_cnt <= 0;
            img_num_cnt <= 0;
        end
        else if(process_xptr == 3 && process_yptr == 3 && img_num_cnt == 1 && kernal_num_cnt == 2)
        begin
            process_xptr   <= process_xptr;
            process_yptr   <= process_yptr;
            kernal_num_cnt <= kernal_num_cnt;
            img_num_cnt    <= img_num_cnt;
        end
        else if(convolution_done_f)
        begin
            process_xptr <= 0;
            process_yptr <= 0;
            kernal_num_cnt <= 0;
            img_num_cnt <= img_num_cnt+1;
        end
        else if(channel_processed_f)
        begin
            process_xptr <= 0;
            process_yptr <= 0;
            kernal_num_cnt <= kernal_num_cnt + 1;
        end
        else if(process_bound_reach_f)
        begin
            process_xptr <= process_xptr + 1;
            process_yptr <= 0;
        end
        else
        begin
            process_yptr <= process_yptr + 1;
        end
    end
end

//---------------------------------------------------------------------
//      CONVOLUTION RESULTS
//---------------------------------------------------------------------
always @(posedge clk)
begin
    if(valid_d3)
    begin
       convolution_result_rf[process_xptr_d3][process_yptr_d3][img_num_cnt_d3] <= fp_add_tree_out[2];
    end
end

//---------------------------------------------------------------------
//      Equalization DOMAIN
//---------------------------------------------------------------------
//-----------------------
//      EQ CTR
//-----------------------
// Controls
reg[4:0] eq_xptr,eq_yptr;
reg[4:0] eq_xptr_d1,eq_yptr_d1,eq_xptr_d2,eq_yptr_d2;
reg[1:0] eq_cnt,eq_cnt_d1,eq_cnt_d2;

//Delays
reg all_eq_done_f_d1,all_eq_done_f_d2;
reg one_eq_done_d1,one_eq_done_d2;
reg eq_done_f,eq_done_f_d1,eq_done_f_d2;
reg eq_valid,eq_valid_d1,eq_valid_d2;

// Flags
wire one_equalized_done_f    = eq_xptr == 3 && eq_yptr == 3;
wire eq_right_bound_reach_f  = eq_yptr == 3;
wire eq_bottom_bound_reach_f = eq_xptr == 3;
wire all_eq_done_f = one_eq_done_d2 && eq_cnt_d2 == 1 && eq_valid_d2;

wire eq_early_start_f = kernal_num_cnt_d3 == 2 && process_xptr_d3 == 1
&& process_yptr_d3 == 1;


// Datapath components
reg[DATA_WIDTH-1:0] equalized_result_rf[0:3][0:3][0:1];
reg[DATA_WIDTH-1:0] adder_tree_in[0:8];
reg[DATA_WIDTH-1:0] adder_tree_pipe_d1[0:2];
reg[DATA_WIDTH-1:0] adder_tree_pipe_d2;
wire[DATA_WIDTH-1:0] eq_fp_add_out[0:7];
reg[DATA_WIDTH-1:0]  eq_fp_pipe_d1[0:2];
reg[DATA_WIDTH-1:0]  eq_fp_pipe_d2;

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        eq_xptr_d1  <= 0;
        eq_yptr_d1  <= 0;
        eq_xptr_d2  <= 0;
        eq_yptr_d2  <= 0;
        eq_valid_d1 <= 0;
        eq_valid_d2 <= 0;
        eq_cnt_d1   <= 0;
        eq_cnt_d2   <= 0;
        eq_done_f_d1 <= 0;
        eq_done_f_d2 <= 0;
        one_eq_done_d1 <= 0;
        one_eq_done_d2 <= 0;
        all_eq_done_f_d1 <= 0;
        all_eq_done_f_d2 <=0;
    end
    else if(eq_done_f_d2 || all_eq_done_f_d2)
    begin
        eq_xptr_d1  <= 0;
        eq_yptr_d1  <= 0;
        eq_valid_d1 <= 0;
        eq_valid_d2 <= 0;

        eq_xptr_d2  <= 0;
        eq_yptr_d2  <= 0;

        eq_cnt_d1   <= 0;
        eq_cnt_d2   <= 0;
        eq_done_f_d1 <= 0;
        eq_done_f_d2 <= 0;
        one_eq_done_d1 <= 0;
        one_eq_done_d2 <= 0;
        if(all_eq_done_f_d2)
        begin
            all_eq_done_f_d1 <= 0;
            all_eq_done_f_d2 <= 0;
        end
    end
    else
    begin
        eq_xptr_d1  <= eq_xptr;
        eq_yptr_d1  <= eq_yptr;
        eq_valid_d1 <= eq_valid;

        eq_valid_d2 <= eq_valid_d1;
        eq_xptr_d2  <= eq_xptr_d1;
        eq_yptr_d2  <= eq_yptr_d1;
        eq_cnt_d1   <= eq_cnt;
        eq_cnt_d2   <= eq_cnt_d1;
        one_eq_done_d1 <= one_equalized_done_f;
        one_eq_done_d2 <= one_eq_done_d1;
        eq_done_f_d1 <= eq_done_f;
        eq_done_f_d2 <= eq_done_f_d1;
        all_eq_done_f_d1 <= all_eq_done_f;
        all_eq_done_f_d2 <= all_eq_done_f_d1;
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
        eq_cur_st <= EQ_IDLE;
    else
        eq_cur_st <= eq_next_st;
end

always @(*)
begin
    eq_next_st = eq_cur_st;
    if(st_EQ_IMG_1)
    begin
        if(eq_done_f_d2) eq_next_st = EQ_WAIT_IMG_2;
    end
    else if(st_EQ_IMG2)
    begin
        if(all_eq_done_f_d2) eq_next_st = EQ_IDLE;
    end
    else if(st_EQ_IDLE)
    begin
        if(convolution_done_f_d3) eq_next_st = EQ_IMG_1;
    end
    else if(st_EQ_WAIT_IMG_2)
    begin
        if(convolution_done_f_d3) eq_next_st = EQ_IMG2;
    end
end

//-----------------------
//      EQ SUB CTRs
//-----------------------
always @(*) begin
    eq_valid = st_EQ_IMG_1 || st_EQ_IMG2;
end

// Problemetic block
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        eq_xptr  <= 0; eq_yptr <= 0;
        eq_done_f <= 0; eq_cnt <= 0;
    end
    else if(st_EQ_WAIT_IMG_2 && (eq_next_st!=eq_cur_st))
    begin
        eq_xptr  <= 0; eq_yptr <= 0;
        eq_done_f <= 0; eq_cnt <= 1;
    end
    else if(st_EQ_IDLE && (eq_next_st!=eq_cur_st))
    begin
        eq_xptr  <= 0; eq_yptr <= 0;
        eq_done_f <= 0; eq_cnt <= 0;
    end
    else if((st_EQ_IDLE || st_EQ_WAIT_IMG_2) && cg_en)
    begin
        // Clock gated
        eq_xptr  <= eq_xptr; eq_yptr <= eq_yptr;
        eq_done_f <= 0; eq_cnt <= eq_cnt;
    end
    else if((st_EQ_IDLE || st_EQ_WAIT_IMG_2))
    begin
        // None clock gating
        eq_xptr  <= ~eq_xptr; eq_yptr <= ~eq_yptr;
        eq_done_f <= 0; eq_cnt <= ~eq_cnt;
    end
    else if(st_EQ_IMG_1 || st_EQ_IMG2)
    begin
        // Ptrs
        if(eq_done_f_d2 || all_eq_done_f_d2)
        begin
            eq_xptr   <= 0;
            eq_yptr   <= 0;
            eq_done_f <= 0;
        end
        else if(one_eq_done_d2)
        begin
            eq_xptr   <= 0;
            eq_yptr   <= 0;
            eq_done_f <= 0;
        end
        else if(one_equalized_done_f)
        begin
            eq_xptr   <= eq_xptr;
            eq_yptr   <= eq_yptr;
            eq_done_f <= 1;
        end
        else if(eq_right_bound_reach_f)
        begin
            eq_xptr <= eq_xptr + 1;
            eq_yptr <= 0;
        end
        else
        begin
            eq_yptr <= eq_yptr + 1;
        end
    end
end

//-----------------------------=====================
//      Adder tree input Selector
//-----------------------------=====================
reg[4:0] eq_xptr_offset[0:8];
reg[4:0] eq_yptr_offset[0:8];

always @(*)
begin
    for(i=0;i<9;i=i+1)
    begin
        adder_tree_in[i] = 0;
    end

    eq_xptr_offset[0] = eq_xptr;   eq_yptr_offset[0] = eq_yptr;
    eq_xptr_offset[1] = eq_xptr;   eq_yptr_offset[1] = eq_yptr+1;
    eq_xptr_offset[2] = eq_xptr;   eq_yptr_offset[2] = eq_yptr+2;
    eq_xptr_offset[3] = eq_xptr+1; eq_yptr_offset[3] = eq_yptr;
    eq_xptr_offset[4] = eq_xptr+1; eq_yptr_offset[4] = eq_yptr+1;
    eq_xptr_offset[5] = eq_xptr+1; eq_yptr_offset[5] = eq_yptr+2;
    eq_xptr_offset[6] = eq_xptr+2; eq_yptr_offset[6] = eq_yptr;
    eq_xptr_offset[7] = eq_xptr+2; eq_yptr_offset[7] = eq_yptr+1;
    eq_xptr_offset[8] = eq_xptr+2; eq_yptr_offset[8] = eq_yptr+2;

    if(opt_ff == 2 || opt_ff == 0) // Replication
    begin
        for(i=0;i<9;i=i+1)
        begin
            // Corners
            if(eq_yptr_offset[i] == 0 && eq_xptr_offset[i] == 0)
                adder_tree_in[i] = convolution_result_rf[0][0][eq_cnt];
            else if(eq_yptr_offset[i] == 5 && eq_xptr_offset[i] == 0)
                adder_tree_in[i] = convolution_result_rf[0][3][eq_cnt];
            else if(eq_yptr_offset[i] == 0 && eq_xptr_offset[i] == 5)
                adder_tree_in[i] = convolution_result_rf[3][0][eq_cnt];
            else if(eq_yptr_offset[i] == 5 && eq_xptr_offset[i] == 5)
                adder_tree_in[i] = convolution_result_rf[3][3][eq_cnt];
            //Boundaries
            else if(eq_xptr_offset[i] == 0)
                adder_tree_in[i] = convolution_result_rf[0][eq_yptr_offset[i]-1][eq_cnt];
            else if(eq_xptr_offset[i] == 5)
                adder_tree_in[i] = convolution_result_rf[3][eq_yptr_offset[i]-1][eq_cnt];
            else if(eq_yptr_offset[i] == 0)
                adder_tree_in[i] = convolution_result_rf[eq_xptr_offset[i]-1][0][eq_cnt];
            else if(eq_yptr_offset[i] == 5)
                adder_tree_in[i] = convolution_result_rf[eq_xptr_offset[i]-1][3][eq_cnt];
            else
                // General case
                adder_tree_in[i] = convolution_result_rf[eq_xptr_offset[i]-1][eq_yptr_offset[i]-1][eq_cnt];
        end
    end
    else // Zeropad
    begin
        for(i=0;i<9;i=i+1)
        begin
            if(eq_yptr_offset[i] == 0 || eq_xptr_offset[i] == 0 || eq_yptr_offset[i] == 5 || eq_xptr_offset[i] == 5)
                adder_tree_in[i] = 0;
            else
                adder_tree_in[i] = convolution_result_rf[eq_xptr_offset[i]-1][eq_yptr_offset[i]-1][eq_cnt];
        end
    end
end

//--------------------------------------------
//      EQ Datapath,6 adds d0
//--------------------------------------------
DW_fp_add_DG #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
          fp_add_B0 ( .DG_ctrl(cg_en?eq_valid:1'b1),.a(adder_tree_in[0]), .b(adder_tree_in[1]), .rnd(3'b000), .z(eq_fp_add_out[0]), .status() );
DW_fp_add_DG #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
          fp_add_B1 ( .DG_ctrl(cg_en?eq_valid:1'b1),.a(adder_tree_in[2]), .b(adder_tree_in[3]), .rnd(3'b000), .z(eq_fp_add_out[1]), .status() );
DW_fp_add_DG #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
          fp_add_B2 (.DG_ctrl(cg_en?eq_valid:1'b1), .a(adder_tree_in[4]), .b(adder_tree_in[5]), .rnd(3'b000), .z(eq_fp_add_out[2]), .status() );
DW_fp_add_DG #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
          fp_add_B3 (.DG_ctrl(cg_en?eq_valid:1'b1), .a(adder_tree_in[6]), .b(adder_tree_in[7]), .rnd(3'b000), .z(eq_fp_add_out[3]), .status() );

DW_fp_add_DG #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
          fp_add_B4 (.DG_ctrl(cg_en?eq_valid:1'b1), .a(eq_fp_add_out[1]), .b(eq_fp_add_out[2]), .rnd(3'b000), .z(eq_fp_add_out[4]), .status() );
DW_fp_add_DG #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
          fp_add_B5 (.DG_ctrl(cg_en?eq_valid:1'b1),.a(eq_fp_add_out[3]), .b(adder_tree_in[8]), .rnd(3'b000), .z(eq_fp_add_out[5]), .status() );

always @(posedge clk)
begin
    if(cg_en)
    begin
        if(eq_valid)
        begin
            adder_tree_pipe_d1[0] <= eq_fp_add_out[0];
            adder_tree_pipe_d1[1] <= eq_fp_add_out[4];
            adder_tree_pipe_d1[2] <= eq_fp_add_out[5];
        end
    end
    else
    begin
        adder_tree_pipe_d1[0] <= eq_fp_add_out[0];
        adder_tree_pipe_d1[1] <= eq_fp_add_out[4];
        adder_tree_pipe_d1[2] <= eq_fp_add_out[5];
    end
end

//-------------------------------------------
//      EQ Datapath, 2 adds d1
//-------------------------------------------
DW_fp_add_DG #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
          fp_add_B6 (.DG_ctrl(cg_en ? eq_valid_d1 :1'b1), .a(adder_tree_pipe_d1[0]), .b(adder_tree_pipe_d1[1]), .rnd(3'b000), .z(eq_fp_add_out[6]), .status() );
DW_fp_add_DG #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
          fp_add_B7 (.DG_ctrl(cg_en ? eq_valid_d1 :1'b1), .a(adder_tree_pipe_d1[2]), .b(eq_fp_add_out[6]), .rnd(3'b000), .z(eq_fp_add_out[7]), .status() );

always @(posedge clk)
begin
    if(cg_en)
    begin
        if(eq_valid_d1)
            adder_tree_pipe_d2 <= eq_fp_add_out[7];
    end
    else
    begin
        adder_tree_pipe_d2 <= eq_fp_add_out[7];
    end

end

//-------------------------------------------
//      EQ Datapath, DIV d2
//-------------------------------------------
wire[DATA_WIDTH-1:0] eq_div_out;
localparam NINE_BY_1 = 32'h3de38e39;

// Instance of DW_fp_mult_DG
DW_fp_mult_DG #(.sig_width(inst_sig_width), .exp_width(inst_exp_width), .ieee_compliance(inst_ieee_compliance))
U1 ( .a(adder_tree_pipe_d2), .b(NINE_BY_1), .rnd(3'b000), .DG_ctrl(~sleep_eq), .z(eq_div_out),
.status() );

//----------------------------------------
//      Equalization Result RF
//----------------------------------------
always @(posedge clk)
begin
    if(eq_valid_d2)
    begin
       equalized_result_rf[eq_xptr_d2][eq_yptr_d2][eq_cnt_d2] <= eq_div_out;
    end
end

//---------------------------------------------------------------------
//      MultiCycle Machine domain(MM)
//---------------------------------------------------------------------
//------------------------------------
//      MM CTRs
//------------------------------------
wire mm_early_start_f = eq_xptr_d2 == 3 && eq_yptr_d2 == 1;

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        mm_cur_st <= MM_IDLE;
    end
    else
    begin
        mm_cur_st <= mm_next_st;
    end
end

always @(*)
begin
    // Change to equalization done flag
    mm_next_st = mm_cur_st;
    case(mm_cur_st)
    MM_IDLE:
    begin
        if(eq_done_f_d2) mm_next_st = MM_MAX_POOLING;
    end
    MM_MAX_POOLING:
    begin
        if(max_pooling_done_f) mm_next_st = MM_FC;
    end
    MM_FC:
    begin
        if(fc_done_f) mm_next_st = MM_NORM_ACT;
    end
    MM_NORM_ACT:
    begin
        if(activation_done_f)
        begin
            if(mm_img_cnt == 1)
                mm_next_st = MM_L1_DISTANCE;
            else
                mm_next_st = MM_WAIT_IMG1;
        end
    end
    MM_WAIT_IMG1:
    begin
        if(eq_done_f_d2)  mm_next_st = MM_MAX_POOLING;
    end
    MM_L1_DISTANCE:
    begin
        if(l1_distance_cal_f)   mm_next_st = MM_DONE;
    end
    MM_DONE:
    begin
        mm_next_st = MM_IDLE;
    end
    endcase
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        out_valid <= 0;
        out       <= 0;
        mm_cnt    <= 0;
        mm_img_cnt<= 0;
    end
    else
    begin
        case(mm_cur_st)
        MM_IDLE:
        begin
            out   <= 0;
            out_valid  <= 0;
            mm_cnt <= 0;
            mm_img_cnt <= 0;
        end
        MM_MAX_POOLING:
        begin
            mm_cnt <= max_pooling_done_f ? 0 : mm_cnt + 1;
        end
        MM_FC:
        begin
            mm_cnt <= fc_done_f ? 0 : (mm_cnt == 4 ? mm_cnt : mm_cnt + 1);
        end
        MM_NORM_ACT:
        begin
            mm_cnt <= activation_done_f ? 0 :((mm_cnt == 4) ? mm_cnt : mm_cnt + 1);
        end
        MM_WAIT_IMG1:
        begin
            if(convolution_done_f_d3)
            begin
                mm_img_cnt <= mm_img_cnt + 1;
                mm_cnt <= 0;
            end
        end
        MM_DONE:
        begin
            mm_cnt <= 0;
            mm_img_cnt <= 0;
            out <= l1_distance_ff;
            out_valid <= 1;
        end
        endcase
    end
end

// mm_cnt delay lines
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        mm_cnt_d1 <= 0;
        mm_cnt_d2 <= 0;
        mm_cnt_d3 <= 0;
        mm_cnt_d4 <= 0;
    end
    else if(mm_cur_st != mm_next_st)
    begin
        mm_cnt_d1 <= 0;
        mm_cnt_d2 <= 0;
        mm_cnt_d3 <= 0;
        mm_cnt_d4 <= 0;
    end
    else
    begin
        mm_cnt_d1 <= mm_cnt;
        mm_cnt_d2 <= mm_cnt_d1;
        mm_cnt_d3 <= mm_cnt_d2;
        mm_cnt_d4 <= mm_cnt_d3;
    end
end
//---------------------------------------------------------------------
//      Max Pooling DATAPATH
//---------------------------------------------------------------------
always @(posedge clk_mp)
begin
    if(mm_next_st == MM_MAX_POOLING || ST_MM_MAX_POOLING)
    begin
        case(mm_cnt)
            'd0:
            begin
                if(fp_cmp_results[0][0])
                begin
                    max_pooling_result_rf[0][0] <= equalized_result_rf[0][0][mm_img_cnt];
                end
                else
                begin
                    max_pooling_result_rf[0][0] <= equalized_result_rf[0][1][mm_img_cnt];
                end

                if(fp_cmp_results[0][1])
                begin
                    max_pooling_result_rf[0][1] <= equalized_result_rf[0][2][mm_img_cnt];
                end
                else
                begin
                    max_pooling_result_rf[0][1] <= equalized_result_rf[0][3][mm_img_cnt];
                end

                if(fp_cmp_results[1][0])
                begin
                    max_pooling_result_rf[1][0] <= equalized_result_rf[2][0][mm_img_cnt];
                end
                else
                begin
                    max_pooling_result_rf[1][0] <= equalized_result_rf[2][1][mm_img_cnt];
                end

                if(fp_cmp_results[1][1])
                begin
                    max_pooling_result_rf[1][1] <= equalized_result_rf[2][2][mm_img_cnt];
                end
                else
                begin
                    max_pooling_result_rf[1][1] <= equalized_result_rf[2][3][mm_img_cnt];
                end
            end
            'd1:
            begin
                // Compare conv_result > max_pooling_result
                if(fp_cmp_results[0][0])
                begin
                    max_pooling_result_rf[0][0] <= equalized_result_rf[1][0][mm_img_cnt];
                end
                else
                begin
                    max_pooling_result_rf[0][0] <= max_pooling_result_rf[0][0];
                end

                if(fp_cmp_results[0][1])
                begin
                    max_pooling_result_rf[0][1] <= equalized_result_rf[1][2][mm_img_cnt];
                end
                else
                begin
                    max_pooling_result_rf[0][1] <= max_pooling_result_rf[0][1];
                end

                if(fp_cmp_results[1][0])
                begin
                    max_pooling_result_rf[1][0] <= equalized_result_rf[3][0][mm_img_cnt];
                end
                else
                begin
                    max_pooling_result_rf[1][0] <= max_pooling_result_rf[1][0];
                end

                if(fp_cmp_results[1][1])
                begin
                    max_pooling_result_rf[1][1] <= equalized_result_rf[3][2][mm_img_cnt];
                end
                else
                begin
                    max_pooling_result_rf[1][1] <= max_pooling_result_rf[1][1];
                end
            end
            'd2:
            begin
                // Compare conv_result > max_pooling_result
                if(fp_cmp_results[0][0])
                begin
                    max_pooling_result_rf[0][0] <= equalized_result_rf[1][1][mm_img_cnt];
                end
                else
                begin
                    max_pooling_result_rf[0][0] <= max_pooling_result_rf[0][0];
                end

                if(fp_cmp_results[0][1])
                begin
                    max_pooling_result_rf[0][1] <= equalized_result_rf[1][3][mm_img_cnt];
                end
                else
                begin
                    max_pooling_result_rf[0][1] <= max_pooling_result_rf[0][1];
                end

                if(fp_cmp_results[1][0])
                begin
                    max_pooling_result_rf[1][0] <= equalized_result_rf[3][1][mm_img_cnt];
                end
                else
                begin
                    max_pooling_result_rf[1][0] <= max_pooling_result_rf[1][0];
                end

                if(fp_cmp_results[1][1])
                begin
                    max_pooling_result_rf[1][1] <= equalized_result_rf[3][3][mm_img_cnt];
                end
                else
                begin
                    max_pooling_result_rf[1][1] <= max_pooling_result_rf[1][1];
                end
            end
            endcase
    end
end

//---------------------------------------------------------------------
//      FULLY CONNECTED (FC DOMAIN)
//---------------------------------------------------------------------
reg[DATA_WIDTH-1:0] fp_add0_FC_d2, fp_mult0_FC_d1, fp_mult1_FC_d1;
reg fc_valid_d1, fc_valid_d2;
reg act_valid_d1,act_valid_d2;
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        fc_valid_d1 <= 0;
    end
    else if(ST_MM_IDLE)
    begin
        fc_valid_d1 <= 0;
    end
    else if(ST_MM_FC)
    begin
        fc_valid_d1 <= mm_cnt == 4 ? 0 : 1;
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        fc_valid_d2 <= 0;
    end
    else
    begin
        fc_valid_d2 <= fc_valid_d1;
    end
end

// Find min max during fc calculation
always @(posedge clk_fc)
begin
    if(ST_MM_FC)
    begin
        if(fc_valid_d1)
        begin
            case(mm_cnt_d1)
            'd0:
            begin
                x_min_ff <= fp_addsub0_out;
                x_max_ff <= fp_addsub0_out;
            end
            default:
            begin
                if(~fp_cmp_results[0][0])
                    x_min_ff <= fp_addsub0_out;
                if(fp_cmp_results[0][1])
                    x_max_ff <= fp_addsub0_out;
            end
            endcase
        end
    end
end

always @(posedge clk_fc)
begin
    fp_mult_fc_d1[0] <= fp_mult_FC_out[0];
    fp_mult_fc_d1[1] <= fp_mult_FC_out[1];
end

always @(posedge clk)
begin
    if(fc_valid_d1)
    begin
        fc_result_rf[0] <= fc_result_rf[1];
        fc_result_rf[1] <= fc_result_rf[2];
        fc_result_rf[2] <= fc_result_rf[3];
        fc_result_rf[3] <= fp_addsub0_out;
    end
    else if(ST_MM_NORM_ACT)
    begin
        fc_result_rf[0] <= fc_result_rf[1];
        fc_result_rf[1] <= fc_result_rf[2];
        fc_result_rf[2] <= fc_result_rf[3];
        fc_result_rf[3] <= 0;
    end
end

//---------------------------------------------------------------------
//      NORM ACT DOMAIN
//---------------------------------------------------------------------
wire[DATA_WIDTH-1:0] max_min_reci_out;
always @(posedge clk)
begin
    if(ST_MM_NORM_ACT)
    begin
        // min_max_diff_reci_ff  <= fp_addsub1_out;
        min_max_diff_reci_ff  <= max_min_reci_out;
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        norm_act_d1 <= 0;
    end
    else if(ST_MM_IDLE)
    begin
        norm_act_d1 <= 0;
    end
    else if(ST_MM_NORM_ACT)
    begin
        norm_act_d1 <= (mm_cnt == 4) ? 0 : 1;
    end
end

always @(posedge clk)
begin
    if(cg_en)
    begin
        if(norm_act_d1)
            activation_var_d2 <= negation;
    end
    else
    begin
        activation_var_d2 <= negation;
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        norm_act_d2 <= 0;
        norm_act_d3 <= 0;
        norm_act_d4 <= 0;
        act_valid_d2 <= 0;
    end
    else
    begin
        act_valid_d2 <= act_valid_d1;
        norm_act_d2 <= norm_act_d1;
        norm_act_d3 <= norm_act_d2;
        norm_act_d4 <= norm_act_d3;
    end
end

always @(posedge clk)
begin
    if(~rst_n)
    begin
        activation_result_rf[0][0] <= 0;
        activation_result_rf[1][0] <= 0;
        activation_result_rf[2][0] <= 0;
        activation_result_rf[3][0] <= 0;

        activation_result_rf[0][1] <= 0;
        activation_result_rf[1][1] <= 0;
        activation_result_rf[2][1] <= 0;
        activation_result_rf[3][1] <= 0;
    end
    else if(norm_act_d4)
    begin
        activation_result_rf[0][mm_img_cnt] <= activation_result_rf[1][mm_img_cnt];
        activation_result_rf[1][mm_img_cnt] <= activation_result_rf[2][mm_img_cnt];
        activation_result_rf[2][mm_img_cnt] <= activation_result_rf[3][mm_img_cnt];
        activation_result_rf[3][mm_img_cnt] <= fp_div1_out;
    end
end

always @(posedge clk)
begin
    if(ST_MM_NORM_ACT)
    begin
        fp_norm_sub0_out_d1  <= fp_addsub0_out;
    end
end

always @(posedge clk)
begin
    if(norm_act_d2)
    begin
        exp_pos_result_d3 <= exp_pos_result;
    end

    if(ST_MM_NORM_ACT && norm_act_d3)
    begin
        if(opt_ff == 0 || opt_ff == 1)
        begin
            //sigmoid
            fp_add3_act_d4<= fp_addsub3_out;
        end
        else
        begin
            //tanh
            fp_sub2_act_d4 <=  fp_addsub2_out;
            fp_add3_act_d4 <=  fp_addsub3_out;
        end
    end
end
//---------------------------
//      RECIPROCAL
//---------------------------
// Instance of DW_fp_recip_DG
DW_fp_recip_DG #(.sig_width(inst_sig_width), .exp_width(inst_exp_width), .ieee_compliance(inst_ieee_compliance),
.faithful_round(faithful_round))
reciprocal_one( .a(fp_addsub1_out), .rnd(3'b000), .DG_ctrl(~sleep_norm_act), .z(max_min_reci_out),
.status() );


//---------------------------------------------------------------------
//      L1 distance domain
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        l1_distance_ff <= 0;
        l1_valid_d1 <= 0;
    end
    else if(ST_MM_IDLE)
    begin
        l1_distance_ff<= 0;
        l1_valid_d1 <= 0;
    end
    else if(ST_MM_L1_DISTANCE)
    begin
        if(l1_valid_d1)
        begin
            l1_valid_d1 <= 0;
            l1_distance_ff <= fp_add_tree_out[2];
        end
        else
        begin
            l1_valid_d1 <= 1;
        end
    end
    else if(ST_MM_DONE)
    begin
        l1_distance_ff <= 0;
    end
end

//---------------------------------------------------------------------
//   L1 distance Datapath
//---------------------------------------------------------------------

always @(posedge clk)
begin
    if(cg_en)
    begin
        if(ST_MM_L1_DISTANCE)
        begin
            abs_out_0_d1 <=  (fp_addsub0_out[31] == 1) ? {1'b0,fp_addsub0_out[30:0]} : fp_addsub0_out;
            abs_out_1_d1 <=  (fp_addsub1_out[31] == 1) ? {1'b0,fp_addsub1_out[30:0]} : fp_addsub1_out;
            abs_out_2_d1 <=  (fp_addsub2_out[31] == 1) ? {1'b0,fp_addsub2_out[30:0]} : fp_addsub2_out;
            abs_out_3_d1 <=  (fp_addsub3_out[31] == 1) ? {1'b0,fp_addsub3_out[30:0]} : fp_addsub3_out;
        end
    end
    else
    begin
        abs_out_0_d1 <=  (fp_addsub0_out[31] == 1) ? {1'b0,fp_addsub0_out[30:0]} : fp_addsub0_out;
        abs_out_1_d1 <=  (fp_addsub1_out[31] == 1) ? {1'b0,fp_addsub1_out[30:0]} : fp_addsub1_out;
        abs_out_2_d1 <=  (fp_addsub2_out[31] == 1) ? {1'b0,fp_addsub2_out[30:0]} : fp_addsub2_out;
        abs_out_3_d1 <=  (fp_addsub3_out[31] == 1) ? {1'b0,fp_addsub3_out[30:0]} : fp_addsub3_out;
    end
end

//---------------------------------------------------------------------
//   MAX POOLING FP_CMP X4 and its input
//---------------------------------------------------------------------
reg[DATA_WIDTH-1:0] fp_cmp_input_a[0:1][0:1];
reg[DATA_WIDTH-1:0] fp_cmp_input_b[0:1][0:1];

always @(*)
begin
    fp_cmp_input_a[0][0] = 1;
    fp_cmp_input_a[0][1] = 1;
    fp_cmp_input_a[1][0] = 1;
    fp_cmp_input_a[1][1] = 1;

    fp_cmp_input_b[0][0] = 1;
    fp_cmp_input_b[0][1] = 1;
    fp_cmp_input_b[1][0] = 1;
    fp_cmp_input_b[1][1] = 1;
    if(ST_MM_MAX_POOLING)
    begin
        case(mm_cnt)
        'd0:
        begin
            fp_cmp_input_a[0][0] = equalized_result_rf[0][0][mm_img_cnt];
            fp_cmp_input_a[0][1] = equalized_result_rf[0][2][mm_img_cnt];
            fp_cmp_input_a[1][0] = equalized_result_rf[2][0][mm_img_cnt];
            fp_cmp_input_a[1][1] = equalized_result_rf[2][2][mm_img_cnt];

            fp_cmp_input_b[0][0] = equalized_result_rf[0][1][mm_img_cnt];
            fp_cmp_input_b[0][1] = equalized_result_rf[0][3][mm_img_cnt];
            fp_cmp_input_b[1][0] = equalized_result_rf[2][1][mm_img_cnt];
            fp_cmp_input_b[1][1] = equalized_result_rf[2][3][mm_img_cnt];
        end
        'd1:
        begin
            fp_cmp_input_a[0][0] = equalized_result_rf[1][0][mm_img_cnt];
            fp_cmp_input_a[0][1] = equalized_result_rf[1][2][mm_img_cnt];
            fp_cmp_input_a[1][0] = equalized_result_rf[3][0][mm_img_cnt];
            fp_cmp_input_a[1][1] = equalized_result_rf[3][2][mm_img_cnt];

            fp_cmp_input_b[0][0] = max_pooling_result_rf[0][0];
            fp_cmp_input_b[0][1] = max_pooling_result_rf[0][1];
            fp_cmp_input_b[1][0] = max_pooling_result_rf[1][0];
            fp_cmp_input_b[1][1] = max_pooling_result_rf[1][1];
        end
        'd2:
        begin
            fp_cmp_input_a[0][0] = equalized_result_rf[1][1][mm_img_cnt];
            fp_cmp_input_a[0][1] = equalized_result_rf[1][3][mm_img_cnt];
            fp_cmp_input_a[1][0] = equalized_result_rf[3][1][mm_img_cnt];
            fp_cmp_input_a[1][1] = equalized_result_rf[3][3][mm_img_cnt];

            fp_cmp_input_b[0][0] = max_pooling_result_rf[0][0];
            fp_cmp_input_b[0][1] = max_pooling_result_rf[0][1];
            fp_cmp_input_b[1][0] = max_pooling_result_rf[1][0];
            fp_cmp_input_b[1][1] = max_pooling_result_rf[1][1];
        end
        endcase
    end

    if(ST_MM_FC)
    // Critical path here. Try reducing it, using case statement shall makes things better
    begin
        // Since I am calculating the Min max at the same time
        // min
        fp_cmp_input_a[0][0] = fp_addsub0_out;
        fp_cmp_input_b[0][0] = x_min_ff;

        // max
        fp_cmp_input_a[0][1] = fp_addsub0_out;
        fp_cmp_input_b[0][1] = x_max_ff;
    end
end

generate
    for(idx = 0;idx<2;idx = idx+1)
        for(jdx = 0;jdx < 2;jdx=jdx+1)
        begin
            DW_fp_cmp_DG_inst
                #(
                    .sig_width       (inst_sig_width),
                    .exp_width       (inst_exp_width),
                    .ieee_compliance (inst_ieee_compliance)
                )
                u_DW_fp_cmp_DG_inst(
                    .inst_a         (  fp_cmp_input_a[idx][jdx]  ),
                    .inst_b         (  fp_cmp_input_b[idx][jdx]  ),
                    .inst_zctr      (           ),
                    .inst_DG_ctrl   (cg_en ? ST_MM_MAX_POOLING || fc_valid_d1 : 1'b1),
                    .aeqb_inst      (           ),
                    .altb_inst      (           ),
                    .agtb_inst      ( fp_cmp_results[idx][jdx]  ),
                    .unordered_inst ( ),
                    .z0_inst        (        ),
                    .z1_inst        (        ),
                    .status0_inst   (   ),
                    .status1_inst   (   )
                );
        end
endgenerate

//---------------------------------------------------------------------
//   FULLY CONNECTED LAYERS FP_MULTS x2 , 1 ADD
//---------------------------------------------------------------------
DW_fp_mult_DG_inst #(inst_sig_width,inst_exp_width,inst_ieee_compliance)
                        u_DW_fp_mult_FC0(
                            .inst_a   (  fp_mult_fc_in_a[0]),
                            .inst_b   (  fp_mult_fc_in_b[0]),
                            .inst_rnd ( 3'b000              ),
                            .inst_DG_ctrl(cg_en ? ST_MM_FC || norm_act_d1:1'b1),
                            .z_inst   (  fp_mult_FC_out[0]),
                            .status_inst  (   )
                        );
DW_fp_mult_DG_inst #(inst_sig_width,inst_exp_width,inst_ieee_compliance)
                        u_DW_fp_mult_FC1(
                            .inst_a   (   fp_mult_fc_in_a[1]),
                            .inst_b   (   fp_mult_fc_in_b[1]),
                            .inst_DG_ctrl(cg_en ? ST_MM_FC || norm_act_d1:1'b1),
                            .inst_rnd ( 3'b000              ),
                            .z_inst   (  fp_mult_FC_out[1] ),
                            .status_inst  (   )
                        );



always@(*)
begin
    fp_mult_fc_in_a[0] = 0;
    fp_mult_fc_in_a[1] = 0;

    fp_mult_fc_in_b[0] = 0;
    fp_mult_fc_in_b[1] = 0;

    if(ST_MM_FC)
    begin
        case(mm_cnt)
        'd0:
        begin
            fp_mult_fc_in_a[0] = max_pooling_result_rf[0][0];
            fp_mult_fc_in_a[1] = max_pooling_result_rf[0][1];

            fp_mult_fc_in_b[0] = weight_rf[0][0];
            fp_mult_fc_in_b[1] = weight_rf[1][0];
        end
        'd1:
        begin
            fp_mult_fc_in_a[0] = max_pooling_result_rf[0][0];
            fp_mult_fc_in_a[1] = max_pooling_result_rf[0][1];

            fp_mult_fc_in_b[0] = weight_rf[0][1];
            fp_mult_fc_in_b[1] = weight_rf[1][1];
        end
        'd2:
        begin
            fp_mult_fc_in_a[0] = max_pooling_result_rf[1][0];
            fp_mult_fc_in_a[1] = max_pooling_result_rf[1][1];
            fp_mult_fc_in_b[0] = weight_rf[0][0];
            fp_mult_fc_in_b[1] = weight_rf[1][0];
        end
        'd3:
        begin
            fp_mult_fc_in_a[0] = max_pooling_result_rf[1][0];
            fp_mult_fc_in_a[1] = max_pooling_result_rf[1][1];
            fp_mult_fc_in_b[0] = weight_rf[0][1];
            fp_mult_fc_in_b[1] = weight_rf[1][1];
        end
        endcase
    end
    else if(ST_MM_NORM_ACT)
    begin
        fp_mult_fc_in_a[0] = min_max_diff_reci_ff;
        fp_mult_fc_in_b[0] = fp_norm_sub0_out_d1;
    end
end

//---------------------------------------------------------------------------------
//   Min Max normalization, DIV , 2x Subtractions = 2x ADDERS, share it with
//---------------------------------------------------------------------------------
always @(*)
begin
    // tanh
    if(opt_ff == 2 || opt_ff == 3)
    begin
        fp_div1_in_a = fp_sub2_act_d4;
        fp_div1_in_b = fp_add3_act_d4;
    end
    else
    begin
        fp_div1_in_a = FP_ONE;
        fp_div1_in_b = fp_add3_act_d4;
    end
end

localparam  div_sig_width = 23;
localparam  div_discarded_sig = inst_sig_width - div_sig_width;

wire[DATA_WIDTH-1-div_discarded_sig : 0] div1_temp_out;

DW_fp_div_DG_inst
    #(
        .sig_width       (div_sig_width        ),
        .exp_width       (inst_exp_width       ),
        .ieee_compliance (inst_ieee_compliance ),
        .faithful_round  (faithful_round  )
    )
    u_DW_fp_div_1(
        .inst_a      (    fp_div1_in_a[DATA_WIDTH-1:div_discarded_sig] ),
        .inst_b      (    fp_div1_in_b[DATA_WIDTH-1:div_discarded_sig] ),
        .inst_rnd    (3'b000    ),
        .inst_DG_ctrl(norm_act_d4),
        .z_inst      (  div1_temp_out),
        .status_inst (  )
    );

assign fp_div1_out = {div1_temp_out,{div_discarded_sig{1'b0}}};
//---------------------------------------------------------------------
//   Activation Sigmoid or tanh, 1 e^x and 2 ADD Sub, 1 more add
//---------------------------------------------------------------------

// FP_TWO
localparam FP_TWO = 32'h40000000;

// z
wire[DATA_WIDTH-1:0] z_value = fp_mult_FC_out[0];
wire[DATA_WIDTH-1:0] norm_act_x2_d1_out;


// Instance of DW_fp_mult_DG
DW_fp_mult_DG #(.sig_width(inst_sig_width), .exp_width(inst_exp_width), .ieee_compliance(inst_ieee_compliance))
norm_act_M2 ( .a(FP_TWO), .b(z_value), .rnd(3'b000), .DG_ctrl(1'b1), .z(norm_act_x2_d1_out),
.status() );

// norm_act_x2_d1_out

always @(*) begin
    negation_in = 0;
    pos_exp_in  = activation_var_d2;

    // Sigmoid
    if(opt_ff == 0 || opt_ff == 1)
    begin
        negation_in = z_value;
    end
    else
    begin
        // tanh
        negation_in = norm_act_x2_d1_out;
    end
end

localparam  exp_sig_width = 23;
localparam  exp_discarded_sig = inst_sig_width - exp_sig_width;

wire[DATA_WIDTH-1-exp_discarded_sig : 0] exp_pos_result_temp;

DW_fp_exp_inst
    #(
        .inst_sig_width       (exp_sig_width       ),
        .inst_exp_width       (inst_exp_width       ),
        .inst_ieee_compliance (inst_ieee_compliance ),
        .inst_arch            (inst_arch            )
    )
    u_DW_fp_exp2(
        .inst_a      (pos_exp_in[DATA_WIDTH-1:exp_discarded_sig] ),
        .z_inst      (exp_pos_result_temp      ),
        .status_inst ( )
    );

assign exp_pos_result =  {exp_pos_result_temp , {exp_discarded_sig{1'b0}}};

//---------------------------------------------------------------------
//      2X DW_ADD_SUB
//---------------------------------------------------------------------
always @(*)
begin
    // 0 addition, 1 subtraction
    fp_addsub0_in_a = 0;
    fp_addsub0_in_b = 0;

    fp_addsub1_in_a = 0;
    fp_addsub1_in_b = 0;

    fp_addsub0_mode = 0;
    fp_addsub1_mode = 0;

    fp_addsub2_in_a = 0;
    fp_addsub2_in_b = 0;

    fp_addsub3_in_a = 0;
    fp_addsub3_in_b = 0;

    fp_addsub2_mode = 0;
    fp_addsub3_mode = 0;

    fp_add_tree_in_a[0] = 0;
    fp_add_tree_in_b[0] = 0;

    fp_add_tree_in_a[1] = 0;
    fp_add_tree_in_b[1] = 0;

    fp_add_tree_in_a[2] = 0;
    fp_add_tree_in_b[2] = 0;

    // Convolution process
    fp_add_tree_in_a[0] = partial_sum_pipe_d2[0];
    fp_add_tree_in_b[0] = partial_sum_pipe_d2[1];
    fp_add_tree_in_a[1] = partial_sum_pipe_d2[2];
    fp_add_tree_in_b[1] = (kernal_num_cnt_d2==1'b0) ? 0 : convolution_result_rf[process_xptr_d2][process_yptr_d2][img_num_cnt_d2];
    fp_add_tree_in_a[2] = fp_add_tree_d3[0];
    fp_add_tree_in_b[2] = fp_add_tree_d3[1];

    if(ST_MM_L1_DISTANCE && ST_P_IDLE)
    begin
        fp_addsub0_mode = 1;
        fp_addsub0_in_a = activation_result_rf[0][0];
        fp_addsub0_in_b = activation_result_rf[0][1];

        fp_addsub1_mode = 1;
        fp_addsub1_in_a = activation_result_rf[1][0];
        fp_addsub1_in_b = activation_result_rf[1][1];

        fp_addsub2_mode = 1;
        fp_addsub2_in_a = activation_result_rf[2][0];
        fp_addsub2_in_b = activation_result_rf[2][1];

        fp_addsub3_mode = 1;
        fp_addsub3_in_a = activation_result_rf[3][0];
        fp_addsub3_in_b = activation_result_rf[3][1];

        fp_add_tree_in_a[0] = abs_out_0_d1;
        fp_add_tree_in_b[0] = abs_out_1_d1;
        fp_add_tree_in_a[1] = abs_out_2_d1;
        fp_add_tree_in_b[1] = abs_out_3_d1;

        fp_add_tree_in_a[2] = fp_add_tree_out[0];
        fp_add_tree_in_b[2] = fp_add_tree_out[1];
    end

    if(ST_MM_FC)
    begin
        fp_addsub0_mode = 0 ;
        fp_addsub0_in_a = fp_mult_fc_d1[0];
        fp_addsub0_in_b = fp_mult_fc_d1[1];
    end

    if(ST_MM_NORM_ACT)
    begin
        fp_addsub0_mode = 1;
        fp_addsub0_in_a = fc_result_rf[0];
        fp_addsub0_in_b = x_min_ff;

        fp_addsub1_mode = 1;
        fp_addsub1_in_a = x_max_ff;
        fp_addsub1_in_b = x_min_ff;

        // Tanh
        fp_addsub2_mode = 1;//subtract mode
        if(opt_ff == 2 || opt_ff == 3)
        begin
            fp_addsub2_in_a = FP_ONE;
            fp_addsub2_in_b = exp_pos_result_d3;
        end

        // Both tanh and sigmoid needs this
        fp_addsub3_mode = 0; // add
        fp_addsub3_in_a = FP_ONE;
        fp_addsub3_in_b = exp_pos_result_d3;
    end
end

// Instance of DW_fp_addsub
DW_fp_addsub_DG #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
fp_addsub0_inst ( .DG_ctrl(ST_MM_FC||ST_MM_NORM_ACT||ST_MM_L1_DISTANCE),.a(fp_addsub0_in_a), .b(fp_addsub0_in_b), .rnd(3'b000),
.op(fp_addsub0_mode), .z(fp_addsub0_out), .status() );

// Instance of DW_fp_addsub
DW_fp_addsub_DG #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
fp_addsub1_inst( .DG_ctrl(ST_MM_NORM_ACT||ST_MM_L1_DISTANCE),.a(fp_addsub1_in_a), .b(fp_addsub1_in_b), .rnd(3'b000),
.op(fp_addsub1_mode), .z(fp_addsub1_out), .status() );

// Instance of DW_fp_addsub
DW_fp_addsub_DG #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
fp_addsub2_inst( .DG_ctrl(norm_act_d3||ST_MM_L1_DISTANCE),.a(fp_addsub2_in_a), .b(fp_addsub2_in_b), .rnd(3'b000),
.op(fp_addsub2_mode), .z(fp_addsub2_out), .status() );

// Instance of DW_fp_addsub
DW_fp_addsub_DG #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
fp_addsub3_inst(.DG_ctrl(norm_act_d3||ST_MM_L1_DISTANCE), .a(fp_addsub3_in_a), .b(fp_addsub3_in_b), .rnd(3'b000),
.op(fp_addsub3_mode), .z(fp_addsub3_out), .status() );

endmodule

//---------------------------------------------------------------------
//   Module Design
//---------------------------------------------------------------------

    module DW_fp_mult_inst( inst_a, inst_b, inst_rnd, z_inst, status_inst );
parameter sig_width = 23;
parameter exp_width = 8;
parameter ieee_compliance = 1;
parameter en_ubr_flag = 0;

input [sig_width+exp_width : 0] inst_a;
input [sig_width+exp_width : 0] inst_b;
input [2 : 0] inst_rnd;
output [sig_width+exp_width : 0] z_inst;
output [7 : 0] status_inst;
// Instance of DW_fp_mult
DW_fp_mult #(sig_width, exp_width, ieee_compliance, en_ubr_flag)
           U1 ( .a(inst_a), .b(inst_b), .rnd(inst_rnd), .z(z_inst), .status(status_inst) );
endmodule

//     module DW_fp_sum3_inst( inst_a, inst_b, inst_c, inst_rnd, z_inst,
//                             status_inst );

// parameter inst_sig_width = 23;
// parameter inst_exp_width = 8;
// parameter inst_ieee_compliance = 0;
// parameter inst_arch_type = 0;

// input [inst_sig_width+inst_exp_width : 0] inst_a;
// input [inst_sig_width+inst_exp_width : 0] inst_b;
// input [inst_sig_width+inst_exp_width : 0] inst_c;
// input [2 : 0] inst_rnd;
// output [inst_sig_width+inst_exp_width : 0] z_inst;
// output [7 : 0] status_inst;
// // Instance of DW_fp_sum3
// DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
//            U1 (
//                .a(inst_a),
//                .b(inst_b),
//                .c(inst_c),
//                .rnd(inst_rnd),
//                .z(z_inst),
//                .status(status_inst) );
// endmodule

    module DW_fp_exp_inst( inst_a, z_inst, status_inst );
parameter inst_sig_width = 10;

parameter inst_exp_width = 5;

parameter inst_ieee_compliance = 1;

parameter inst_arch = 2;

input [inst_sig_width+inst_exp_width : 0] inst_a;
output [inst_sig_width+inst_exp_width : 0] z_inst;
output [7 : 0] status_inst;

// Instance of DW_fp_exp
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) U1 (
              .a(inst_a),
              .z(z_inst),
              .status(status_inst) );
endmodule


//     module DW_fp_div_inst( inst_a, inst_b, inst_rnd, z_inst, status_inst );
// parameter sig_width = 23;
// parameter exp_width = 8;
// parameter ieee_compliance = 0;
// parameter faithful_round = 0;
// parameter en_ubr_flag = 0;

// input [sig_width+exp_width : 0] inst_a;
// input [sig_width+exp_width : 0] inst_b;
// input [2 : 0] inst_rnd;
// output [sig_width+exp_width : 0] z_inst;
// output [7 : 0] status_inst;
// // Instance of DW_fp_div
// DW_fp_div #(sig_width, exp_width, ieee_compliance, faithful_round, en_ubr_flag) U1
//           ( .a(inst_a), .b(inst_b), .rnd(inst_rnd), .z(z_inst), .status(status_inst)
//           );
// endmodule

//     module DW_fp_cmp_inst( inst_a, inst_b, inst_zctr, aeqb_inst, altb_inst,
//                            agtb_inst, unordered_inst, z0_inst, z1_inst, status0_inst,
//                            status1_inst );
// parameter sig_width = 23;
// parameter exp_width = 8;
// parameter ieee_compliance = 0;
// input [sig_width+exp_width : 0] inst_a;
// input [sig_width+exp_width : 0] inst_b;
// input inst_zctr;
// output aeqb_inst;
// output altb_inst;
// output agtb_inst;
// output unordered_inst;
// output [sig_width+exp_width : 0] z0_inst;
// output [sig_width+exp_width : 0] z1_inst;
// output [7 : 0] status0_inst;
// output [7 : 0] status1_inst;
// // Instance of DW_fp_cmp
// DW_fp_cmp #(sig_width, exp_width, ieee_compliance)
//           U1 ( .a(inst_a), .b(inst_b), .zctr(inst_zctr), .aeqb(aeqb_inst),
//                .altb(altb_inst), .agtb(agtb_inst), .unordered(unordered_inst),
//                .z0(z0_inst), .z1(z1_inst), .status0(status0_inst),
//                .status1(status1_inst) );
// endmodule

//     module DW_fp_add_inst( inst_a, inst_b, inst_rnd, z_inst, status_inst );
// parameter sig_width = 23;
// parameter exp_width = 8;
// parameter ieee_compliance = 0;
// input [sig_width+exp_width : 0] inst_a;
// input [sig_width+exp_width : 0] inst_b;
// input [2 : 0] inst_rnd;
// output [sig_width+exp_width : 0] z_inst;
// output [7 : 0] status_inst;
// // Instance of DW_fp_add
// DW_fp_add #(sig_width, exp_width, ieee_compliance)
//           U1 ( .a(inst_a), .b(inst_b), .rnd(inst_rnd), .z(z_inst), .status(status_inst) );
// endmodule


//     module DW_fp_sub_inst( inst_a, inst_b, inst_rnd, z_inst, status_inst );
// parameter sig_width = 23;
// parameter exp_width = 8;
// parameter ieee_compliance = 0;
// input [sig_width+exp_width : 0] inst_a;
// input [sig_width+exp_width : 0] inst_b;
// input [2 : 0] inst_rnd;
// output [sig_width+exp_width : 0] z_inst;
// output [7 : 0] status_inst;
// // Instance of DW_fp_sub
// DW_fp_sub #(sig_width, exp_width, ieee_compliance)
//           U1 ( .a(inst_a), .b(inst_b), .rnd(inst_rnd), .z(z_inst), .status(status_inst) );
// endmodule

module DW_fp_addsub_inst( inst_a, inst_b, inst_rnd, inst_op, z_inst,
status_inst );
parameter sig_width = 23;
parameter exp_width = 8;
parameter ieee_compliance = 0;
input [sig_width+exp_width : 0] inst_a;
input [sig_width+exp_width : 0] inst_b;
input [2 : 0] inst_rnd;
input inst_op;
output [sig_width+exp_width : 0] z_inst;
output [7 : 0] status_inst;
// Instance of DW_fp_addsub
DW_fp_addsub #(sig_width, exp_width, ieee_compliance)
U1 ( .a(inst_a), .b(inst_b), .rnd(inst_rnd),
.op(inst_op), .z(z_inst), .status(status_inst) );
endmodule

module DW_fp_recip_DG_inst( inst_a, inst_rnd, inst_DG_ctrl, z_inst, status_inst );
parameter sig_width = 23;
parameter exp_width = 8;
parameter ieee_compliance = 0;
parameter faithful_round = 0;

input [sig_width+exp_width : 0] inst_a;
input [2 : 0] inst_rnd;
input inst_DG_ctrl;
output [sig_width+exp_width : 0] z_inst;
output [7 : 0] status_inst;
// Instance of DW_fp_recip_DG
DW_fp_recip_DG #(sig_width, exp_width, ieee_compliance, faithful_round)
U1 ( .a(inst_a), .rnd(inst_rnd), .DG_ctrl(inst_DG_ctrl), .z(z_inst),
.status(status_inst) );
endmodule

module DW_fp_add_DG_inst( inst_a, inst_b, inst_rnd, inst_DG_ctrl, z_inst,
status_inst );
parameter sig_width = 23;
parameter exp_width = 8;
parameter ieee_compliance = 0;
input [sig_width+exp_width : 0] inst_a;
input [sig_width+exp_width : 0] inst_b;
input [2 : 0] inst_rnd;
input inst_DG_ctrl;
output [sig_width+exp_width : 0] z_inst;
output [7 : 0] status_inst;
// Instance of DW_fp_add_DG
DW_fp_add_DG #(sig_width, exp_width, ieee_compliance)
U1 ( .a(inst_a), .b(inst_b), .rnd(inst_rnd), .DG_ctrl(inst_DG_ctrl), .z(z_inst),
.status(status_inst) );
endmodule

module DW_fp_mult_DG_inst( inst_a, inst_b, inst_rnd, inst_DG_ctrl, z_inst,
status_inst );
parameter sig_width = 23;
parameter exp_width = 8;
parameter ieee_compliance = 1;
input [sig_width+exp_width : 0] inst_a;
input [sig_width+exp_width : 0] inst_b;
input [2 : 0] inst_rnd;
input inst_DG_ctrl;
output [sig_width+exp_width : 0] z_inst;
output [7 : 0] status_inst;
// Instance of DW_fp_mult_DG
DW_fp_mult_DG #(sig_width, exp_width, ieee_compliance)
U1 ( .a(inst_a), .b(inst_b), .rnd(inst_rnd), .DG_ctrl(inst_DG_ctrl), .z(z_inst),
.status(status_inst) );
endmodule

module DW_fp_sum3_DG_inst( inst_a, inst_b, inst_c, inst_rnd, inst_DG_ctrl,
z_inst, status_inst );
parameter sig_width = 23;
parameter exp_width = 8;
parameter ieee_compliance = 0;
parameter arch_type = 0;

input [sig_width+exp_width : 0] inst_a;
input [sig_width+exp_width : 0] inst_b;
input [sig_width+exp_width : 0] inst_c;
input [2 : 0] inst_rnd;
input inst_DG_ctrl;
output [sig_width+exp_width : 0] z_inst;
output [7 : 0] status_inst;
// Instance of DW_fp_sum3_DG
DW_fp_sum3_DG #(sig_width, exp_width, ieee_compliance, arch_type)
U1 ( .a(inst_a), .b(inst_b), .c(inst_c), .rnd(inst_rnd), .DG_ctrl(inst_DG_ctrl),
.z(z_inst), .status(status_inst) );
endmodule

module DW_fp_cmp_DG_inst( inst_a, inst_b, inst_zctr, inst_DG_ctrl, aeqb_inst,
altb_inst, agtb_inst, unordered_inst, z0_inst, z1_inst,
status0_inst, status1_inst );
parameter sig_width = 23;
parameter exp_width = 8;
parameter ieee_compliance = 0;
input [sig_width+exp_width : 0] inst_a;
input [sig_width+exp_width : 0] inst_b;
input inst_zctr;
input inst_DG_ctrl;
output aeqb_inst;
output altb_inst;
output agtb_inst;
output unordered_inst;
output [sig_width+exp_width : 0] z0_inst;
output [sig_width+exp_width : 0] z1_inst;
output [7 : 0] status0_inst;
output [7 : 0] status1_inst;
// Instance of DW_fp_cmp_DG
DW_fp_cmp_DG #(sig_width, exp_width, ieee_compliance)
U1 ( .a(inst_a), .b(inst_b), .zctr(inst_zctr), .DG_ctrl(inst_DG_ctrl),
.aeqb(aeqb_inst), .altb(altb_inst), .agtb(agtb_inst), .unordered(unordered_inst),
.z0(z0_inst), .z1(z1_inst), .status0(status0_inst), .status1(status1_inst) );
endmodule

module DW_fp_div_DG_inst( inst_a, inst_b, inst_rnd, inst_DG_ctrl, z_inst,
status_inst );
parameter sig_width = 23;
parameter exp_width = 8;
parameter ieee_compliance = 0;
parameter faithful_round = 0;

input [sig_width+exp_width : 0] inst_a;
input [sig_width+exp_width : 0] inst_b;
input [2 : 0] inst_rnd;
input inst_DG_ctrl;
output [sig_width+exp_width : 0] z_inst;
output [7 : 0] status_inst;
// Instance of DW_fp_div_DG
DW_fp_div_DG #(sig_width, exp_width, ieee_compliance, faithful_round)
U1 ( .a(inst_a), .b(inst_b), .rnd(inst_rnd), .DG_ctrl(inst_DG_ctrl), .z(z_inst),
.status(status_inst) );
endmodule