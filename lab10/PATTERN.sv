`include "Usertype_BEV.sv"
`define CYCLE_TIME 10.0

program automatic PATTERN(input clk, INF.PATTERN inf);
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
parameter PATNUM = 3600 ;
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter BASE_Addr = 65536 ;
// parameter BASE_End = 65536 + 255*8 ;

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
Data       golden_data;
Order_Info golden_order_info;

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

    // Constraint can only be used once.
	constraint limit {
        month inside {[1:12]};
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12)
            day inside {[1:31]};
        else if (month == 4 || month == 6 || month == 9 || month == 11)
            day inside {[1:30]};
        else if (month == 2)
            day inside {[1:28]};
    }
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
rand_gap        r_gap        = new(SEED);

int make_drink_cnt;

//================================================================
//  initial
//================================================================
initial begin
	// read in initial DRAM data
	$readmemh(DRAM_p_r, golden_DRAM);
	// initial deposit value
	// current_box = { golden_DRAM[BASE_Addr+0], golden_DRAM[BASE_Addr+1], golden_DRAM[BASE_Addr+2], golden_DRAM[BASE_Addr+3],
    // golden_DRAM[BASE_Addr+4], golden_DRAM[BASE_Addr+5], golden_DRAM[BASE_Addr+6], golden_DRAM[BASE_Addr+7]};
    golden_no_box  = 0;
    make_drink_cnt = 0;
	// $display("BOX 0");
    // get_box_info_task;
    // display_box_info;

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
		random_gap_task;
		// r_action.randomize();

		// golden_act  = r_action.action ;
        seq_generate;
        golden_err_msg  = No_Err;
        golden_complete = 1'b1;
		//Start giving inputs
		case(golden_act)
			Make_drink: begin
				// $display("                  Making drink                    ");
				make_drink_task;
			end
			Supply: begin
				// $display("                  Supply                    ");
				supply_task;
			end
			Check_Valid_Date: begin
				// $display("                  Checking valid date                    ");
				check_valid_date_task;
			end
		endcase
        update_dram_info_task;
		wait_outvalid_task;
        output_task;

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
    $display("======================================");
    $display("Make drink counter: %d",make_drink_cnt);
    $display("======================================");
	#(10);
    YOU_PASS_task;
    // $finish;
end

//================================================================
//  Sequence generator
//================================================================
task seq_generate;
begin
    // 3600
    // 2400 make drinks, with 8 types and 3 sizes picking randomly
    // 600,600,600 sequence AABBCCACB for make drink, supply and check dates
    // From pat count, generate the pattern
    if(patcount < 1800)
    begin
        case(patcount%9)
        0: golden_act = Make_drink;
        1: golden_act = Make_drink;
        2: golden_act = Supply;
        3: golden_act = Supply;
        4: golden_act = Check_Valid_Date;
        5: golden_act = Check_Valid_Date;
        6: golden_act = Make_drink;
        7: golden_act = Check_Valid_Date;
        8: golden_act = Supply;
        endcase
    end
    else
    begin
        golden_act = Make_drink;
    end
end
endtask

//================================================================
//  env task
//================================================================
task reset_task ; begin
	#(2.0);	inf.rst_n = 0 ;
	#(3.0);
	if (inf.out_valid!==0 || inf.err_msg!==0 || inf.complete !== 0)
    begin
		// fail;
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

task random_gap_task ; begin
	r_gap.randomize();
	for( i=0 ; i<r_gap.gap ; i++ )	@(negedge clk);
end endtask

task wait_outvalid_task; begin
	cycles = 0 ;
	while (inf.out_valid!==1)
    begin
		cycles = cycles + 1 ;
		if (cycles==1000) begin
			// fail;
            // Spec. 8
            // Your latency should be less than 1200 cycle for each operation.
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                SPEC 4 FAIL!                                                                ");
            $display ("                                             The execution latency is limited in 1000 cycles.                                               ");
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
	// $display("output_task");
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
            // $display("Checking make drink out data \n");
    		if ( (inf.complete!==golden_complete) || (inf.err_msg!==golden_err_msg))
            begin
				$display("-----------------------------------------------------------");
    	    	$display("                       FAIL Make drink                     ");
    	    	$display("    Golden complete : %6d    your complete : %6d ", golden_complete, inf.complete);
    			$display("    Golden err_msg  : %6d    your err_msg  : %6d ", golden_err_msg, inf.err_msg);
    			$display("-----------------------------------------------------------");
                $display("Expected box info: \n");
                display_box_info;
                display_current_golden_info;
                fail;
		        // #(100);
    			$finish;
    		end
    	end
		else if (golden_act == Supply)
        begin
            // $display("Checking Supply out data \n");
    		if ( (inf.complete!==golden_complete) || (inf.err_msg!==golden_err_msg))
            begin
				$display("-----------------------------------------------------------");
    	    	$display("                           FAIL Supply                     ");
    	    	$display("    Golden complete : %6d    your complete : %6d ", golden_complete, inf.complete);
    			$display("    Golden err_msg  : %6d    your err_msg  : %6d ", golden_err_msg, inf.err_msg);
    			$display("-----------------------------------------------------------");
                $display("Expected box info: \n");
                display_box_info;
                display_current_golden_info;
                fail;
		        // #(100);
    			$finish;
    		end
        end
        else if(golden_act == Check_Valid_Date)
        begin
            // $display("Checking Check valid date out data \n");
            if ( (inf.complete!==golden_complete) || (inf.err_msg!==golden_err_msg))
            begin
				$display("-----------------------------------------------------------");
    	    	$display("                           FAIL Check Valid date                     ");
    	    	$display("    Golden complete : %6d    your complete : %6d ", golden_complete, inf.complete);
    			$display("    Golden err_msg  : %6d    your err_msg  : %6d ", golden_err_msg, inf.err_msg);
    			$display("-----------------------------------------------------------");
                $display("Expected box info: \n");
                display_box_info;
                display_current_golden_info;
                fail;
		        // #(100);
    			$finish;
    		end
        end
	    @(negedge clk);
	    y = y + 1;
    end
end
endtask

//================================================================
//  get box info task
//================================================================
task display_box_info;
begin
    $display("=================================================================================================");
    $display("                                       Current dram box info                                                   ");
    $display("                          Box number:%d                                                            ",golden_no_box);
    $display("                          Black tea: hex =  %h, dec = %d", golden_box_info.black_tea,golden_box_info.black_tea);
    $display("                          Green tea: hex =  %h, dec = %d", golden_box_info.green_tea,golden_box_info.green_tea);
    $display("                          Milk: hex =  %h, dec = %d", golden_box_info.milk,golden_box_info.milk);
    $display("                          Pineapple Juice: hex =  %h, dec = %d", golden_box_info.pineapple_juice,golden_box_info.pineapple_juice);
    $display("                          Month: hex =  %h, dec = %d", golden_box_info.M,golden_box_info.M);
    $display("                          Day: hex =  %h, dec = %d", golden_box_info.D,golden_box_info.D);
    $display("=================================================================================================");
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

//================================================================
//  Display current golden info
//================================================================
task display_current_golden_info;
begin
    case(golden_act)
    Make_drink:
    begin
    $display("=================================================================================================");
    $display("                                       Current golden info                                                   ");
    $display("                          Box number:%d                                                            ",golden_no_box);
    $display("                          Type:  %s" , golden_type);
    $display("                          Size:  %s" , golden_size);
    $display("                          Month:  %d", golden_date.M);
    $display("                          Day:  %d"  , golden_date.D);
    $display("=================================================================================================");
    end
    Supply:
    begin
    $display("=================================================================================================");
    $display("                                       Current golden info                                                   ");
    $display("                          Box number:%d                                                            ",golden_no_box);
    $display("                          Black tea:        %d", golden_supply_black_tea);
    $display("                          Green tea:        %d", golden_supply_green_tea);
    $display("                          Milk:             %d", golden_supply_milk);
    $display("                          Pineapple juice:  %d", golden_supply_pineapple_juice);
    $display("                          Month:  %d", golden_date.M);
    $display("                          Day:  %d", golden_date.D);
    $display("=================================================================================================");
    end
    Check_Valid_Date:
    begin
    $display("=================================================================================================");
    $display("                                       Current golden info                                                   ");
    $display("                          Box number:%d                                                            ",golden_no_box);
    $display("                          Month:  %d", golden_date.M);
    $display("                          Day:  %d", golden_date.D);
    $display("=================================================================================================");
    end
    endcase
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
	inf.sel_action_valid = 1'b1;
    inf.D = golden_act;
    @(negedge clk);
    inf.sel_action_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    // Generate Types, 8 types
    inf.type_valid = 1'b1;
    r_bev_type.randomize();

    // Golden type selection 8 types
    // golden_type = r_bev_type.bev_type;

    case(make_drink_cnt%8)
    0:  golden_type = Black_Tea;
    1:  golden_type = Milk_Tea ;
    2:  golden_type = Extra_Milk_Tea;
    3:  golden_type = Green_Tea;
    4:  golden_type = Green_Milk_Tea;
    5:  golden_type = Pineapple_Juice;
    6:  golden_type = Super_Pineapple_Tea;
    7:  golden_type = Super_Pineapple_Milk_Tea ;
    endcase

    inf.D  = golden_type;
    @(negedge clk);
    inf.type_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

	// Generate Size, 3 sizes
    inf.size_valid = 1'b1;
    r_bev_size.randomize();
    // golden_size = r_bev_size.bev_size;

    case(make_drink_cnt%3)
    0: golden_size = L;
    1: golden_size = M;
    2: golden_size = S;
    endcase
    make_drink_cnt++;

    // Golden size selection, 3 sizes
    inf.D  = golden_size;
    @(negedge clk);
    inf.size_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

	// Give Today's Date
    inf.date_valid = 1'b1;
    r_date.randomize();
    golden_date.D = r_date.day;
    golden_date.M = r_date.month;

    inf.D  = {3'b0,golden_date.M,golden_date.D};
    @(negedge clk);
    inf.date_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

	// Box #No.
    inf.box_no_valid= 1'b1;
    r_box_num.randomize();
    golden_no_box = r_box_num.box_num;
    // golden_no_box = 7;
    inf.D  = golden_no_box;
    @(negedge clk);
    inf.box_no_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    // Generate golden signals for output check uses
    // Pull out data from the ingredient box

    get_box_info_task;
    golden_complete = 1'b1;
    golden_err_msg  = No_Err;

    // First check expieration date
    if((golden_box_info.M > golden_date.M) || ((golden_box_info.M == golden_date.M) && (golden_box_info.D >= golden_date.D)))
    begin
        // Then determine the drink I want to make
        case(golden_type)
        Black_Tea:begin // Black tea 1
            temp_black_tea = golden_box_info.black_tea;
            // Determine the size
            case(golden_size)
            S:begin
                temp_black_tea -= S_size;
            end
            M:begin
                temp_black_tea -= M_size;
            end
            L:begin
                temp_black_tea -= L_size;
            end
            default:begin
               $display("Size error!");
            end
            endcase

            if(temp_black_tea < 0)
            begin
               $display("Not enough ingredient for making Black Tea!");
               golden_err_msg  = No_Ing;
               golden_complete = 1'b0;
            end
            else
            begin
                // Update the golden box info
                golden_box_info.black_tea = temp_black_tea;
            end
        end
        Milk_Tea:begin // Black tea 3, Milk 1
            temp_black_tea = golden_box_info.black_tea;
            temp_milk      = golden_box_info.milk;
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
               $display("Size error!");
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
               $display("Size error!");
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
               $display("Size error!");
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
               $display("Size error!");
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
               $display("Size error!");
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
               $display("Size error!");
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
               $display("Size error!");
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
                golden_box_info.milk                 = temp_milk;
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
        // $display("Ingredient Expired");
        golden_err_msg  = No_Exp;
        golden_complete = 1'b0;
    end
    // $display("Expected value writing back to DRAM\n");
    // update_dram_info_task;
    // display_box_info;
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
	inf.sel_action_valid = 1'b1;
    inf.D = golden_act;
    @(negedge clk);
    inf.sel_action_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    // Giving date
	inf.date_valid = 1'b1;
    r_date.randomize();
    golden_date.D = r_date.day;
    golden_date.M = r_date.month;
    inf.D  = {3'b0,golden_date.M,golden_date.D};
    @(negedge clk);
    inf.date_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    // Giving box #no.
	inf.box_no_valid = 1'b1;
    r_box_num.randomize();
    golden_no_box = r_box_num.box_num;
    // golden_no_box = 7;
    inf.D  = golden_no_box;
    @(negedge clk);
    inf.box_no_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    //Black Tea
	inf.box_sup_valid = 1'b1;
    r_supply_amt.randomize();
    golden_supply_black_tea = r_supply_amt.supply_amt;
    inf.D  = golden_supply_black_tea;
    @(negedge clk);
    inf.box_sup_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    //Green Tea
	inf.box_sup_valid = 1'b1;
    r_supply_amt.randomize();
    golden_supply_green_tea = r_supply_amt.supply_amt;
    inf.D  = golden_supply_green_tea;
    @(negedge clk);
    inf.box_sup_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    //Milk
	inf.box_sup_valid = 1'b1;
    r_supply_amt.randomize();
    golden_supply_milk = r_supply_amt.supply_amt;
    inf.D  = golden_supply_milk;
    @(negedge clk);
    inf.box_sup_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    //Pineapple juice
	inf.box_sup_valid = 1'b1;
    r_supply_amt.randomize();
    golden_supply_pineapple_juice = r_supply_amt.supply_amt;
    inf.D  = golden_supply_pineapple_juice;
    @(negedge clk);
    inf.box_sup_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    // $display("Supplying\n");
    // $display("Golden info for current ops");
    // display_current_golden_info;
    // Get dram value
    // Generate golden signals for output check uses
    // Pull out data from the ingredient box

    get_box_info_task;
    // $display("Box info before");
    // display_box_info;
    // display_box_info;

    // Perform opeartion according to these ingredients.
    golden_complete = 1'b1;

    // Generate golden result
    temp_black_tea       = golden_box_info.black_tea;
    temp_green_tea       = golden_box_info.green_tea;
    temp_milk            = golden_box_info.milk;
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

    if(temp_black_tea>4095) golden_box_info.black_tea = 4095; else golden_box_info.black_tea = temp_black_tea;

    if(temp_green_tea>4095) golden_box_info.green_tea = 4095; else golden_box_info.green_tea = temp_green_tea;

    if(temp_milk>4095)      golden_box_info.milk = 4095; else golden_box_info.milk = temp_milk;

    if(temp_pineapple_juice>4095) golden_box_info.pineapple_juice = 4095; else golden_box_info.pineapple_juice = temp_pineapple_juice;

    // The date must also gets updated when supplying
    golden_box_info.M = golden_date.M;
    golden_box_info.D = golden_date.D;
end
endtask

//================================================================
//  Check valid date
//================================================================
task check_valid_date_task;
begin
    // Generate Input actions
	inf.sel_action_valid = 1'b1;
    inf.D = {10'b0,golden_act};
    @(negedge clk);
    inf.sel_action_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    // Give Today's Date
    inf.date_valid = 1'b1;
    r_date.randomize();
    golden_date.D = r_date.day;
    golden_date.M = r_date.month;

    inf.D  = {3'b0,golden_date.M,golden_date.D};
    @(negedge clk);
    inf.date_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    // Box #No.
    inf.box_no_valid= 1'b1;
    r_box_num.randomize();
    golden_no_box = r_box_num.box_num;
    // golden_no_box = 7;
    inf.D  = golden_no_box;
    @(negedge clk);
    inf.box_no_valid = 1'b0;
    inf.D = 'bx;
    delay_task;

    // Golden signals for output check uses
    // Pull out data from the ingredient box
    get_box_info_task;
    // display_box_info;
    // Perform opeartion according to these ingredients.
    golden_complete = 1'b1;

    // display_current_golden_info;

    // Start checking dates
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

task YOU_PASS_task;begin
$display ("----------------------------------------------------------------------------------------------------------------------");
$display ("                                                  Congratulations!                                                    ");
$display ("                                           You have passed all patterns!                                              ");
$display ("                                                                                                                      ");
$display ("                                        Your execution cycles   = %5d cycles                                          ", total_cycles);
$display ("                                        Your clock period       = %.1f ns                                             ", `CYCLE_TIME);
$display ("                                        Total latency           = %.1f ns                                             ", total_cycles*`CYCLE_TIME );
$display ("----------------------------------------------------------------------------------------------------------------------");
$finish;
end endtask

task fail; begin
$display("====================================================================================");
$display("                                      Wrong Answer                                  ");
$display("====================================================================================");
end endtask

endprogram
