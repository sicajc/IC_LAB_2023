//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2021 ICLAB Spring Course
//   Lab10		 : Happy Farm (HF)
//   Author    	 : Shiuan-Yun Ding (mirkat.ding@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : CHECKER.sv
//   Module Name : Checker
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
//`include "Usertype_PKG.sv"

module Checker(input clk, INF.CHECKER inf);
import usertype::*;
//================================================================
//  define cover group
//================================================================
// bins*at_least = 5 * 100 = 500
covergroup Spec1 @(posedge clk && inf.amnt_valid);
    //Each bins hits at least 100 times, five bins ranging from this range.
	coverpoint inf.D.d_amnt {
		option.at_least = 100 ;     // Define for each bins, it hits 100 times
		bins b1 = {[    0:12000]} ; // The range of the bins
		bins b2 = {[12001:24000]} ;
		bins b3 = {[24001:36000]} ;
		bins b4 = {[36001:48000]} ;
		bins b5 = {[48001:60000]} ;
	}
endgroup : Spec1
// bins*at_least = 255 * 10 = 2550
covergroup Spec2 @(posedge clk && inf.id_valid);// Sampling timing
   	coverpoint inf.D.d_id[0] { // The variable you want to cover
   		option.at_least = 10 ;
   		option.auto_bin_max = 255 ; //Dividing inf.D.d_id[0] into 255 bins averagely
   	}
endgroup : Spec2
// bins*at_least = 25 * 10 = 250
covergroup Spec3 @(posedge clk && inf.act_valid);
   	coverpoint inf.D.d_act[0] {
   		option.at_least = 10 ; // At least 10 times for this variable
   		bins b[] = (Seed, Water, Reap, Steal, Check_dep => Seed, Water, Reap, Steal, Check_dep) ;// Each cross couple terms
   	}
endgroup : Spec3
// bins*at_least = 4 * 100 = 400
covergroup Spec4 @(negedge clk && inf.out_valid);// Notice spec want us to sample at negedge clk
	coverpoint inf.err_msg {
		option.at_least = 100 ;
		bins b1 = {Is_Empty } ; // This bins is checking error message except No_Err
		bins b2 = {Not_Empty} ;
		bins b3 = {Has_Grown} ;
		bins b4 = {Not_Grown} ;
	}
endgroup : Spec4
//================================================================
//  declare cover group
//================================================================
// Instantiation of cover group
Spec1 cov_inst_1 = new();
Spec2 cov_inst_2 = new();
Spec3 cov_inst_3 = new();
Spec4 cov_inst_4 = new();

//************************************ below assertion is to check your pattern *****************************************
//                                          Please finish and hand in it
// This is an example assertion given by TA, please write other assertions at the below
// assert_interval : assert property ( @(posedge clk)  inf.out_valid==1 |=> inf.id_valid==0 )
// else begin
// 	$display("Assertion X is violated");
// 	$fatal;
// end
//================================================================
//  assertions
//================================================================
// 1. All outputs should be zero after reset, note always@ also has built in assertion.
always @(negedge inf.rst_n) begin
	#1;
    // Check initial states for all values
	assert_1 : assert ((inf.out_valid===0)&&(inf.err_msg==No_Err)&&(inf.complete===0)&&(inf.out_info===0)&&(inf.out_deposit===0))
	else begin
		$display("Assertion 1 is violated");
		$fatal;
	end
end

// 2. If action is completed, err_msg must be 4’b0, immediately checks the transition at same time.
assert_2 : assert property ( @(posedge clk) (inf.complete===1) |-> (inf.err_msg===No_Err) )
 else
 begin
 	$display("Assertion 2 is violated");
 	$fatal;
 end
//================================================================
Action act ;
always_ff @(posedge clk or negedge inf.rst_n)  begin
	if (!inf.rst_n)				act <= No_action ;
	else begin
		if (inf.act_valid==1) 	act <= inf.D.d_act[0] ;
	end
end
//================================================================
 // 3. If action is “check deposit”, out_info should be 0 when out_valid is high.
assert_3 : assert property ( @(posedge clk) ( act===Check_dep && inf.out_valid===1 ) |-> (inf.out_info===0) )
else
begin
	$display("Assertion 3 is violated");
 	$fatal;
end
// 4. If action isn’t “check deposit”, out_deposit should be 0 when out_valid is high.
assert_4 :assert property ( @(posedge clk)   ( act!==Check_dep && inf.out_valid===1 ) |-> (inf.out_deposit===0) )
else
begin
 	$display("Assertion 4 is violated");
 	$fatal;
end
// 5. Out_valid will be high for one cycle.
assert_5 : assert property ( @(posedge clk)  (inf.out_valid===1) |=> (inf.out_valid===0) )
else
begin
	$display("Assertion 5 is violated");
	$fatal;
end
// 6. The gap length between id_valid and act_valid is at least 1 cycle.
assert_6 : assert property ( @(posedge clk)  (inf.id_valid===1) |=> (inf.act_valid===0) )
else
begin
 	$display("Assertion 6 is violated");
 	$fatal;
end

// 7. When action is Seed, the gap length between cat_valid and amnt_valid is at least 1 cycle.
assert_7 :assert property ( @(posedge clk) ( act===Seed && inf.cat_valid===1 ) |=> (inf.amnt_valid===0) )
else begin
 	$display("Assertion 7 is violated");
 	$fatal;
end
//================================================================
logic no_one;
assign no_one = !( inf.id_valid || inf.act_valid || inf.cat_valid || inf.amnt_valid ) ;
//================================================================
// 8. The four valid signals won’t overlap with each other.( id_valid, act_valid, cat_valid, amnt_valid )
assert_8 :assert property ( @(posedge clk) $onehot({ inf.id_valid, inf.act_valid, inf.cat_valid, inf.amnt_valid , no_one }) )
// Means only one of these 5 property can appear at once.
else
begin
 	$display("Assertion 8 is violated");
 	$fatal;
end
// 9. Next operation will be valid 2-10 cycles after out_valid fall.
assert_9 :assert property ( @(posedge clk) (inf.out_valid==1)  |-> ##[2:10] ( inf.id_valid===1 || inf.act_valid===1) )
else begin
 	$display("Assertion 9 is violated");
 	$fatal;
end
// 10. Latency should be less than 1200 cycle for each operation.
assert_10_1 : assert property ( @(posedge clk) ( (act==Seed||act==Water) && (inf.amnt_valid===1) ) |-> ( ##[1:1200] inf.out_valid===1 ) )
else
begin
	$display("Assertion 10 is violated");
	$fatal;
end
assert_10_2 : assert property ( @(posedge clk) ( (inf.D.d_act[0]==Reap||inf.D.d_act[0]==Steal||inf.D.d_act[0]==Check_dep) && (inf.act_valid===1)) |-> ( ##[1:1200] inf.out_valid===1 ) )
else
begin
	$display("Assertion 10 is violated");
	$fatal;
end

endmodule