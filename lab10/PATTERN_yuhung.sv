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

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
integer total_latency, latency;
integer i_pat;
parameter SEED = 67 ;
// integer a;

//================================================================
// wire & registers 
//================================================================
// logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];  // 256 box
logic [7:0] golden_DRAM [(65536+0):((65536+8*256)-1)];  // 256 box
Action     golden_act;
Bev_Type   golden_type;
Bev_Size   golden_size;
Date       golden_date;
int        golden_no_box;
Bev_Bal    golden_box_info;

Order_Info golden_order_info;
Data       golden_data;


logic golden_complete;
Error_Msg golden_err_msg;
logic [31:0] golden_out_info;


ING black, green, milk, pine;
ING golden_supply_black_tea, golden_supply_green_tea, golden_supply_milk, golden_supply_pineapple_juice;
logic [12:0]sum_out_black,sum_out_green, sum_out_milk, sum_out_pine;
wire overflow;
assign overflow = (sum_out_black[12] ||sum_out_green[12] ||sum_out_milk[12]  ||sum_out_pine[12] );
//================================================================
// class random
//================================================================
class rand_action;
	rand Action action;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit { action inside {Make_drink, Supply, Check_Valid_Date}; }
endclass
class rand_date;
	rand Date date;
	function new (int seed);
		this.srandom(seed);
	endfunction

    // Constraint can only be used once.
	constraint limit {
        date.M inside {[1:12]};
        if (date.M == 1 || date.M == 3 || date.M == 5 || date.M == 7 || date.M == 8 || date.M == 10 || date.M == 12)
            date.D inside {[1:31]};
        else if (date.M == 4 || date.M == 6 || date.M == 9 || date.M == 11)
            date.D inside {[1:30]};
        else if (date.M == 2)
            date.D inside {[1:28]};
    }
endclass
class rand_bev_type;
	rand Bev_Type bev_type;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit {bev_type inside {Black_Tea,Milk_Tea,Extra_Milk_Tea,Green_Tea,Green_Milk_Tea,Pineapple_Juice,Super_Pineapple_Tea,Super_Pineapple_Milk_Tea};}
endclass

class rand_bev_size;
	rand Bev_Size bev_size;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit { bev_size inside {L,M,S}; }
endclass

class rand_box_no;
    rand int box_no;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit { box_no inside {[0:255]}; }
endclass

class rand_supply_amount;
    rand int supply_amount;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit { supply_amount inside {[0:4095]}; }
endclass

class rand_delay; // Delays for input valid signals
	rand int delay;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit { delay inside {[0:3]}; } // Generates a delay between 0~3
endclass

class rand_gap;
	rand int gap;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit { gap inside {[1:3]}; } // Generates a delay between 1~4
endclass

rand_delay r_delay = new(SEED) ;
rand_bev_type r_bev_type = new(SEED) ;
rand_bev_size r_bev_size = new(SEED) ;
rand_action   r_action   = new(SEED) ;
rand_box_no   r_box_no  = new(SEED) ;
rand_date     r_date     = new(SEED) ;
rand_supply_amount r_supply_amount = new(SEED);
rand_gap        r_gap        = new(SEED);

//================================================================
// initial
//================================================================
initial begin
    reset_task;

    $readmemh(DRAM_p_r,golden_DRAM);
    golden_no_box = 0;
    for (i_pat = 1; i_pat <= 1800; i_pat = i_pat + 1) begin
        if (i_pat%9== 0)	golden_act = Make_drink ;
		else if (i_pat%9== 1)	golden_act = Check_Valid_Date ;
		else if (i_pat%9== 2)	golden_act = Supply ;
		else if (i_pat%9== 3)	golden_act = Supply ;
		else if (i_pat%9== 4)	golden_act = Make_drink ;
		else if (i_pat%9== 5)	golden_act = Supply ;
		else if (i_pat%9== 6)	golden_act = Check_Valid_Date ;
		else if (i_pat%9== 7)	golden_act = Check_Valid_Date ;
		else if (i_pat%9== 8)	golden_act = Make_drink ;
        case(golden_act)
			Make_drink: 
				make_drink_task;
			Supply:
				supply_task;
			Check_Valid_Date:
				check_valid_date_task;
		endcase
        // input_task;

        wait_out_valid_task;
        check_ans_task;
        gap_task;
        $display("\033[1;32mPASS PATTERN NO.%4d\033[00m", i_pat);

    end
    for (i_pat = 1801; i_pat <= 3600; i_pat = i_pat + 1) begin
        golden_act = Make_drink ;
        case(golden_act)
			Make_drink: 
				make_drink_task;
			Supply:
				supply_task;
			Check_Valid_Date:
				check_valid_date_task;
		endcase
        // input_task;

        wait_out_valid_task;
        check_ans_task;
        gap_task;
        $display("\033[1;32mPASS PATTERN NO.%4d\033[00m", i_pat);

    end
    YOU_PASS_task;
end 
//======================================
//              TASKS
//======================================

task reset_task; begin
    inf.rst_n            = 'b1;
    inf.sel_action_valid = 'b0;
    inf.type_valid       = 'b0;
    inf.size_valid       = 'b0;
    inf.date_valid       = 'b0;
    inf.box_no_valid     = 'b0;
    inf.box_sup_valid    = 'b0;
    inf.D                = 'dx;

    total_latency        = 0;

    #(10) inf.rst_n = 0;
    #(10) inf.rst_n = 1;
    if ( inf.out_valid !== 0 || inf.complete !== 0 || inf.err_msg !== 0) begin
        $display("==========================================================================");
        $display("    Output signal should be 0 at %-12d ps  ", $time*1000);
        $display("==========================================================================");
        repeat(5) #(10);
        $finish;
    end
end endtask
// task input_task; begin
//     @(negedge clk);
//     // r_action.randomize();
//     in_valid = 1;
//     a = $fscanf(pat_read, "%d ", direction);
// 	a = $fscanf(pat_read, "%d ", addr_dram);
// 	a = $fscanf(pat_read, "%d ", addr_sd);
//     addr_dram_save = addr_dram;
//     addr_sd_save = addr_sd;
//     @(negedge clk);
//     in_valid = 0;
//     direction = 'bx;
//     addr_dram = 'bx; // CORRECT HERE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//     addr_sd = 'bx;
// 	//  $display("direction = %d", direction);
// 	//  $display("addr_dram = %d", addr_dram);
//     //  $display("addr_sd = %d", addr_sd);
// end endtask
integer i;
task wait_out_valid_task; begin
    latency = 0;
    while(inf.out_valid !== 1'b1) begin
        // $display("latency = %d", latency) ;
	    latency = latency + 1;
      if( latency == 1000) begin
          $display("\033[1;31mThe execution latency is over 1000 cycles.\033[00m");
	    repeat(2)@(negedge clk);
	    $finish;
      end
     @(negedge clk);
   end
   total_latency = total_latency + latency;
end endtask

task delay_task ; begin
	r_delay.randomize();
	for( i=0 ; i<r_delay.delay ; i++ )	begin
        @(negedge clk);
    end
end endtask
task gap_task ; begin
	r_gap.randomize();
	for( i=0 ; i<r_gap.gap ; i++ )		begin
        @(negedge clk);
    end
end endtask
integer y;
task check_ans_task; begin
	// $display("output_task");
	y = 0;
	while (inf.out_valid===1)
    begin
		if (y >= 1)
        begin
			$display("\033[1;31mOutvalid is more than 1 cycles.\033[00m");
	        #(100);
			$finish;
		end
		else if (golden_act==Make_drink)
        begin
            // $display("Checking make drink out data \n");
    		if ( (inf.complete!==golden_complete) || (inf.err_msg!==golden_err_msg))
            begin
				$display("\033[1;31m                       Make drink\033[00m");
    	    	$display("    Golden complete : %6d    your complete : %6d ", golden_complete, inf.complete);
    			$display("    Golden err_msg  : %6d    your err_msg  : %6d ", golden_err_msg, inf.err_msg);
    			$display("\033[1;31m                       Wrong Answer\033[00m");
		        #(100);
    			$finish;
    		end
    	end
		else if (golden_act == Supply)
        begin
            // $display("Checking Supply out data \n");
    		if ( (inf.complete!==golden_complete) || (inf.err_msg!==golden_err_msg))
            begin
				$display("\033[1;31m                       Supply\033[00m");
    	    	$display("    Golden complete : %6d    your complete : %6d ", golden_complete, inf.complete);
    			$display("    Golden err_msg  : %6d    your err_msg  : %6d ", golden_err_msg, inf.err_msg);
    			$display("\033[1;31m                       Wrong Answer\033[00m");
		        #(100);
    			$finish;
    		end
        end
        else if(golden_act == Check_Valid_Date)
        begin
            // $display("Checking Check valid date out data \n");
            if ( (inf.complete!==golden_complete) || (inf.err_msg!==golden_err_msg))
            begin
				$display("\033[1;31m                       Check valid date\033[00m");
    	    	$display("    Golden complete : %6d    your complete : %6d ", golden_complete, inf.complete);
    			$display("    Golden err_msg  : %6d    your err_msg  : %6d ", golden_err_msg, inf.err_msg);
    			$display("\033[1;31m                       Wrong Answer\033[00m");
		        #(100);
    			$finish;
    		end
        end
	    @(negedge clk);
	    y = y + 1;
    end
end
endtask
task get_box_info_task;
begin
    golden_box_info.black_tea       = {golden_DRAM[65536+golden_no_box*8 + 7],golden_DRAM[65536+golden_no_box*8 + 6][7:4]};
	golden_box_info.green_tea       = {golden_DRAM[65536+golden_no_box*8 + 6][3:0],golden_DRAM[65536+golden_no_box*8 + 5]};
	golden_box_info.M               = golden_DRAM[65536+golden_no_box*8 + 4];
	golden_box_info.milk            =  {golden_DRAM[65536+golden_no_box*8 + 3],golden_DRAM[65536+golden_no_box*8 + 2][7:4]};
	golden_box_info.pineapple_juice =  {golden_DRAM[65536+golden_no_box*8 + 2][3:0],golden_DRAM[65536+golden_no_box*8 + 1]};
	golden_box_info.D               =  golden_DRAM[65536+golden_no_box*8 + 0];
end
endtask
task sel_action_valid_task;
begin
	inf.sel_action_valid = 1'b1;
    inf.D = golden_act;
    @(negedge clk);
    inf.sel_action_valid = 1'b0;
    inf.D = 'bx;
    delay_task;
end
endtask
task date_valid_task;
begin
    inf.date_valid = 1'b1;
    r_date.randomize();
    golden_date = r_date.date;

    inf.D  = {3'b0,golden_date};
    @(negedge clk);
    inf.date_valid = 1'b0;
    inf.D = 'bx;
    delay_task;
end
endtask
task box_no_valid_task;
begin
    inf.box_no_valid= 1'b1;
    r_box_num.randomize();
    golden_no_box = r_box_num.box_num;
    inf.D  = golden_no_box;
    @(negedge clk);
    inf.box_no_valid = 1'b0;
    inf.D = 'bx;
    delay_task;
end
endtask
task make_drink_task;
begin
    sel_action_valid_task;

    inf.type_valid = 1'b1;
    r_bev_type.randomize();
    golden_type = r_bev_type.bev_type;
    inf.D  = golden_type;
    @(negedge clk);
    inf.type_valid = 1'b0;
    inf.D = 'bx;
    delay_task;
    
    inf.size_valid = 1'b1;
    r_bev_size.randomize();
    golden_size = r_bev_size.bev_size;
    inf.D  = golden_size;
    @(negedge clk);
    inf.size_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    date_valid_task;
	box_no_valid_task;



    get_box_info_task;
    golden_complete = 1'b1;
    golden_err_msg  = No_Err;

    if((golden_box_info.M > golden_date.M) || ((golden_box_info.M == golden_date.M) && (golden_box_info.D >= golden_date.D)))
    begin
        begin
        case(golden_type)
            Black_Tea      	         :begin
                case(golden_size)
                L: black  = 12'd960;
                M: black  = 12'd720;
                S: black  = 12'd480;
                endcase
            end
            Milk_Tea	             :begin
                case(golden_size)
                L: black  = 12'd720;
                M: black  = 12'd540;
                S: black  = 12'd360;
                endcase
            end
            Extra_Milk_Tea           :begin
                case(golden_size)
                L: black  = 12'd480;
                M: black  = 12'd360;
                S: black  = 12'd240;
                endcase
            end
            Super_Pineapple_Tea      :begin
                case(golden_size)
                L: black  = 12'd480;
                M: black  = 12'd360;
                S: black  = 12'd240;
                endcase
            end
            Super_Pineapple_Milk_Tea :begin
                case(golden_size)
                L: black  = 12'd480;
                M: black  = 12'd360;
                S: black  = 12'd240;
                endcase
            end
            default black = 12'd0;
        endcase
        case(golden_type)
            Green_Tea 	             :begin
                case(golden_size)
                L: green  = 12'd960;
                M: green  = 12'd720;
                S: green  = 12'd480;
                endcase
            end
            Green_Milk_Tea           :begin
                case(golden_size)
                L: green  = 12'd480;
                M: green  = 12'd360;
                S: green  = 12'd240;
                endcase
            end
            default green = 12'd0;
        endcase
        case(golden_type)
            Milk_Tea	             :begin
                case(golden_size)
                L: milk  = 12'd240;
                M: milk  = 12'd180;
                S: milk  = 12'd120;
                endcase
            end
            Extra_Milk_Tea           :begin
                case(golden_size)
                L: milk  = 12'd480;
                M: milk  = 12'd360;
                S: milk  = 12'd240;
                endcase
            end
            Green_Milk_Tea           :begin
                case(golden_size)
                L: milk  = 12'd480;
                M: milk  = 12'd360;
                S: milk  = 12'd240;
                endcase
            end
            Super_Pineapple_Milk_Tea :begin
                case(golden_size)
                L: milk  = 12'd240;
                M: milk  = 12'd180;
                S: milk  = 12'd120;
                endcase
            end
            default milk = 12'd0;
        endcase
        case(golden_type)
            Pineapple_Juice          :begin
                case(golden_size)
                L: pine  = 12'd960;
                M: pine  = 12'd720;
                S: pine  = 12'd480;
                endcase
            end
            Super_Pineapple_Tea      :begin
                case(golden_size)
                L: pine  = 12'd480;
                M: pine  = 12'd360;
                S: pine  = 12'd240;
                endcase
            end
            Super_Pineapple_Milk_Tea :begin
                case(golden_size)
                L: pine  = 12'd240;
                M: pine  = 12'd180;
                S: pine  = 12'd120;
                endcase
            end
            default pine = 12'd0;
        endcase
        if(((black > golden_box_info.black_tea)||(green > golden_box_info.green_tea)||(milk > golden_box_info.milk)||
            (pine > golden_box_info.pineapple_juice)))begin
                golden_err_msg = No_Ing;
                golden_complete = 1'b0;
            end
        end
        else 
        begin
            golden_box_info.black_tea -= black;
            golden_box_info.green_tea -= green;
            golden_box_info.milk -= milk;
            golden_box_info.pineapple_juice -= pine;
        end
    else
    begin
        golden_err_msg  = No_Exp;
        golden_complete = 1'b0;
    end
end
endtask

task supply_task;
begin
    sel_action_valid_task;
    date_valid_task;
	box_no_valid_task;

    get_box_info_task;
    golden_complete = 1'b1;
    golden_err_msg  = No_Err;

    
	inf.box_sup_valid = 1'b1; //black
    r_supply_amount.randomize();
    golden_supply_black_tea = r_supply_amount.supply_amount;
    inf.D  = golden_supply_black_tea;
    @(negedge clk);
    inf.box_sup_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    inf.box_sup_valid = 1'b1; //green
    r_supply_amount.randomize();
    golden_supply_green_tea = r_supply_amount.supply_amount;
    inf.D  = golden_supply_green_tea;
    @(negedge clk);
    inf.box_sup_valid = 1'b0;
    inf.D = 'bx;
    delay_task;
    
    inf.box_sup_valid = 1'b1; //milk
    r_supply_amount.randomize();
    golden_supply_milk = r_supply_amount.supply_amount;
    inf.D  = golden_supply_milk;
    @(negedge clk);
    inf.box_sup_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    inf.box_sup_valid = 1'b1; //pine
    r_supply_amount.randomize();
    golden_supply_pineapple_juice = r_supply_amount.supply_amount;
    inf.D  = golden_supply_pineapple_juice;
    @(negedge clk);
    inf.box_sup_valid = 1'b0;
    inf.D = 'bx;
    delay_task;
    
    get_box_info_task;

    golden_complete = 1'b1;
    sum_out_black = golden_box_info.black_tea + golden_supply_black_tea;
    sum_out_green = golden_box_info.green_tea + golden_supply_green_tea;
    sum_out_milk  = golden_box_info.milk      + golden_supply_milk;
    sum_out_pine  = golden_box_info.pineapple_juice + golden_supply_pineapple_juice;
    if(overflow)begin
        golden_err_msg  = Ing_OF;
        golden_complete = 1'b0;
    end
    else
    begin
        golden_err_msg  = No_Err;
        golden_complete = 1'b1;
    end
    golden_box_info.M = golden_date.M;
    golden_box_info.D = golden_date.D;

    golden_box_info = {((sum_out_black[12])?12'hFFF:sum_out_black[11:0]),
            ((sum_out_green[12])?12'hFFF:sum_out_green[11:0]),
            golden_date.M,
            ((sum_out_milk[12])?12'hFFF:sum_out_milk[11:0]),
            ((sum_out_pine[12])?12'hFFF:sum_out_pine[11:0]),
            golden_date.D};

end
endtask
task check_valid_date_task;
begin
    sel_action_valid_task;
    date_valid_task;
	box_no_valid_task;
    get_box_info_task;
    if(golden_box_info.M > golden_date.M)
    begin
        golden_complete = 1'b1;
        golden_err_msg  = No_Err;
    end
    else if(golden_box_info.M == golden_date.M && golden_box_info.D >= golden_date.D)
    begin
        golden_complete = 1'b1;
        golden_err_msg  = No_Err;
    end
    else
    begin
        golden_complete = 1'b0;
        golden_err_msg  = No_Exp;
    end
end
endtask
task YOU_PASS_task;begin
    $display("********************************************************************");
    $display("                        \033[0;38;5;219mCongratulations!\033[m      ");
    $display("                 \033[0;38;5;219mYou have passed all patterns!\033[m");
    $display("                 \033[0;38;5;219mTotal time: %d \033[m",$time);
    $display("********************************************************************");
	repeat(2) @(negedge clk);
    $finish;
end endtask

endprogram
