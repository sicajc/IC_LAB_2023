//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Siamese Neural Network
//   Author     		:　Yeh-Shun Liang (maggie8905121@gmail.com)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SNN.v
//   Module Name : SNN
//   Release version : V1.0 (Release Date: 2023-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
`define C2Q 0
module SNN(
    //Input Port

    clk,
    rst_n,
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

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

parameter DATA_WIDTH = inst_sig_width + inst_exp_width + 1;

parameter en_ubr_flag  = 0;
parameter faithful_round = 0;

//---------------------------------------------------------------------
//      STATES
//---------------------------------------------------------------------
reg[2:0] p_cur_st, p_next_st;
reg[7:0] mm_cur_st,mm_next_st;

localparam  P_IDLE = 3'b001;
localparam  P_RD_DATA = 3'b010;
localparam  P_PROCESSING = 3'b100;

localparam  MM_IDLE = 8'b0000_0001;
localparam  MM_MAX_POOLING = 8'b0000_0010;
localparam  MM_FC = 8'b0000_0100;
localparam  MM_NORM = 8'b0000_1000;
localparam  MM_ACT = 8'b0001_0000;
localparam  MM_WAIT_IMG1 = 8'b0010_0000;
localparam  MM_L1_DISTANCE = 8'b0100_0000;
localparam  MM_DONE = 8'b1000_0000;

wire ST_P_IDLE = p_cur_st[0];
wire ST_P_RD_DATA = p_cur_st[1];
wire ST_P_PROCESSING = p_cur_st[2];

wire ST_MM_IDLE   = mm_cur_st[0];
wire ST_MM_MAX_POOLING   = mm_cur_st[1];
wire ST_MM_FC   = mm_cur_st[2];
wire ST_MM_NORM   = mm_cur_st[3];
wire ST_MM_ACT   = mm_cur_st[4];
wire ST_MM_WAIT_IMG1   = mm_cur_st[5];
wire ST_MM_L1_DISTANCE   = mm_cur_st[6];
wire ST_MM_DONE   = mm_cur_st[7];

reg[8:0] rd_cnt;
reg[4:0] mm_cnt,pixel_cnt;
reg  processing_f_ff;
reg  valid_d1,valid_d2,valid_d3;

reg[1:0] img_num_cnt,img_num_cnt_d1,img_num_cnt_d2,img_num_cnt_d3;
reg[DATA_WIDTH-1:0] x_min_ff,x_max_ff;

reg[2:0] kernal_num_cnt,kernal_num_cnt_d1,kernal_num_cnt_d2,kernal_num_cnt_d3;

reg[5:0] process_xptr, process_yptr,process_xptr_d1, process_yptr_d1,process_xptr_d2,process_yptr_d2,process_xptr_d3,
process_yptr_d3;

reg[5:0] wr_img_xptr,wr_img_yptr;
reg mm_img_cnt;
reg[4:0] mm_cnt_d1,mm_cnt_d2;
reg norm_valid_d1;
reg[DATA_WIDTH-1:0] exp_pos_result_d1, exp_neg_result_d1, fp_sub0_act_d2,
fp_add_act_d2;
reg[DATA_WIDTH-1:0] fp_mult_fc_d1[0:1];


reg[DATA_WIDTH-1:0] abs_in;
reg[DATA_WIDTH-1:0] abs_out_d1;

reg[DATA_WIDTH-1:0] negation_in;
reg[DATA_WIDTH-1:0] pos_exp_in;

wire[DATA_WIDTH-1:0] fp_mult_FC_out[0:1];
wire[DATA_WIDTH-1:0] fp_add0_out;


reg[DATA_WIDTH-1:0] fp_add0_in_a;
reg[DATA_WIDTH-1:0] fp_add0_in_b;

reg[DATA_WIDTH-1:0] fp_mult_fc_in_a[0:1];
reg[DATA_WIDTH-1:0] fp_mult_fc_in_b[0:1];

reg[DATA_WIDTH-1:0] fp_div_in_a;
reg[DATA_WIDTH-1:0] fp_div_in_b;
wire[DATA_WIDTH-1:0] fp_div_out;

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

wire fp_cmp_results[0:1][0:1];

reg[DATA_WIDTH-1:0] min_max_diff_ff;
reg[DATA_WIDTH-1:0] kernal_rf[0:2][0:2][0:2];
reg[DATA_WIDTH-1:0] img_rf[0:5][0:5][0:2][0:1];
reg[DATA_WIDTH-1:0] weight_rf[0:1][0:1];
wire start_processing_f = rd_cnt == 8;

reg[2:0]  wr_kernal_num_cnt,wr_img_channel_cnt;
reg       wr_img_num_cnt;
reg[1:0] opt_ff;
reg[2:0] wr_kernal_yptr,wr_kernal_xptr;

localparam IMG_SIZE = 4;

integer i,j,k,c;

//---------------------------------------------------------------------
//      flags
//---------------------------------------------------------------------
wire rd_data_done_f = rd_cnt == 95;
wire all_convolution_done_f = img_num_cnt == 1 && kernal_num_cnt == 2 && process_xptr == 3 && process_yptr == 3;
wire channel_processed_f = process_xptr == 3 && process_yptr == 3;
wire convolution_done_f     = kernal_num_cnt == 2 && channel_processed_f;
wire max_pooling_done_f     = mm_cnt == 2 && ST_MM_MAX_POOLING;
wire fc_done_f              = mm_cnt_d2 == 3 && ST_MM_FC;
wire norm_processed_f       = mm_cnt_d1 == 3 && ST_MM_NORM;
wire activation_done_f      = mm_cnt_d2 == 3 && ST_MM_ACT;
wire l1_distance_cal_f      = mm_cnt_d1 == 3 && ST_MM_L1_DISTANCE;
reg convolution_done_f_d1,convolution_done_f_d2,convolution_done_f_d3;
reg pixel_valid,pixel_valid_d1,pixel_valid_d2,pixel_valid_d3;

//---------------------------------------------------------------------
//      2X DW_ADD_SUB
//---------------------------------------------------------------------
reg[DATA_WIDTH-1:0]  fp_addsub0_in_a,fp_addsub0_in_b,fp_addsub1_in_a,fp_addsub1_in_b;
wire[DATA_WIDTH-1:0] fp_addsub0_out,fp_addsub1_out;
reg fp_addsub0_mode, fp_addsub1_mode;

always @(*)
begin
    // 0 addition, 1 subtraction
    fp_addsub0_in_a = 0;
    fp_addsub0_in_b = 0;

    fp_addsub1_in_a = 0;
    fp_addsub1_in_b = 0;

    fp_addsub0_mode = 0;
    fp_addsub1_mode = 0;

    if(ST_MM_FC)
    begin
        fp_addsub0_mode = 0 ;
        fp_addsub0_in_a = fp_mult_fc_d1[0];
        fp_addsub0_in_b = fp_mult_fc_d1[1];
    end

    if(ST_MM_NORM)
    begin
        fp_addsub0_mode = 1;
        case(mm_cnt)
        'd0:  fp_addsub0_in_a = fc_result_rf[0];
        'd1:  fp_addsub0_in_a = fc_result_rf[1];
        'd2:  fp_addsub0_in_a = fc_result_rf[2];
        'd3:  fp_addsub0_in_a = fc_result_rf[3];
        endcase
        fp_addsub0_in_b = x_min_ff;

        fp_addsub1_mode = 1;
        fp_addsub1_in_a = x_max_ff;
        fp_addsub1_in_b = x_min_ff;
    end

    if(ST_MM_ACT)
    begin
        fp_addsub0_mode = 1;

        if(opt_ff == 2 || opt_ff == 3)
        begin
            fp_addsub0_in_a = exp_pos_result_d1;
            fp_addsub0_in_b = exp_neg_result_d1;
        end

        fp_addsub1_mode = 0;

        if(opt_ff == 2 || opt_ff == 3)
        begin
            // tanh
            fp_addsub1_in_a = exp_pos_result_d1;
            fp_addsub1_in_b = exp_neg_result_d1;
        end
        else
        begin
            // sigmoid
            fp_addsub1_in_a = FP_ONE;
            fp_addsub1_in_b = exp_neg_result_d1;
        end
    end

    if(ST_MM_L1_DISTANCE)
    begin
        fp_addsub0_mode = 1;
        case(mm_cnt)
        'd0:begin
            fp_addsub0_in_a = activation_result_rf[0][0];
            fp_addsub0_in_b = activation_result_rf[0][1];
        end
        'd1:begin
            fp_addsub0_in_a = activation_result_rf[1][0];
            fp_addsub0_in_b = activation_result_rf[1][1];
        end
        'd2:begin
            fp_addsub0_in_a = activation_result_rf[2][0];
            fp_addsub0_in_b = activation_result_rf[2][1];
        end
        'd3:begin
            fp_addsub0_in_a = activation_result_rf[3][0];
            fp_addsub0_in_b = activation_result_rf[3][1];
        end
        endcase

        fp_addsub1_mode = 0;
        fp_addsub1_in_a = abs_out_d1;
        fp_addsub1_in_b = l1_distance_ff;
    end
end

// Instance of DW_fp_addsub
DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
fp_addsub0_inst ( .a(fp_addsub0_in_a), .b(fp_addsub0_in_b), .rnd(3'b000),
.op(fp_addsub0_mode), .z(fp_addsub0_out), .status() );

// Instance of DW_fp_addsub
DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
fp_addsub1_inst( .a(fp_addsub1_in_a), .b(fp_addsub1_in_b), .rnd(3'b000),
.op(fp_addsub1_mode), .z(fp_addsub1_out), .status() );
//---------------------------------------------------------------------
//      CTRs
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
    # `C2Q;
    if(~rst_n)
    begin
        p_cur_st <= P_IDLE;
        mm_cur_st <= MM_IDLE;
    end
    else
    begin
        p_cur_st <= p_next_st;
        mm_cur_st <= mm_next_st;
    end
end

always @(posedge clk or negedge rst_n)
begin
    # `C2Q;
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

always @(*)
begin
    mm_next_st = mm_cur_st;
    case(mm_cur_st)
    MM_IDLE:
    begin
        // Needs to be replaced with delayed done signal
        if(convolution_done_f_d3) mm_next_st = MM_MAX_POOLING;
    end
    MM_MAX_POOLING:
    begin
        if(max_pooling_done_f) mm_next_st = MM_FC;
    end
    MM_FC:
    begin
        if(fc_done_f) mm_next_st = MM_NORM;
    end
    MM_NORM:
    begin
        if(norm_processed_f) mm_next_st = MM_ACT;
    end
    MM_ACT:
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
        if(convolution_done_f_d3)  mm_next_st = MM_MAX_POOLING;
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

//---------------------------------------------------------------------
//      KERNALS, IMGS, WEIGHTS
//---------------------------------------------------------------------


wire wr_boundary_reach_f = wr_img_yptr == 3 && ST_P_RD_DATA;
wire wr_channel_done_f   = wr_img_yptr == 3 && wr_img_xptr == 3 && ST_P_RD_DATA;
wire wr_img_done_f       = wr_channel_done_f && wr_img_channel_cnt == 2 && ST_P_RD_DATA;
wire wr_all_img_done_f   = wr_img_done_f && wr_img_num_cnt == 1 && ST_P_RD_DATA;

wire wr_kernal_bound_reach_f  = wr_kernal_yptr == 2  && ST_P_RD_DATA;
wire wr_kernal_done_f         = wr_kernal_yptr == 2 && wr_kernal_xptr == 2 && ST_P_RD_DATA;
wire wr_all_kernal_done_f     = wr_kernal_done_f && wr_kernal_num_cnt == 2 && ST_P_RD_DATA;

always @(posedge clk or negedge rst_n)
begin
    # `C2Q;
    if(~rst_n)
    begin
        for(i=0;i<3;i=i+1)
            for(j=0;j<3;j=j+1)
                for(k=0;k<3;k=k+1)
                    kernal_rf[i][j][k] <= 0;

        for(i=0;i<6;i=i+1)
            for(j=0;j<6;j=j+1)
                for(k=0;k<3;k=k+1)
                    for(c=0;c<2;c=c+1)
                        img_rf[i][j][k][c] <= 0;

        for(i=0;i<2;i=i+1)
            for(j=0;j<2;j=j+1)
                    weight_rf[i][j] <= 0;

        processing_f_ff <= 0;
        // Since padding, start from (1,1)
        wr_img_xptr <= 0;
        wr_img_yptr <= 0;
        wr_img_num_cnt <= 0;
        wr_img_channel_cnt <= 0;
        opt_ff <= 0;

        // Kernals
        wr_kernal_num_cnt <= 0;
        wr_kernal_yptr <= 0;
        wr_kernal_xptr <= 0;
        rd_cnt  <= 0;

    end
    else if(ST_P_IDLE)
    begin
        // Reading in images, kernals and weight_rf
        if(in_valid)
        begin
            if(Opt == 0 || Opt == 2)
            begin
                img_rf[0][0][0][0] <= Img;
                img_rf[0][1][0][0] <= Img;
                img_rf[1][0][0][0] <= Img;
                img_rf[1][1][0][0] <= Img;
            end
            else
            begin
                img_rf[1][1][0][0] <= Img;
            end

            kernal_rf[0][0][0] <= Kernel;
            weight_rf[0][0]    <= Weight;

            opt_ff <= Opt;
            wr_img_yptr <= wr_img_yptr + 1;
            wr_kernal_yptr <= wr_kernal_yptr + 1;
            rd_cnt <= rd_cnt + 1;
        end
        else if(ST_MM_DONE)
        begin
            for(i=0;i<3;i=i+1)
                for(j=0;j<3;j=j+1)
                    for(k=0;k<3;k=k+1)
                        kernal_rf[i][j][k] <= 0;

            for(i=0;i<6;i=i+1)
                for(j=0;j<6;j=j+1)
                    for(k=0;k<3;k=k+1)
                        for(c=0;c<2;c=c+1)
                            img_rf[i][j][k][c] <= 0;

            for(i=0;i<2;i=i+1)
                for(j=0;j<2;j=j+1)
                    weight_rf[i][j] <= 0;

            processing_f_ff <= 0;
            // Since padding, start from (1,1)
            wr_img_xptr <= 0;
            wr_img_yptr <= 0;
            wr_img_num_cnt <= 0;
            wr_img_channel_cnt <= 0;
            opt_ff <= 0;

            // Kernals
            wr_kernal_num_cnt <= 0;
            wr_kernal_yptr <= 0;
            wr_kernal_xptr <= 0;
            rd_cnt <= 0;
        end
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

        rd_cnt <= rd_cnt + 1;
        // Replication
        if(opt_ff == 0 || opt_ff == 2)
        begin
            if(wr_img_xptr == 0 && wr_img_yptr == 0)
            begin
                // (x,y,channel,img)
                img_rf[0][0][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
                img_rf[0][1][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
                img_rf[1][0][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
                img_rf[1][1][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
            end
            else if(wr_img_xptr == 0 && wr_img_yptr == IMG_SIZE-1)
            begin
                // (x,y,channel,img)
                img_rf[1][4][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
                img_rf[1][5][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
                img_rf[0][4][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
                img_rf[0][5][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
            end
            else if(wr_img_xptr == IMG_SIZE-1 && wr_img_yptr == 0)
            begin
                // (x,y,channel,img)
                img_rf[4][1][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
                img_rf[4][0][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
                img_rf[5][0][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
                img_rf[5][1][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
            end
            else if(wr_img_xptr == IMG_SIZE -1 && wr_img_yptr == IMG_SIZE-1)
            begin
                // (x,y,channel,img)
                img_rf[4][4][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
                img_rf[4][5][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
                img_rf[5][4][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
                img_rf[5][5][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
            end
            else if(wr_img_xptr == 0)
            begin
                img_rf[0][wr_img_yptr+1][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
                img_rf[1][wr_img_yptr+1][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
            end
            else if(wr_img_yptr == 0)
            begin
                img_rf[wr_img_xptr+1][0][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
                img_rf[wr_img_xptr+1][1][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
            end
            else if(wr_img_xptr == IMG_SIZE -1)
            begin
                img_rf[4][wr_img_yptr+1][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
                img_rf[5][wr_img_yptr+1][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
            end
            else if(wr_img_yptr == IMG_SIZE-1)
            begin
                img_rf[wr_img_xptr+1][4][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
                img_rf[wr_img_xptr+1][5][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
            end
            else
            begin
                img_rf[wr_img_xptr+1][wr_img_yptr+1][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
            end
        end
        else
        begin
            img_rf[wr_img_xptr+1][wr_img_yptr+1][wr_img_channel_cnt][wr_img_num_cnt] <= Img;
        end

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
        if(wr_all_kernal_done_f)
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

        // Start sending signals to MAC at 10th cycle while reading
        if(start_processing_f)
        begin
            processing_f_ff <= 1;
        end
    end
    else
    begin
        if(all_convolution_done_f)
            processing_f_ff <= 0;
    end
end

wire process_bound_reach_f = process_yptr == 3;

always @(posedge clk or negedge rst_n)
begin
    # `C2Q;
    if(~rst_n)
    begin
        process_xptr <= 0;
        process_yptr <= 0;
        kernal_num_cnt <= 0;
        img_num_cnt <= 0;
    end
    else if(ST_P_IDLE)
    begin
        process_xptr <= 0;
        process_yptr <= 0;
        kernal_num_cnt <= 0;
        img_num_cnt <= 0;
    end
    else if((ST_P_RD_DATA || ST_P_PROCESSING) && processing_f_ff)
    begin
        if(all_convolution_done_f)
        begin
            process_xptr <= 0;
            process_yptr <= 0;
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
//      PIPELINE DATAPATH
//---------------------------------------------------------------------
//==========================================
//   MAC Stage  3 SUM stage
//==========================================

wire[DATA_WIDTH-1:0] mac_outputs;

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

MAC#(
       .DATA_WIDTH      (DATA_WIDTH      ),
       .sig_width       (inst_sig_width       ),
       .exp_width       (inst_exp_width       ),
       .ieee_compliance (inst_ieee_compliance ),
       .en_ubr_flag     (en_ubr_flag     ),
       .inst_arch_type  (inst_arch  )
   )
   u_MAC1(
       .clk(clk),
       .rst_n(rst_n),
       .pixel0       (img_rf[row_00][col_00][kernal_num_cnt][img_num_cnt]),
       .pixel1       (img_rf[row_01][col_01][kernal_num_cnt][img_num_cnt]),
       .pixel2       (img_rf[row_02][col_02][kernal_num_cnt][img_num_cnt]),
       .pixel3       (img_rf[row_10][col_10][kernal_num_cnt][img_num_cnt]),
       .pixel4       (img_rf[row_11][col_11][kernal_num_cnt][img_num_cnt]),
       .pixel5       (img_rf[row_12][col_12][kernal_num_cnt][img_num_cnt]),
       .pixel6       (img_rf[row_20][col_20][kernal_num_cnt][img_num_cnt]),
       .pixel7       (img_rf[row_21][col_21][kernal_num_cnt][img_num_cnt]),
       .pixel8       (img_rf[row_22][col_22][kernal_num_cnt][img_num_cnt]),

       .kernal0      (kernal_rf[0][0][kernal_num_cnt]),
       .kernal1      (kernal_rf[0][1][kernal_num_cnt]),
       .kernal2      (kernal_rf[0][2][kernal_num_cnt]),
       .kernal3      (kernal_rf[1][0][kernal_num_cnt]),
       .kernal4      (kernal_rf[1][1][kernal_num_cnt]),
       .kernal5      (kernal_rf[1][2][kernal_num_cnt]),
       .kernal6      (kernal_rf[2][0][kernal_num_cnt]),
       .kernal7      (kernal_rf[2][1][kernal_num_cnt]),
       .kernal8      (kernal_rf[2][2][kernal_num_cnt]),
       .macResult_ff (mac_outputs)
   );

//---------------------------------------------------------------------
//      CONVOLUTION RESULTS
//---------------------------------------------------------------------
reg[DATA_WIDTH-1:0] convolution_result_rf[0:3][0:3][0:1];
wire[DATA_WIDTH-1:0] fp_accumulation_result;


always @(posedge clk or negedge rst_n)
begin
    # `C2Q;
    if(~rst_n)
    begin
        for(i=0;i<4;i=i+1)
            for(j=0;j<4;j=j+1)
                for(k=0;k<2;k=k+1)
                    convolution_result_rf[i][j][k] <= 0;
    end
    else if(ST_MM_DONE)
    begin
        for(i=0;i<4;i=i+1)
            for(j=0;j<4;j=j+1)
                for(k=0;k<2;k=k+1)
                    convolution_result_rf[i][j][k] <= 0;
    end
    else if(valid_d3)
    begin
       convolution_result_rf[process_xptr_d3][process_yptr_d3][img_num_cnt_d3] <= fp_accumulation_result;
    end
end

//---------------------------------------------------------------------
//      Convolution accumulator
//---------------------------------------------------------------------
DW_fp_add_inst
    #(
        .sig_width       (inst_sig_width       ),
        .exp_width       (inst_exp_width       ),
        .ieee_compliance (inst_ieee_compliance )
    )
    u_DW_fp_add_ACT2(
        .inst_a      (convolution_result_rf[process_xptr_d3][process_yptr_d3][img_num_cnt_d3]),
        .inst_b      (mac_outputs),
        .inst_rnd    (3'b000    ),
        .z_inst      ( fp_accumulation_result     ),
        .status_inst ( )
    );

//---------------------------------------------------------------------
//      MM DATAPATH
//---------------------------------------------------------------------


// mm_cnt delay lines
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        mm_cnt_d1 <= 0;
        mm_cnt_d2 <= 0;
    end
    else if(mm_cur_st != mm_next_st)
    begin
        mm_cnt_d1 <= 0;
        mm_cnt_d2 <= 0;
    end
    else
    begin
        mm_cnt_d1 <= mm_cnt;
        mm_cnt_d2 <= mm_cnt_d1;
    end
end
reg[DATA_WIDTH-1:0] fp_add0_FC_d2, fp_mult0_FC_d1, fp_mult1_FC_d1;


reg fc_valid_d1, fc_valid_d2;
reg act_valid_d1,act_valid_d2;

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
reg l1_valid_d1;
always @(posedge clk or negedge rst_n)
begin
    # `C2Q;
    if(~rst_n)
    begin
        for(i=0;i<2;i=i+1)
            for(j=0;j<2;j=j+1)
                max_pooling_result_rf[i][j] <= 0;

        for(i=0;i<4;i=i+1)
            fc_result_rf[i] <= 0;

        for(i=0;i<4;i=i+1)
            norm_result_rf[i] <= 0;

        for(i=0;i<4;i=i+1)
            for(j=0;j<2;j=j+1)
                activation_result_rf[i][j] <= 0;

        out_valid <= 0;
        out       <= 0;
        mm_cnt    <= 0;
        mm_img_cnt<=0;
        l1_distance_ff <= 0;
        min_max_diff_ff   <= 0;
        fc_valid_d1 <= 0;
        l1_valid_d1 <= 0;
    end
    else
    begin
        case(mm_cur_st)
        MM_IDLE:
        begin
            for(i=0;i<3;i=i+1)
                for(j=0;j<3;j=j+1)
                    max_pooling_result_rf[i][j] <= 0;

            for(i=0;i<4;i=i+1)
                fc_result_rf[i] <= 0;

            for(i=0;i<4;i=i+1)
                norm_result_rf[i] <= 0;

            for(i=0;i<4;i=i+1)
                for(j=0;j<2;j=j+1)
                    activation_result_rf[i][j] <= 0;

            out   <= 0;
            out_valid  <= 0;

            mm_cnt <= 0;
            mm_img_cnt <= 0;
            l1_distance_ff<= 0;
            min_max_diff_ff <= 0;
            fc_valid_d1 <= 0;
            act_valid_d1 <= 0;
            l1_valid_d1 <= 0;
        end
        MM_MAX_POOLING:
        begin
            mm_cnt <= max_pooling_done_f ? 0 : mm_cnt + 1;
            case(mm_cnt)
            'd0:
            begin
                if(fp_cmp_results[0][0])
                begin
                    max_pooling_result_rf[0][0] <= convolution_result_rf[0][0][mm_img_cnt];
                end
                else
                begin
                    max_pooling_result_rf[0][0] <= convolution_result_rf[0][1][mm_img_cnt];
                end

                if(fp_cmp_results[0][1])
                begin
                    max_pooling_result_rf[0][1] <= convolution_result_rf[0][2][mm_img_cnt];
                end
                else
                begin
                    max_pooling_result_rf[0][1] <= convolution_result_rf[0][3][mm_img_cnt];
                end

                if(fp_cmp_results[1][0])
                begin
                    max_pooling_result_rf[1][0] <= convolution_result_rf[2][0][mm_img_cnt];
                end
                else
                begin
                    max_pooling_result_rf[1][0] <= convolution_result_rf[2][1][mm_img_cnt];
                end

                if(fp_cmp_results[1][1])
                begin
                    max_pooling_result_rf[1][1] <= convolution_result_rf[2][2][mm_img_cnt];
                end
                else
                begin
                    max_pooling_result_rf[1][1] <= convolution_result_rf[2][3][mm_img_cnt];
                end
            end
            'd1:
            begin
                // Compare conv_result > max_pooling_result
                if(fp_cmp_results[0][0])
                begin
                    max_pooling_result_rf[0][0] <= convolution_result_rf[1][0][mm_img_cnt];
                end
                else
                begin
                    max_pooling_result_rf[0][0] <= max_pooling_result_rf[0][0];
                end

                if(fp_cmp_results[0][1])
                begin
                    max_pooling_result_rf[0][1] <= convolution_result_rf[1][2][mm_img_cnt];
                end
                else
                begin
                    max_pooling_result_rf[0][1] <= max_pooling_result_rf[0][1];
                end

                if(fp_cmp_results[1][0])
                begin
                    max_pooling_result_rf[1][0] <= convolution_result_rf[3][0][mm_img_cnt];
                end
                else
                begin
                    max_pooling_result_rf[1][0] <= max_pooling_result_rf[1][0];
                end

                if(fp_cmp_results[1][1])
                begin
                    max_pooling_result_rf[1][1] <= convolution_result_rf[3][2][mm_img_cnt];
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
                    max_pooling_result_rf[0][0] <= convolution_result_rf[1][1][mm_img_cnt];
                end
                else
                begin
                    max_pooling_result_rf[0][0] <= max_pooling_result_rf[0][0];
                end

                if(fp_cmp_results[0][1])
                begin
                    max_pooling_result_rf[0][1] <= convolution_result_rf[1][3][mm_img_cnt];
                end
                else
                begin
                    max_pooling_result_rf[0][1] <= max_pooling_result_rf[0][1];
                end

                if(fp_cmp_results[1][0])
                begin
                    max_pooling_result_rf[1][0] <= convolution_result_rf[3][1][mm_img_cnt];
                end
                else
                begin
                    max_pooling_result_rf[1][0] <= max_pooling_result_rf[1][0];
                end

                if(fp_cmp_results[1][1])
                begin
                    max_pooling_result_rf[1][1] <= convolution_result_rf[3][3][mm_img_cnt];
                end
                else
                begin
                    max_pooling_result_rf[1][1] <= max_pooling_result_rf[1][1];
                end
            end
            endcase
        end
        MM_FC:
        begin
            mm_cnt      <= fc_done_f ? 0 : (mm_cnt == 4 ? mm_cnt : mm_cnt + 1);
            fc_valid_d1 <= mm_cnt == 4 ? 0 : 1;

            if(fc_valid_d2)
            begin
                case(mm_cnt_d2)
                'd0:begin
                    fc_result_rf[0] <= fp_add0_FC_d2;
                end
                'd1:begin
                    fc_result_rf[1] <= fp_add0_FC_d2;
                end
                'd2:begin
                    fc_result_rf[2] <= fp_add0_FC_d2;
                end
                'd3:begin
                    fc_result_rf[3] <= fp_add0_FC_d2;
                end
                endcase
            end

        end
        MM_NORM:
        begin
            mm_cnt <= norm_processed_f ? 0 : ( (mm_cnt == 4) ? mm_cnt : mm_cnt + 1);
            norm_valid_d1 <= (mm_cnt == 4) ? 0 : 1;

            min_max_diff_ff  <= fp_addsub1_out;

            if(norm_valid_d1)
            begin
                case(mm_cnt_d1)
                'd0:
                begin
                    norm_result_rf[0] <= fp_div_out;
                end
                'd1:
                begin
                    norm_result_rf[1] <= fp_div_out;
                end
                'd2:
                begin
                    norm_result_rf[2] <= fp_div_out;
                end
                'd3:
                begin
                    norm_result_rf[3] <= fp_div_out;
                end
                endcase
            end

        end
        MM_ACT:
        begin
            mm_cnt <= activation_done_f ? 0 :((mm_cnt == 4) ? mm_cnt : mm_cnt + 1);
            act_valid_d1 <= (mm_cnt == 4) ? 0 : 1;

            if(act_valid_d2)
            begin
                case(mm_cnt_d2)
                'd0: activation_result_rf[0][mm_img_cnt] <= fp_div_out;
                'd1: activation_result_rf[1][mm_img_cnt] <= fp_div_out;
                'd2: activation_result_rf[2][mm_img_cnt] <= fp_div_out;
                'd3: activation_result_rf[3][mm_img_cnt] <= fp_div_out;
                endcase
            end
        end
        MM_WAIT_IMG1:
        begin
            if(convolution_done_f_d3)
            begin
                mm_img_cnt <= mm_img_cnt + 1;
                mm_cnt <= 0;
            end
        end
        MM_L1_DISTANCE:
        begin
            mm_cnt <= l1_distance_cal_f ?  0 :  ((mm_cnt == 4) ? mm_cnt : mm_cnt + 1);
            l1_valid_d1 <= mm_cnt == 4 ? 0 : 1;

            if(l1_valid_d1)
                l1_distance_ff <= fp_addsub1_out;
        end
        MM_DONE:
        begin
            for(i=0;i<3;i=i+1)
                for(j=0;j<3;j=j+1)
                    max_pooling_result_rf[i][j] <= 0;

            for(i=0;i<4;i=i+1)
                fc_result_rf[i] <= 0;

            for(i=0;i<4;i=i+1)
                norm_result_rf[i] <= 0;

            for(i=0;i<4;i=i+1)
                for(j=0;j<2;j=j+1)
                    activation_result_rf[i][j] <= 0;

            mm_cnt <= 0;
            mm_img_cnt <= 0;

            out <= l1_distance_ff;
            out_valid <= 1;
        end
        endcase
    end
end

//---------------------------------------------------------------------
//   MAX POOLING FP_CMP X4 and its input
//---------------------------------------------------------------------

// Find min max during fc calculation
always @(posedge clk or negedge rst_n)
begin
    # `C2Q;
    if(~rst_n)
    begin
        x_min_ff <= 0;
        x_max_ff <= 0;
    end
    else if(ST_MM_FC)
    begin
        if(fc_valid_d2)
        begin
            case(mm_cnt_d2)
            'd0:
            begin
                x_min_ff <= fp_add0_FC_d2;
                x_max_ff <= fp_add0_FC_d2;
            end
            default:
            begin
                if(~fp_cmp_results[0][0])
                    x_min_ff <= fp_add0_FC_d2;
                if(fp_cmp_results[0][1])
                    x_max_ff <= fp_add0_FC_d2;
            end
            endcase
        end
    end
end

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
            fp_cmp_input_a[0][0] = convolution_result_rf[0][0][mm_img_cnt];
            fp_cmp_input_a[0][1] = convolution_result_rf[0][2][mm_img_cnt];
            fp_cmp_input_a[1][0] = convolution_result_rf[2][0][mm_img_cnt];
            fp_cmp_input_a[1][1] = convolution_result_rf[2][2][mm_img_cnt];

            fp_cmp_input_b[0][0] = convolution_result_rf[0][1][mm_img_cnt];
            fp_cmp_input_b[0][1] = convolution_result_rf[0][3][mm_img_cnt];
            fp_cmp_input_b[1][0] = convolution_result_rf[2][1][mm_img_cnt];
            fp_cmp_input_b[1][1] = convolution_result_rf[2][3][mm_img_cnt];
        end
        'd1:
        begin
            fp_cmp_input_a[0][0] = convolution_result_rf[1][0][mm_img_cnt];
            fp_cmp_input_a[0][1] = convolution_result_rf[1][2][mm_img_cnt];
            fp_cmp_input_a[1][0] = convolution_result_rf[3][0][mm_img_cnt];
            fp_cmp_input_a[1][1] = convolution_result_rf[3][2][mm_img_cnt];

            fp_cmp_input_b[0][0] = max_pooling_result_rf[0][0];
            fp_cmp_input_b[0][1] = max_pooling_result_rf[0][1];
            fp_cmp_input_b[1][0] = max_pooling_result_rf[1][0];
            fp_cmp_input_b[1][1] = max_pooling_result_rf[1][1];
        end
        'd2:
        begin
            fp_cmp_input_a[0][0] = convolution_result_rf[1][1][mm_img_cnt];
            fp_cmp_input_a[0][1] = convolution_result_rf[1][3][mm_img_cnt];
            fp_cmp_input_a[1][0] = convolution_result_rf[3][1][mm_img_cnt];
            fp_cmp_input_a[1][1] = convolution_result_rf[3][3][mm_img_cnt];

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
        fp_cmp_input_a[0][0] = fp_add0_FC_d2;
        fp_cmp_input_b[0][0] = x_min_ff;

        // max
        fp_cmp_input_a[0][1] = fp_add0_FC_d2;
        fp_cmp_input_b[0][1] = x_max_ff;
    end
end

genvar idx,jdx;
generate
    for(idx = 0;idx<2;idx = idx+1)
        for(jdx = 0;jdx < 2;jdx=jdx+1)
        begin
            DW_fp_cmp_inst
                #(
                    .sig_width       (inst_sig_width),
                    .exp_width       (inst_exp_width),
                    .ieee_compliance (inst_ieee_compliance)
                )
                u_DW_fp_cmp_inst(
                    .inst_a         (  fp_cmp_input_a[idx][jdx]  ),
                    .inst_b         (  fp_cmp_input_b[idx][jdx]  ),
                    .inst_zctr      (           ),
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
DW_fp_mult_inst #(inst_sig_width,inst_exp_width,inst_ieee_compliance,en_ubr_flag)
                        u_DW_fp_mult_FC0(
                            .inst_a   (  fp_mult_fc_in_a[0]),
                            .inst_b   (  fp_mult_fc_in_b[0]),
                            .inst_rnd ( 3'b000              ),
                            .z_inst   (  fp_mult_FC_out[0]),
                            .status_inst  (   )
                        );
DW_fp_mult_inst #(inst_sig_width,inst_exp_width,inst_ieee_compliance,en_ubr_flag)
                        u_DW_fp_mult_FC1(
                            .inst_a   (   fp_mult_fc_in_a[1]),
                            .inst_b   (   fp_mult_fc_in_b[1]),
                            .inst_rnd ( 3'b000              ),
                            .z_inst   (  fp_mult_FC_out[1] ),
                            .status_inst  (   )
                        );

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        fp_add0_FC_d2 <= 0;
        fp_mult_fc_d1[0] <= 0;
        fp_mult_fc_d1[1] <= 0;
    end
    else
    begin
        fp_add0_FC_d2 <= fp_addsub0_out;
        fp_mult_fc_d1[0] <= fp_mult_FC_out[0];
        fp_mult_fc_d1[1] <= fp_mult_FC_out[1];
    end
end

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
end

//---------------------------------------------------------------------------------
//   Min Max normalization, DIV , 2x Subtractions = 2x ADDERS, share it with
//---------------------------------------------------------------------------------

always @(posedge clk or negedge rst_n)
begin
    # `C2Q;
    if(~rst_n)
    begin
        fp_norm_sub0_out_d1 <= 0;
    end
    else if(ST_MM_NORM)
    begin
        fp_norm_sub0_out_d1  <= fp_addsub0_out;
    end
end

always @(*)
begin
    fp_div_in_a = 0;
    fp_div_in_b = min_max_diff_ff;

    if(ST_MM_NORM)
    begin
        fp_div_in_a = fp_norm_sub0_out_d1;
    end

    if(ST_MM_ACT)
    begin
        if(opt_ff == 2 || opt_ff == 3)
        begin
            // tanh
            fp_div_in_a = fp_sub0_act_d2;
            fp_div_in_b = fp_add_act_d2;
        end
        else
        begin
            fp_div_in_a = FP_ONE;
            fp_div_in_b = fp_add_act_d2;
        end
    end
end


DW_fp_div_inst
    #(
        .sig_width       (inst_sig_width        ),
        .exp_width       (inst_exp_width       ),
        .ieee_compliance (inst_ieee_compliance ),
        .faithful_round  (faithful_round  ),
        .en_ubr_flag     (en_ubr_flag     )
    )
    u_DW_fp_div_0(
        .inst_a      (    fp_div_in_a ),
        .inst_b      (    fp_div_in_b  ),
        .inst_rnd    (3'b000    ),
        .z_inst      (  fp_div_out),
        .status_inst (  )
    );

//---------------------------------------------------------------------
//   Activation Sigmoid or tanh, 2 e^x and 1 Sub, 1 Add
//---------------------------------------------------------------------
always @(*) begin
    negation_in = 0;
    pos_exp_in  = 0;
    if(ST_MM_ACT)
    begin
        if(opt_ff == 0 || opt_ff == 1)
        begin
            // Sigmoid
            case(mm_cnt)
            'd0:begin
                negation_in = norm_result_rf[0];
            end
            'd1:begin
                negation_in = norm_result_rf[1];
            end
            'd2:begin
                negation_in = norm_result_rf[2];
            end
            'd3:begin
                negation_in = norm_result_rf[3];
            end
            endcase
        end
        else
        begin
            // tanh
            case(mm_cnt)
            'd0:begin
                negation_in = norm_result_rf[0];
                pos_exp_in  = norm_result_rf[0];
            end
            'd1:begin
                negation_in = norm_result_rf[1];
                pos_exp_in  = norm_result_rf[1];
            end
            'd2:begin
                negation_in = norm_result_rf[2];
                pos_exp_in  = norm_result_rf[2];
            end
            'd3:begin
                negation_in = norm_result_rf[3];
                pos_exp_in  = norm_result_rf[3];
            end
            endcase
        end
    end
end


always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
    begin
        fp_sub0_act_d2<=0;
        fp_add_act_d2 <=0;
        exp_pos_result_d1 <= 0;
        exp_neg_result_d1 <= 0;
        act_valid_d2 <= 0;
    end
    else
    begin
        act_valid_d2 <= act_valid_d1;
        exp_pos_result_d1 <= exp_pos_result;
        exp_neg_result_d1 <= exp_neg_result;

        if(ST_MM_ACT)
        begin
            if(opt_ff == 0 || opt_ff == 1)
            begin
                //sigmoid
                fp_add_act_d2<= fp_addsub1_out;
            end
            else
            begin
                //tanh
                fp_sub0_act_d2<= fp_addsub0_out;
                fp_add_act_d2 <=  fp_addsub1_out;
            end
        end
    end
end

DW_fp_exp_inst
    #(
        .inst_sig_width       (inst_sig_width       ),
        .inst_exp_width       (inst_exp_width       ),
        .inst_ieee_compliance (inst_ieee_compliance ),
        .inst_arch            (inst_arch            )
    )
    u_DW_fp_exp1(
        .inst_a      (negation      ),
        .z_inst      (exp_neg_result      ),
        .status_inst ( )
    );

DW_fp_exp_inst
    #(
        .inst_sig_width       (inst_sig_width       ),
        .inst_exp_width       (inst_exp_width       ),
        .inst_ieee_compliance (inst_ieee_compliance ),
        .inst_arch            (inst_arch            )
    )
    u_DW_fp_exp2(
        .inst_a      (pos_exp_in ),
        .z_inst      (exp_pos_result      ),
        .status_inst ( )
    );

//---------------------------------------------------------------------
//   L1 distance 1 SUB, 1 absolute, 1 ADD
//---------------------------------------------------------------------

always @(posedge clk or negedge rst_n)
begin:FP_ABS
    if(~rst_n)
    begin
        abs_out_d1 <= 0;
    end
    else if(fp_addsub0_out[31] == 1)
    begin
        abs_out_d1 <= {1'b0,fp_addsub0_out[30:0]};
    end
    else
    begin
        abs_out_d1 <= fp_addsub0_out;
    end
end

endmodule




 //---------------------------------------------------------------------
    //   Module Design
    //---------------------------------------------------------------------

    module MAC#(parameter DATA_WIDTH = 32,
                parameter sig_width = 23,
                parameter exp_width = 8,
                parameter ieee_compliance = 1,
                parameter en_ubr_flag = 0,
                parameter inst_arch_type = 2) (
        input clk,
        input rst_n,
        input[DATA_WIDTH-1:0] pixel0,
        input[DATA_WIDTH-1:0] pixel1,
        input[DATA_WIDTH-1:0] pixel2,
        input[DATA_WIDTH-1:0] pixel3,
        input[DATA_WIDTH-1:0] pixel4,
        input[DATA_WIDTH-1:0] pixel5,
        input[DATA_WIDTH-1:0] pixel6,
        input[DATA_WIDTH-1:0] pixel7,
        input[DATA_WIDTH-1:0] pixel8,

        input[DATA_WIDTH-1:0] kernal0,
        input[DATA_WIDTH-1:0] kernal1,
        input[DATA_WIDTH-1:0] kernal2,
        input[DATA_WIDTH-1:0] kernal3,
        input[DATA_WIDTH-1:0] kernal4,
        input[DATA_WIDTH-1:0] kernal5,
        input[DATA_WIDTH-1:0] kernal6,
        input[DATA_WIDTH-1:0] kernal7,
        input[DATA_WIDTH-1:0] kernal8,

        output reg[DATA_WIDTH-1:0] macResult_ff

    );
integer i;
genvar idx;
genvar jdx;

wire[DATA_WIDTH-1:0] pixels[0:8];
wire[DATA_WIDTH-1:0] kernals[0:8];
wire[DATA_WIDTH-1:0] mults_result[0:8];
wire[DATA_WIDTH-1:0] partial_sum[0:2];
wire[DATA_WIDTH-1:0] mac_result;
reg[DATA_WIDTH-1:0]  mults_result_pipe[0:8];
reg[DATA_WIDTH-1:0] partial_sum_pipe[0:2];

assign pixels[0] = pixel0;
assign pixels[1] = pixel1;
assign pixels[2] = pixel2;
assign pixels[3] = pixel3;
assign pixels[4] = pixel4;
assign pixels[5] = pixel5;
assign pixels[6] = pixel6;
assign pixels[7] = pixel7;
assign pixels[8] = pixel8;

assign kernals[0] = kernal0;
assign kernals[1] = kernal1;
assign kernals[2] = kernal2;
assign kernals[3] = kernal3;
assign kernals[4] = kernal4;
assign kernals[5] = kernal5;
assign kernals[6] = kernal6;
assign kernals[7] = kernal7;
assign kernals[8] = kernal8;

generate
    for(idx = 0; idx < 9 ; idx = idx+1)
    begin:PARRALLEL_MULTS
        DW_fp_mult_inst #(sig_width,exp_width,ieee_compliance,en_ubr_flag)
                        u_DW_fp_mult_inst(
                            .inst_a   ( pixels[idx]         ),
                            .inst_b   ( kernals[idx]        ),
                            .inst_rnd ( 3'b000              ),
                            .z_inst   ( mults_result[idx]   ),
                            .status_inst  (   )
                        );
    end
endgenerate

always @(posedge clk or negedge rst_n)
begin
    #`C2Q;
    if(~rst_n)
    begin
        for(i=0;i<9;i=i+1)
        begin
            mults_result_pipe[i] <= 0;
        end
    end
    else
    begin
        for(i=0;i<9;i=i+1)
        begin
            mults_result_pipe[i] <= mults_result[i];
        end
    end
end

// 3x 3 inputs fp adders
DW_fp_sum3_inst #(sig_width,exp_width,ieee_compliance,inst_arch_type)
                u_DW_fp_sum3_inst1(
                    .inst_a   ( mults_result_pipe[0]),
                    .inst_b   ( mults_result_pipe[1]),
                    .inst_c   ( mults_result_pipe[2]   ),
                    .inst_rnd ( 3'b000 ),
                    .z_inst   ( partial_sum[0]   ),
                    .status_inst  (   )
                );

DW_fp_sum3_inst #(sig_width,exp_width,ieee_compliance,inst_arch_type)
                u_DW_fp_sum3_inst2(
                    .inst_a   ( mults_result_pipe[3]),
                    .inst_b   ( mults_result_pipe[4]),
                    .inst_c   ( mults_result_pipe[5]   ),
                    .inst_rnd ( 3'b000 ),
                    .z_inst   ( partial_sum[1]),
                    .status_inst  (   )
                );

DW_fp_sum3_inst #(sig_width,exp_width,ieee_compliance,inst_arch_type)
                u_DW_fp_sum3_inst3(
                    .inst_a   ( mults_result_pipe[6]),
                    .inst_b   ( mults_result_pipe[7]),
                    .inst_c   ( mults_result_pipe[8]   ),
                    .inst_rnd ( 3'b000 ),
                    .z_inst   ( partial_sum[2]),
                    .status_inst  (   )
                );

always @(posedge clk or negedge rst_n) begin
    # `C2Q;
    if(~rst_n)
    begin
        for(i=0;i<3;i=i+1)
        begin
           partial_sum_pipe[i] <= 0;
        end
    end
    else
    begin
        for(i=0;i<3;i=i+1)
        begin
            partial_sum_pipe[i]<=partial_sum[i];
        end
    end
end


// 3 input fp adders
DW_fp_sum3_inst #(sig_width,exp_width,ieee_compliance,inst_arch_type)
                u_DW_fp_sum3_inst(
                    .inst_a   ( partial_sum_pipe[0]),
                    .inst_b   ( partial_sum_pipe[1]),
                    .inst_c   ( partial_sum_pipe[2]   ),
                    .inst_rnd ( 3'b000 ),
                    .z_inst   ( mac_result  ),
                    .status_inst  (   )
                );

// Ouput buffer
always @(posedge clk or negedge rst_n)
begin
    //synopsys_translate_off
    # `C2Q;
    //synopsys_translate_on
    if(~rst_n)
    begin
        macResult_ff <= 0;
    end
    else
    begin
        macResult_ff <= mac_result;
    end
end

endmodule

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

    module DW_fp_sum3_inst( inst_a, inst_b, inst_c, inst_rnd, z_inst,
                            status_inst );

parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;

input [inst_sig_width+inst_exp_width : 0] inst_a;
input [inst_sig_width+inst_exp_width : 0] inst_b;
input [inst_sig_width+inst_exp_width : 0] inst_c;
input [2 : 0] inst_rnd;
output [inst_sig_width+inst_exp_width : 0] z_inst;
output [7 : 0] status_inst;
// Instance of DW_fp_sum3
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
           U1 (
               .a(inst_a),
               .b(inst_b),
               .c(inst_c),
               .rnd(inst_rnd),
               .z(z_inst),
               .status(status_inst) );
endmodule

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


    module DW_fp_div_inst( inst_a, inst_b, inst_rnd, z_inst, status_inst );
parameter sig_width = 23;
parameter exp_width = 8;
parameter ieee_compliance = 0;
parameter faithful_round = 0;
parameter en_ubr_flag = 0;

input [sig_width+exp_width : 0] inst_a;
input [sig_width+exp_width : 0] inst_b;
input [2 : 0] inst_rnd;
output [sig_width+exp_width : 0] z_inst;
output [7 : 0] status_inst;
// Instance of DW_fp_div
DW_fp_div #(sig_width, exp_width, ieee_compliance, faithful_round, en_ubr_flag) U1
          ( .a(inst_a), .b(inst_b), .rnd(inst_rnd), .z(z_inst), .status(status_inst)
          );
endmodule


    module DW_fp_cmp_inst( inst_a, inst_b, inst_zctr, aeqb_inst, altb_inst,
                           agtb_inst, unordered_inst, z0_inst, z1_inst, status0_inst,
                           status1_inst );
parameter sig_width = 23;
parameter exp_width = 8;
parameter ieee_compliance = 0;
input [sig_width+exp_width : 0] inst_a;
input [sig_width+exp_width : 0] inst_b;
input inst_zctr;
output aeqb_inst;
output altb_inst;
output agtb_inst;
output unordered_inst;
output [sig_width+exp_width : 0] z0_inst;
output [sig_width+exp_width : 0] z1_inst;
output [7 : 0] status0_inst;
output [7 : 0] status1_inst;
// Instance of DW_fp_cmp
DW_fp_cmp #(sig_width, exp_width, ieee_compliance)
          U1 ( .a(inst_a), .b(inst_b), .zctr(inst_zctr), .aeqb(aeqb_inst),
               .altb(altb_inst), .agtb(agtb_inst), .unordered(unordered_inst),
               .z0(z0_inst), .z1(z1_inst), .status0(status0_inst),
               .status1(status1_inst) );
endmodule

    module DW_fp_add_inst( inst_a, inst_b, inst_rnd, z_inst, status_inst );
parameter sig_width = 23;
parameter exp_width = 8;
parameter ieee_compliance = 0;
input [sig_width+exp_width : 0] inst_a;
input [sig_width+exp_width : 0] inst_b;
input [2 : 0] inst_rnd;
output [sig_width+exp_width : 0] z_inst;
output [7 : 0] status_inst;
// Instance of DW_fp_add
DW_fp_add #(sig_width, exp_width, ieee_compliance)
          U1 ( .a(inst_a), .b(inst_b), .rnd(inst_rnd), .z(z_inst), .status(status_inst) );
endmodule


    module DW_fp_sub_inst( inst_a, inst_b, inst_rnd, z_inst, status_inst );
parameter sig_width = 23;
parameter exp_width = 8;
parameter ieee_compliance = 0;
input [sig_width+exp_width : 0] inst_a;
input [sig_width+exp_width : 0] inst_b;
input [2 : 0] inst_rnd;
output [sig_width+exp_width : 0] z_inst;
output [7 : 0] status_inst;
// Instance of DW_fp_sub
DW_fp_sub #(sig_width, exp_width, ieee_compliance)
          U1 ( .a(inst_a), .b(inst_b), .rnd(inst_rnd), .z(z_inst), .status(status_inst) );
endmodule

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