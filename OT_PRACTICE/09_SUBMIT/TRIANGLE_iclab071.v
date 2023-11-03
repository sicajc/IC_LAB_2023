//synopsys translate_off
`include "DW_div.v"
`include "DW_div_seq.v"
`include "DW_div_pipe.v"
//synopsys translate_on

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

reg in_valid_temp;
reg [7:0] AC_L, BC_L, AB_L;
reg [7:0] counter;
reg signed[30:0] CosA_temp, CosB_temp, CosC_temp;
reg signed[17:0] BC2_temp, AC2_temp, AB2_temp;

reg signed[30:0]inst_a;
reg signed[17:0]inst_b;
wire signed[30:0]quotient_inst;
wire signed[17:0]remainder_inst;
wire divide_by_0_inst;
reg signed[30:0]inst_aa;
reg signed[17:0]inst_bb;
wire signed[30:0]quotient_instt;
wire signed[17:0]remainder_instt;
wire divide_by_0_instt;
reg signed[30:0]inst_aaa;
reg signed[17:0]inst_bbb;
wire signed[30:0]quotient_insttt;
wire signed[17:0]remainder_insttt;
wire divide_by_0_insttt;
reg signed[30:0]fin_cai, fin_cbi, fin_cci;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		in_valid_temp <= 0;
	end
	else if(in_valid)begin
		in_valid_temp <= 1;
	end
	else if(counter==28)begin
		in_valid_temp <= 0;
	end
end


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		counter <= 0;
	end
	else if(((in_valid) ||(in_valid_temp==1)) )begin
		if(counter==28)begin
			counter <= 0;
		end
		else counter <= counter+1;
	end

end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		BC_L <= 0;
	end
	else if(counter==0 && in_valid)begin
		BC_L <= in_length;
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		AC_L <= 0;
	end
	else if(counter==1)begin
		AC_L <= in_length;
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		AB_L <= 0;
	end
	else if(counter==2)begin
		AB_L <= in_length;
	end
end


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		CosA_temp <= 0;
	end
	else if(counter==3)begin
		CosA_temp <= AC_L*AC_L + AB_L*AB_L - BC_L*BC_L;
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		CosB_temp <= 0;
	end
	else if(counter==3)begin
		CosB_temp <= BC_L*BC_L + AB_L*AB_L - AC_L*AC_L;
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		CosC_temp <= 0;
	end
	else if(counter==3)begin
		CosC_temp <= BC_L*BC_L + AC_L*AC_L - AB_L*AB_L;
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		BC2_temp <= 0;
	end
	else if(counter==4)begin
		BC2_temp <= 2*AC_L*AB_L;
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		AC2_temp <= 0;
	end
	else if(counter==4)begin
		AC2_temp <= 2*BC_L*AB_L;
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		AB2_temp <= 0;
	end
	else if(counter==4)begin
		AB2_temp <= 2*BC_L*AC_L;
	end
end
//!========================================================

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		inst_a <= 0;
	end
	else if(counter==5)begin
		inst_a <= CosA_temp << 13;
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		inst_b <= 0;
	end
	else if(counter==5)begin
		inst_b <= BC2_temp;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		fin_cai <= 0;
	end
	else if(counter==22)begin
		fin_cai <= quotient_inst;
	end
end


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		inst_aa <= 0;
	end
	else if(counter==5)begin
		inst_aa <= CosB_temp << 13;
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		inst_bb <= 0;
	end
	else if(counter==5)begin
		inst_bb <= AC2_temp;
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		fin_cbi <= 0;
	end
	else if(counter==22)begin
		fin_cbi <= quotient_instt;
	end
end


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		inst_aaa <= 0;
	end
	else if(counter==5)begin
		inst_aaa <= CosC_temp << 13;
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		inst_bbb <= 0;
	end
	else if(counter==5)begin
		inst_bbb <= AB2_temp;
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		fin_cci <= 0;
	end
	else if(counter==22)begin
		fin_cci <= quotient_insttt;
	end
end

DW_div_pipe #(31,18,1,0,15,0,1,0)U1 (.clk(clk),.rst_n(rst_n),
.en(0),
.a(inst_a),
.b(inst_b),
.quotient(quotient_inst),
.remainder(remainder_inst),
.divide_by_0(divide_by_0_inst) );
DW_div_pipe #(31,18,1,0,15,0,1,0)U2 (.clk(clk),.rst_n(rst_n),
.en(0),
.a(inst_aa),
.b(inst_bb),
.quotient(quotient_instt),
.remainder(remainder_instt),
.divide_by_0(divide_by_0_instt) );
DW_div_pipe #(31,18,1,0,15,0,1,0)U3 (.clk(clk),.rst_n(rst_n),
.en(0),
.a(inst_aaa),
.b(inst_bbb),
.quotient(quotient_insttt),
.remainder(remainder_insttt),
.divide_by_0(divide_by_0_insttt) );


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_valid <= 0;
	end
	else if((counter==25)||(counter==26)||(counter==27))begin
		out_valid <= 1;
	end
	else out_valid <= 0;
end

reg signed[15:0]out_cos_temp1, out_cos_temp2, out_cos_temp3;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_cos_temp1 <= 0;
		out_cos_temp2 <= 0;
		out_cos_temp3 <= 0;
	end
	else if(counter==24)begin
		out_cos_temp1 <= {fin_cai};
		out_cos_temp2 <= {fin_cbi};
		out_cos_temp3 <= {fin_cci};
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_cos <= 0;
	end
	else if(counter==25)begin
		out_cos <= out_cos_temp1;
	end
	else if(counter==26)begin
		out_cos <= out_cos_temp2;
	end
	else if(counter==27)begin
		out_cos <= out_cos_temp3;
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_tri <= 0;
	end
	else if(counter==25)begin
		if((CosA_temp==0)||(CosB_temp==0)||(CosC_temp==0))begin		
			out_tri <= 2'b11;
		end
		else if((fin_cai<0)||(fin_cbi<0)||(fin_cci<0))begin
			out_tri <= 2'b01;
		end
		else begin
			out_tri <= 2'b00;	
		end
	end
end



   

endmodule
