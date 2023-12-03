/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory 
Lab09: SystemVerilog Design and Verification 
File Name   : PATTERN.sv
Module Name : PATTERN
Release version : v1.0 (Release Date: Nov-2023)
Author : Jui-Huang Tsai (erictsai.10@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype_BEV.sv"
`define Black   "\033[0;30m"     // Black
`define Red     "\033[0;31m"     // Red
`define Green   "\033[0;32m"     // Green
`define Yellow  "\033[0;33m"     // Yellow
`define Blue    "\033[0;34m"     // Blue
`define Purple  "\033[0;35m"     // Purple
`define Cyan    "\033[0;36m"     // Cyan
`define White   "\033[0;37m"     // White

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;
/*modport PATTERN(
        input out_valid, err_msg, complete,
        output rst_n, sel_action_valid, type_valid, 
                size_valid, date_valid, box_no_valid, box_sup_valid, D
    );*/
//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";

//================================================================
// wire & registers 
//================================================================
logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];  // 256 box
integer SEED = 123;
Action ACTION;
//assign ACTION = inf.D.d_act[0];
Bev_Type TYPE;
//assign TYPE = inf.D.d_type[0];
Bev_Size SIZE;
//assign SIZE = inf.D.d_size[0];
Date DATE;
//assign DATE = inf.D.d_date[0];
Barrel_No BOX_NO;
//assign BOX_NO = inf.D.d_box_no[0];

logic [63:0] DATA;
assign DATA = {golden_DRAM[65536+BOX_NO*8+7], golden_DRAM[65536+BOX_NO*8+6],
                golden_DRAM[65536+BOX_NO*8+5], golden_DRAM[65536+BOX_NO*8+4],
                golden_DRAM[65536+BOX_NO*8+3], golden_DRAM[65536+BOX_NO*8+2],
                golden_DRAM[65536+BOX_NO*8+1], golden_DRAM[65536+BOX_NO*8+0]};

logic OVER;
logic [11:0] MM0, MM1, MM2, MM3;

logic [63:0] WRITE_BACK;
logic [11:0] S1, S2, S3, S4;
//================================================================
// class random
//================================================================

class random_action;
    randc Action act_id;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint range{
        act_id inside{Make_drink, Supply, Check_Valid_Date};
    }
endclass

class random_type;
    randc Bev_Type bev_type;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint range{
        bev_type inside{Black_Tea, Milk_Tea, Extra_Milk_Tea, Green_Tea, Green_Milk_Tea,
                        Pineapple_Juice, Super_Pineapple_Tea, Super_Pineapple_Milk_Tea};
    }
endclass

class random_size;
    randc Bev_Size bev_size;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint range{
        bev_size inside{L, M, S};
    }
endclass

class random_date;
    randc Month month;
    randc Day day;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint limit{
        month inside{[1:12]};
        (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) -> day inside{[1:31]};
        (month == 4 || month == 6 || month == 9 || month == 11) -> day inside{[1:30]};
        (month == 2) -> day inside{[1:28]};
    }
endclass

class random_box_no;
    randc Barrel_No box_no;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint range{
        box_no inside{[0:255]};
    }
endclass

class random_ing;
    randc ING ing;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint range{
        ing inside{[0:4095]};
    }
endclass


random_action r_act_id = new(SEED);
random_type r_bev_type = new(SEED);
random_size r_bev_size = new(SEED);
random_date r_date = new(SEED);
Date date;
random_box_no r_box_no = new(SEED);
random_ing r_ing = new(SEED);
integer i;
logic [15:0] counter_0;
logic [15:0] counter_t;
//================================================================
// initial
//================================================================
initial begin
    counter_0 = 0;
    counter_t = 0;
    inf.sel_action_valid = 0;
    inf.type_valid = 0;
    inf.size_valid = 0;
    inf.date_valid = 0;
    inf.box_no_valid = 0;
    inf.box_sup_valid = 0;
    inf.D = 'dx;
    reset_signal_task;
    i = 0;

    $readmemh(DRAM_p_r,golden_DRAM);
    repeat(3600) begin
        
        i = i + 1;
        invalid_select_action;
        $display(`Yellow, "*  ACTION: %p   *",ACTION);
        $display(`White,"*****************************************");
        case(ACTION)
            Make_drink: begin
                invalid_type;
                invalid_size;
                invalid_date;
                invalid_box_no;
                $display(`Blue, "*  BOX_NO %d   *",BOX_NO);
                $display(`White,"*****************************************");
                $display(`Blue, "*  DATA %h   *",DATA);
                $display(`White,"*****************************************");
                check_make_drink;
                //repeat( ({$random(SEED)} % 4 + 0) ) @(negedge clk);//0 1 2 3
            end 
            Supply: begin
                invalid_date;
                invalid_box_no;
                invalid_box_sup;
                check_supply;
                //repeat( ({$random(SEED)} % 4 + 0) ) @(negedge clk);//0 1 2 3

            end 
            Check_Valid_Date: begin
                invalid_date;
                invalid_box_no;
                check_date;
                //repeat( ({$random(SEED)} % 4 + 0) ) @(negedge clk);//0 1 2 3
            end 
        endcase
        $display(`White,"*****************************************");
        $display(`White,"*           pass pattern %d    *", i);
        $display(`White,"*****************************************");
    end 
    //repeat(5) #(10);
    $display(`White,"*****************************************");
    $display(`White,"*              Congratulations          *");
    $display(`White,"*****************************************");
    $finish;
end

task reset_signal_task; begin
    inf.rst_n            = 1;
    inf.sel_action_valid = 0;
    inf.type_valid       = 0;
    inf.size_valid       = 0;
    inf.date_valid       = 0;
    inf.box_no_valid     = 0;
    inf.box_sup_valid    = 0;
    inf.D                = 'dx;
    force clk = 0;
    #(10); inf.rst_n = 0; 
    #(10); inf.rst_n = 1;
    if ( inf.out_valid !== 0 || inf.complete !== 0 || inf.err_msg !== 0) begin
        //$display("************************************************************");  
        //$display("                          FAIL!                             ");    
        //$display(`Yellow,"*                    SPEC MAIN-1 FAIL                      *");
        //$display("*  Output signal should be 0 after initial RESET  at %8t   *",$time);
        //$display(`White,"************************************************************");
        repeat(5) #(10);
        $finish;
    end
	#(10); release clk;
end endtask

/*always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) counter_0 <= 0;
    else counter_0 <= counter_0_nxt;
end */
Action SSS;

task invalid_select_action; begin
    //repeat( ({$random(SEED)} % 4 + 0) ) @(negedge clk);//1 2 3 4 
    inf.sel_action_valid = 1;
    //r_act_id.randomize();
    //inf.D.d_act[0] = r_act_id.act_id;
    if(counter_0 < 1800) SSS = Make_drink;
    else if(counter_0 % 9 === 0) SSS = Check_Valid_Date;
    else if(counter_0 % 9 === 1) SSS = Check_Valid_Date;
    else if(counter_0 % 9 === 2) SSS = Supply;
    else if(counter_0 % 9 === 3) SSS = Supply;
    else if(counter_0 % 9 === 4) SSS = Make_drink;
    else if(counter_0 % 9 === 5) SSS = Make_drink;
    else if(counter_0 % 9 === 6) SSS = Supply;
    else if(counter_0 % 9 === 7) SSS = Check_Valid_Date;
    else if(counter_0 % 9 === 8) SSS = Make_drink;

    inf.D.d_act[0] = SSS;
    counter_0 = counter_0 + 1;
    ACTION = inf.D.d_act[0];
    $display(`Yellow, "*  inf.D.d_act[0] %d   *",inf.D.d_act[0]);
    $display(`White,"*****************************************");
    @(negedge clk);
    inf.sel_action_valid = 0;
    inf.D                = 'dx;
    inf.type_valid       = 0;
    inf.size_valid       = 0;
    inf.date_valid       = 0;
    inf.box_no_valid     = 0;
    inf.box_sup_valid    = 0;
end endtask

Bev_Type TTT;

task invalid_type; begin
    //repeat( ({$random(SEED)} % 4 + 0) ) @(negedge clk);//0 1 2 3 
    inf.type_valid = 1;
    //r_bev_type.randomize();
    //inf.D.d_type[0] = r_bev_type.bev_type;
    if(counter_t<300) TTT = Black_Tea;
    else if(counter_t<600) TTT = Milk_Tea;
    else if(counter_t<900) TTT = Extra_Milk_Tea;
    else if(counter_t<1200) TTT = Green_Tea;
    else if(counter_t<1500) TTT = Green_Milk_Tea;
    else if(counter_t<1800) TTT = Pineapple_Juice;
    else if(counter_t<2100) TTT = Super_Pineapple_Tea;
    else if(counter_t<2400) TTT = Super_Pineapple_Milk_Tea;
    inf.D.d_type[0] = TTT;
    counter_t = counter_t + 1;
    TYPE = inf.D.d_type[0];
    $display(`Yellow, "*  inf.D.d_type[0] %d   *",inf.D.d_type[0]);
    $display(`White,"*****************************************");
    @(negedge clk);
    inf.type_valid = 0;
    inf.sel_action_valid = 0;
    inf.D                = 'dx;
    inf.size_valid       = 0;
    inf.date_valid       = 0;
    inf.box_no_valid     = 0;
    inf.box_sup_valid    = 0;
end endtask

task invalid_size; begin
    //repeat( ({$random(SEED)} % 4 + 0) ) @(negedge clk);//0 1 2 3 
    inf.size_valid = 1;
    r_bev_size.randomize();
    inf.D.d_size[0] = r_bev_size.bev_size;
    SIZE = inf.D.d_size[0];
    $display(`Yellow, "*  inf.D.d_size[0] %d   *",inf.D.d_size[0]);
    $display(`White,"*****************************************");
    @(negedge clk);
    inf.type_valid = 0;
    inf.sel_action_valid = 0;
    inf.size_valid       = 0;
    inf.D                = 'dx;
    inf.date_valid       = 0;
    inf.box_no_valid     = 0;
    inf.box_sup_valid    = 0;
end endtask

task invalid_date; begin
    //repeat( ({$random(SEED)} % 4 + 0) ) @(negedge clk);//0 1 2 3 
    inf.date_valid = 1;
    r_date.randomize();
    date.M = r_date.month;
    date.D = r_date.day;
    inf.D.d_date[0] = date;
    DATE = inf.D.d_date[0];
    $display(`Yellow, "*  inf.D.d_date[0] %d %d  *",inf.D.d_date[0].M,inf.D.d_date[0].D);
    $display(`White,"*****************************************");
    @(negedge clk);
    inf.type_valid = 0;
    inf.sel_action_valid = 0;
    inf.size_valid       = 0;
    inf.date_valid       = 0;
    inf.D                = 'dx;
    inf.box_no_valid     = 0;
    inf.box_sup_valid    = 0;
end endtask

task invalid_box_no; begin
    //repeat( ({$random(SEED)} % 4 + 0) ) @(negedge clk);//0 1 2 3 
    inf.box_no_valid = 1;
    r_box_no.randomize();
    inf.D.d_box_no[0] = r_box_no.box_no;
    BOX_NO = inf.D.d_box_no[0];
    $display(`Yellow, "*  inf.D.d_box_no[0]  %d  *",inf.D.d_box_no[0]);
    $display(`White,"*****************************************");
    @(negedge clk);
    inf.type_valid = 0;
    inf.sel_action_valid = 0;
    inf.size_valid       = 0;
    inf.date_valid       = 0;
    inf.box_no_valid     = 0;
    inf.D                = 'dx;
    inf.box_sup_valid    = 0;
end endtask

task check_make_drink; begin
    //always_comb begin
    OVER = 0;
    MM0 = DATA[63:52];
    MM1 = DATA[51:40];
    MM2 = DATA[31:20];
    MM3 = DATA[19:8];
    $display(`Yellow, "*  black_tea %d   *",DATA[63:52]);
    $display(`White,"*****************************************");
    $display(`Yellow, "*  green_tea %d   *",DATA[51:40]);
    $display(`White,"*****************************************");
    $display(`Yellow, "*  M %d   *",DATA[39:32]);
    $display(`White,"*****************************************");
    $display(`Yellow, "*  milk %d   *",DATA[31:20]);
    $display(`White,"*****************************************");
    $display(`Yellow, "*  pineapple_juice %d   *",DATA[19:8]);
    $display(`White,"*****************************************");
    $display(`Yellow, "*  D %d   *",DATA[7:0]);
    $display(`White,"*****************************************");
    case(TYPE)
        Black_Tea: begin
            case(SIZE)
                L: begin
                    MM0 = DATA[63:52] - 960;
                    if(DATA[63:52] < 960) OVER = 1;
                    else OVER = 0;
                end 
                M: begin
                    MM0 = DATA[63:52] - 720;
                    if(DATA[63:52] < 720) OVER = 1;
                    else OVER = 0;
                end 
                S: begin
                    MM0 = DATA[63:52] - 480;
                    if(DATA[63:52] < 480) OVER = 1;
                    else OVER = 0;
                end 
            endcase
        end 
		Milk_Tea: begin
            case(SIZE)
                L: begin
                    MM0 = DATA[63:52] - 720;
                    MM2 = DATA[31:20] - 240;
                    if(DATA[63:52] < 720) OVER = 1;
                    else if(DATA[31:20] < 240) OVER = 1;
                    else OVER = 0;
                end 
                M: begin
                    MM0 = DATA[63:52] - 540;
                    MM2 = DATA[31:20] - 180;
                    if(DATA[63:52] < 540) OVER = 1;
                    else if(DATA[31:20] < 180) OVER = 1;
                    else OVER = 0;
                end 
                S: begin
                    MM0 = DATA[63:52] - 360;
                    MM2 = DATA[31:20] - 120;
                    if(DATA[63:52] < 360) OVER = 1;
                    else if(DATA[31:20] < 120) OVER = 1;
                    else OVER = 0;
                end 
            endcase
        end 
		Extra_Milk_Tea: begin
            case(SIZE)
                L: begin
                    MM0 = DATA[63:52] - 480;
                    MM2 = DATA[31:20] - 480;
                    if(DATA[63:52] < 480) OVER = 1;
                    else if(DATA[31:20] < 480) OVER = 1;
                    else OVER = 0;
                end 
                M: begin
                    MM0 = DATA[63:52] - 360;
                    MM2 = DATA[31:20] - 360;
                    if(DATA[63:52] < 360) OVER = 1;
                    else if(DATA[31:20] < 360) OVER = 1;
                    else OVER = 0;
                end 
                S: begin
                    MM0 = DATA[63:52] - 240;
                    MM2 = DATA[31:20] - 240;
                    if(DATA[63:52] < 240) OVER = 1;
                    else if(DATA[31:20] < 240) OVER = 1;
                    else OVER = 0;
                end 
            endcase
        end 
		Green_Tea: begin
            case(SIZE)
                L: begin
                    MM1 = DATA[51:40] - 960;
                    if(DATA[51:40] < 960) OVER = 1;
                    else OVER = 0;
                end 
                M: begin
                    MM1 = DATA[51:40] - 720;
                    if(DATA[51:40] < 720) OVER = 1;
                    else OVER = 0;
                end 
                S: begin
                    MM1 = DATA[51:40] - 480;
                    if(DATA[51:40] < 480) OVER = 1;
                    else OVER = 0;
                end 
            endcase
        end 
        Green_Milk_Tea: begin
            case(SIZE)
                L: begin
                    MM1 = DATA[51:40] - 480;
                    MM2 = DATA[31:20] - 480;
                    if(DATA[51:40] < 480) OVER = 1;
                    else if(DATA[31:20] < 480) OVER = 1;
                    else OVER = 0;
                end 
                M: begin
                    MM1 = DATA[51:40] - 360;
                    MM2 = DATA[31:20] - 360;
                    if(DATA[51:40] < 360) OVER = 1;
                    else if(DATA[31:20] < 360) OVER = 1;
                    else OVER = 0;
                end 
                S: begin
                    MM1 = DATA[51:40] - 240;
                    MM2 = DATA[31:20] - 240;
                    if(DATA[51:40] < 240) OVER = 1;
                    else if(DATA[31:20] < 240) OVER = 1;
                    else OVER = 0;
                end 
            endcase
        end 
        Pineapple_Juice: begin
            case(SIZE)
                L: begin
                    MM3 = DATA[19:8] - 960;
                    if(DATA[19:8] < 960) OVER = 1;
                    else OVER = 0;
                end 
                M: begin
                    MM3 = DATA[19:8] - 720;
                    if(DATA[19:8] < 720) OVER = 1;
                    else OVER = 0;
                end 
                S: begin
                    MM3 = DATA[19:8] - 480;
                    if(DATA[19:8] < 480) OVER = 1;
                    else OVER = 0;
                end 
            endcase
        end 
        Super_Pineapple_Tea: begin
            case(SIZE)
                L: begin
                    MM0 = DATA[63:52] - 480;
                    MM3 = DATA[19:8] - 480;
                    if(DATA[63:52] < 480) OVER = 1;
                    else if(DATA[19:8] < 480) OVER = 1;
                    else OVER = 0;
                end 
                M: begin
                    MM0 = DATA[63:52] - 360;
                    MM3 = DATA[19:8] - 360;
                    if(DATA[63:52] < 360) OVER = 1;
                    else if(DATA[19:8] < 360) OVER = 1;
                    else OVER = 0;
                end 
                S: begin
                    MM0 = DATA[63:52] - 240;
                    MM3 = DATA[19:8] - 240;
                    if(DATA[63:52] < 240) OVER = 1;
                    else if(DATA[19:8] < 240) OVER = 1;
                    else OVER = 0;
                end 
            endcase
        end 
        Super_Pineapple_Milk_Tea: begin
            case(SIZE)
                L: begin
                    MM0 = DATA[63:52] - 480;
                    MM2 = DATA[31:20] - 240;
                    MM3 = DATA[19:8] - 240;
                    if(DATA[63:52] < 480) OVER = 1;
                    else if(DATA[31:20] < 240) OVER = 1;
                    else if(DATA[19:8] < 240) OVER = 1;
                    else OVER = 0;
                end 
                M: begin
                    MM0 = DATA[63:52] - 360;
                    MM2 = DATA[31:20] - 180;
                    MM3 = DATA[19:8] - 180;
                    if(DATA[63:52] < 360) OVER = 1;
                    else if(DATA[31:20] < 180) OVER = 1;
                    else if(DATA[19:8] < 180) OVER = 1;
                    else OVER = 0;
                end 
                S: begin
                    MM0 = DATA[63:52] - 240;
                    MM2 = DATA[31:20] - 120;
                    MM3 = DATA[19:8] - 120;
                    if(DATA[63:52] < 240) OVER = 1;
                    else if(DATA[31:20] < 120) OVER = 1;
                    else if(DATA[19:8] < 120) OVER = 1;
                    else OVER = 0;
                end 
            endcase
        end 
    endcase
//end 
    while(inf.out_valid !== 1) begin
        @(negedge clk);
        $display(`Green,"**************");
    end 
    while(inf.out_valid === 1) begin
        //$display(`Red,"**************");
        if(DATE.M > DATA[39:32]) begin
            $display(`White,"**************");
            $display(`Red, "*  No_Exp  *");
            $display(`White,"**************");
            if(inf.err_msg !== No_Exp || inf.complete !== 0) begin
                $display(`Yellow, "*  No_Exp  *");
                $display(`White,"**************");
                $display(`Yellow, "*  Wrong Answer  *");
                $display(`White,"********************");
                $finish;
            end  
        end 
        else if(DATE.M==DATA[39:32] && DATE.D>DATA[7:0]) begin
            $display(`White,"**************");
            $display(`Red, "*  No_Exp  *");
            $display(`White,"**************");
            if(inf.err_msg !== No_Exp || inf.complete !== 0) begin
                $display(`Yellow, "*  No_Exp  *");
                $display(`White,"**************");
                $display(`Yellow, "*  Wrong Answer  *");
                $display(`White,"********************");
                $finish;
            end 
        end     
        else if(OVER) begin
            $display(`White,"**************");
            $display(`Red, "*  No_Ing  *");
            $display(`White,"**************");
            if(inf.err_msg !== No_Ing || inf.complete !== 0) begin
                $display(`Yellow, "*  No_Ing  *");
                $display(`White,"**************");
                $display(`Yellow, "*  Wrong Answer  *");
                $display(`White,"********************");
                $finish;
            end 
        end 
        else begin
            $display(`White,"**************");
            $display(`Red, "*  No_Err  *");
            $display(`White,"**************");
            if(inf.err_msg !== No_Err || inf.complete !== 1) begin
                $display(`Yellow, "*  No_Err  *");
                $display(`White,"**************");
                $display(`Yellow, "*  Wrong Answer  *");
                $display(`White,"********************");
                $finish;
            end 
            WRITE_BACK = {MM0, MM1, DATA[39:32], MM2, MM3, DATA[7:0]};
            $display(`White,"**************");
            $display(`Red, "*  MM0 %d   *",MM0);
            $display(`White,"**************");
            $display(`White,"**************");
            $display(`Red, "*  MM1 %d   *",MM1);
            $display(`White,"**************");
            $display(`White,"**************");
            $display(`Red, "*  DATA[39:32] %d   *",DATA[39:32]);
            $display(`White,"**************");
            $display(`White,"**************");
            $display(`Red, "*  MM2 %d   *",MM2);
            $display(`White,"**************");
            $display(`White,"**************");
            $display(`Red, "*  MM3 %d   *",MM3);
            $display(`White,"**************");
            $display(`White,"**************");
            $display(`Red, "*  DATA[7:0] %d   *",DATA[7:0]);
            $display(`White,"**************");
            golden_DRAM[65536+BOX_NO*8+7] = WRITE_BACK[63:56];
            golden_DRAM[65536+BOX_NO*8+6] = WRITE_BACK[55:48];
            golden_DRAM[65536+BOX_NO*8+5] = WRITE_BACK[47:40];
            golden_DRAM[65536+BOX_NO*8+4] = WRITE_BACK[39:32];
            golden_DRAM[65536+BOX_NO*8+3] = WRITE_BACK[31:24];
            golden_DRAM[65536+BOX_NO*8+2] = WRITE_BACK[23:16];
            golden_DRAM[65536+BOX_NO*8+1] = WRITE_BACK[15:8];
            golden_DRAM[65536+BOX_NO*8+0] = WRITE_BACK[7:0];
        end 
        @(negedge clk);
    end 
    //@(negedge clk);
end endtask

task invalid_box_sup; begin
    //repeat( ({$random(SEED)} % 4 + 0) ) @(negedge clk);//0 1 2 3 
    inf.box_sup_valid = 1;
    r_ing.randomize();
    inf.D.d_ing[0] = r_ing.ing;
    S1 = r_ing.ing;
    $display(`Yellow, "*  inf.D.d_ing[0]  %d  *",inf.D.d_ing[0]);
    $display(`White,"*****************************************");
    @(negedge clk);
    inf.type_valid = 0;
    inf.sel_action_valid = 0;
    inf.size_valid       = 0;
    inf.date_valid       = 0;
    inf.box_no_valid     = 0;
    inf.box_sup_valid    = 0;
    inf.D                = 'dx;

    //repeat( ({$random(SEED)} % 4 + 0) ) @(negedge clk);//0 1 2 3 
    inf.box_sup_valid = 1;
    r_ing.randomize();
    inf.D.d_ing[0] = r_ing.ing;
    S2 = r_ing.ing;
    $display(`Yellow, "*  inf.D.d_ing[0]  %d  *",inf.D.d_ing[0]);
    $display(`White,"*****************************************");
    @(negedge clk);
    inf.type_valid = 0;
    inf.sel_action_valid = 0;
    inf.size_valid       = 0;
    inf.date_valid       = 0;
    inf.box_no_valid     = 0;
    inf.box_sup_valid    = 0;
    inf.D                = 'dx;

    //repeat( ({$random(SEED)} % 4 + 0) ) @(negedge clk);//0 1 2 3 
    inf.box_sup_valid = 1;
    r_ing.randomize();
    inf.D.d_ing[0] = r_ing.ing;
    S3 = r_ing.ing;
    $display(`Yellow, "*  inf.D.d_ing[0]  %d  *",inf.D.d_ing[0]);
    $display(`White,"*****************************************");
    @(negedge clk);
    inf.type_valid = 0;
    inf.sel_action_valid = 0;
    inf.size_valid       = 0;
    inf.date_valid       = 0;
    inf.box_no_valid     = 0;
    inf.box_sup_valid    = 0;
    inf.D                = 'dx;

    //repeat( ({$random(SEED)} % 4 + 0) ) @(negedge clk);//0 1 2 3 
    inf.box_sup_valid = 1;
    r_ing.randomize();
    inf.D.d_ing[0] = r_ing.ing;
    S4 = r_ing.ing;
    $display(`Yellow, "*  inf.D.d_ing[0]  %d  *",inf.D.d_ing[0]);
    $display(`White,"*****************************************");
    @(negedge clk);
    inf.type_valid = 0;
    inf.sel_action_valid = 0;
    inf.size_valid       = 0;
    inf.date_valid       = 0;
    inf.box_no_valid     = 0;
    inf.box_sup_valid    = 0;
    inf.D                = 'dx;
end endtask

logic [12:0] m0, m1, m2, m3;
assign m0 = DATA[63:52] + S1;
assign m1 = DATA[51:40] + S2;
assign m2 = DATA[31:20] + S3;
assign m3 = DATA[19:8] + S4;

logic [11:0] M0, M1, M2, M3;
assign M0 = (m0 > 4095) ? 4095 : m0;
assign M1 = (m1 > 4095) ? 4095 : m1;
assign M2 = (m2 > 4095) ? 4095 : m2;
assign M3 = (m3 > 4095) ? 4095 : m3;

task check_supply; begin
    $display(`Yellow, "*  m0 %d   *",m0);
    $display(`White,"*****************************************");
    $display(`Yellow, "*  m1 %d   *",m1);
    $display(`White,"*****************************************");
    $display(`Yellow, "*  m2 %d   *",m2);
    $display(`White,"*****************************************");
    $display(`Yellow, "*  m3 %d   *",m3);
    $display(`White,"*****************************************");
    //$display(`Yellow, "*  pineapple_juice %d   *",DATA[19:8]);
    //$display(`White,"*****************************************");
    //$display(`Yellow, "*  D %d   *",DATA[7:0]);
    //$display(`White,"*****************************************");
    while(inf.out_valid !== 1) begin
        @(negedge clk);
        $display(`Green,"**************");
    end 
    while(inf.out_valid === 1) begin
        if(m0 > 4095 || m1 > 4095 || m2 > 4095 || m3 > 4095) begin
            $display(`Red, "*  m0 %d   *",m0);
            $display(`White,"*****************************************");
            $display(`Red, "*  m1 %d   *",m1);
            $display(`White,"*****************************************");
            $display(`Red, "*  m2 %d   *",m2);
            $display(`White,"*****************************************");
            $display(`Red, "*  m3 %d   *",m3);
            $display(`White,"*****************************************");
            $display(`White,"**************");
            $display(`Red, "*  Ing_OF  *");
            $display(`White,"**************");
            if(inf.err_msg !== Ing_OF || inf.complete !== 0) begin
                $display(`Yellow, "*  Ing_OF  *");
                $display(`White,"**************");
                $display(`Yellow, "*  Wrong Answer  *");
                $display(`White,"********************");
                $finish;
            end
        end 
        else begin
            $display(`White,"**************");
            $display(`Red, "*  No_Err  *");
            $display(`White,"**************");
            if(inf.err_msg !== No_Err || inf.complete !== 1) begin
                $display(`Yellow, "*  No_Err  *");
                $display(`White,"**************");
                $display(`Yellow, "*  Wrong Answer  *");
                $display(`White,"********************");
                $finish;
            end 
            /*WRITE_BACK = {M0, M1, 4'b0, DATE.M, M2, M3, 3'b0, DATE.D};
            $display(`White,"**************");
            $display(`Red, "*  M0 %d   *",M0);
            $display(`White,"**************");
            $display(`White,"**************");
            $display(`Red, "*  M1 %d   *",M1);
            $display(`White,"**************");
            $display(`White,"**************");
            $display(`Red, "*  DATE.M %d   *",DATE.M);
            $display(`White,"**************");
            $display(`White,"**************");
            $display(`Red, "*  M2 %d   *",M2);
            $display(`White,"**************");
            $display(`White,"**************");
            $display(`Red, "*  M3 %d   *",M3);
            $display(`White,"**************");
            $display(`White,"**************");
            $display(`Red, "*  DATE.D %d   *",DATE.D);
            //$display(`Red, "*  golden_DRAM %d   *",golden_DRAM[65536+BOX_NO*8+7]);
            $display(`White,"**************");
            $display(`White,"**************");
            $display(`Red, "*  WRITE_BACK %h   *",WRITE_BACK);
            //$display(`Red, "*  golden_DRAM %d   *",golden_DRAM[65536+BOX_NO*8+7]);
            $display(`White,"**************");
            $display(`Red, "*  golden_DRAM %d   *",golden_DRAM[65536+BOX_NO*8+7]);
            $display(`Red, "*  WRITE_BACK[63:56] %d   *",WRITE_BACK[63:56]);
            //WRITE_BACK = {MM0, MM1, DATA[39:32], MM2, MM3, DATA[7:0]};
            golden_DRAM[65536+BOX_NO*8+7] = WRITE_BACK[63:56];
            golden_DRAM[65536+BOX_NO*8+6] = WRITE_BACK[55:48];
            golden_DRAM[65536+BOX_NO*8+5] = WRITE_BACK[47:40];
            golden_DRAM[65536+BOX_NO*8+4] = WRITE_BACK[39:32];
            golden_DRAM[65536+BOX_NO*8+3] = WRITE_BACK[31:24];
            golden_DRAM[65536+BOX_NO*8+2] = WRITE_BACK[23:16];
            golden_DRAM[65536+BOX_NO*8+1] = WRITE_BACK[15:8];
            golden_DRAM[65536+BOX_NO*8+0] = WRITE_BACK[7:0];
            $display(`Red, "*  golden_DRAM %d   *",golden_DRAM[65536+BOX_NO*8+7]);*/
        end 
        WRITE_BACK = {M0, M1, 4'b0, DATE.M, M2, M3, 3'b0, DATE.D};
            $display(`White,"**************");
            $display(`Red, "*  M0 %d   *",M0);
            $display(`White,"**************");
            $display(`White,"**************");
            $display(`Red, "*  M1 %d   *",M1);
            $display(`White,"**************");
            $display(`White,"**************");
            $display(`Red, "*  DATE.M %d   *",DATE.M);
            $display(`White,"**************");
            $display(`White,"**************");
            $display(`Red, "*  M2 %d   *",M2);
            $display(`White,"**************");
            $display(`White,"**************");
            $display(`Red, "*  M3 %d   *",M3);
            $display(`White,"**************");
            $display(`White,"**************");
            $display(`Red, "*  DATE.D %d   *",DATE.D);
            //$display(`Red, "*  golden_DRAM %d   *",golden_DRAM[65536+BOX_NO*8+7]);
            $display(`White,"**************");
            $display(`White,"**************");
            $display(`Red, "*  WRITE_BACK %h   *",WRITE_BACK);
            //$display(`Red, "*  golden_DRAM %d   *",golden_DRAM[65536+BOX_NO*8+7]);
            $display(`White,"**************");
            $display(`Red, "*  golden_DRAM %d   *",golden_DRAM[65536+BOX_NO*8+7]);
            $display(`Red, "*  WRITE_BACK[63:56] %d   *",WRITE_BACK[63:56]);
            //WRITE_BACK = {MM0, MM1, DATA[39:32], MM2, MM3, DATA[7:0]};
            golden_DRAM[65536+BOX_NO*8+7] = WRITE_BACK[63:56];
            golden_DRAM[65536+BOX_NO*8+6] = WRITE_BACK[55:48];
            golden_DRAM[65536+BOX_NO*8+5] = WRITE_BACK[47:40];
            golden_DRAM[65536+BOX_NO*8+4] = WRITE_BACK[39:32];
            golden_DRAM[65536+BOX_NO*8+3] = WRITE_BACK[31:24];
            golden_DRAM[65536+BOX_NO*8+2] = WRITE_BACK[23:16];
            golden_DRAM[65536+BOX_NO*8+1] = WRITE_BACK[15:8];
            golden_DRAM[65536+BOX_NO*8+0] = WRITE_BACK[7:0];
            $display(`Red, "*  golden_DRAM %d   *",golden_DRAM[65536+BOX_NO*8+7]);
        @(negedge clk);
    end 
end endtask

task check_date; begin
    while(inf.out_valid !== 1) begin
        @(negedge clk);
        $display(`Green,"**************");
    end 
    while(inf.out_valid === 1) begin
        $display(`White,"**************");
        $display(`Red, "*  DATE.M %d   *",DATE.M);
        $display(`White,"**************");
        $display(`White,"**************");
        $display(`Red, "*  DATA[39:32] %d   *",DATA[39:32]);
        $display(`White,"**************");
        $display(`White,"**************");
        $display(`Red, "*  DATE.D %d   *",DATE.D);
        $display(`White,"**************");
        $display(`White,"**************");
        $display(`Red, "*  DATA[7:0] %d   *",DATA[7:0]);
        $display(`White,"**************");
        if(DATE.M>DATA[39:32]) begin
            $display(`White,"**************");
            $display(`Red, "*  No_Exp  *");
            $display(`White,"**************");
            if(inf.err_msg !== No_Exp || inf.complete !== 0) begin
                $display(`Yellow, "*  No_Exp  *");
                $display(`White,"**************");
                $display(`Yellow, "*  Wrong Answer  *");
                $display(`White,"********************");
                $finish;
            end 
        end 
        else if(DATE.M==DATA[39:32] && DATE.D>DATA[7:0]) begin
            $display(`White,"**************");
            $display(`Red, "*  No_Exp  *");
            $display(`White,"**************");
            if(inf.err_msg !== No_Exp || inf.complete !== 0) begin
                $display(`Yellow, "*  No_Exp  *");
                $display(`White,"**************");
                $display(`Yellow, "*  Wrong Answer  *");
                $display(`White,"********************");
                $finish;
            end 
        end 
        else begin
            $display(`White,"**************");
            $display(`Red, "*  No_Err  *");
            $display(`White,"**************");
            if(inf.err_msg !== No_Err || inf.complete !== 1) begin
                $display(`Yellow, "*  No_Err  *");
                $display(`White,"**************");
                $display(`Yellow, "*  Wrong Answer  *");
                $display(`White,"********************");
                $finish;
            end 
        end
        @(negedge clk);
    end 
end endtask



endprogram
