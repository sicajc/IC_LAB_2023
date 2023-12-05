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
// for Lab10

`include "Usertype_BEV.sv"
`define SEED 28825252
`define PATNUM 3600
`define CYCLE_TIME 12.0
`define DEBUG_PRINT 0
`define MODE 0 // 0: auto mode, 1: manual mode(make drink), 2: manual mode(supply), 3: manual mode(check valid date)
program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
//   PARAMETER & INTEGER DECLARATION
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";

integer i_pat, y;
integer patcount;
integer total_latency, latency;
integer out_val_clk_times;
integer bev_type_size_count;

real      CYCLE  = `CYCLE_TIME;
parameter SEED   = `SEED ;
parameter PATNUM = `PATNUM ;
//================================================================
//   Logic Declaration
//================================================================
logic [7:0] golden_DRAM [((65536 + 8 * 256) - 1):(65536 + 0)];
logic [63:0] data_in_DRAM;
logic       golden_complete;
Error_Msg   golden_err_msg;

ING ing_black_tea_dram, ing_black_tea_need;
ING ing_green_tea_dram, ing_green_tea_need;
ING ing_milk_dram, ing_milk_need;
ING ing_pineapple_juice_dram, ing_pineapple_juice_need;
Date date_dram;

//================================================================
//   Class random
//================================================================
// Class representing a random action.
class random_act;
    randc Action act_id;
    constraint range{
        act_id inside{Make_drink, Supply, Check_Valid_Date};
    }
endclass

// Class representing a random box from 0 to 255.
class random_box;
    randc logic [7:0] box_id;
    constraint range{
        box_id inside{[0:255]};
    }
endclass

class rand_delay;
	rand int delay;
	function new (int seed);
		this.srandom(seed);
	endfunction
  task pause();
    this.randomize();
    repeat(r_delay.delay) @(negedge clk);
  endtask
	constraint limit { delay inside {[0:0]}; }
endclass

// random action
class rand_action;
	rand Action action;
	function new (int seed);
		this.srandom(seed);
	endfunction
  function cov_set(int value);
    // AABBCCACB
    if(value < 1800) begin
      if((value % 9) == 0 || (value % 9) == 1 || (value % 9) == 6) begin
        this.action = Make_drink;
      end else if((value % 9) == 2 || (value % 9) == 3 || (value % 9) == 8) begin
        this.action = Supply;
      end else if((value % 9) == 4 || (value % 9) == 5 || (value % 9) == 7) begin
        this.action = Check_Valid_Date;
      end
    end
    else begin
      this.action = Make_drink;
    end
  endfunction
	//constraint limit { action inside {Make_drink, Supply, Check_Valid_Date}; }
  constraint limit {
    if(`MODE == 0) {
      action inside {Make_drink, Supply, Check_Valid_Date};
    } else if(`MODE == 1) {
      action inside {Make_drink};
    } else if(`MODE == 2) {
      action inside {Supply};
    } else if(`MODE == 3) {
      action inside {Check_Valid_Date};
    }
  }
endclass

// random bev_type
class rand_bev_type;
  rand Bev_Type bev_type;
  function new (int seed);
    this.srandom(seed);
  endfunction
  function cov_set (int value);
    value %= 24;
    if(0 <= value && value <= 2)        this.bev_type = Black_Tea;
    else if(3 <= value && value <= 5)   this.bev_type = Milk_Tea;
    else if(6 <= value && value <= 8)   this.bev_type = Extra_Milk_Tea;
    else if(9 <= value && value <= 11)  this.bev_type = Green_Tea;
    else if(12 <= value && value <= 14) this.bev_type = Green_Milk_Tea;
    else if(15 <= value && value <= 17) this.bev_type = Pineapple_Juice;
    else if(18 <= value && value <= 20) this.bev_type = Super_Pineapple_Tea;
    else                                this.bev_type = Super_Pineapple_Milk_Tea;
  endfunction
  constraint limit { bev_type inside {Black_Tea, Milk_Tea, Extra_Milk_Tea, Green_Tea, Green_Milk_Tea, Pineapple_Juice, Super_Pineapple_Tea, Super_Pineapple_Milk_Tea}; }
endclass

// random bev_size
class rand_bev_size;
  rand Bev_Size bev_size;
  function new (int seed);
    this.srandom(seed);
  endfunction
  function cov_set (int value);
    if(value % 3 == 0)      this.bev_size = L;
    else if(value % 3 == 1) this.bev_size = M;
    else                    this.bev_size = S;
  endfunction
  constraint limit { bev_size inside {L, M, S}; }
endclass

// random date
class rand_date;
  rand Date date;
  function new (int seed);
    this.srandom(seed);
  endfunction
  constraint limit {
    date.M inside {[1:12]};
    if (date.M == 1 || date.M == 3 || date.M == 5 || date.M == 7 || date.M == 8 || date.M == 10 || date.M == 12) {
      date.D inside {[1:31]};
    } else if (date.M == 4 || date.M == 6 || date.M == 9 || date.M == 11) {
      date.D inside {[1:30]};
    } else if (date.M == 2) {
      date.D inside {[1:28]};
    }
  }
endclass

// random ingredient
class rand_ing;
  rand ING ing;
  logic [4:0] cov_count;
  function new (int seed);
    this.srandom(seed);
    cov_count = 0;
  endfunction
  function cov_set (int value); // supply action with auto_bin_max = 32, and each bin have to hit at least one time.
    this.ing = this.cov_count * 128 + value % 128;
    this.cov_count = this.cov_count + 1;
  endfunction
  constraint limit { ing inside {[0:4095]}; } // 2^12 - 1
endclass

// random barrel_no
class rand_barrel_no;
  rand Barrel_No barrel_no;
  function new (int seed);
    this.srandom(seed);
  endfunction
  constraint limit { barrel_no inside {[0:255]}; } // 2^8 - 1
endclass


rand_delay r_delay = new(SEED);
rand_action r_action = new(SEED);
rand_bev_type r_bev_type = new(SEED);
rand_bev_size r_bev_size = new(SEED);
rand_date r_date = new(SEED);
rand_ing r_ing_black_tea = new(SEED);
rand_ing r_ing_green_tea = new(SEED);
rand_ing r_ing_milk = new(SEED);
rand_ing r_ing_pineapple_juice = new(SEED);
rand_barrel_no r_barrel_no = new(SEED);


//================================================================
//   Initial
//================================================================
initial begin
  // read DRAM data
  $readmemh(DRAM_p_r, golden_DRAM);
  reset_signal_task;
  total_latency = 0;
  bev_type_size_count = 0;

  for (i_pat = 0; i_pat < PATNUM; i_pat = i_pat + 1) begin
    gen_pattern;
    input_task;
    wait_out_valid_task;
    gen_golden;
    check_ans_task;
    total_latency = total_latency + latency;
  end

  YOU_PASS_task;
end

//================================================================
//   Task
//================================================================
task reset_signal_task; begin
	inf.rst_n     = 1'b1 ;
  inf.sel_action_valid  = 1'b0 ;
  inf.type_valid = 1'b0 ;
  inf.size_valid = 1'b0 ;
  inf.date_valid = 1'b0 ;
  inf.box_no_valid = 1'b0 ;
  inf.box_sup_valid = 1'b0 ;
	inf.D = 'bx;

	#(0.5 * CYCLE);
  inf.rst_n = 0 ;

	#(1 * CYCLE);
  if( (inf.out_valid !== 0) || (inf.err_msg !== 0) || (inf.complete !== 0))
  begin
    $display("***********************************************************************");
    $display("*  Wrong Answer Error:                                                *");
    $display("*  Output signal should reset after initial RESET                     *");
    $display("***********************************************************************");
    // DO NOT PUT @(negedge clk) HERE
    $finish;
  end
  #(CYCLE);  inf.rst_n = 1;
  // wait clk
  @(negedge clk);
end endtask

task gen_pattern; begin
  // reset golden
  golden_complete = 1'bx;
  golden_err_msg = No_Err;
  // random action
  r_action.randomize();
  r_action.cov_set(i_pat);
  //$display("ipat = %d / action = %d", i_pat, r_action.action);
  // date
  r_date.randomize();
  // barrel_no
  r_barrel_no.randomize();
  // data_in_DRAM
  data_in_DRAM[63:56] = golden_DRAM[(65536 + r_barrel_no.barrel_no * 8) + 7];
  data_in_DRAM[55:48] = golden_DRAM[(65536 + r_barrel_no.barrel_no * 8) + 6];
  data_in_DRAM[47:40] = golden_DRAM[(65536 + r_barrel_no.barrel_no * 8) + 5];
  data_in_DRAM[39:32] = golden_DRAM[(65536 + r_barrel_no.barrel_no * 8) + 4];
  data_in_DRAM[31:24] = golden_DRAM[(65536 + r_barrel_no.barrel_no * 8) + 3];
  data_in_DRAM[23:16] = golden_DRAM[(65536 + r_barrel_no.barrel_no * 8) + 2];
  data_in_DRAM[15:8]  = golden_DRAM[(65536 + r_barrel_no.barrel_no * 8) + 1];
  data_in_DRAM[7:0]   = golden_DRAM[(65536 + r_barrel_no.barrel_no * 8) + 0];
  ing_black_tea_dram       = data_in_DRAM[63:52];
  ing_green_tea_dram       = data_in_DRAM[51:40];
  ing_milk_dram            = data_in_DRAM[31:20];
  ing_pineapple_juice_dram = data_in_DRAM[19:8];
  date_dram.M             = data_in_DRAM[39:32];
  date_dram.D             = data_in_DRAM[7:0];
  // corresponding to each action
  case(r_action.action)
    Make_drink: begin
      r_bev_type.randomize(); r_bev_type.cov_set(bev_type_size_count);
      r_bev_size.randomize(); r_bev_size.cov_set(bev_type_size_count);
      bev_type_size_count = bev_type_size_count + 1;
      // $display("action: %d, bev_type: %d, bev_size: %d", r_action.action, r_bev_type.bev_type, r_bev_size.bev_size);

      if(`DEBUG_PRINT) begin
        $write("\033[0;33m");
        $display("***********************************************************************");
        $display("*  Pattern No.     : %4d                         ", i_pat);
        $display("*  Action          : Make_drink                  ");
        $display("*  Type            : %10s                        ", r_bev_type.bev_type);
        $display("*  Size            : %10s                        ", r_bev_size.bev_size);
        $display("*  Date            : %02d/%02d                   ", r_date.date.M, r_date.date.D);
        $display("*  Barrel No.      : %3d (0x%2x)                 ", r_barrel_no.barrel_no, r_barrel_no.barrel_no);
        $display("-----------------------------------------------------------------------");
        $display("*  DRAM Address    : 0x%4x                       ", (r_barrel_no.barrel_no * 8));
        $display("*  Black Tea       : %4d (0x%03x)                ", ing_black_tea_dram, ing_black_tea_dram);
        $display("*  Green Tea       : %4d (0x%03x)                ", ing_green_tea_dram, ing_green_tea_dram);
        $display("*  Milk            : %4d (0x%03x)                ", ing_milk_dram, ing_milk_dram);
        $display("*  Pineapple Juice : %4d (0x%03x)                ", ing_pineapple_juice_dram, ing_pineapple_juice_dram);
        $display("*  Date            : %02d/%02d                   ", date_dram.M, date_dram.D);
        $display("***********************************************************************");
        $write("\033[m");
      end
    end
    Supply: begin
      r_ing_black_tea.randomize();       r_ing_black_tea.cov_set(i_pat);
      r_ing_green_tea.randomize();       r_ing_green_tea.cov_set(i_pat);
      r_ing_milk.randomize();            r_ing_milk.cov_set(i_pat);
      r_ing_pineapple_juice.randomize(); r_ing_pineapple_juice.cov_set(i_pat);

      if(`DEBUG_PRINT) begin
        $write("\033[0;33m");
        $display("***********************************************************************");
        $display("*  Pattern No.     : %4d                         ", i_pat);
        $display("*  Action          : Supply                      ");
        $display("*  Date            : %02d/%02d                   ", r_date.date.M, r_date.date.D);
        $display("*  Barrel No.      : %3d (0x%2x)                 ", r_barrel_no.barrel_no, r_barrel_no.barrel_no);
        $display("*  Black Tea       : %4d (0x%03x)                ", r_ing_black_tea.ing, r_ing_black_tea.ing);
        $display("*  Green Tea       : %4d (0x%03x)                ", r_ing_green_tea.ing, r_ing_green_tea.ing);
        $display("*  Milk            : %4d (0x%03x)                ", r_ing_milk.ing, r_ing_milk.ing);
        $display("*  Pineapple Juice : %4d (0x%03x)                ", r_ing_pineapple_juice.ing, r_ing_pineapple_juice.ing);
        $display("-----------------------------------------------------------------------");
        $display("*  DRAM Address    : 0x%4x                       ", (r_barrel_no.barrel_no * 8));
        $display("*  Black Tea       : %4d (0x%03x)                ", ing_black_tea_dram, ing_black_tea_dram);
        $display("*  Green Tea       : %4d (0x%03x)                ", ing_green_tea_dram, ing_green_tea_dram);
        $display("*  Milk            : %4d (0x%03x)                ", ing_milk_dram, ing_milk_dram);
        $display("*  Pineapple Juice : %4d (0x%03x)                ", ing_pineapple_juice_dram, ing_pineapple_juice_dram);
        $display("*  Date            : %02d/%02d                   ", date_dram.M, date_dram.D);
        $display("***********************************************************************");
        $write("\033[m");
      end
    end
    Check_Valid_Date: begin
      if(`DEBUG_PRINT) begin
        $write("\033[0;33m");
        $display("***********************************************************************");
        $display("*  Pattern No.     : %4d                         ", i_pat);
        $display("*  Action          : Check_Valid_Date            ");
        $display("*  Date            : %02d/%02d                   ", r_date.date.M, r_date.date.D);
        $display("*  Barrel No.      : %3d (0x%2x)                 ", r_barrel_no.barrel_no, r_barrel_no.barrel_no);
        $display("-----------------------------------------------------------------------");
        $display("*  DRAM Address    : 0x%4x                       ", (r_barrel_no.barrel_no * 8));
        $display("*  Date            : %02d/%02d                   ", date_dram.M, date_dram.D);
        $display("***********************************************************************");
        $write("\033[m");
      end
    end
    default: begin
      $display("***********************************************************************");
      $display("*  Error (Pattern internal Error)                                     *");
      $display("*  The action is out of range                                         *");
      $display("***********************************************************************");
      repeat(2)@(negedge clk);
      $finish;
    end
  endcase
end endtask

task input_task; begin
  // action input
  r_delay.pause();
  inf.sel_action_valid = 1'b1;
  inf.D.d_act[0] = r_action.action;
  @(negedge clk);
  inf.sel_action_valid = 1'b0;
  inf.D = 'bx;

  // corresponding to each action
  case(r_action.action)
    Make_drink: begin
      // type input
      r_delay.pause();
      inf.type_valid = 1'b1;
      inf.D.d_type[0] = r_bev_type.bev_type;
      @(negedge clk);
      inf.type_valid = 1'b0;
      inf.D = 'bx;
      // size input
      r_delay.pause();
      inf.size_valid = 1'b1;
      inf.D.d_size[0] = r_bev_size.bev_size;
      @(negedge clk);
      inf.size_valid = 1'b0;
      inf.D = 'bx;
      // date input
      r_delay.pause();
      inf.date_valid = 1'b1;
      inf.D.d_date[0] = r_date.date;
      @(negedge clk);
      inf.date_valid = 1'b0;
      inf.D = 'bx;
      // box_no input
      r_delay.pause();
      inf.box_no_valid = 1'b1;
      inf.D.d_box_no[0] = r_barrel_no.barrel_no;
      @(negedge clk);
      inf.box_no_valid = 1'b0;
      inf.D = 'bx;
    end
    Supply: begin
      // date input
      r_delay.pause();
      inf.date_valid = 1'b1;
      inf.D.d_date[0] = r_date.date;
      @(negedge clk);
      inf.date_valid = 1'b0;
      inf.D = 'bx;
      // box_no input
      r_delay.pause();
      inf.box_no_valid = 1'b1;
      inf.D.d_box_no[0] = r_barrel_no.barrel_no;
      @(negedge clk);
      inf.box_no_valid = 1'b0;
      inf.D = 'bx;
      // black_tea input
      r_delay.pause();
      inf.box_sup_valid = 1'b1;
      inf.D.d_ing[0] = r_ing_black_tea.ing;
      @(negedge clk);
      inf.box_sup_valid = 1'b0;
      inf.D = 'bx;
      // green_tea input
      r_delay.pause();
      inf.box_sup_valid = 1'b1;
      inf.D.d_ing[0] = r_ing_green_tea.ing;
      @(negedge clk);
      inf.box_sup_valid = 1'b0;
      inf.D = 'bx;
      // milk input
      r_delay.pause();
      inf.box_sup_valid = 1'b1;
      inf.D.d_ing[0] = r_ing_milk.ing;
      @(negedge clk);
      inf.box_sup_valid = 1'b0;
      inf.D = 'bx;
      // pineapple_juice input
      r_delay.pause();
      inf.box_sup_valid = 1'b1;
      inf.D.d_ing[0] = r_ing_pineapple_juice.ing;
      @(negedge clk);
      inf.box_sup_valid = 1'b0;
      inf.D = 'bx;
    end
    Check_Valid_Date: begin
      // date input
      r_delay.pause();
      inf.date_valid = 1'b1;
      inf.D.d_date[0] = r_date.date;
      @(negedge clk);
      inf.date_valid = 1'b0;
      inf.D = 'bx;
      // box_no input
      r_delay.pause();
      inf.box_no_valid = 1'b1;
      inf.D.d_box_no[0] = r_barrel_no.barrel_no;
      @(negedge clk);
      inf.box_no_valid = 1'b0;
      inf.D = 'bx;
    end
    default: begin
      $display("***********************************************************************");
      $display("*  Error (Pattern internal Error)                                     *");
      $display("*  The action is out of range                                         *");
      $display("***********************************************************************");
      repeat(2)@(negedge clk);
      $finish;
    end
  endcase
end endtask

task wait_out_valid_task; begin
  latency = 0;
  while(inf.out_valid !== 1) begin
    latency = latency + 1;
    if(latency > 1000) begin
      $display("***********************************************************************");
      $display("*  Wrong Answer Error:                                                *");
      $display("*  The execution latency should not over 1,000 cycles.                *");
      $display("***********************************************************************");
      repeat(2)@(negedge clk);
      $finish;
    end
    @(negedge clk);
  end
end endtask

task gen_golden; begin
  // corresponding to each action
  case(r_action.action)
    Make_drink: begin
      // update ingredient needed
      // Input	Black	Green	Milk	Pineapple	Sum
      // Black Tea	0	1	0	0	0	1
      // Milk Tea	1	3	0	1	0	4
      // Extra Milk Tea	2	1	0	1	0	2
      // Green Tea	3	0	1	0	0	1
      // Green Milk Tea	4	0	1	1	0	2
      // Pineapple Juice	5	0	0	0	1	1
      // Super Pineapple Tea	6	1	0	0	1	2
      // Super Pineapple Milk Tea	7	2	0	1	1	4

      case(r_bev_type.bev_type)
        Black_Tea: begin
          if(r_bev_size.bev_size == L) begin
            ing_black_tea_need       = 960 * 1 / 1;
            ing_green_tea_need       = 960 * 0 / 1;
            ing_milk_need            = 960 * 0 / 1;
            ing_pineapple_juice_need = 960 * 0 / 1;
          end
          else if(r_bev_size.bev_size == M) begin
            ing_black_tea_need       = 720 * 1 / 1;
            ing_green_tea_need       = 720 * 0 / 1;
            ing_milk_need            = 720 * 0 / 1;
            ing_pineapple_juice_need = 720 * 0 / 1;
          end
          else if(r_bev_size.bev_size == S) begin
            ing_black_tea_need       = 480 * 1 / 1;
            ing_green_tea_need       = 480 * 0 / 1;
            ing_milk_need            = 480 * 0 / 1;
            ing_pineapple_juice_need = 480 * 0 / 1;
          end
        end
        Milk_Tea: begin
          if(r_bev_size.bev_size == L) begin
            ing_black_tea_need       = 960 * 3 / 4;
            ing_green_tea_need       = 960 * 0 / 4;
            ing_milk_need            = 960 * 1 / 4;
            ing_pineapple_juice_need = 960 * 0 / 4;
          end
          else if(r_bev_size.bev_size == M) begin
            ing_black_tea_need       = 720 * 3 / 4;
            ing_green_tea_need       = 720 * 0 / 4;
            ing_milk_need            = 720 * 1 / 4;
            ing_pineapple_juice_need = 720 * 0 / 4;
          end
          else if(r_bev_size.bev_size == S) begin
            ing_black_tea_need       = 480 * 3 / 4;
            ing_green_tea_need       = 480 * 0 / 4;
            ing_milk_need            = 480 * 1 / 4;
            ing_pineapple_juice_need = 480 * 0 / 4;
          end
        end
        Extra_Milk_Tea: begin
          if(r_bev_size.bev_size == L) begin
            ing_black_tea_need       = 960 * 1 / 2;
            ing_green_tea_need       = 960 * 0 / 2;
            ing_milk_need            = 960 * 1 / 2;
            ing_pineapple_juice_need = 960 * 0 / 2;
          end
          else if(r_bev_size.bev_size == M) begin
            ing_black_tea_need       = 720 * 1 / 2;
            ing_green_tea_need       = 720 * 0 / 2;
            ing_milk_need            = 720 * 1 / 2;
            ing_pineapple_juice_need = 720 * 0 / 2;
          end
          else if(r_bev_size.bev_size == S) begin
            ing_black_tea_need       = 480 * 1 / 2;
            ing_green_tea_need       = 480 * 0 / 2;
            ing_milk_need            = 480 * 1 / 2;
            ing_pineapple_juice_need = 480 * 0 / 2;
          end
        end
        Green_Tea: begin
          if(r_bev_size.bev_size == L) begin
            ing_black_tea_need       = 960 * 0 / 1;
            ing_green_tea_need       = 960 * 1 / 1;
            ing_milk_need            = 960 * 0 / 1;
            ing_pineapple_juice_need = 960 * 0 / 1;
          end
          else if(r_bev_size.bev_size == M) begin
            ing_black_tea_need       = 720 * 0 / 1;
            ing_green_tea_need       = 720 * 1 / 1;
            ing_milk_need            = 720 * 0 / 1;
            ing_pineapple_juice_need = 720 * 0 / 1;
          end
          else if(r_bev_size.bev_size == S) begin
            ing_black_tea_need       = 480 * 0 / 1;
            ing_green_tea_need       = 480 * 1 / 1;
            ing_milk_need            = 480 * 0 / 1;
            ing_pineapple_juice_need = 480 * 0 / 1;
          end
        end
        Green_Milk_Tea: begin
          if(r_bev_size.bev_size == L) begin
            ing_black_tea_need       = 960 * 0 / 2;
            ing_green_tea_need       = 960 * 1 / 2;
            ing_milk_need            = 960 * 1 / 2;
            ing_pineapple_juice_need = 960 * 0 / 2;
          end
          else if(r_bev_size.bev_size == M) begin
            ing_black_tea_need       = 720 * 0 / 2;
            ing_green_tea_need       = 720 * 1 / 2;
            ing_milk_need            = 720 * 1 / 2;
            ing_pineapple_juice_need = 720 * 0 / 2;
          end
          else if(r_bev_size.bev_size == S) begin
            ing_black_tea_need       = 480 * 0 / 2;
            ing_green_tea_need       = 480 * 1 / 2;
            ing_milk_need            = 480 * 1 / 2;
            ing_pineapple_juice_need = 480 * 0 / 2;
          end
        end
        Pineapple_Juice: begin
          if(r_bev_size.bev_size == L) begin
            ing_black_tea_need       = 960 * 0 / 1;
            ing_green_tea_need       = 960 * 0 / 1;
            ing_milk_need            = 960 * 0 / 1;
            ing_pineapple_juice_need = 960 * 1 / 1;
          end
          else if(r_bev_size.bev_size == M) begin
            ing_black_tea_need       = 720 * 0 / 1;
            ing_green_tea_need       = 720 * 0 / 1;
            ing_milk_need            = 720 * 0 / 1;
            ing_pineapple_juice_need = 720 * 1 / 1;
          end
          else if(r_bev_size.bev_size == S) begin
            ing_black_tea_need       = 480 * 0 / 1;
            ing_green_tea_need       = 480 * 0 / 1;
            ing_milk_need            = 480 * 0 / 1;
            ing_pineapple_juice_need = 480 * 1 / 1;
          end
        end
        Super_Pineapple_Tea: begin
          if(r_bev_size.bev_size == L) begin
            ing_black_tea_need       = 960 * 1 / 2;
            ing_green_tea_need       = 960 * 0 / 2;
            ing_milk_need            = 960 * 0 / 2;
            ing_pineapple_juice_need = 960 * 1 / 2;
          end
          else if(r_bev_size.bev_size == M) begin
            ing_black_tea_need       = 720 * 1 / 2;
            ing_green_tea_need       = 720 * 0 / 2;
            ing_milk_need            = 720 * 0 / 2;
            ing_pineapple_juice_need = 720 * 1 / 2;
          end
          else if(r_bev_size.bev_size == S) begin
            ing_black_tea_need       = 480 * 1 / 2;
            ing_green_tea_need       = 480 * 0 / 2;
            ing_milk_need            = 480 * 0 / 2;
            ing_pineapple_juice_need = 480 * 1 / 2;
          end
        end
        Super_Pineapple_Milk_Tea: begin
          if(r_bev_size.bev_size == L) begin
            ing_black_tea_need       = 960 * 2 / 4;
            ing_green_tea_need       = 960 * 0 / 4;
            ing_milk_need            = 960 * 1 / 4;
            ing_pineapple_juice_need = 960 * 1 / 4;
          end
          else if(r_bev_size.bev_size == M) begin
            ing_black_tea_need       = 720 * 2 / 4;
            ing_green_tea_need       = 720 * 0 / 4;
            ing_milk_need            = 720 * 1 / 4;
            ing_pineapple_juice_need = 720 * 1 / 4;
          end
          else if(r_bev_size.bev_size == S) begin
            ing_black_tea_need       = 480 * 2 / 4;
            ing_green_tea_need       = 480 * 0 / 4;
            ing_milk_need            = 480 * 1 / 4;
            ing_pineapple_juice_need = 480 * 1 / 4;
          end
        end
      endcase
      // print needed ingredient
      if(`DEBUG_PRINT) begin
        $write("\033[0;36m");
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $display("|  Needed Ingredient                                                  ");
        $display("|  Black Tea       : %4d (0x%03x)                ", ing_black_tea_need, ing_black_tea_need);
        $display("|  Green Tea       : %4d (0x%03x)                ", ing_green_tea_need, ing_green_tea_need);
        $display("|  Milk            : %4d (0x%03x)                ", ing_milk_need, ing_milk_need);
        $display("|  Pineapple Juice : %4d (0x%03x)                ", ing_pineapple_juice_need, ing_pineapple_juice_need);
        $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        $write("\033[m");
      end

      if((r_date.date.M > date_dram.M) || ((r_date.date.M == date_dram.M) && (r_date.date.D > date_dram.D))) begin
        golden_complete = 1'b0;
        golden_err_msg = No_Exp;
      end
      else if((ing_black_tea_dram < ing_black_tea_need) || (ing_green_tea_dram < ing_green_tea_need) || (ing_milk_dram < ing_milk_need) || (ing_pineapple_juice_dram < ing_pineapple_juice_need)) begin
        golden_complete = 1'b0;
        golden_err_msg = No_Ing;
      end
      else begin
        golden_complete = 1'b1;
        golden_err_msg = No_Err;
        // do make drink
        ing_black_tea_dram       -= ing_black_tea_need;
        ing_green_tea_dram       -= ing_green_tea_need;
        ing_milk_dram            -= ing_milk_need;
        ing_pineapple_juice_dram -= ing_pineapple_juice_need;
        //update DRAM data
        data_in_DRAM[63:52] = ing_black_tea_dram;
        data_in_DRAM[51:40] = ing_green_tea_dram;
        data_in_DRAM[31:20] = ing_milk_dram;
        data_in_DRAM[19:8]  = ing_pineapple_juice_dram;
        // update golden_DRAM
        golden_DRAM[(65536 + r_barrel_no.barrel_no * 8) + 7] = data_in_DRAM[63:56];
        golden_DRAM[(65536 + r_barrel_no.barrel_no * 8) + 6] = data_in_DRAM[55:48];
        golden_DRAM[(65536 + r_barrel_no.barrel_no * 8) + 5] = data_in_DRAM[47:40];
        golden_DRAM[(65536 + r_barrel_no.barrel_no * 8) + 4] = data_in_DRAM[39:32];
        golden_DRAM[(65536 + r_barrel_no.barrel_no * 8) + 3] = data_in_DRAM[31:24];
        golden_DRAM[(65536 + r_barrel_no.barrel_no * 8) + 2] = data_in_DRAM[23:16];
        golden_DRAM[(65536 + r_barrel_no.barrel_no * 8) + 1] = data_in_DRAM[15:8];
        golden_DRAM[(65536 + r_barrel_no.barrel_no * 8) + 0] = data_in_DRAM[7:0];
      end
    end
    Supply: begin
      // default error message
      golden_complete = 1'b1;
      golden_err_msg = No_Err;
      // add ingredient
      if(ing_black_tea_dram + r_ing_black_tea.ing > 4095) begin
        ing_black_tea_dram = 4095;
        golden_complete = 1'b0;
        golden_err_msg = Ing_OF;
      end
      else begin
        ing_black_tea_dram = ing_black_tea_dram + r_ing_black_tea.ing;
      end
      if(ing_green_tea_dram + r_ing_green_tea.ing > 4095) begin
        ing_green_tea_dram = 4095;
        golden_complete = 1'b0;
        golden_err_msg = Ing_OF;
      end
      else begin
        ing_green_tea_dram = ing_green_tea_dram + r_ing_green_tea.ing;
      end
      if(ing_milk_dram + r_ing_milk.ing > 4095) begin
        ing_milk_dram = 4095;
        golden_complete = 1'b0;
        golden_err_msg = Ing_OF;
      end
      else begin
        ing_milk_dram = ing_milk_dram + r_ing_milk.ing;
      end
      if(ing_pineapple_juice_dram + r_ing_pineapple_juice.ing > 4095) begin
        ing_pineapple_juice_dram = 4095;
        golden_complete = 1'b0;
        golden_err_msg = Ing_OF;
      end
      else begin
        ing_pineapple_juice_dram = ing_pineapple_juice_dram + r_ing_pineapple_juice.ing;
      end
      // update DRAM data
      data_in_DRAM[63:52] = ing_black_tea_dram;
      data_in_DRAM[51:40] = ing_green_tea_dram;
      data_in_DRAM[31:20] = ing_milk_dram;
      data_in_DRAM[19:8]  = ing_pineapple_juice_dram;
      data_in_DRAM[39:32] = r_date.date.M;
      data_in_DRAM[7:0]   = r_date.date.D;
      // update golden_DRAM
      golden_DRAM[(65536 + r_barrel_no.barrel_no * 8) + 7] = data_in_DRAM[63:56];
      golden_DRAM[(65536 + r_barrel_no.barrel_no * 8) + 6] = data_in_DRAM[55:48];
      golden_DRAM[(65536 + r_barrel_no.barrel_no * 8) + 5] = data_in_DRAM[47:40];
      golden_DRAM[(65536 + r_barrel_no.barrel_no * 8) + 4] = data_in_DRAM[39:32];
      golden_DRAM[(65536 + r_barrel_no.barrel_no * 8) + 3] = data_in_DRAM[31:24];
      golden_DRAM[(65536 + r_barrel_no.barrel_no * 8) + 2] = data_in_DRAM[23:16];
      golden_DRAM[(65536 + r_barrel_no.barrel_no * 8) + 1] = data_in_DRAM[15:8];
      golden_DRAM[(65536 + r_barrel_no.barrel_no * 8) + 0] = data_in_DRAM[7:0];
    end
    Check_Valid_Date: begin
      if((r_date.date.M > date_dram.M) || ((r_date.date.M == date_dram.M) && (r_date.date.D > date_dram.D))) begin
        golden_complete = 1'b0;
        golden_err_msg = No_Exp;
      end
      else begin
        golden_complete = 1'b1;
        golden_err_msg = No_Err;
      end
    end
    default: begin
      $display("***********************************************************************");
      $display("*  Error (Pattern internal Error)                                     *");
      $display("*  The action is out of range                                         *");
      $display("***********************************************************************");
      repeat(2)@(negedge clk);
      $finish;
    end
  endcase
end endtask

task check_ans_task; begin
  integer ans_count = 1;
  for(integer i = 0; i < ans_count; i = i + 1) begin
    if(inf.out_valid !== 1) begin
      $display("***********************************************************************");
      $display("*  Wrong Answer Error:                                                *");
      $display("*  out_valid mantain too short                                        *");
      $display("***********************************************************************");
      repeat(2)@(negedge clk);
      $finish;
    end

    if((inf.complete !== golden_complete) || (inf.err_msg !== golden_err_msg)) begin
      $display("***********************************************************************");
      $display("*  Wrong Answer Error:                                                *");
      $display("*  The out_data should be correct when out_valid is high              *");
      $display("*  Your        : complete = %1b error_msg = %2x                          *", inf.complete, inf.err_msg);
      $display("*  Golden      : complete = %1b error_msg = %2x                          *", golden_complete, golden_err_msg);
      $display("***********************************************************************");
      repeat(2)@(negedge clk);
      $finish;
    end
    @(negedge clk);
  end

  if(inf.out_valid === 1) begin
    $display("***********************************************************************");
    $display("*  Wrong Answer Error:                                                *");
    $display("*  out_valid mantain too long                                         *");
    $display("***********************************************************************");
    repeat(2)@(negedge clk);
    $finish;
  end

  $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %4d\033[m", i_pat, latency);
end endtask

task YOU_PASS_task; begin
  $display("***********************************************************************");
  $display("*  \033[0;42;5m                         Congratulations!                        \033[m  *");
  $display("*  Your execution cycles = %18d   cycles                *", total_latency);
  $display("*  Your clock period     = %20.1f ns                    *", CYCLE);
  $display("*  Total Latency         = %20.1f ns                    *", total_latency*CYCLE);
  $display("***********************************************************************");
  $finish;
end endtask

endprogram
