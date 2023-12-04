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

// class BEV;
//     Bev_Type bev_type;
//     Bev_Size bev_size;
// endclass

// BEV bev_info = new();

// always_ff @(posedge clk) begin
//     if (inf.type_valid) begin
//         bev_info.bev_type = inf.D.d_type[0];
//     end
// end

// always_ff @(posedge clk) begin
//     if (inf.size_valid) begin
//         bev_info.bev_size = inf.D.d_size[0];
//     end
// end





/*
2.	Each case of Bererage_Size should be select at least 100 times.
*/


/*
3.	Create a cross bin for the SPEC1 and SPEC2. Each combination should be selected at least 100 times.
(Black Tea, Milk Tea, Extra Milk Tea, Green Tea, Green Milk Tea, Pineapple Juice, Super Pineapple Tea, Super Pineapple Tea) x (L, M, S)
*/


/*
4.	Output signal inf.err_msg should be No_Err, No_Exp, No_Ing and Ing_OF, each at least 20 times. (Sample the value when inf.out_valid is high)
*/


/*
5.	Create the transitions bin for the inf.D.cur_act[0] signal from [0:2] to [0:2]. Each transition should be hit at least 200 times. (sample the value at posedge clk iff inf.sel_action_valid)
*/


/*
6.	Create a covergroup for material of supply action with auto_bin_max = 32, and each bin have to hit at least one time.
*/


/*
    Create instances of Spec1, Spec2, Spec3, Spec4, Spec5, and Spec6
*/


/*
    Asseration
*/

/*
    If you need, you can declare some FSM, logic, flag, and etc. here.
*/


/*
    1. All outputs signals (including BEV.sv and bridge.sv) should be zero after reset.
*/


/*
    2.	Latency should be less than 1000 cycles for each operation.
*/


/*
    3. If action is completed, err_msg should be no_err
*/


/*
    4. Next input valid will be valid 1-4 cycles after previous input valid fall
*/


/*
    5. All input valid signals won't overlap with each other.
*/


/*
    6. Out_valid can only be high for exactly one cycle.
*/

/*
    7. Next operation will be valid 1-4 cycles after out_valid fall.
*/



/*
    8. The input date from pattern should adhere to the real calendar. (ex: 2/29, 3/0, 4/31, 13/1 are illegal cases)
*/


/*
    9. C_in_valid can only be high for one cycle and can't be pulled high again before C_out_valid
*/


endmodule
