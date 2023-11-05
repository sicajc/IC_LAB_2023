module TRIANGLE(
    clk,
    rst_n,
    in_valid,
    coord_x,
    coord_y,
    out_valid,
    out_length,
	out_incenter
);
//================================================================
//  INPUT AND OUTPUT DECLARATION
//================================================================
input wire clk, rst_n, in_valid;
input wire [4:0] coord_x, coord_y;
output reg out_valid;
output reg [12:0] out_length, out_incenter;
//================================================================
//  Wires & Registers
//================================================================
reg[4:0] cur_state,next_state;
localparam  IDLE         = 5'd0;
localparam  RD_DATA      = 5'd1;
localparam  DIFF_SQR_SUM = 5'd2;
localparam  SQRT         = 5'd3;
localparam  CAL_QUO_DIV  = 5'd4;
localparam  CAL_DIV      = 5'd5;
localparam  OUTPUT       = 5'd6;


wire ST_IDLE   = cur_state == 0;
wire ST_RD_DATA   = cur_state == 1;
wire ST_DIFF_SQR_SUM   = cur_state == 2;
wire ST_SQRT   = cur_state == 3;
wire ST_CAL_QUO_DIV   = cur_state == 4;
wire ST_CAL_DIV   = cur_state == 5;
wire ST_OUTPUT   = cur_state == 6;

reg[3:0] cnt;

wire rd_data_done_f = cnt == 2 && ST_RD_DATA;
wire output_done_f  = cnt == 2 && OUTPUT;

//================================================================
//  MAIN FSM
//================================================================
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        cur_state <= IDLE;
    end
    else
    begin
        case (cur_state)
            IDLE:               cur_state <= in_valid ? RD_DATA : IDLE;
            RD_DATA:            cur_state <= rd_data_done_f ? DIFF_SQR_SUM : RD_DATA;
            DIFF_SQR_SUM:       cur_state <= SQRT;
            SQRT:               cur_state <= CAL_QUO_DIV;
            CAL_QUO_DIV:        cur_state <= CAL_DIV;
            CAL_DIV:            cur_state <= OUTPUT;
            OUTPUT:             cur_state <= output_done_f ? IDLE : OUTPUT;
            default:            cur_state <= IDLE;
        endcase
    end
end

reg signed[5:0] x_a_in_ff,y_a_in_ff,x_b_in_ff,y_b_in_ff,x_c_in_ff,y_c_in_ff;
reg [12:0] a_diff_sum_ff,b_diff_sum_ff,c_diff_sum_ff;
reg [13:0] a_sqrt_ff,b_sqrt_ff,c_sqrt_ff;
reg [20:0] xq_ff,yq_ff;
reg [15:0] xd_ff,yd_ff;
reg [27:0] xcenter_ff,ycenter_ff;

wire[13:0] a_sqrt_out,b_sqrt_out,c_sqrt_out;
//================================================================
//  DATAPATH
//================================================================
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        cnt <= 0;
        x_a_in_ff <= 0;
        y_a_in_ff <= 0;
        x_b_in_ff <= 0;
        y_b_in_ff <= 0;
        x_c_in_ff <= 0;
        y_c_in_ff <= 0;
        a_diff_sum_ff <= 0;
        b_diff_sum_ff <= 0;
        a_sqrt_ff <= 0;
        b_sqrt_ff <= 0;
        xq_ff <= 0;
        yq_ff <= 0;
        xd_ff <= 0;
        yd_ff <= 0;
        xcenter_ff <= 0;
        ycenter_ff <= 0;
        c_sqrt_ff <= 0;
        c_diff_sum_ff <= 0;
        out_valid <= 0;
        out_length <= 0;
        out_incenter <= 0;
    end
    else
    begin
        case(cur_state)
        IDLE:
        begin
            if(in_valid)
            begin
                cnt <= cnt + 1;
                x_a_in_ff <= coord_x;
                y_a_in_ff <= coord_y;
            end
            else
            begin
                cnt <= 0;
                x_a_in_ff <= 0;
                y_a_in_ff <= 0;
            end

            x_b_in_ff <= 0;
            y_b_in_ff <= 0;
            x_c_in_ff <= 0;
            y_c_in_ff <= 0;
            a_diff_sum_ff <= 0;
            b_diff_sum_ff <= 0;
            c_diff_sum_ff <= 0;
            a_sqrt_ff <= 0;
            b_sqrt_ff <= 0;
            xq_ff <= 0;
            yq_ff <= 0;
            xd_ff <= 0;
            yd_ff <= 0;
            xcenter_ff <= 0;
            ycenter_ff <= 0;
            c_sqrt_ff <= 0;
            out_valid <= 0;
            out_length <= 0;
            out_incenter <= 0;
        end
        RD_DATA:
        begin
            cnt <= rd_data_done_f ?  0 : cnt + 1;

            case(cnt)
            'd1:
            begin
                x_b_in_ff <= coord_x;
                y_b_in_ff <= coord_y;
            end
            'd2:
            begin
                x_c_in_ff <= coord_x;
                y_c_in_ff <= coord_y;
            end
            endcase
        end
        DIFF_SQR_SUM:
        begin
            a_diff_sum_ff <= (x_b_in_ff - x_c_in_ff) * (x_b_in_ff - x_c_in_ff) + (y_b_in_ff - y_c_in_ff) * (y_b_in_ff - y_c_in_ff);
            b_diff_sum_ff <= (x_a_in_ff - x_c_in_ff) * (x_a_in_ff - x_c_in_ff) + (y_a_in_ff - y_c_in_ff) * (y_a_in_ff - y_c_in_ff);
            c_diff_sum_ff <= (x_a_in_ff - x_b_in_ff) * (x_a_in_ff - x_b_in_ff) + (y_a_in_ff - y_b_in_ff) * (y_a_in_ff - y_b_in_ff);
        end
        SQRT:
        begin
            a_sqrt_ff <= a_sqrt_out;
            b_sqrt_ff <= b_sqrt_out;
            c_sqrt_ff <= c_sqrt_out;
        end
        CAL_QUO_DIV:
        begin
            xq_ff <= a_sqrt_ff * x_a_in_ff + b_sqrt_ff * x_b_in_ff + c_sqrt_ff * x_c_in_ff;
            xd_ff <= a_sqrt_ff + b_sqrt_ff + c_sqrt_ff;

			yq_ff <= a_sqrt_ff * y_a_in_ff + b_sqrt_ff * y_b_in_ff + c_sqrt_ff * y_c_in_ff;
            yd_ff <= a_sqrt_ff + b_sqrt_ff + c_sqrt_ff;
        end
        CAL_DIV:
        begin
            xcenter_ff <= {xq_ff,7'b0} / xd_ff ;
            ycenter_ff <= {yq_ff,7'b0} / yd_ff ;
            cnt <= 0;
        end
        OUTPUT:
        begin
            out_valid <= 1;
            cnt <= cnt + 1;
            case(cnt)
            'd0:
            begin
                out_incenter <= xcenter_ff;
                out_length   <= a_sqrt_ff;
            end
            'd1:
            begin
                out_incenter <= ycenter_ff;
                out_length   <= b_sqrt_ff;
            end
            'd2:
            begin
                out_length   <= c_sqrt_ff;
            end
            endcase
        end
        endcase
    end
end

// wire[13:0] square_root_tc_a,square_root_tc_b,square_root_tc_c;

// Instance of DW_sqrt_seq
DW_sqrt_inst sqrt_a(.radicand({a_diff_sum_ff,14'b0}),.square_root(a_sqrt_out));
DW_sqrt_inst sqrt_b(.radicand({b_diff_sum_ff,14'b0}),.square_root(b_sqrt_out));
DW_sqrt_inst sqrt_c(.radicand({c_diff_sum_ff,14'b0}),.square_root(c_sqrt_out));


endmodule

module DW_sqrt_inst (radicand, square_root);
parameter radicand_width = 27;
parameter tc_mode = 0;
input [radicand_width-1 : 0]
radicand;
output [(radicand_width+1)/2-1 : 0] square_root;
// Please add +incdir+$SYNOPSYS/dw/sim_ver+ to your verilog simulator
// command line (for simulation).
// instance of DW_sqrt
DW_sqrt #(radicand_width, tc_mode)
U1 (.a(radicand), .root(square_root));
endmodule