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

//***** Coverage Part *****


//class BEV;
    Bev_Type bev_type;
    Bev_Size bev_size;
//endclass
logic size_valid_d1;


//BEV bev_info = new();

always_ff @( posedge clk ) begin
    if(inf.type_valid)  bev_type <= inf.D.d_type[0];
end
always_ff @( posedge clk ) begin
    if(inf.size_valid)  bev_size <= inf.D.d_size[0];
end
always_ff @( posedge clk ) begin
    size_valid_d1 <= inf.size_valid;
end

// 1.   Each case of Beverage_Type should be select at least 100 times.
covergroup Spec1 @(posedge clk iff(inf.type_valid));
    option.per_instance = 1;
    option.at_least = 100;
    btype:coverpoint inf.D.d_type[0]{
        bins b_bev_type [] = {[Black_Tea:Super_Pineapple_Milk_Tea]};
    }
endgroup

// 2.	Each case of Bererage_Size should be select at least 100 times.
covergroup Spec2 @(posedge clk iff(inf.size_valid));
    option.per_instance = 1;
    option.at_least = 100;
    bsize:coverpoint inf.D.d_size[0]{
        bins b1 = {L};
        bins b2 = {M};
        bins b3 = {S};
    }
endgroup

// 3.	Create a cross bin for the SPEC1 and SPEC2. Each combination should be selected at least 100 times. 
//      (Black Tea, Milk Tea, Extra Milk Tea, Green Tea, Green Milk Tea, Pineapple Juice, Super Pineapple Tea, Super Pineapple Tea) x (L, M, S)
covergroup Spec3 @(posedge clk iff(size_valid_d1));
    option.per_instance = 1;
    option.at_least = 100;
    bcross:cross bev_type, bev_size{
        
    }
endgroup

// 4.	Output signal inf.err_msg should be No_Err, No_Exp, No_Ing and Ing_OF, each at least 20 times. (Sample the value when inf.out_valid is high)
covergroup Spec4 @(posedge clk iff(inf.out_valid));
    option.per_instance = 1;
    coverpoint inf.err_msg{
        option.at_least = 20;
        bins b0 = {No_Err};
        bins b1 = {No_Exp};
        bins b2 = {No_Ing};
        bins b3 = {Ing_OF};
    }
endgroup    

// 5.	Create the transitions bin for the inf.D.act[0] signal from [0:2] to [0:2]. Each transition should be hit at least 200 times. (sample the value at posedge clk iff inf.sel_action_valid)
covergroup Spec5 @(posedge clk iff(inf.sel_action_valid));
    option.per_instance = 1;
    coverpoint inf.D.d_act[0]{
        option.at_least = 200;
        bins b[] = ([0:2] => [0:2]);
    }
endgroup

// 6.	Create a covergroup for material of supply action with auto_bin_max = 32, and each bin have to hit at least one time.
covergroup Spec6 @(posedge clk iff(inf.box_sup_valid));
    option.per_instance = 1;
    coverpoint inf.D.d_ing[0]{
        option.at_least = 1;
        option.auto_bin_max = 32;
    }
endgroup

// Create instances of Spec1, Spec2, Spec3, Spec4, Spec5, and Spec6
// Spec1_2_3 cov_inst_1_2_3 = new();

Spec1 cov_1 = new();
Spec2 cov_2 = new();
Spec3 cov_3 = new();
Spec4 cov_4 = new();
Spec5 cov_5 = new();
Spec6 cov_6 = new();


//***** Asseration *****
// If you need, you can declare some FSM, logic, flag, and etc. here.

// 1.   All outputs signals (including BEV.sv and bridge.sv) should be zero after reset.
always @(negedge inf.rst_n) begin
    #1;
    assert_1:   assert((inf.out_valid===0)&(inf.err_msg===0)&(inf.complete===0)&
                        (inf.C_addr===0)&(inf.C_data_w===0)&(inf.C_in_valid===0)&(inf.C_r_wb===0)&
                        (inf.C_out_valid===0)&(inf.C_data_r===0)&
                        (inf.AR_VALID===0)&(inf.AR_ADDR===0)&(inf.R_READY===0)&
                        (inf.AW_VALID===0)&(inf.AW_ADDR===0)&(inf.W_VALID===0)&(inf.W_DATA===0)&(inf.B_READY===0))
                else begin
                    $display("Assertion 1 is violated");
                    $fatal;
                end
end
// out_valid, err_msg, complete,
// C_addr, C_data_w, C_in_valid, C_r_wb
// C_out_valid, C_data_r, 
// AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY

// 2.   Latency should be less than 1000 cycles for each operation.
Action act;
always_ff @( posedge clk ) begin
    if(inf.sel_action_valid)    act <= inf.D.d_act[0];
    else                        act <= act;
end

assert_2_make_drink:    assert property(@(posedge clk) (act==Make_drink && inf.box_no_valid===1) |-> ##[1:1000] inf.out_valid===1)
                        else begin
                            $display("Assertion 2 is violated");
                            $fatal;
                        end
assert_2_supply:        assert property(@(posedge clk) (act==Supply && inf.box_sup_valid===1) |-> ##[1:1000] inf.out_valid===1)
                        else begin
                            $display("Assertion 2 is violated");
                            $fatal;
                        end
assert_2_check_date:    assert property(@(posedge clk) (act==Check_Valid_Date && inf.box_no_valid===1) |-> ##[1:1000] inf.out_valid===1)
                        else begin
                            $display("Assertion 2 is violated");
                            $fatal;
                        end


// 3.   If action is completed (complete=1), err_msg should be 2’b0 (no_err).
assert_3:   assert property(@(negedge clk) (inf.complete===1)|->(inf.err_msg===0)) //@(posedge clk) 
            else begin
                $display("Assertion 3 is violated");
                $fatal;
            end

// 4.   Next input valid will be valid 1-4 cycles after previous input valid fall.
//TODO: depend on action
logic [1:0] cnt_box_sup;
always_ff @( posedge clk or negedge inf.rst_n ) begin
    if(~inf.rst_n)              cnt_box_sup <= 'd0;
    else if(inf.box_sup_valid)  cnt_box_sup <= cnt_box_sup + 'd1;
    else                        cnt_box_sup <= cnt_box_sup;
end



property p_in_make_drink;
    @(posedge clk) (inf.D.d_act[0]==Make_drink && inf.sel_action_valid===1) |-> ##[1:4] inf.type_valid;// |-> ##[1:4] inf.size_valid===1 |-> ##[1:4] inf.date_valid===1 |-> ##[1:4] inf.box_no_valid===1;
endproperty
property p_in_make_drink_1;
    @(posedge clk) (act==Make_drink && inf.type_valid) |-> ##[1:4] inf.size_valid;
endproperty
property p_in_make_drink_2;
    @(posedge clk) (act==Make_drink && inf.size_valid) |-> ##[1:4] inf.date_valid;
endproperty
property p_in_make_drink_3;
    @(posedge clk) (act==Make_drink && inf.date_valid) |-> ##[1:4] inf.box_no_valid;
endproperty

property p_supply;
    @(posedge clk) (inf.D.d_act[0]==Supply && inf.sel_action_valid===1) |-> ##[1:4] inf.date_valid;// |-> ##[1:4] inf.box_no_valid;// |-> ##[1:4] inf.box_sup_valid===1;
    // |-> ##[1:4] inf.box_sup_valid===1 |-> ##[1:4] inf.box_sup_valid===1 |-> ##[1:4] inf.box_sup_valid===1;
endproperty
property p_supply_0;
    @(posedge clk) (act==Supply && inf.date_valid) |-> ##[1:4] inf.box_no_valid;
endproperty
property p_supply_1;
    @(posedge clk) (act==Supply && inf.box_no_valid) |-> ##[1:4] inf.box_sup_valid;
endproperty
property p_supply_2;
    @(posedge clk) (act==Supply && cnt_box_sup==0 && inf.box_sup_valid) |-> ##[1:4] inf.box_sup_valid;
endproperty
property p_supply_3;
    @(posedge clk) (act==Supply && cnt_box_sup==1 && inf.box_sup_valid) |-> ##[1:4] inf.box_sup_valid;
endproperty
property p_supply_4;
    @(posedge clk) (act==Supply && cnt_box_sup==2 && inf.box_sup_valid) |-> ##[1:4] inf.box_sup_valid;
endproperty


property p_check_date;
    @(posedge clk) (inf.D.d_act[0]==Check_Valid_Date && inf.sel_action_valid) |-> ##[1:4] inf.date_valid;// |-> ##[1:4] inf.box_no_valid===1;
endproperty
property p_check_date_1;
    @(posedge clk) (act==Check_Valid_Date && inf.date_valid) |-> ##[1:4] inf.box_no_valid;
endproperty

assert_4_make_drink:    assert property(p_in_make_drink)
                        else begin
                            $display("Assertion 4 is violated");
                            $fatal;
                        end
assert_4_make_drink1:    assert property(p_in_make_drink_1)
                        else begin
                            $display("Assertion 4 is violated");
                            $fatal;
                        end
assert_4_make_drink2:    assert property(p_in_make_drink_2)
                        else begin
                            $display("Assertion 4 is violated");
                            $fatal;
                        end
assert_4_make_drink3:    assert property(p_in_make_drink_3)
                        else begin
                            $display("Assertion 4 is violated");
                            $fatal;
                        end

assert_4_supply:        assert property(p_supply)
                        else begin
                            $display("Assertion 4 is violated");
                            $fatal;
                        end
assert_4_supply0:        assert property(p_supply_0)
                        else begin
                            $display("Assertion 4 is violated");
                            $fatal;
                        end
assert_4_supply1:        assert property(p_supply_1)
                        else begin
                            $display("Assertion 4 is violated");
                            $fatal;
                        end
assert_4_supply2:        assert property(p_supply_2)
                        else begin
                            $display("Assertion 4 is violated");
                            $fatal;
                        end
assert_4_supply3:        assert property(p_supply_3)
                        else begin
                            $display("Assertion 4 is violated");
                            $fatal;
                        end
assert_4_supply4:        assert property(p_supply_4)
                        else begin
                            $display("Assertion 4 is violated");
                            $fatal;
                        end



assert_4_check_date:    assert property(p_check_date)
                        else begin
                            $display("Assertion 4 is violated");
                            $fatal;
                        end
assert_4_check_date1:    assert property(p_check_date_1)
                        else begin
                            $display("Assertion 4 is violated");
                            $fatal;
                        end


// 5.   All input valid signals won't overlap with each other. //TODO
// sel_action_valid, type_valid, size_valid, date_valid, box_no_valid, box_sup_valid
assert_5:   assert property(@(posedge clk) $onehot0({inf.sel_action_valid, inf.type_valid, inf.size_valid, inf.date_valid, inf.box_no_valid, inf.box_sup_valid}))
            else begin
                $display("Assertion 5 is violated");
                $fatal;
            end



/*
sequence only_sel_action;
    (inf.type_valid===0)&(inf.size_valid===0)&(inf.date_valid===0)&(inf.box_no_valid===0)&(inf.box_sup_valid===0);
endsequence
sequence only_type;
    (inf.sel_action_valid===0)&(inf.size_valid===0)&(inf.date_valid===0)&(inf.box_no_valid===0)&(inf.box_sup_valid===0);
endsequence
sequence only_size;
    (inf.sel_action_valid===0)&(inf.type_valid===0)&(inf.date_valid===0)&(inf.box_no_valid===0)&(inf.box_sup_valid===0);
endsequence
sequence only_date;
    (inf.sel_action_valid===0)&(inf.type_valid===0)&(inf.size_valid===0)&(inf.box_no_valid===0)&(inf.box_sup_valid===0);
endsequence
sequence only_box_no;
    (inf.sel_action_valid===0)&(inf.type_valid===0)&(inf.size_valid===0)&(inf.date_valid===0)&(inf.box_sup_valid===0);
endsequence
sequence only_box_sup;
    (inf.sel_action_valid===0)&(inf.type_valid===0)&(inf.size_valid===0)&(inf.date_valid===0)&(inf.box_no_valid===0);
endsequence


assert_5_sel_action:    assert property(@(posedge clk) (inf.sel_action_valid===1)|->(only_sel_action))
                        else begin
                            $display("Assertion 5 is violated");
                            $fatal;
                        end
assert_5_type:          assert property(@(posedge clk) (inf.type_valid===1)|->(only_type))
                        else begin
                            $display("Assertion 5 is violated");
                            $fatal;
                        end
assert_5_size:          assert property(@(posedge clk) (inf.size_valid===1)|->(only_size))
                        else begin
                            $display("Assertion 5 is violated");
                            $fatal;
                        end
assert_5_date:          assert property(@(posedge clk) (inf.date_valid===1)|->(only_date))
                        else begin
                            $display("Assertion 5 is violated");
                            $fatal;
                        end
assert_5_box_no:        assert property(@(posedge clk) (inf.box_no_valid===1)|->(only_box_no))
                        else begin
                            $display("Assertion 5 is violated");
                            $fatal;
                        end
assert_5_box_sup:       assert property(@(posedge clk) (inf.box_sup_valid===1)|->(only_box_sup))
                        else begin
                            $display("Assertion 5 is violated");
                            $fatal;
                        end
*/


// 6.   Out_valid can only be high for exactly one cycle.
assert_6:   assert property(@(posedge clk) (inf.out_valid===1)|=>(inf.out_valid===0))
            else begin
                $display("Assertion 6 is violated");
                $fatal;
            end

// 7.   Next operation will be valid 1-4 cycles after out_valid fall. //! why not ##[1:4]
assert_7:   assert property(@(posedge clk) (inf.out_valid===1) |-> ##[1:4] (inf.sel_action_valid===1))
            else begin
                $display("Assertion 7 is violated");
                $fatal;
            end

// 8.   The input date from pattern should adhere to the real calendar. (ex: 2/29, 3/0, 4/31, 13/1 are illegal cases)
logic real_calendar;

assert_8:   assert property(p_assert_8)
            else begin
                $display("Assertion 8 is violated");
                $fatal;
            end

property p_assert_8;
    @(posedge clk) (inf.date_valid |-> real_calendar);
endproperty

always_comb begin
    if(inf.D.d_date[0].M=='d2) begin
        if(inf.D.d_date[0].D >= 'd1 && inf.D.d_date[0].D <= 'd28)   real_calendar = 1'b1;
        else                                                        real_calendar = 1'b0;
    end
    else if(inf.D.d_date[0].M=='d1 || inf.D.d_date[0].M=='d3 || inf.D.d_date[0].M=='d5 || inf.D.d_date[0].M=='d7 ||
            inf.D.d_date[0].M=='d8 || inf.D.d_date[0].M=='d10 || inf.D.d_date[0].M=='d12) begin
                if(inf.D.d_date[0].D >= 'd1 && inf.D.d_date[0].D <= 'd31)   real_calendar = 1'b1;
                else                                                        real_calendar = 1'b0;
            end
    else if(inf.D.d_date[0].M=='d4 || inf.D.d_date[0].M=='d6 || inf.D.d_date[0].M=='d9 || inf.D.d_date[0].M=='d11) begin
        if(inf.D.d_date[0].D >= 'd1 && inf.D.d_date[0].D <= 'd30)   real_calendar = 1'b1;
        else                                                        real_calendar = 1'b0;
    end
    else    real_calendar = 1'b0;
end

// 9.   C_in_valid can only be high for one cycle and can't be pulled high again before C_out_valid
logic bridge_busy;
always_ff @( posedge clk or negedge inf.rst_n ) begin
    if(~inf.rst_n)              bridge_busy <= 1'b0;
    else if(inf.C_in_valid)     bridge_busy <= 1'b1;
    else if(inf.C_out_valid)    bridge_busy <= 1'b0;
    else                        bridge_busy <= bridge_busy;
end

assert_9_1: assert property(@(posedge clk) (inf.C_in_valid===1)|=>(inf.C_in_valid===0))
            else begin
                $display("Assertion 9 is violated");
                $fatal;
            end
assert_9_2: assert property(@(posedge clk) (inf.C_in_valid |-> ~bridge_busy))
            else begin
                $display("Assertion 9 is violated");
                $fatal;
            end



endmodule
