// Baseline :                   320,000
// Extract DIV          out from mode 0: 229,874
// Extract MULTS of              mode 0: 217443.444072
// Sharing mults of first stage of mode1 and mode2 with mode0: 237000
// Use only 1 DIV and 1 MULT
// in mode0 by calculating xr early on when doing boundary check: 181000
// Modify mode2 regrouping terms, remove xl_ff: 180833
// Removing resets for datapath components, change state encoding scheme: 178338.28
// Removing redundants logics : 178152
// Change signed division into unsigned division:162880
// Adjust bit width, change absolute value into unsigned/2 : 153080
// Change signed multipliers into unsigned ones by rewriting equations of mode0 and mode2: 152029
// Share multiplier with mode0,mode1,mode2 : 147196
// A_sqr, b_sqr signed mults to unsigned mults : 139499.238384
// Sharing mode1,mode2 signed multipliers : 135763
// 6 bit only in mode1:126955.383797
// Stealing cycle to compute mode1 from read_data stage, dff to be seems largers:114494
// Removing cnts away , replace with y_ptr : 113470
// Datapath components reset removed, Last version: 113114

module CC(
           //Input Port
           clk,
           rst_n,
           in_valid,
           mode,
           xi,
           yi,

           //Output Port
           out_valid,
           xo,
           yo
       );

input               clk, rst_n, in_valid;
input       [1:0]   mode;
input       [7:0]   xi, yi;

output reg          out_valid;
output reg  [7:0]   xo, yo;
//==============================================//
//             Parameter and Integer            //
//==============================================//
localparam  DIV_LENGTH   = 8;
localparam  DATA_WIDTH   = 8;
localparam  DIV_IN   = 18;

parameter   MULTS_INPUT = 9;
parameter   MULTS_OUT = 17;

localparam R_SQR_BITS = 13;
localparam D_SQR_BITS = 24;
localparam ABS_RESULT_BITS = 17;
localparam CROSS_ADD_BITS = 18;
localparam AB_SQR_BITS = 13;





//==============================================//
//            FSM State Declaration             //
//==============================================//
reg[2:0] currentState, nextState;

localparam IDLE                     = 3'd0;
localparam RD_DATA                  = 3'd1;
localparam OUT_FIRST_POINT          = 3'd2;
localparam MODE0                    = 3'd3;
localparam MODE1                    = 3'd4;
localparam MODE2                    = 3'd5;

wire state_IDLE                      = currentState == IDLE;
wire state_RD_DATA                   = currentState == RD_DATA;
wire state_OUTPUT_FIRST_POINT        = currentState == OUT_FIRST_POINT;
wire state_MODE0                     = currentState == MODE0;
wire state_MODE1                     = currentState == MODE1;
wire state_MODE2                     = currentState == MODE2;

//==============================================//
//                 reg declaration              //
//==============================================//
reg signed[DATA_WIDTH-1:0] a1,a2,b1,b2,c1,c2,d1,d2;
reg signed[5:0] a1_m1,a2_m1,b1_m1,b2_m1,c1_m1,c2_m1,d1_m1,d2_m1;

reg signed[DATA_WIDTH-1:0] xul,xur,xdl,xdr;
reg signed[DATA_WIDTH-1:0] xr,xl,xr_ff;
reg signed[DATA_WIDTH-1:0] yu,yd;


reg signed[DATA_WIDTH-1:0] x_ff[0:3];
reg signed[DATA_WIDTH-1:0] y_ff[0:3];

reg signed[7:0] x_ptr,y_ptr;
reg rd_data_done_d;

reg[1:0] mode1_result;
reg[DATA_WIDTH*2-1:0] mode2_result;
reg[1:0] mode_ff;

localparam MODE0_DIV_IN0 = 16;
localparam MODE0_DIV_IN1 = 8;
localparam MODE0_DIV_LENGTH = 8;

localparam MODE0_MULT0_IN0 = 9;
localparam MODE0_MULT0_IN1 = 9;
localparam MODE0_MULT0_LENGTH = 17;

localparam MODE1_MULT0_IN0 = 9;
localparam MODE1_MULT0_IN1 = 9;
localparam MODE1_MULT0_LENGTH = 17;

reg signed[MODE0_MULT0_IN0-1:0]   mode0_mult0_in0;
reg signed[MODE0_MULT0_IN1-1:0]   mode0_mult0_in1;
reg signed[MODE0_MULT0_LENGTH-1:0] mode0_mult0_out;

reg signed[MODE1_MULT0_IN0-1:0]   mode1_mult0_in0;
reg signed[MODE1_MULT0_IN1-1:0]   mode1_mult0_in1;
reg signed[MODE1_MULT0_LENGTH-1:0] mode1_mult0_out;

reg xul_gt_xdl;
reg xur_gt_xdr;
reg signed[DATA_WIDTH:0] xul_xdl_sub;
reg signed[DATA_WIDTH:0] xdr_xur_sub;
reg signed[DATA_WIDTH:0] yu_sub_yd;
reg signed[DATA_WIDTH:0] xdl_sub_xul;
reg signed[DATA_WIDTH:0] xur_sub_xdr;

reg[AB_SQR_BITS-1:0] ab_sqr;

reg signed[AB_SQR_BITS-1:0] ab_sqr_ff;
reg signed[12:0]  d_sqr_first_term_ff;

reg [R_SQR_BITS-1:0] r_square;
reg [D_SQR_BITS-1:0] d_square;

reg [ABS_RESULT_BITS-1:0] abs_result;
reg signed[CROSS_ADD_BITS-1:0] cross_add;
// Using unsigned division, since the upper and lower are always positive
reg [MODE0_DIV_IN0-1:0]   mode0_div0_in0;
reg [MODE0_DIV_IN1-1:0]   mode0_div0_in1;
reg [MODE0_DIV_LENGTH-1:0] mode0_div0_out;

//==============================================//
//                 flags                        //
//==============================================//
wire read_done_f                = y_ptr == 3;
wire rendering_done_f           = y_ptr == yu & x_ptr == xur;
// Combinational loop exists here
reg  right_bound_reach_d;
wire right_bound_reach_f        =  ~right_bound_reach_d && x_ptr == xr_ff;
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        right_bound_reach_d <= 0 ;
    end
    else
    begin
        right_bound_reach_d <= right_bound_reach_f;
    end
end

//==============================================//
//             Current State Block              //
//==============================================//
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        currentState <= IDLE;
    end
    else
    begin
        currentState <= nextState;
    end
end

//==============================================//
//              Next State Block                //
//==============================================//
always @(*)
begin: NXT_STATE
    nextState = currentState;
    case (currentState)
        IDLE:
        begin
            nextState            = in_valid ? RD_DATA : IDLE;
        end
        RD_DATA :
        begin
            if(read_done_f)
            begin
                case(mode_ff)
                    'd0:
                    begin
                        nextState = (mode_ff == 0) ? OUT_FIRST_POINT: currentState;
                    end
                    'd1:
                    begin
                        nextState = (mode_ff == 1) ? MODE1: currentState;
                    end
                    'd2:
                    begin
                        nextState = (mode_ff == 2) ? MODE2: currentState;
                    end
                endcase
            end
        end
        OUT_FIRST_POINT:
        begin
            // Sends outs the first point of the quadrallateral
            nextState = MODE0;
        end
        MODE0:
        begin
            if(rendering_done_f)
            begin
                nextState = IDLE;
            end
        end
        MODE1:
        begin
            nextState            = IDLE;
        end
        MODE2:
        begin
            nextState            = IDLE;
        end
    endcase
end

// integer i;
wire read_data = state_RD_DATA || state_IDLE;
always @(posedge clk)
begin
    if(read_data)
    begin
        if(in_valid)
        begin
            mode_ff <= mode;
            x_ff[y_ptr] <= xi;
            y_ff[y_ptr] <= yi;
        end
    end
end


always @(*)
begin
    xul = x_ff[0];
    xur = x_ff[1];
    xdl = x_ff[2];
    xdr = x_ff[3];

    yu = y_ff[0];
    yd = y_ff[2];

    a1 = x_ff[0];
    a2 = y_ff[0];
    b1 = x_ff[1];
    b2 = y_ff[1];
    c1 = x_ff[2];
    c2 = y_ff[2];
    d1 = x_ff[3];
    d2 = y_ff[3];

    a1_m1 = x_ff[0];
    a2_m1 = y_ff[0];
    b1_m1 = x_ff[1];
    b2_m1 = y_ff[1];
    c1_m1 = x_ff[2];
    c2_m1 = y_ff[2];
    d1_m1 = x_ff[3];
    d2_m1 = y_ff[3];
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        x_ptr <= 0;
        y_ptr <= 0;
        xr_ff <= 0;
        // ab_sqr_ff <= 0;
        // d_sqr_first_term_ff <= 0;
    end
    else if(state_RD_DATA || state_IDLE)
    begin
        if(read_done_f)
        begin
            y_ptr <= 0;
        end
        else if(in_valid)
        begin
            y_ptr <= y_ptr + 1;
        end

        case(y_ptr)
            'd2:
                ab_sqr_ff           <= mode0_mult0_out - mode1_mult0_out;
            'd3:
                d_sqr_first_term_ff <= mode0_mult0_out - mode1_mult0_out;
        endcase
    end
    else
    begin
        case({state_OUTPUT_FIRST_POINT,state_MODE0})
            2'b10:
            begin
                x_ptr <= xdl + 1;
                y_ptr <= yd;
                xr_ff <= xdr;
            end
            2'b01:
            begin
                x_ptr <= ~right_bound_reach_d & right_bound_reach_f ? xl        : x_ptr + 1;
                y_ptr <= rendering_done_f ? 0 : (right_bound_reach_f ? y_ptr + 1 : y_ptr);
                xr_ff <= right_bound_reach_d ? xr        : xr_ff;
            end
            default:
            begin
                x_ptr <= x_ptr;
                y_ptr <= y_ptr;
            end
        endcase
    end
end

always @(*)
begin
    // Rewrite the equations s.t. only unsigned mults and div be used!
    d_square     = 0;
    r_square     = 0;
    mode1_result = 0;
    cross_add    = 0;
    abs_result   = 0;
    mode2_result = 0;
    xl           = 0;
    xr           = 0;

    // 1 unsigned DIV
    mode0_div0_out = mode0_div0_in0 / mode0_div0_in1;

    mode0_div0_in0 = 0;
    mode0_div0_in1 = 1;

    // 1 MULTS
    // Notice since we only have ++ or -- here
    // Unsigned multipliers can be used here with some arrangements, -- simply take two's complement
    mode0_mult0_out = mode0_mult0_in0 * mode0_mult0_in1;

    mode0_mult0_in0 = 0;
    mode0_mult0_in1 = 0;

    mode1_mult0_out = mode1_mult0_in0 * mode1_mult0_in1;

    mode1_mult0_in0 = 0;
    mode1_mult0_in1 = 0;

    // Common operations
    xul_gt_xdl  = 0;
    xur_gt_xdr  = 0;
    yu_sub_yd   = 0;

    xul_xdl_sub = 0;
    xdr_xur_sub = 0;
    xdl_sub_xul    = 0;
    xur_sub_xdr    = 0;

    if(state_RD_DATA)
    begin
        case(y_ptr)
            'd2:
            begin
                // a^2
                mode0_mult0_in0 = a2_m1 - b2_m1;
                mode0_mult0_in1 = a2_m1 - b2_m1;

                // b^2
                mode1_mult0_in0 = a1_m1 - b1_m1;
                mode1_mult0_in1 = b1_m1 - a1_m1;
            end
            'd3:
            begin
                //d^2 first term
                mode0_mult0_in0 = a2_m1 - b2_m1;
                mode0_mult0_in1 = c1_m1 - a1_m1;

                mode1_mult0_in0 = b1_m1 - a1_m1;
                mode1_mult0_in1 = a2_m1 - c2_m1;
            end
        endcase
    end
    else
    begin
        case({state_MODE0,state_MODE1,state_MODE2})
            3'b100:
            begin
                // Common operations
                xul_gt_xdl  = (xul >= xdl);
                xur_gt_xdr  = (xur >= xdr);
                yu_sub_yd   = yu - yd;
                xul_xdl_sub = xul-xdl;
                xdr_xur_sub = xdr-xur;
                xdl_sub_xul    = xdl-xul;
                xur_sub_xdr    = xur-xdr;

                mode0_div0_in1 = yu_sub_yd;

                // This is not optimized
                if(~right_bound_reach_d)
                begin
                    if(xul_gt_xdl == 1)
                    begin
                        mode0_mult0_in1 = xul_xdl_sub;
                        if(right_bound_reach_f)
                        begin
                            // xl = xdl + ((((y_ptr+1)-yd)*(xul_xdl_sub)) / yu_sub_yd);

                            mode0_mult0_in0 = (y_ptr-yd)+1;

                            mode0_div0_in0 = $unsigned(mode0_mult0_out);

                            xl = xdl + $signed(mode0_div0_out);
                        end
                        else
                        begin
                            mode0_mult0_in0 = y_ptr-yd;
                            mode0_div0_in0 = $unsigned(mode0_mult0_out);

                            xl = xdl + $signed(mode0_div0_out);
                        end
                    end
                    else
                    begin
                        mode0_mult0_in1 = xdl_sub_xul;
                        if(right_bound_reach_f)
                        begin
                            mode0_mult0_in0 = (yu-y_ptr)-1 ;
                            mode0_div0_in0 = $unsigned(mode0_mult0_out);
                            xl = xul + $signed(mode0_div0_out);
                        end
                        else
                        begin
                            mode0_mult0_in0 = (yu-y_ptr);
                            mode0_div0_in0 = $unsigned(mode0_mult0_out);
                            xl = xul + $signed(mode0_div0_out);
                        end
                    end
                end
                else
                begin
                    if(xur_gt_xdr == 1)
                    begin
                        mode0_mult0_in1 = xur_sub_xdr;
                        if(right_bound_reach_f)
                        begin
                            mode0_mult0_in0 = (y_ptr-yd)+1;
                            mode0_div0_in0 = $unsigned(mode0_mult0_out);
                            xr = xdr + $signed(mode0_div0_out);
                        end
                        else
                        begin
                            mode0_mult0_in0 = (y_ptr-yd);
                            mode0_div0_in0 = $unsigned(mode0_mult0_out);
                            xr = xdr + $signed(mode0_div0_out);
                        end
                    end
                    else
                    begin
                        mode0_mult0_in1 = xdr_xur_sub;
                        if(right_bound_reach_f)
                        begin
                            mode0_mult0_in0 = (yu-y_ptr)-1;
                            mode0_div0_in0 = $unsigned(mode0_mult0_out);
                            xr = xur + $signed(mode0_div0_out);
                        end
                        else
                        begin
                            mode0_mult0_in0 = (yu-y_ptr);
                            mode0_div0_in0 = $unsigned(mode0_mult0_out);
                            xr = xur + $signed(mode0_div0_out);
                        end
                    end
                end
            end
            3'b010:
            begin
                // Since d_square and r_square is positive for sure,

                // Share multiplers with mode0
                mode0_mult0_in0 = d1_m1-c1_m1;
                mode0_mult0_in1 = d1_m1-c1_m1;

                // Share multiplers with mode2
                mode1_mult0_in0 = c2_m1-d2_m1;
                mode1_mult0_in1 = d2_m1-c2_m1;

                d_square = (d_sqr_first_term_ff) * (d_sqr_first_term_ff);
                r_square = (mode0_mult0_out) - (mode1_mult0_out);

                ab_sqr = ab_sqr_ff;

                // the product r_square * (a^2+b^2), mult can use unsigned ones.
                if (d_square > $unsigned(r_square) * $unsigned(ab_sqr))
                begin
                    mode1_result = 0;
                end
                else if(d_square < $unsigned(r_square) * $unsigned(ab_sqr))
                begin
                    mode1_result = 1;
                end
                else
                begin
                    mode1_result = 2;
                end
            end
            3'b001:
            begin
                // Share mults with mode0
                mode0_mult0_in0 = c1-a1;
                mode0_mult0_in1 = d2-b2;

                // Share multiplers with mode1
                mode1_mult0_in0 = c2-a2;
                mode1_mult0_in1 = b1-d1;

                cross_add =  (mode0_mult0_out) + (mode1_mult0_out);

                if( cross_add >= 0)
                begin
                    abs_result = cross_add;
                end
                else
                begin
                    abs_result = ~cross_add + 1;
                end

                mode2_result = abs_result/2;
            end
        endcase
    end
end

// OUTPUT
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        out_valid <= 0;
        xo        <= 0;
        yo        <= 0;
    end
    else if(state_IDLE || state_RD_DATA)
    begin
        out_valid <= 0;
        xo        <= 0;
        yo        <= 0;
    end
    else if(state_MODE0 || state_OUTPUT_FIRST_POINT)
    begin
        out_valid <= 1;
        case({state_OUTPUT_FIRST_POINT,state_MODE0})
            2'b10:
            begin
                xo <= xdl;
                yo <= yd;
            end
            2'b01:
            begin
                xo <= x_ptr;
                yo <= y_ptr;
            end
            default:
            begin
                xo <= xo;
                yo <= yo;
            end
        endcase
    end
    else if(state_MODE1 || state_MODE2)
    begin
        if(state_MODE1)
        begin
            out_valid <= 1;
            xo <= 0;
            yo <= mode1_result;
        end
        else
        begin
            out_valid <= 1;
            xo <= mode2_result[15:8];
            yo <= mode2_result[7:0];
        end
    end
    else
    begin
        out_valid <= 0;
        xo        <= 0;
        yo        <= 0;
    end
end

endmodule