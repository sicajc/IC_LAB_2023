`include "Usertype_BEV.sv"
`include "../00_TESTBED/pseudo_DRAM.sv"

program automatic PATTERN_BEV(input clk, INF.PATTERN_BEV inf);
import usertype::*;

//================================================================
//  integer & parameter
//================================================================
//
integer i, cycles, total_cycles, y;
integer patcount;
integer color_stage = 0, color, r = 5, g = 0, b = 0 ;
//
parameter SEED = 67 ;
parameter PATNUM = 10 ;
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter BASE_Addr = 65536 ;
parameter BASE_End = 65536 + 255*8 ;

//================================================================
//  logic
//================================================================
logic [7:0] golden_DRAM[(BASE_Addr+0):((BASE_Addr+256*8)-1)];
// operation info.
// Data golden_data;
Action     golden_act;
Bev_Type   golden_type;
Bev_Size   golden_size;
int        golden_no_box;
Date       golden_date;
Bev_Bal    golden_bev_bal;
Order_Info golden_order_info;
Data       golden_data;

// Dram info
Bev_Bal   golden_box_info;

// golden outputs
logic golden_complete;
Error_Msg golden_err_msg;
logic [31:0] golden_out_info;
//================================================================
//  class
//================================================================
// First instantiate classes of RNG generator and add constraints for each needed element.
class rand_delay;
	rand int delay;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit { delay inside {[1:4]}; } // Generates a delay between 1~4
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

class rand_action;
	rand Action action;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit { action inside {Make_drink, Supply, Check_Valid_Date}; }
endclass

class rand_box_num;
    rand int box_num;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit { box_num inside {[0:255]}; }
endclass

class rand_supply_amt;
    rand int supply_amt;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit { supply_amt inside {[0:4095]}; }
endclass

class rand_date;
	rand reg[3:0] month;
    rand reg[4:0] day;
	function new (int seed);
		this.srandom(seed);
	endfunction

	constraint limit { month inside {[1:12]};}

    if(month == 1 || month == 3 ||month == 5 || month == 7 || month == 8 || month == 10 || month == 12):
    begin
        constraint limit { day inside {[1:31]};}
    end
    else if(month == 4 || month == 6 || month == 9 || month == 11):
    begin
        constraint limit { day inside {[1:30]};}
    end
    else if(month == 2)
    begin
        constraint limit { day inside {[1:28]};}
    end
endclass

//
rand_delay r_delay = new(SEED) ;
//
rand_bev_type r_bev_type = new(SEED) ;
rand_bev_size r_bev_size = new(SEED) ;
rand_action   r_action   = new(SEED) ;
rand_box_num  r_box_num  = new(SEED) ;
rand_date     r_date     = new(SEED) ;
rand_supply_amt r_supply_amt = new(SEED);


//================================================================
//  initial
//================================================================
initial begin
	// read in initial DRAM data
	$readmemh(DRAM_p_r, golden_DRAM);
	// initial deposit value
	current_box = { golden_DRAM[BASE_Addr+0], golden_DRAM[BASE_Addr+1], golden_DRAM[BASE_Addr+2], golden_DRAM[BASE_Addr+3],
    golden_DRAM[BASE_Addr+4], golden_DRAM[BASE_Addr+5], golden_DRAM[BASE_Addr+6], golden_DRAM[BASE_Addr+7]};

	$display("BOX 0 = %h", current_box);
	// reset output signals
	inf.rst_n = 1'b1 ;
	inf.sel_action_valid = 1'b0 ;
	inf.type_valid = 1'b0 ;
	inf.size_valid = 1'b0 ;
	inf.date_valid = 1'b0 ;
	inf.box_no_valid = 1'b0 ;
	inf.box_sup_valid = 1'b0 ;
    inf.D = 'bx;

	// reset
	total_cycles = 0 ;
	reset_task;
	//
	@(negedge clk);
	for( patcount=0 ; patcount<PATNUM ; patcount+=1 ) begin
		// randomize, makes the r_give_id becomes a random number with the give constraints
		r_action.randomize();

		golden_act  = r_action.action ;
		//Start giving inputs
		case(golden_act)
			Make_drink: begin
				$display("Make drink");
				make_drink_task;
			end
			Supply: begin
				$display("Supply");
				supply_task;
			end
			Check_Valid_Date: begin
				$display("Checking valid date");
				check_valid_date_task;
			end
		endcase
        // For checking
        get_box_info_task;
		wait_outvalid_task;
		output_task;
		//
		delay_task;
		//
		case(color_stage)
            0: begin
                r = r - 1;
                g = g + 1;
                if(r == 0) color_stage = 1;
            end
            1: begin
                g = g - 1;
                b = b + 1;
                if(g == 0) color_stage = 2;
            end
            2: begin
                b = b - 1;
                r = r + 1;
                if(b == 0) color_stage = 0;
            end
        endcase
        color = 16 + r*36 + g*6 + b;
        if(color < 100) $display("\033[38;5;%2dmPASS PATTERN NO.%4d\033[00m", color, patcount+1);
        else $display("\033[38;5;%3dmPASS PATTERN NO.%4d\033[00m", color, patcount+1);
	end
	#(1000);
    YOU_PASS_task;
    $finish;
end

//================================================================
//  env task
//================================================================
task reset_task ; begin
	#(2.0);	inf.rst_n = 0 ;
	#(3.0);
	if (inf.out_valid!==0 || inf.err_msg!==0 || inf.complete !== 0) begin
		fail;
        // Spec. 3
        // Using  asynchronous  reset  active  low  architecture. All  outputs  should  be zero after reset.
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                SPEC 3 FAIL!                                                                ");
        $display ("                                   All output signals should be reset after the reset signal is asserted.                                   ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        #(100);
        $finish;
	end
	#(2.0);	inf.rst_n = 1 ;
end endtask

task delay_task ; begin
	r_delay.randomize();
	for( i=0 ; i<r_delay.delay ; i++ )	@(negedge clk);
end endtask

task wait_outvalid_task; begin
	cycles = 0 ;
	while (inf.out_valid!==1)
    begin
		cycles = cycles + 1 ;
		if (cycles==1000) begin
			fail;
            // Spec. 8
            // Your latency should be less than 1200 cycle for each operation.
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                SPEC 8 FAIL!                                                                ");
            $display ("                                             The execution latency is limited in 1200 cycles.                                               ");
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        	#(100);
            $finish;
		end
		@(negedge clk);
	end
	total_cycles = total_cycles + cycles ;
end endtask


//================================================================
//  output task
//================================================================
task output_task; begin
	$display("output_task");
	y = 0;
	while (inf.out_valid===1)
    begin
		if (y >= 1)
        begin
			$display ("--------------------------------------------------");
			$display ("                        FAIL                      ");
			$display ("          Outvalid is more than 1 cycles          ");
			$display ("--------------------------------------------------");
	        #(100);
			$finish;
		end
		else if (golden_act==Make_drink)
        begin
            $display("Checking make drink out data \n");
    		if ( (inf.complete!==golden_complete) || (inf.err_msg!==golden_err_msg))
            begin
				$display("-----------------------------------------------------------");
    	    	$display("                       FAIL Make drink                     ");
    	    	$display("    Golden complete : %6d    your complete : %6d ", golden_complete, inf.complete);
    			$display("    Golden err_msg  : %6d    your err_msg  : %6d ", golden_err_msg, inf.err_msg);
    			$display("-----------------------------------------------------------");
                get_box_info_task;
		        #(100);
    			$finish;
    		end
    	end
		else if (golden_act == Supply)
        begin
            $display("Checking make drink out data \n");
    		if ( (inf.complete!==golden_complete) || (inf.err_msg!==golden_err_msg))
            begin
				$display("-----------------------------------------------------------");
    	    	$display("                           FAIL Supply                     ");
    	    	$display("    Golden complete : %6d    your complete : %6d ", golden_complete, inf.complete);
    			$display("    Golden err_msg  : %6d    your err_msg  : %6d ", golden_err_msg, inf.err_msg);
    			$display("-----------------------------------------------------------");
                get_box_info_task;
		        #(100);
    			$finish;
    		end
        end
        else if(golden_act == Check_Valid_Date)
        begin
            if ( (inf.complete!==golden_complete) || (inf.err_msg!==golden_err_msg))
            begin
				$display("-----------------------------------------------------------");
    	    	$display("                           FAIL Check Valid date                     ");
    	    	$display("    Golden complete : %6d    your complete : %6d ", golden_complete, inf.complete);
    			$display("    Golden err_msg  : %6d    your err_msg  : %6d ", golden_err_msg, inf.err_msg);
    			$display("-----------------------------------------------------------");
                get_box_info_task;
		        #(100);
    			$finish;
    		end
        end
    end
	@(negedge clk);
	y = y + 1;
end
endtask

//================================================================
//  get box info task
//================================================================
task display_cur_gold_task;
begin
    $display("================================================================");
    $display("                          Current Golden                        ");
    $display("             Black tea = %h", golden_box_info.black_tea);
    $display("             Green tea = %h", golden_box_info.green_tea);
    $display("             Milk = %h", golden_box_info.milk);
    $display("             Pineapple Juice = %h", golden_box_info.pineapple_juice);
    $display("             Month = %h", golden_box_info.month);
    $display("             Day = %h", golden_box_info.day);
    $display("================================================================");
end
endtask


task get_box_info_task;
begin
    golden_box_info.black_tea       = {golden_DRAM[BASE_Addr+golden_no_box*8 + 7],golden_DRAM[BASE_Addr+golden_no_box*8 + 6][7:4]};
	golden_box_info.green_tea       = {golden_DRAM[BASE_Addr+golden_no_box*8 + 6][3:0],golden_DRAM[BASE_Addr+golden_no_box*8 + 5]};
	golden_box_info.M               = golden_DRAM[BASE_Addr+golden_no_box*8 + 4];
	golden_box_info.milk            =  {golden_DRAM[BASE_Addr+golden_no_box*8 + 3],golden_DRAM[BASE_Addr+golden_no_box*8 + 2][7:4]};
	golden_box_info.pineapple_juice =  {golden_DRAM[BASE_Addr+golden_no_box*8 + 2][3:0],golden_DRAM[BASE_Addr+golden_no_box*8 + 1]};
	golden_box_info.D               =  golden_DRAM[BASE_Addr+golden_no_box*8 + 0];
end
endtask

int temp_black_tea;
int temp_green_tea;
int temp_milk;
int temp_pineapple_juice;

int black_tea_need;
int green_tea_need;
int milk_need;
int pineapple_juice_need;

parameter S_size = 480;
parameter M_size = 720;
parameter L_size = 960;

//================================================================
//  make drink
//================================================================
task make_drink_task;
begin
	// Generate Input actions
	sel_action_valid = 1'b1;
    inf.D = golden_act;
    @(negedge clk);
    sel_action_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    // Generate Types, 8 types
    type_valid = 1'b1;
    r_bev_type.randomize();
    golden_type = r_bev_type.bev_type;
    inf.D  = golden_type;
    @(negedge clk);
    type_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

	//Generate Size, 3 sizes
    size_valid = 1'b1;
    r_bev_size.randomize();
    golden_size = r_bev_size.bev_size;
    inf.D  = golden_size;
    @(negedge clk);
    size_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

	// Give Today's Date
    date_valid = 1'b1;
    r_date.randomize();
    golden_date.D = r_date.day;
    golden_date.M = r_date.month;

    inf.D  = {3'b0,golden_date.M,golden_date.D};
    @(negedge clk);
    date_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

	// Box #No.
    box_no_valid= 1'b1;
    r_box_num.randomize();
    golden_no_box = r_box_num.box_num;
    inf.D  = golden_no_box;
    @(negedge clk);
    box_no_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    // Generate golden signals for output check uses
    // Pull out data from the ingredient box
    get_box_info_task;
    display_cur_gold_task;
    // Perform opeartion according to these ingredients.
    golden_complete = 1'b1;
    // First check expieration date
    if(golden_box_info.month >= golden_date.M && golden_box_info.day >= golden_date.D)
    begin
        // Then determine the drink I want to make
        case(golden_type)
        Black_Tea:begin // Black tea 1
            temp_black_tea = golden_box_info.black_tea;
            // Determine the size
            case(golden_size)
            S:begin
                temp_black_tea -= 480;
            end
            M:begin
                temp_black_tea -= 720;
            end
            L:begin
                temp_black_tea -= 960;
            end
            default:begin
               $display("Size error!")
            end
            endcase

            if(temp_black_tea < 0)
            begin
               $display("Not enough ingredient for making Black Tea!");
               golden_err_msg  = No_Ing;
               golden_complete = 1'b0;
            end
            else // Update the golden box info
            begin
                golden_box_info.black_tea = temp_black_tea;
            end
        end
        Milk_Tea:begin // Black tea 3, Milk 1
            temp_black_tea = golden_box_info.black_tea;
            temp_milk = golden_box_info.milk;
            // Determine the size
            case(golden_size)
            S:begin
                black_tea_need = (S_size/4)*3;
                milk_need      = (S_size/4)*1;

                temp_black_tea -= black_tea_need;
                temp_milk      -= milk_need;
            end
            M:begin
                black_tea_need = (M_size/4)*3;
                milk_need      = (M_size/4)*1;

                temp_black_tea -= black_tea_need;
                temp_milk      -= milk_need;
            end
            L:begin
                black_tea_need = (L_size/4)*3;
                milk_need      = (L_size/4)*1;

                temp_black_tea -= black_tea_need;
                temp_milk      -= milk_need;
            end
            default:begin
               $display("Size error!")
            end
            endcase

            if(temp_black_tea < 0 || temp_milk < 0)
            begin
               $display("Not enough ingredient for making Milk Tea!");
               golden_err_msg  = No_Ing;
               golden_complete = 1'b0;
            end
            else // Update the golden box info
            begin
                golden_box_info.black_tea = temp_black_tea;
                golden_box_info.milk      = temp_milk;
            end
        end
        Extra_Milk_Tea:begin
            temp_black_tea = golden_box_info.black_tea;
            temp_milk      = golden_box_info.milk;
            // Determine the size
            case(golden_size)
            S:begin
                black_tea_need = (S_size/2)*1;
                milk_need      = (S_size/2)*1;

                temp_black_tea -= black_tea_need;
                temp_milk      -= milk_need;
            end
            M:begin
                black_tea_need = (M_size/2)*1;
                milk_need      = (M_size/2)*1;

                temp_black_tea -= black_tea_need;
                temp_milk      -= milk_need;
            end
            L:begin
                black_tea_need = (L_size/2)*1;
                milk_need      = (L_size/2)*1;

                temp_black_tea -= black_tea_need;
                temp_milk      -= milk_need;
            end
            default:begin
               $display("Size error!")
            end
            endcase

            if(temp_black_tea < 0 || temp_milk < 0)
            begin
               $display("Not enough ingredient for making Extra milk Tea!");
               golden_err_msg  = No_Ing;
               golden_complete = 1'b0;
            end
            else // Update the golden box info
            begin
                golden_box_info.black_tea = temp_black_tea;
                golden_box_info.milk      = temp_milk;
            end
        end
        Green_Tea:begin
            temp_green_tea = golden_box_info.green_tea;
            // Determine the size
            case(golden_size)
            S:begin
                temp_green_tea -= S_size;
            end
            M:begin
                temp_green_tea -= M_size;
            end
            L:begin
                temp_green_tea -= L_size;
            end
            default:begin
               $display("Size error!")
            end
            endcase

            if(temp_green_tea < 0)
            begin
               $display("Not enough ingredient for making Green Tea!");
               golden_err_msg  = No_Ing;
               golden_complete = 1'b0;
            end
            else // Update the golden box info
            begin
                golden_box_info.green_tea = temp_green_tea;
            end
        end
        Green_Milk_Tea:begin
            temp_green_tea = golden_box_info.green_tea;
            temp_milk      = golden_box_info.milk;
            // Determine the size
            case(golden_size)
            S:begin
                green_tea_need = (S_size/2)*1;
                milk_need      = (S_size/2)*1;

                temp_green_tea -= green_tea_need;
                temp_milk      -= milk_need;
            end
            M:begin
                green_tea_need = (M_size/2)*1;
                milk_need      = (M_size/2)*1;

                temp_green_tea -= green_tea_need;
                temp_milk      -= milk_need;
            end
            L:begin
                green_tea_need = (L_size/2)*1;
                milk_need      = (L_size/2)*1;

                temp_green_tea -= green_tea_need;
                temp_milk      -= milk_need;
            end
            default:begin
               $display("Size error!")
            end
            endcase

            if(temp_green_tea < 0 || temp_milk < 0)
            begin
               $display("Not enough ingredient for making green milk tea!");
               golden_err_msg  = No_Ing;
               golden_complete = 1'b0;
            end
            else // Update the golden box info
            begin
                golden_box_info.green_tea = temp_green_tea;
                golden_box_info.milk      = temp_milk;
            end
        end
        Pineapple_Juice:begin
            temp_pineapple_juice = golden_box_info.pineapple_juice;
            // Determine the size
            case(golden_size)
            S:begin
                temp_pineapple_juice -= S_size;
            end
            M:begin
                temp_pineapple_juice -= M_size;
            end
            L:begin
                temp_pineapple_juice -= L_size;
            end
            default:begin
               $display("Size error!")
            end
            endcase

            if(temp_pineapple_juice < 0)
            begin
               $display("Not enough ingredient for making Pine apple juice!");
               golden_err_msg  = No_Ing;
               golden_complete = 1'b0;
            end
            else // Update the golden box info
            begin
                golden_box_info.pineapple_juice = temp_pineapple_juice;
            end
        end
        Super_Pineapple_Tea:
        begin
            temp_black_tea       = golden_box_info.black_tea;
            temp_pineapple_juice = golden_box_info.pineapple_juice;
            // Determine the size
            case(golden_size)
            S:begin
                pineapple_juice_need = (S_size/2)*1;
                black_tea_need       = (S_size/2)*1;

                temp_pineapple_juice -= pineapple_juice_need;
                temp_black_tea       -= black_tea_need;
            end
            M:begin
                pineapple_juice_need = (M_size/2)*1;
                black_tea_need       = (M_size/2)*1;

                temp_pineapple_juice -= pineapple_juice_need;
                temp_black_tea       -= black_tea_need;
            end
            L:begin
                pineapple_juice_need = (L_size/2)*1;
                black_tea_need       = (L_size/2)*1;

                temp_pineapple_juice -= pineapple_juice_need;
                temp_black_tea       -= black_tea_need;
            end
            default:begin
               $display("Size error!")
            end
            endcase

            if(temp_pineapple_juice < 0 || temp_black_tea < 0)
            begin
               $display("Not enough ingredient for making Super pineapple tea");
               golden_err_msg  = No_Ing;
               golden_complete = 1'b0;
            end
            else // Update the golden box info
            begin
                golden_box_info.pineapple_juice = temp_pineapple_juice;
                golden_box_info.black_tea            = temp_black_tea;
            end
        end
        Super_Pineapple_Milk_Tea:
        begin
            temp_black_tea       = golden_box_info.black_tea;
            temp_pineapple_juice = golden_box_info.pineapple_juice;
            temp_milk            = golden_box_info.milk;
            // Determine the size
            case(golden_size)
            S:begin
                black_tea_need       = (S_size/4)*2;
                pineapple_juice_need = (S_size/4)*1;
                milk_need            = (S_size/4)*1;

                temp_pineapple_juice -= pineapple_juice_need;
                temp_black_tea       -= black_tea_need;
                temp_milk            -= milk_need;
            end
            M:begin
                black_tea_need       = (M_size/4)*2;
                pineapple_juice_need = (M_size/4)*1;
                milk_need            = (M_size/4)*1;

                temp_pineapple_juice -= pineapple_juice_need;
                temp_black_tea       -= black_tea_need;
                temp_milk            -= milk_need;
            end
            L:begin
                black_tea_need       = (L_size/4)*2;
                pineapple_juice_need = (L_size/4)*1;
                milk_need            = (L_size/4)*1;

                temp_pineapple_juice -= pineapple_juice_need;
                temp_black_tea       -= black_tea_need;
                temp_milk            -= milk_need;
            end
            default:begin
               $display("Size error!")
            end
            endcase

            if(temp_pineapple_juice < 0 || temp_black_tea < 0 || temp_milk < 0)
            begin
               $display("Not enough ingredient for making Super pineapple tea");
               golden_err_msg  = No_Ing;
               golden_complete = 1'b0;
            end
            else // Enough to make drink update the golden box info
            begin
                golden_box_info.pineapple_juice      = temp_pineapple_juice;
                golden_box_info.black_tea            = temp_black_tea;
            end
        end
        default:
        begin
            $display("===================================");
            $display("Type Error!!!");
            $display("===================================");
        end
        endcase

    end
    else
    begin
        // Expired
        $display("Ingredient Expired");
        golden_err_msg  = No_Exp;
        golden_complete = 1'b0;
    end
    update_dram_info_task;
end
endtask
//================================================================
//  Supply
//================================================================
int golden_supply_black_tea;
int golden_supply_green_tea;
int golden_supply_milk;
int golden_supply_pineapple_juice;


task supply_task;
begin
    // Generate Input actions
	sel_action_valid = 1'b1;
    inf.D = golden_act;
    @(negedge clk);
    sel_action_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    // Giving date
	date_valid = 1'b1;
    r_date.randomize();
    golden_date.D = r_date.day;
    golden_date.M = r_date.month;
    inf.D  = {3'b0,golden_date.M,golden_date.D};
    @(negedge clk);
    date_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    // Giving box #no.
	box_no_valid = 1'b1;
    inf.D  = golden_no_box;
    @(negedge clk);
    box_no_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    //Black Tea
	box_sup_valid = 1'b1;
    r_supply_amt.randomize()
    golden_supply_black_tea = r_supply_amt.supply_amt;
    inf.D  = golden_supply_black_tea;
    @(negedge clk);
    box_no_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    //Green Tea
	box_sup_valid = 1'b1;
    r_supply_amt.randomize()
    golden_supply_green_tea = r_supply_amt.supply_amt;
    inf.D  = golden_supply_green_tea;
    @(negedge clk);
    box_no_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    //Milk
	box_sup_valid = 1'b1;
    r_supply_amt.randomize()
    golden_supply_milk = r_supply_amt.supply_amt;
    inf.D  = golden_supply_milk;
    @(negedge clk);
    box_no_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    //Pineapple juice
	box_sup_valid = 1'b1;
    r_supply_amt.randomize()
    golden_supply_pineapple_juice = r_supply_amt.supply_amt;
    inf.D  = golden_supply_pineapple_juice;
    @(negedge clk);
    box_no_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    // Get dram value
    // Generate golden signals for output check uses
    // Pull out data from the ingredient box
    get_box_info_task;
    display_cur_gold_task;

    // Perform opeartion according to these ingredients.
    golden_complete = 1'b1;

    // Generate golden result
    temp_black_tea = golden_box_info.black_tea;
    temp_green_tea = golden_box_info.green_tea;
    temp_milk      = golden_box_info.milk;
    temp_pineapple_juice = golden_box_info.pineapple_juice;

    // Add the supplies
    temp_black_tea += golden_supply_black_tea;
    temp_green_tea += golden_supply_green_tea;
    temp_milk      += golden_supply_milk;
    temp_pineapple_juice += golden_supply_pineapple_juice;

    if(temp_black_tea > 4095 || temp_green_tea > 4095 || temp_milk > 4095 || temp_pineapple_juice > 4095)
    begin
        golden_err_msg  = Ing_OF;
        golden_complete = 1'b0;
    end
    else
    begin
        golden_err_msg  = No_Err;
        golden_complete = 1'b1;
    end

    if(temp_black_tea>4095) golden_box_info.black_tea = 4095 else golden_box_info.black_tea = temp_black_tea;

    if(temp_green_tea>4095) golden_box_info.green_tea = 4095 else golden_box_info.green_tea = temp_green_tea;

    if(temp_milk>4095) golden_box_info.milk = 4095 else golden_box_info.milk = temp_milk;

    if(temp_pineapple_juice>4095) golden_box_info.pineapple_juice = 4095 else golden_box_info.pineapple_juice = temp_pineapple_juice;

    // Updates the DRAM
    update_dram_info_task;
end
endtask
//================================================================
//  Check valid date
//================================================================
task check_valid_date_task
begin
    // Generate Input actions
	sel_action_valid = 1'b1;
    inf.D = golden_act;
    @(negedge clk);
    sel_action_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    // Give Today's Date
    date_valid = 1'b1;
    r_date.randomize();
    golden_date.D = r_date.day;
    golden_date.M = r_date.month;

    inf.D  = {3'b0,golden_date.M,golden_date.D};
    @(negedge clk);
    date_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    // Box #No.
    box_no_valid= 1'b1;
    r_box_num.randomize();
    golden_no_box = r_box_num.box_num;
    inf.D  = golden_no_box;
    @(negedge clk);
    box_no_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    // Golden signals for output check uses
    // Pull out data from the ingredient box
    get_box_info_task;
    display_cur_gold_task;
    // Perform opeartion according to these ingredients.
    golden_complete = 1'b1;

    // Start checking outputs, no need for updates
    if(golden_box_info.month >= golden_date.M && golden_box_info.day >= golden_date.D)
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


task update_dram_info_task;
begin
    golden_DRAM[BASE_Addr+golden_no_box*8 + 7]      = golden_box_info.black_tea[11:4];
    golden_DRAM[BASE_Addr+golden_no_box*8 + 6][7:4] = golden_box_info.black_tea[3:0];
	golden_DRAM[BASE_Addr+golden_no_box*8 + 6][3:0] = golden_box_info.green_tea[11:8];
    golden_DRAM[BASE_Addr+golden_no_box*8 + 5]      = golden_box_info.green_tea[7:0];
    golden_DRAM[BASE_Addr+golden_no_box*8 + 4]      = golden_box_info.M;
    golden_DRAM[BASE_Addr+golden_no_box*8 + 3]      = golden_box_info.milk[11:4];
    golden_DRAM[BASE_Addr+golden_no_box*8 + 2][7:4] = golden_box_info.milk[3:0];
    golden_DRAM[BASE_Addr+golden_no_box*8 + 2][3:0] = golden_box_info.pineapple_juice[11:8];
    golden_DRAM[BASE_Addr+golden_no_box*8 + 1]      = golden_box_info.pineapple_juice[7:0];
    golden_DRAM[BASE_Addr+golden_no_box*8 + 0]      = golden_box_info.D;
end
endtask

endprogram
