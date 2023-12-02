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
    Cover group define
*/
/*
1. Each case of Beverage_Type should be select at least 100 times.
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

Action cur_act;
always_ff @(posedge clk or negedge inf.rst_n)  begin
	if (!inf.rst_n)				        cur_act <= Make_drink;
	else begin
		if (inf.sel_action_valid==1) 	cur_act <= inf.D.d_act[0] ;
	end
end

covergroup Spec1 @(posedge clk iff(inf.type_valid));
    option.per_instance = 1;
    option.at_least = 100;

    bin_bev_type: coverpoint bev_info.bev_type{
    bins b_bev_type[] ={[Black_Tea:Super_Pineapple_Milk_Tea]};
    }
endgroup:Spec1

/*
2.	Each case of Bererage_Size should be select at least 100 times.
*/
covergroup Spec2 @(posedge clk iff(inf.size_valid));
    option.per_instance = 1;
	option.at_least = 100;
	bin_bev_size: coverpoint bev_info.bev_size{
        bins b_size[] = {[L:S]};
    }
endgroup:Spec2

/*
3.	Create a cross bin for the SPEC1 and SPEC2. Each combination should be selected at least 100 times.
(Black Tea, Milk Tea, Extra Milk Tea, Green Tea, Green Milk Tea, Pineapple Juice, Super Pineapple Tea, Super Pineapple Tea) x (L, M, S)
*/
covergroup Spec3 @(posedge clk iff(inf.date_valid && cur_act==Make_drink));
    option.per_instance = 1;
   	option.at_least = 100 ; // At least 100 times for this variable

    cross bev_info.bev_type,bev_info.bev_size;
endgroup : Spec3

/*
4.	Output signal inf.err_msg should be No_Err, No_Exp, No_Ing and Ing_OF, each at least 20 times. (Sample the value when inf.out_valid is high)
*/
covergroup Spec4 @(negedge clk iff(inf.out_valid));
    option.per_instance = 1;
   	coverpoint inf.err_msg {
   		option.at_least = 20 ; // At least 10 times for this variable
   		bins b1 = {No_Err};
   		bins b2 = {No_Exp};
   		bins b3 = {No_Ing};
   		bins b4 = {Ing_OF};
    }
endgroup : Spec4

/*
5.	Create the transitions bin for the inf.D.cur_act[0] signal from [0:2] to [0:2]. Each transition should be hit at least 200 times. (sample the value at posedge clk iff inf.sel_action_valid)
*/
covergroup Spec5 @(posedge clk iff(inf.sel_action_valid));
    option.per_instance = 1;
   	coverpoint inf.D.d_act[0] {
   		option.at_least = 200 ; // At least 10 times for this variable
		// A,A,B,B,C,C,A,C,B,CIRCULATES
   		bins b_bev_act_trans[] = (Make_drink,Supply,Check_Valid_Date=>Make_drink,Supply,Check_Valid_Date);// Each cross couple terms
   	}
endgroup: Spec5

/*
6.	Create a covergroup for material of supply action with auto_bin_max = 32, and each bin have to hit at least one time.
*/
covergroup Spec6 @(posedge clk iff(inf.box_sup_valid));
    option.per_instance = 1;
	option.auto_bin_max = 32;
   	coverpoint inf.D.d_ing[0] {
   		option.at_least = 1 ; // At least 10 times for this variable
   	}
endgroup: Spec6
/*
    Create instances of Spec1, Spec2, Spec3, Spec4, Spec5, and Spec6
*/
Spec1 cg_1 = new();
Spec2 cg_2 = new();
Spec3 cg_3 = new();
Spec4 cg_4 = new();
Spec5 cg_5 = new();
Spec6 cg_6 = new();
/*
    Asseration
*/

/*
    If you need, you can declare some FSM, logic, flag, and etc. here.
*/

/*
    1. All outputs signals (including BEV.sv and bridge.sv) should be zero after reset.
*/
always @(negedge inf.rst_n) begin
	#2;
    // Check initial states for output all values
	assert_1 : assert ((inf.out_valid===0)&&(inf.err_msg==No_Err)&&(inf.complete===0)&&
    (inf.C_out_valid===0)&&(inf.C_data_r===0)&&(inf.C_addr===0)&&(inf.C_data_w===0)&&
    (inf.C_in_valid===0)&&(inf.C_r_wb===0)&&(inf.AR_VALID===0)&&(inf.AR_ADDR===0)&&(inf.R_READY===0)
    &&(inf.AW_VALID===0)&&(inf.AW_ADDR===0)&&(inf.W_VALID===0)&&(inf.W_DATA===0)&&(inf.B_READY===0))
	else begin
        $display("===================================================");
		$display("              Assertion 1 is violated              ");
		$display("===================================================");
		$fatal;
	end
end


wire[4:0] month = inf.D.d_date[0].M;
wire[5:0] day   = inf.D.d_date[0].D;

/*
    2.	Latency should be less than 1000 cycles for each operation.
*/
assert_2_1 : assert property ( @(posedge clk) ( (cur_act===Make_drink||cur_act===Check_Valid_Date) && (inf.box_no_valid===1) ) |-> ( ##[1:1000] inf.out_valid===1 ) )
else
begin
	$display("====================================");
	$display("      Assertion 2 is violated       ");
    $display("====================================");
	$fatal;
end

assert_2_2 : assert property ( @(posedge clk) ( (cur_act===Supply) && (inf.box_sup_valid===1) ) |-> ( ##[1:1000] inf.out_valid===1 ) )
else
begin
	$display("====================================");
	$display("      Assertion 2 is violated       ");
    $display("====================================");
	$fatal;
end

/*
    3. If action is completed, err_msg should be no_err
*/
assert_3_0 : assert property ( @(negedge clk) ( (inf.complete === 1) |-> (inf.err_msg === No_Err) ) )
else
begin
	$display("***************************");
	$display("  Assertion 3 is violated");
    $display("***************************");
	$fatal;
end


logic[1:0] cnt;
always_ff @(posedge clk or negedge inf.rst_n)  begin
	if (!inf.rst_n) cnt <= 0 ;
	else begin
		if (inf.box_sup_valid==1) cnt <= cnt + 1;
	end
end
/*
    4. Next input valid will be valid 1-4 cycles after previous input valid fall
*/
// Make drink
assert_4_0 : assert property ( @(negedge clk) ( (cur_act===Make_drink) && (inf.sel_action_valid===1) ) |-> ( ##[1:4] inf.type_valid===1 ) )
else
begin
	$display("***************************");
	$display("  Assertion 4 is violated");
    $display("***************************");
	$fatal;
end

assert_4_1 : assert property ( @(posedge clk) ( (cur_act===Make_drink) && (inf.type_valid===1) ) |-> ( ##[1:4] inf.size_valid===1 ) )
else
begin
	$display("***************************");
	$display("  Assertion 4 is violated");
    $display("***************************");
	$fatal;
end

assert_4_2 : assert property ( @(posedge clk) ( (cur_act===Make_drink) && (inf.size_valid===1) ) |-> ( ##[1:4] inf.date_valid===1 ) )
else
begin
	$display("***************************");
	$display("  Assertion 4 is violated");
    $display("***************************");
	$fatal;
end

assert_4_3 : assert property ( @(posedge clk) ( ((cur_act===Make_drink)) && (inf.date_valid===1) ) |-> ( ##[1:4] inf.box_no_valid===1 ) )
else
begin
	$display("***************************");
	$display("  Assertion 4 is violated");
    $display("***************************");
	$fatal;
end

// Supply
assert_4_4 : assert property ( @(negedge clk) ( (cur_act===Supply) && (inf.sel_action_valid===1) ) |-> ( ##[1:4] inf.date_valid===1 ) )
else
begin
	$display("***************************");
	$display("  Assertion 4 is violated");
    $display("***************************");
	$fatal;
end

assert_4_5 : assert property ( @(posedge clk) ( (cur_act===Supply) && (inf.box_no_valid===1) ) |-> ( ##[1:4] inf.box_sup_valid===1 ) )
else
begin
	$display("***************************");
	$display("  Assertion 4 is violated");
    $display("***************************");
	$fatal;
end


assert_4_7 : assert property ( @(posedge clk) ( (cur_act===Supply) && (inf.box_sup_valid===1) && (cnt!==3) ) |-> ( ##[1:4] inf.box_sup_valid===1 ) )
else
begin
	$display("***************************");
	$display("  Assertion 4 is violated");
    $display("***************************");
	$fatal;
end

// Check valid date
assert_4_8 : assert property ( @(negedge clk) ( (cur_act===Check_Valid_Date) && (inf.sel_action_valid===1) ) |-> ( ##[1:4] inf.date_valid===1 ) )
else
begin
	$display("***************************");
	$display("  Assertion 4 is violated");
    $display("***************************");
	$fatal;
end

assert_4_9 : assert property ( @(negedge clk) ( (cur_act===Check_Valid_Date) && (inf.date_valid===1) ) |-> ( ##[1:4] inf.box_no_valid===1 ) )
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
wire none = !((inf.sel_action_valid===1) || (inf.type_valid===1) || (inf.size_valid===1) || (inf.date_valid===1) || (inf.box_no_valid===1) || (inf.box_sup_valid===1) );
assert_5: assert property ( @(posedge clk) $onehot({inf.sel_action_valid, inf.type_valid,inf.size_valid, inf.date_valid, inf.box_no_valid, inf.box_sup_valid, none}) )
else
begin
 	$display("============================================");
 	$display("          Assertion 5 is violated           ");
 	$display("============================================");
 	$fatal;
end

/*
    6. Out_valid can only be high for exactly one cycle.
*/
assert_6 : assert property ( @(posedge clk) (inf.out_valid===1) |=> (inf.out_valid===0) )
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
assert_7 : assert property ( @(posedge clk) (inf.out_valid===1) |-> ##[1:4] (inf.sel_action_valid === 1) )
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
// 1,3,5,7,8,10,12
// 2
// 4,6,9,11
assert_8_0: assert property(@(posedge clk) ( (inf.date_valid) && (month===1 || month===3 || month===5 || month===7 || month===8 || month===10 || month===12) ) |-> ( day>=1 && day<=31))
else
begin
	$display("***************************");
	$display("  Assertion 8 is violated");
    $display("***************************");
	$fatal;
end

assert_8_1: assert property(@(posedge clk) (inf.date_valid) |-> ( month >= 1 && month <= 12))
else
begin
	$display("***************************");
	$display("  Assertion 8 is violated");
    $display("***************************");
	$fatal;
end

assert_8_2: assert property(@(posedge clk) ( (inf.date_valid) && (month===2)) |-> (day>=1 && day<=28))
else
begin
	$display("***************************");
	$display("  Assertion 8 is violated");
    $display("***************************");
	$fatal;
end

assert_8_3: assert property(@(posedge clk) ( (inf.date_valid) && (month===4 || month===6 || month===9 || month===11)) |-> (day>=1 && day<=30))
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
assert_9: assert property(C_in_valid_low_property)
else
begin
	$display("***************************");
	$display("  Assertion 9 is violated");
    $display("***************************");
	$fatal;
end

property C_in_valid_low_property;
	@(posedge clk)  (inf.C_in_valid === 1) |=> ((inf.C_in_valid === 0) until $fell(inf.C_out_valid===1));
endproperty

endmodule
