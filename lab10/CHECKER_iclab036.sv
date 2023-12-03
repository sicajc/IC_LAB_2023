/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory 
Lab10: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: Nov-2023)
Author : Jui-Huang Tsai (erictsai.10@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype_BEV.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;

/*
    Coverage Part
*/


class BEV;
    Bev_Type bev_type;
    Bev_Size bev_size;
endclass

BEV bev_info = new();

always_ff @(posedge clk) begin
    if (inf.type_valid) begin
        bev_info.bev_type = inf.D.d_type[0];
    end
end
always_ff @(posedge clk) begin
    if (inf.size_valid) begin
        bev_info.bev_size = inf.D.d_size[0];
    end
end
/**/

/*
1. Each case of Beverage_Type should be select at least 100 times.
*/
Action ACTION ;

covergroup Spec1 @(posedge clk);
    option.per_instance = 1;
    option.at_least = 100;
    /*btype1: coverpoint bev_info.bev_type{
        bins b_bev_type [] = {[Black_Tea:Super_Pineapple_Milk_Tea]};
    }*/
endgroup


/*
2.	Each case of Bererage_Size should be select at least 100 times.
*/
covergroup Spec2 @(posedge clk);
    option.per_instance = 1;
    option.at_least = 100;
    /*btype2: coverpoint bev_info.bev_size{
        bins b_bev_size [] = {[L:S]};
    }*/
endgroup
/*
3.	Create a cross bin for the SPEC1 and SPEC2. Each combination should be selected at least 100 times. 
(Black Tea, Milk Tea, Extra Milk Tea, Green Tea, Green Milk Tea, Pineapple Juice, Super Pineapple Tea, Super Pineapple Tea) x (L, M, S)
*/
/*logic [3:0] opa;
logic [3:0] opb;
covergroup Spec3 @(posedge clk);
    coverpoint opa;
    coverpoint opb;
    cross opa, opb;

endgroup*/
covergroup Spec1_2_3 @(posedge clk iff(inf.date_valid && ACTION === Make_drink));
    option.per_instance = 1;
    option.at_least = 100;
    btype1: coverpoint bev_info.bev_type{
        //option.weight = 0;
        //option.auto_bin_max = 0;
        bins b_bev_type [] = {[Black_Tea:Super_Pineapple_Milk_Tea]};
    }
    btype2: coverpoint bev_info.bev_size{
        //option.weight = 0;
        //option.auto_bin_max = 0;
        bins b_bev_size [] = {[L:S]};
    }
    cross btype1, btype2;/*{
        //option.cross_auto_bin_max = 0;
        option.at_least = 100;
    }*/
endgroup
/*
4.	Output signal inf.err_msg should be No_Err, No_Exp, No_Ing and Ing_OF, each at least 20 times. (Sample the value when inf.out_valid is high)
*/
covergroup Spec4 @(negedge clk iff(inf.out_valid));
    option.per_instance = 1;
	btype4: coverpoint inf.err_msg {
		option.at_least = 20 ;
		bins b1 = {No_Err } ;
		bins b2 = {No_Exp} ;
		bins b3 = {No_Ing} ;
		bins b4 = {Ing_OF} ;
    }
endgroup
/*
5.	Create the transitions bin for the inf.D.act[0] signal from [0:2] to [0:2]. Each transition should be hit at least 200 times. (sample the value at posedge clk iff inf.sel_action_valid)
*/
covergroup Spec5 @(negedge clk && inf.sel_action_valid);
    option.per_instance = 1;
	btype5: coverpoint inf.D.d_act[0] {
		option.at_least = 200 ;
		bins b[] = (Make_drink, Supply, Check_Valid_Date => Make_drink, Supply, Check_Valid_Date) ;
    }
endgroup
/*
6.	Create a covergroup for material of supply action with auto_bin_max = 32, and each bin have to hit at least one time.
*/
covergroup Spec6 @(negedge clk && inf.box_sup_valid);
    option.per_instance = 1;
    option.auto_bin_max = 32;//4096/32=128
	btype6: coverpoint inf.D.d_ing[0] {
		option.at_least = 1 ;
        //bins b1 = {[4095:0]};
		
    }
endgroup
/*
    Create instances of Spec1, Spec2, Spec3, Spec4, Spec5, and Spec6
*/
// Spec1_2_3 cov_inst_1_2_3 = new();
Spec1 cov_inst_1 = new();//8
Spec2 cov_inst_2 = new();//3
Spec1_2_3 cov_inst_3 = new();//11+24=35 //35+24=59
Spec4 cov_inst_4 = new();//4
Spec5 cov_inst_5 = new();//9  //59  // 91-59=32
Spec6 cov_inst_6 = new();//12 // 36+35=71
//4096/32=2^12/2^5=2^7
/*
    Asseration
*/

/*
    If you need, you can declare some FSM, logic, flag, and etc. here.
*/

/*
    1. All outputs signals (including BEV.sv and bridge.sv) should be zero after reset.
*/
/*always_ff @(posedge rst_n) begin 
    ap_Spec_1: assert property (p_Spec_1) else $fatal("Assertion 1 is violated");
end

property p_Spec_1;
    @(posedge rst_n) request !inf.out_valid ##0 !inf.err_msg ##0 !inf.complete ##0 !inf.C_addr ##0 !inf.C_data_w ##0 !inf.C_in_valid ##0 !inf.C_r_wb ##0 !inf.C_out_valid ##0 !inf.C_data_r ##0 !inf.AR_VALID ##0 !inf.AR_ADDR ##0 !inf.R_READY ##0 !inf.AW_VALID ##0 !inf.AW_ADDR ##0 !inf.W_VALID ##0 !inf.W_DATA ##0 !inf.B_READY;
endproperty: p_Spec_1*/

always @(negedge inf.rst_n) begin
	#2;
	ap_Spec_1 : assert ((inf.out_valid===0)&&(inf.err_msg==No_Err)&&(inf.complete===0)&&(inf.C_addr===0)&&(inf.C_data_w===0)&&(inf.C_in_valid===0)&&(inf.C_r_wb===0)&&(inf.C_out_valid===0)&&(inf.C_data_r===0)&&(inf.AR_VALID===0)&&(inf.AR_ADDR===0)&&(inf.R_READY===0)&&(inf.AW_VALID===0)&&(inf.AW_ADDR===0)&&(inf.W_VALID===0)&&(inf.W_DATA===0)&&(inf.B_READY===0))
	else begin
        $display("***************************");
		$display("  Assertion 1 is violated");
        $display("***************************");
		$fatal; 
	end
end
/*
    2.	Latency should be less than 1000 cycles for each operation.
*/

always_ff @(posedge clk or negedge inf.rst_n)  begin
	if (!inf.rst_n) ACTION <= Make_drink ;
	else begin 
		if (inf.sel_action_valid==1) ACTION <= inf.D.d_act[0];
	end
end

logic [1:0] counter ;
always_ff @(posedge clk or negedge inf.rst_n)  begin
	if (!inf.rst_n) counter <= 0 ;
	else begin 
		if (inf.box_sup_valid==1) counter <= counter + 1;
	end
end

ap_Spec_2_0 : assert property ( @(posedge clk) ( (ACTION===Make_drink||ACTION===Check_Valid_Date) && (inf.box_no_valid===1) ) |-> ( ##[1:1000] inf.out_valid===1 ) )
else
begin
	$display("***************************");
	$display("  Assertion 2 is violated");
    $display("***************************");
	$fatal; 
end 
ap_Spec_2_1 : assert property ( @(posedge clk) ( (ACTION===Supply) && (inf.box_sup_valid===1) ) |-> ( ##[1:1000] inf.out_valid===1 ) )
else
begin
	$display("***************************");
	$display("  Assertion 2 is violated");
    $display("***************************");
	$fatal; 
end
						
/*
    3. If out_valid does not pull up, complete should be 0.
*/
ap_Spec_3_0 : assert property ( @(posedge clk) ( (inf.out_valid===0) |-> (inf.complete===0 ) ) )
else
begin
	$display("***************************");
	$display("  Assertion 3 is violated");
    $display("***************************");
	$fatal; 
end
ap_Spec_3_1 : assert property ( @(negedge clk) ( (inf.err_msg===No_Exp) |-> (inf.complete===0 ) ) )
else
begin
	$display("***************************");
	$display("  Assertion 3 is violated");
    $display("***************************");
	$fatal; 
end
ap_Spec_3_2 : assert property ( @(negedge clk) ( (inf.err_msg===No_Ing) |-> (inf.complete===0 ) ) )
else
begin
	$display("***************************");
	$display("  Assertion 3 is violated");
    $display("***************************");
	$fatal; 
end
/*
    4. Next input valid will be valid 1-4 cycles after previous input valid fall.
*/
ap_Spec_4_0 : assert property ( @(negedge clk) ( (ACTION===Make_drink) && (inf.sel_action_valid===1) ) |-> ( ##[1:4] inf.type_valid===1 ) )
else
begin
	$display("***************************");
	$display("  Assertion 4 is violated");
    $display("***************************");
	$fatal; 
end
ap_Spec_4_1 : assert property ( @(negedge clk) ( (ACTION===Make_drink) && (inf.type_valid===1) ) |-> ( ##[1:4] inf.size_valid===1 ) )
else
begin
	$display("***************************");
	$display("  Assertion 4 is violated");
    $display("***************************");
	$fatal; 
end
ap_Spec_4_2 : assert property ( @(negedge clk) ( (ACTION===Make_drink) && (inf.size_valid===1) ) |-> ( ##[1:4] inf.date_valid===1 ) )
else
begin
	$display("***************************");
	$display("  Assertion 4 is violated");
    $display("***************************");
	$fatal; 
end
ap_Spec_4_3 : assert property ( @(negedge clk) ( (ACTION===Make_drink) && (inf.date_valid===1) ) |-> ( ##[1:4] inf.box_no_valid===1 ) )
else
begin
	$display("***************************");
	$display("  Assertion 4 is violated");
    $display("***************************");
	$fatal; 
end
ap_Spec_4_4 : assert property ( @(negedge clk) ( (ACTION===Supply) && (inf.sel_action_valid===1) ) |-> ( ##[1:4] inf.date_valid===1 ) )
else
begin
	$display("***************************");
	$display("  Assertion 4 is violated");
    $display("***************************");
	$fatal; 
end
ap_Spec_4_5 : assert property ( @(negedge clk) ( (ACTION===Supply) && (inf.date_valid===1) ) |-> ( ##[1:4] inf.box_no_valid===1 ) )
else
begin
	$display("***************************");
	$display("  Assertion 4 is violated");
    $display("***************************");
	$fatal; 
end
ap_Spec_4_6 : assert property ( @(negedge clk) ( (ACTION===Check_Valid_Date) && (inf.sel_action_valid===1) ) |-> ( ##[1:4] inf.date_valid===1 ) )
else
begin
	$display("***************************");
	$display("  Assertion 4 is violated");
    $display("***************************");
	$fatal; 
end
ap_Spec_4_7 : assert property ( @(negedge clk) ( (ACTION===Check_Valid_Date) && (inf.date_valid===1) ) |-> ( ##[1:4] inf.box_no_valid===1 ) )
else
begin
	$display("***************************");
	$display("  Assertion 4 is violated");
    $display("***************************");
	$fatal; 
end
ap_Spec_4_8 : assert property ( @(posedge clk) ( (ACTION===Supply) && (inf.box_sup_valid===1) && (counter !==3)) |-> ( ##[1:4] inf.box_sup_valid===1 ) )
else
begin
	$display("***************************");
	$display("  Assertion 4 is violated");
    $display("***************************");
	$fatal; 
end
ap_Spec_4_9 : assert property ( @(negedge clk) ( (ACTION===Supply) && (inf.box_no_valid===1) ) |-> ( ##[1:4] inf.box_sup_valid===1 ) )
else
begin
	$display("***************************");
	$display("  Assertion 4 is violated");
    $display("***************************");
	$fatal; 
end
/*
    5. All input valid signals won't overlap with each other. 
*/
logic K;
assign K = !((inf.sel_action_valid===1) || (inf.type_valid===1) || (inf.size_valid===1) || (inf.date_valid===1) || (inf.box_no_valid===1) || (inf.box_sup_valid===1) );
ap_Spec_5 : assert property ( @(posedge clk) $onehot( {inf.sel_action_valid, inf.type_valid, inf.size_valid, inf.date_valid, inf.box_no_valid, inf.box_sup_valid, K} ) )
else
begin
	$display("***************************");
	$display("  Assertion 5 is violated");
    $display("***************************");
	$fatal; 
end
/*
    6. Out_valid can only be high for exactly one cycle.
*/
ap_Spec_6 : assert property ( @(posedge clk) (inf.out_valid===1) |=> (inf.out_valid===0) )
else
begin
	$display("***************************");
	$display("  Assertion 6 is violated");
    $display("***************************");
	$fatal; 
end
/*
    7. Next operation will be valid 1-4 cycles after out_valid fall.
*/
ap_Spec_7 : assert property ( @(posedge clk) (inf.out_valid===1) |-> ( ##[1:4] inf.sel_action_valid===1) )
else
begin
	$display("***************************");
	$display("  Assertion 7 is violated");
    $display("***************************");
	$fatal; 
end
/*
    8. The input date from pattern should adhere to the real calendar. (ex: 2/29, 3/0, 4/31, 13/1 are illegal cases)
*/
logic [4:0] MM;
logic [5:0] DD;
assign MM = inf.D.d_date[0].M;
assign DD = inf.D.d_date[0].D;
ap_Spec_8_0 : assert property ( @(posedge clk) ( (inf.date_valid) && (inf.D.d_date[0].M===1 || inf.D.d_date[0].M===3 || inf.D.d_date[0].M===5 || inf.D.d_date[0].M===7 || inf.D.d_date[0].M===8 || inf.D.d_date[0].M===10 || inf.D.d_date[0].M===12) ) |-> ( inf.D.d_date[0].D>=1 && inf.D.d_date[0].D<=31) )
else
begin
	$display("***************************");
	$display("  Assertion 8 is violated");
    $display("***************************");
	$fatal; 
end
ap_Spec_8_1 : assert property ( @(posedge clk) ( (inf.date_valid) && (inf.D.d_date[0].M===4 || inf.D.d_date[0].M===6 || inf.D.d_date[0].M===9 || inf.D.d_date[0].M===11) ) |-> ( inf.D.d_date[0].D>=1 && inf.D.d_date[0].D<=30) )
else
begin
	$display("***************************");
	$display("  Assertion 8 is violated");
    $display("***************************");
	$fatal; 
end
ap_Spec_8_2 : assert property ( @(posedge clk) ( (inf.date_valid) && (inf.D.d_date[0].M===2) ) |-> ( inf.D.d_date[0].D>=1 && inf.D.d_date[0].D<=28) )
else
begin
	$display("***************************");
	$display("  Assertion 8 is violated");
    $display("***************************");
	$fatal; 
end
ap_Spec_8_3 : assert property ( @(posedge clk) (inf.date_valid) |-> ( inf.D.d_date[0].M>=1 && inf.D.d_date[0].M<=12) )
else
begin
	$display("***************************");
	$display("  Assertion 8 is violated");
    $display("***************************");
	$fatal; 
end
/*
    9. C_in_valid can only be high for one cycle and can't be pulled high again before C_out_valid
*/
logic KK;
always_ff @(posedge clk or negedge inf.rst_n)  begin
	if (!inf.rst_n) KK <= 0;
	else begin 
        if(inf.C_in_valid) KK <= 1;
		else if (inf.C_out_valid==1) KK <= 0;
	end
end
ap_Spec_9_0 : assert property ( @(posedge clk) ( (KK) && (inf.C_in_valid===1) ) |=> (inf.C_in_valid===0) )
else
begin
	$display("***************************");
	$display("  Assertion 9 is violated");
    $display("***************************");
	$fatal; 
end


endmodule
