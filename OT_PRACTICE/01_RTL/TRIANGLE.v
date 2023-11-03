module TRIANGLE(
    clk,
    rst_n,
    in_valid,
    in_length,
    out_cos,
    out_valid,
    out_tri
);
input wire clk, rst_n, in_valid;
input wire [7:0] in_length;

output reg out_valid;
output reg [15:0] out_cos;
output reg [1:0] out_tri;

reg start_div_f;

reg signed[18:0] a_quotient_ff,a_dividend_ff;
reg signed[18:0] b_quotient_ff,b_dividend_ff;
reg signed[18:0] c_quotient_ff,c_dividend_ff;

wire signed[31:0]  a_q_out,b_q_out,c_q_out;

wire a_cos_done_f,b_cos_done_f,c_cos_done_f;
reg[3:0] cur_state,next_state;
reg div_hold_f;
reg[3:0] cnt;


// States
localparam IDLE = 4'd1;
localparam RD_DATA = 4'd2;
localparam CAL_QUOTIENT_DIV = 4'd3;
localparam FIND_COS = 4'd4;
localparam COMPARE_DET_TYPE = 4'd5;
localparam OUTPUT = 4'd6;

wire ST_IDLE   =  cur_state == 1;
wire ST_RD_DATA   =  cur_state == 2;
wire ST_CAL_QUOTIENT_DIV   =  cur_state == 3;
wire ST_FIND_COS   =  cur_state == 4;
wire ST_COMPARE_DET_TYPE   =  cur_state == 5;
wire ST_OUTPUT   =  cur_state == 6;

// FSM
always @(posedge clk or negedge rst_n)
begin
	if(~rst_n)
	begin
		cur_state <= IDLE;
	end
	else
	begin
		cur_state <= next_state;
	end
end

wire rd_done_f   = cnt == 2 && ST_RD_DATA;
wire cos_found_f =  div_hold_f && a_cos_done_f && b_cos_done_f && c_cos_done_f && ST_FIND_COS;
wire output_done_f = cnt == 2 && ST_OUTPUT;

always @(*)
begin
	next_state = cur_state;
	case(cur_state)
	IDLE:					next_state = in_valid  ? RD_DATA : IDLE;
	RD_DATA:				next_state = rd_done_f ? CAL_QUOTIENT_DIV : RD_DATA;
	CAL_QUOTIENT_DIV:		next_state = FIND_COS;
	FIND_COS:				next_state = cos_found_f ? OUTPUT : FIND_COS;
	OUTPUT:					next_state = output_done_f ? IDLE : OUTPUT;
	endcase
end


reg[7:0] a_ff,b_ff,c_ff;

parameter DATA_WIDTH     = 32;
parameter INT_WIDTH      = 3;
parameter FRACTION_WIDTH = 13;

reg signed[DATA_WIDTH-1:0] a_cos_out_ff,b_cos_out_ff,c_cos_out_ff;

//DATAPATH
always @(posedge clk or negedge rst_n)
begin
	if(~rst_n)
	begin
		a_ff <= 0; b_ff <= 0; c_ff <= 0;
		a_quotient_ff <= 0 ;b_quotient_ff <= 0; c_quotient_ff <= 0;
		a_dividend_ff <= 0; b_dividend_ff <= 0; c_dividend_ff <= 0;
		cnt <= 0;
		start_div_f <= 0;
		out_tri <= 0;
		out_cos <= 0;
		out_valid <= 0;
		a_cos_out_ff <= 0; b_cos_out_ff <= 0; c_cos_out_ff <= 0;
		div_hold_f <= 0;
	end
	else
	begin
		case(cur_state)
	    IDLE:
		begin
			if(in_valid)
			begin
				a_ff <= in_length;
				cnt <= cnt+1;
			end
			else
			begin
				a_ff <= 0;
				cnt <= 0;
			end
			b_ff <= 0; c_ff <= 0;
			a_quotient_ff <= 0 ;b_quotient_ff <= 0; c_quotient_ff <= 0;
			a_dividend_ff <= 0; b_dividend_ff <= 0; c_dividend_ff <= 0;
			start_div_f <= 0;
			out_tri <= 0;
			out_cos <= 0;
			out_valid <= 0;
			a_cos_out_ff <= 0; b_cos_out_ff <= 0; c_cos_out_ff <= 0;
			div_hold_f <= 0;
		end
	    RD_DATA:
		begin
			cnt <= cnt + 1;
			if(cnt == 1 && in_valid)
			begin
				b_ff <= in_length;
			end
			else if(cnt == 2 && in_valid)
			begin
				c_ff <= in_length;
			end
		end
	    CAL_QUOTIENT_DIV:
		begin
			// Fixed point arithmetic, scale the fixed point
			// Div a/b integer, if you want a[3:0] b[3:0] with a precision of 3 bits, simply a[3:0] << 3 / b[3:0] ,
			// i.e. a[6:0] / b[3:0] , due to fixed point arithmetic, 0001111. -> 111100 / 1111.00, so that the fixed point
			// remainders appears.
			a_quotient_ff <= b_ff*b_ff + c_ff*c_ff - a_ff*a_ff;
			b_quotient_ff <= a_ff*a_ff + c_ff*c_ff - b_ff*b_ff;
			c_quotient_ff <= a_ff*a_ff + b_ff*b_ff - c_ff*c_ff;

			a_dividend_ff <= 2*b_ff*c_ff;
			b_dividend_ff <= 2*a_ff*c_ff;
			c_dividend_ff <= 2*a_ff*b_ff;
			start_div_f <= 1;

			cnt <= 0;
		end
	    FIND_COS:
		begin
			if(start_div_f == 1)
			begin
				div_hold_f <= 1;
				start_div_f <= 0;
			end

			if(cos_found_f)
			begin
				div_hold_f <= 0;
				a_cos_out_ff <= a_q_out;
				b_cos_out_ff <= b_q_out;
				c_cos_out_ff <= c_q_out;
			end
		end
	    OUTPUT:
		begin
			out_valid <= 1;
			cnt <= cnt + 1;

			// Need to determine fix point integer width
			if((a_cos_out_ff == 0) || (b_cos_out_ff == 0) || (c_cos_out_ff == 0))
			begin
				out_tri <= 3;
			end
			else if((a_cos_out_ff > 0) && (b_cos_out_ff >0) && (c_cos_out_ff > 0))
			begin
				out_tri <= 0;
			end
			else if((a_cos_out_ff < 0) || (b_cos_out_ff <0) || (c_cos_out_ff < 0))
			begin
				out_tri <= 1;
			end


			case(cnt)
			'd0: out_cos <= a_cos_out_ff;
			'd1: out_cos <= b_cos_out_ff;
			'd2: out_cos <= c_cos_out_ff;
			endcase
		end
	    endcase
	end
end


// Sequential division
DW_div_seq_inst A_cos(.inst_clk(clk), .inst_rst_n(rst_n), .inst_hold(1'b0), .inst_start(start_div_f), .inst_a({a_quotient_ff,13'b0}),
.inst_b(a_dividend_ff), .complete_inst(a_cos_done_f), .divide_by_0_inst(), .quotient_inst(a_q_out), .remainder_inst());
DW_div_seq_inst B_cos(.inst_clk(clk), .inst_rst_n(rst_n), .inst_hold(1'b0), .inst_start(start_div_f), .inst_a({b_quotient_ff,13'b0}),
.inst_b(b_dividend_ff), .complete_inst(b_cos_done_f), .divide_by_0_inst(), .quotient_inst(b_q_out), .remainder_inst());
DW_div_seq_inst C_cos(.inst_clk(clk), .inst_rst_n(rst_n), .inst_hold(1'b0), .inst_start(start_div_f), .inst_a({c_quotient_ff,13'b0}),
.inst_b(c_dividend_ff), .complete_inst(c_cos_done_f), .divide_by_0_inst(), .quotient_inst(c_q_out), .remainder_inst());

endmodule

module DW_div_seq_inst(inst_clk, inst_rst_n, inst_hold, inst_start, inst_a,
inst_b, complete_inst, divide_by_0_inst, quotient_inst, remainder_inst);
parameter inst_a_width = 32;
parameter inst_b_width = 19;
parameter inst_tc_mode = 1;
parameter inst_num_cyc = 25;
parameter inst_rst_mode = 0;
parameter inst_input_mode = 0;
parameter inst_output_mode = 1;
parameter inst_early_start = 0;
// Please add +incdir+$SYNOPSYS/dw/sim_ver+ to your verilog simulator
// command line (for simulation).
input inst_clk;
input inst_rst_n;
input inst_hold;
input inst_start;
input [inst_a_width-1 : 0] inst_a;
input [inst_b_width-1 : 0] inst_b;
output complete_inst;
output divide_by_0_inst;
output [inst_a_width-1 : 0] quotient_inst;
output [inst_b_width-1 : 0] remainder_inst;
// Instance of DW_div_seq
DW_div_seq #(inst_a_width, inst_b_width, inst_tc_mode, inst_num_cyc,
inst_rst_mode, inst_input_mode, inst_output_mode,
inst_early_start)
U1 (.clk(inst_clk),
.rst_n(inst_rst_n),
.hold(inst_hold),
.start(inst_start),
.a(inst_a),
.b(inst_b),
.complete(complete_inst),
.divide_by_0(divide_by_0_inst),
.quotient(quotient_inst),
.remainder(remainder_inst) );
endmodule
