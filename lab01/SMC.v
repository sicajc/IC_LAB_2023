// Final Version
module SMC(
           // Input signals
           mode,
           W_0, V_GS_0, V_DS_0,
           W_1, V_GS_1, V_DS_1,
           W_2, V_GS_2, V_DS_2,
           W_3, V_GS_3, V_DS_3,
           W_4, V_GS_4, V_DS_4,
           W_5, V_GS_5, V_DS_5,
           // Output signals
           out_n
       );

//================================================================
//   INPUT AND OUTPUT DECLARATION
//================================================================
input [2:0] W_0, V_GS_0, V_DS_0;
input [2:0] W_1, V_GS_1, V_DS_1;
input [2:0] W_2, V_GS_2, V_DS_2;
input [2:0] W_3, V_GS_3, V_DS_3;
input [2:0] W_4, V_GS_4, V_DS_4;
input [2:0] W_5, V_GS_5, V_DS_5;
input [1:0] mode;
output reg [7:0] out_n;


//================================================================
//   PARAMETERS
//================================================================

localparam DATA_WIDTH     = 3;
localparam NUM_OF_ELEMENT = 6;

localparam GM_ID_WIDTH    = 8;

integer idx;

reg[DATA_WIDTH-1:0] width_W[0:NUM_OF_ELEMENT-1];
reg[DATA_WIDTH-1:0] vgs[0:NUM_OF_ELEMENT-1];
reg[DATA_WIDTH-1:0] vds[0:NUM_OF_ELEMENT-1];
reg[GM_ID_WIDTH-1:0] gm_id_result[0:NUM_OF_ELEMENT-1];


always @(*)
begin:INPUTS_ARRAY
    width_W[0] = W_0;
    width_W[1] = W_1;
    width_W[2] = W_2;
    width_W[3] = W_3;
    width_W[4] = W_4;
    width_W[5] = W_5;

    vgs[0] =    V_GS_0;
    vgs[1] =    V_GS_1;
    vgs[2] =    V_GS_2;
    vgs[3] =    V_GS_3;
    vgs[4] =    V_GS_4;
    vgs[5] =    V_GS_5;

    vds[0] =    V_DS_0;
    vds[1] =    V_DS_1;
    vds[2] =    V_DS_2;
    vds[3] =    V_DS_3;
    vds[4] =    V_DS_4;
    vds[5] =    V_DS_5;
end

//===============================
//   ID GM Calculation
//===============================
localparam D_SUB_ONE       = 6;
localparam SORTERS_WIDTH   = 7;
localparam DIV_WIDTH       = 8;

reg[D_SUB_ONE-1        :0] D_sub_one[0:NUM_OF_ELEMENT-1];
reg[DIV_WIDTH-1        :0] div_result[0:NUM_OF_ELEMENT-1];
reg[DIV_WIDTH-1:0]         div_input[0:NUM_OF_ELEMENT-1];

localparam  MULT_IN_WIDTH     = 6;
localparam  MULT_RESULT_WIDTH = 8;
reg[MULT_IN_WIDTH-1:0]           mult1_one[0:NUM_OF_ELEMENT-1];
reg[MULT_IN_WIDTH-1:0]           mult2_one[0:NUM_OF_ELEMENT-1];
reg[MULT_RESULT_WIDTH-1:0]       mult_result_one[0:NUM_OF_ELEMENT-1];

reg[MULT_IN_WIDTH-1:0]           mult1_two[0:NUM_OF_ELEMENT-1];
reg[MULT_IN_WIDTH-1:0]           mult2_two[0:NUM_OF_ELEMENT-1];
reg[MULT_RESULT_WIDTH-1:0]       mult_result_two[0:NUM_OF_ELEMENT-1];

localparam SHIFTER_WIDTH       = 8;
localparam SHIFTER_IN_WIDTH    = 8;
reg[SHIFTER_IN_WIDTH-1:0]    shifter_in[0:NUM_OF_ELEMENT-1];
reg[SHIFTER_WIDTH-1:0] shifted_value[0:NUM_OF_ELEMENT-1];

always @(*)
begin // Shall only have 6 div/3 here
    for(idx=0;idx<NUM_OF_ELEMENT;idx=idx+1)
    begin
        //Variables initilization
        D_sub_one[idx] = vgs[idx] - 1;

        // 6 DIVs
        div_result[idx]= div_input[idx] / 3;

        // 12 MULTs
        mult_result_one[idx] = mult1_one[idx] * mult2_one[idx];
        mult_result_two[idx] = mult1_two[idx] * mult2_two[idx];

        // 1 shifter
        shifted_value[idx] = 2 * shifter_in[idx];

        // Initialization
        mult1_one[idx] = 0;

        mult2_one[idx] = 0;
        mult1_two[idx] = 0;
        mult2_two[idx] = 0;
        shifter_in[idx] = 0;
        div_input[idx]  = 1;

        if(D_sub_one[idx] > vds[idx]) // Triode
        begin
            if(mode[0])
            begin
                //id
                // Vds x W
                mult1_one[idx] = vds[idx];
                mult2_one[idx] = width_W[idx];

                // 2 x vgs
                shifter_in[idx] = vgs[idx];

                // A = (Vds x W) x (2 x vgs - vds - 2)
                mult1_two[idx] = mult_result_one[idx];
                mult2_two[idx] = (shifted_value[idx] - vds[idx] - 2);

                //  A/3
                div_input[idx] = mult_result_two[idx];

                gm_id_result[idx] = div_result[idx];
            end
            else
            begin
                //gm
                // B = W x Vds
                mult1_one[idx] = width_W[idx];
                mult2_one[idx] = vds[idx];

                // 2 x B = C
                shifter_in[idx] = mult_result_one[idx];

                // C/3
                div_input[idx] = shifted_value[idx];

                gm_id_result[idx] = div_result[idx];
            end
        end
        else
        begin // Saturation
            if(mode[0])
            begin//id
                // W x (Vgs-1) = C
                mult1_one[idx] = width_W[idx];
                mult2_one[idx] = D_sub_one[idx];

                // C x (Vgs-1) = D
                mult1_two[idx] = mult_result_one[idx];
                mult2_two[idx] = D_sub_one[idx];

                //  D / 3
                div_input[idx] = mult_result_two[idx];

                gm_id_result[idx] = div_result[idx];
            end
            else
            begin
                //gm
                // W x (Vgs-1) = A
                mult1_one[idx] = width_W[idx];
                mult2_one[idx] = D_sub_one[idx];

                // A x 2 = D
                shifter_in[idx] = mult_result_one[idx];

                // D / 3
                div_input[idx] = shifted_value[idx];

                gm_id_result[idx] = div_result[idx];
            end
        end
    end
end


//===============================
//   6 inputs BITONIC SORTERS
//===============================
reg [SORTERS_WIDTH-1:0] stage_zero[0:NUM_OF_ELEMENT-1];
reg [SORTERS_WIDTH-1:0] stage_one[0:NUM_OF_ELEMENT-1];
reg [SORTERS_WIDTH-1:0] stage_two[0:NUM_OF_ELEMENT-1];
reg [SORTERS_WIDTH-1:0] stage_three[0:NUM_OF_ELEMENT-1];
reg [SORTERS_WIDTH-1:0] stage_four[0:NUM_OF_ELEMENT-1];
reg [SORTERS_WIDTH-1:0] stage_five[0:NUM_OF_ELEMENT-1];
reg [SORTERS_WIDTH-1:0] stage_six[0:NUM_OF_ELEMENT-1];
reg [SORTERS_WIDTH-1:0] stage_seven[0:NUM_OF_ELEMENT-1];
reg [SORTERS_WIDTH-1:0] sorted_results[0:NUM_OF_ELEMENT-1];

always @(*)
begin:BITONIC_SORT
    // Initilize value for all the variables
    // stage 0
    for(idx=0;idx<NUM_OF_ELEMENT;idx=idx+1)
    begin
        stage_zero[idx]   = gm_id_result[idx];
    end

    stage_zero[1] = (gm_id_result[1]>gm_id_result[5]) ? gm_id_result[1]:
              gm_id_result[5];

    stage_zero[5] = (gm_id_result[1]>gm_id_result[5]) ? gm_id_result[5]:
              gm_id_result[1];

    stage_zero[0] = (gm_id_result[0]>gm_id_result[4]) ? gm_id_result[0]:
              gm_id_result[4];

    stage_zero[4] = (gm_id_result[0]>gm_id_result[4]) ? gm_id_result[4]:
              gm_id_result[0];

    //stage 1
    for(idx=0;idx<NUM_OF_ELEMENT;idx=idx+1)
    begin
        stage_one[idx]   = stage_zero[idx];
    end

    stage_one[3] = (stage_zero[3]>stage_zero[5]) ? stage_zero[3]:
             stage_zero[5];

    stage_one[5] = (stage_zero[3]>stage_zero[5]) ? stage_zero[5]:
             stage_zero[3];

    stage_one[2] = (stage_zero[2]>stage_zero[4]) ? stage_zero[2]:
             stage_zero[4];

    stage_one[4] = (stage_zero[2]>stage_zero[4]) ? stage_zero[4]:
             stage_zero[2];

    //stage 2
    for(idx=0;idx<NUM_OF_ELEMENT;idx=idx+1)
    begin
        stage_two[idx]   = stage_one[idx];
    end

    stage_two[1] = (stage_one[1]>stage_one[3]) ? stage_one[1]:
             stage_one[3];

    stage_two[3] = (stage_one[1]>stage_one[3]) ? stage_one[3]:
             stage_one[1];

    stage_two[0] = (stage_one[0]>stage_one[2]) ? stage_one[0]:
             stage_one[2];

    stage_two[2] = (stage_one[0]>stage_one[2]) ? stage_one[2]:
             stage_one[0];

    //stage 3
    for(idx=0;idx<NUM_OF_ELEMENT;idx=idx+1)
    begin
        stage_three[idx]   = stage_two[idx];
    end

    stage_three[0] = (stage_two[0]>stage_two[1]) ? stage_two[0]:
               stage_two[1];

    stage_three[1] = (stage_two[0]>stage_two[1]) ? stage_two[1]:
               stage_two[0];

    stage_three[2] = (stage_two[2]>stage_two[3]) ? stage_two[2]:
               stage_two[3];

    stage_three[3] = (stage_two[2]>stage_two[3]) ? stage_two[3]:
               stage_two[2];

    stage_three[4] = (stage_two[4]>stage_two[5]) ? stage_two[4]:
               stage_two[5];

    stage_three[5] = (stage_two[4]>stage_two[5]) ? stage_two[5]:
               stage_two[4];

    //stage 4
    for(idx=0;idx<NUM_OF_ELEMENT;idx=idx+1)
    begin
        stage_four[idx]   = stage_three[idx];
    end

    stage_four[1] = (stage_three[1]>stage_three[4]) ? stage_three[1]:
              stage_three[4];

    stage_four[4] = (stage_three[1]>stage_three[4]) ? stage_three[4]:
              stage_three[1];

    //stage 5
    for(idx=0;idx<NUM_OF_ELEMENT;idx=idx+1)
    begin
        stage_five[idx]   = stage_four[idx];
    end

    stage_five[1] = (stage_four[1]>stage_four[2]) ? stage_four[1]:
              stage_four[2];

    stage_five[2] = (stage_four[1]>stage_four[2]) ? stage_four[2]:
              stage_four[1];

    stage_five[3] = (stage_four[3]>stage_four[4]) ? stage_four[3]:
              stage_four[4];

    stage_five[4] = (stage_four[3]>stage_four[4]) ? stage_four[4]:
              stage_four[3];

    for(idx=0;idx<NUM_OF_ELEMENT;idx=idx+1)
    begin
        sorted_results[idx] = stage_five[idx];
    end
end

//===============================
//   CALCULATE & OUTPUT
//===============================
// Should only have 1  div/3 here
always @(*)
begin
    case(mode)
        2'b00:
        begin
            out_n = ((sorted_results[3]+sorted_results[4])+sorted_results[5])/3;
        end
        2'b01:
        begin
            out_n = ((((2 * sorted_results[3])+sorted_results[3]) + (4 * sorted_results[4]) +
                      (4 * sorted_results[5]) + sorted_results[5])/4)/3;
        end
        2'b10:
        begin
            out_n = (((sorted_results[0]+sorted_results[1])+sorted_results[2]))/3;
        end
        2'b11:
        begin
            out_n = ((((2 * sorted_results[0])+sorted_results[0]) + (4 * sorted_results[1]) +
                      (4 * sorted_results[2]) + sorted_results[2])/4)/3;
        end
        default:
        begin
            out_n = 0;
        end
    endcase
end
endmodule