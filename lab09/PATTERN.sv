`include "Usertype_BEV.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
//  integer & parameter
//================================================================
//
integer cycles;
integer cycles_sum;
integer z;
integer patcnt;
integer j;
//
integer SEED = 67 ;
parameter PATNUM = 3600 ;
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter BASE_Addr = 65536 ;
// parameter BASE_End = 65536 + 255*8 ;

//================================================================
//  logic
//================================================================
logic [7:0] golden_DRAM[(BASE_Addr+0):((BASE_Addr+256*8)-1)];
// operation info.
// Data data_g;
Action     act_g;
Bev_Type   type_g;
Bev_Size   size_g;
int        no_box_g;
Date       date_g;
Bev_Bal    bev_bal_g;
Data       data_g;
Order_Info order_inf_g;

// Dram info
Bev_Bal   box_info_g;

// golden outputs
logic complete_g;
Error_Msg err_msg_g;
logic [31:0] out_info_g;
//================================================================
//  RANDOM INSTANTIATION
//================================================================
//=========================
//  Delay class
//=========================
class delay_random; // Delays for input valid signals
	rand int delay;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit { delay inside {[0:3]}; }
endclass
delay_random r_delay = new(SEED) ;
//=========================
//  Gap class
//=========================
class gap_random;
	rand int gap;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit { gap inside {[1:3]}; }
endclass
gap_random        r_gap        = new(SEED);
//=========================
//  Bev type class
//=========================
class bev_type_random;
	rand Bev_Type bev_type;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit {bev_type inside {Black_Tea,Milk_Tea,Extra_Milk_Tea,
    Green_Tea,Green_Milk_Tea,Pineapple_Juice,
    Super_Pineapple_Tea,Super_Pineapple_Milk_Tea};}
endclass
bev_type_random r_bev_type = new(SEED) ;
//=========================
//  Bev size class
//=========================
class bev_size_random;
	rand Bev_Size bev_size;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit { bev_size inside {L,M,S}; }
endclass
bev_size_random r_bev_size = new(SEED) ;
//=========================
//    Action random
//=========================
class action_random;
	rand Action action;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit { action inside {Make_drink, Supply, Check_Valid_Date}; }
endclass
action_random   r_action   = new(SEED) ;
//=========================
//      Box random
//=========================
class rand_box_num;
    rand int box_num;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit { box_num inside {[0:255]}; }
endclass
rand_box_num  r_box_num  = new(SEED) ;
//=========================
//   Supply amt random
//=========================
class rand_supply_amt;
    rand int supply_amt;
	function new (int seed);
		this.srandom(seed);
	endfunction
	constraint limit { supply_amt inside {[0:4095]}; }
endclass
rand_supply_amt r_supply_amt = new(SEED);
//=========================
//  Date random
//=========================
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
rand_date     r_date     = new(SEED) ;


int make_drink_cnt;

//================================================================
//  initial
//================================================================
initial begin
	// read in initial DRAM data
	$readmemh(DRAM_p_r, golden_DRAM);
	inf.rst_n = 1'b1 ;
	// initial deposit value
	// current_box = { golden_DRAM[BASE_Addr+0], golden_DRAM[BASE_Addr+1], golden_DRAM[BASE_Addr+2], golden_DRAM[BASE_Addr+3],
    // golden_DRAM[BASE_Addr+4], golden_DRAM[BASE_Addr+5], golden_DRAM[BASE_Addr+6], golden_DRAM[BASE_Addr+7]};
    no_box_g  = 0;
    make_drink_cnt = 0;
	// $display("BOX 0");
    // get_box_info_task;
    // display_box_info;

	// reset output signals
    inf.D = 'bx;
	inf.box_no_valid = 1'b0 ;
	inf.sel_action_valid = 1'b0 ;

	// reset
	cycles_sum = 0 ;
	inf.size_valid = 1'b0 ;

    // Reseting
    #(1.0);	inf.rst_n = 0 ;
	#(`CYCLE_TIME*5);
	if (inf.out_valid!==0 || inf.err_msg!==0 || inf.complete !== 0)
    begin
        $display ("                                                                SPEC 3 FAIL!                                                                ");
        #(100);
        $finish;
	end
	#(1.0);	inf.rst_n = 1 ;


	inf.type_valid = 1'b0 ;
	inf.box_sup_valid = 1'b0 ;
	inf.date_valid = 1'b0 ;
	//
	@(negedge clk);

	for( patcnt=0 ; patcnt<PATNUM ; patcnt+=1 ) begin
		random_gap_task;
		// r_action.randomize();

		// act_g  = r_action.action ;
        seq_generate;
        err_msg_g  = No_Err;
        complete_g = 1'b1;
		//Start giving inputs
		case(act_g)
			Make_drink:
            begin
				make_drink_task;
			end
			Supply:
            begin
				supply_task;
			end
			Check_Valid_Date:
            begin
				valid_date_check_task;
			end
		endcase
        update_dram_info_task;
		wait_outvalid_task;
        output_task;

        $display("PASS PATTERN NO.%4d", patcnt+1);
	end
    // $display("======================================");
    // $display("Make drink counter: %d",make_drink_cnt);
    // $display("======================================");
	// #(10);
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
    if(patcnt < 1800)
    begin
        case(patcnt%9)
        0: act_g = Make_drink;
        1: act_g = Make_drink;
        2: act_g = Supply;
        3: act_g = Supply;
        4: act_g = Check_Valid_Date;
        5: act_g = Check_Valid_Date;
        6: act_g = Make_drink;
        7: act_g = Check_Valid_Date;
        8: act_g = Supply;
        endcase
    end
    else
    begin
        act_g = Make_drink;
    end
end
endtask

//================================================================
//  resets and wait out valid
//================================================================
task wait_outvalid_task;
begin
	cycles = 0 ;
	while (inf.out_valid!==1)
    begin
		cycles = cycles + 1 ;
		if (cycles==1000)
        begin
            $display ("============================================================================================================================");
            $display ("                                                                SPEC 4 FAIL!                                                ");
            $display ("============================================================================================================================");
        	#(100);
            $finish;
		end
		@(negedge clk);
	end
	cycles_sum = cycles_sum + cycles ;
end
endtask


//================================================================
//  output task
//================================================================
task output_task; begin
	// $display("output_task");
	z = 0;
	while (inf.out_valid===1)
    begin
		if (z >= 1)
        begin
			$display ("--------------------------------------------------");
			$display ("                        FAIL                      ");
			$display ("          Outvalid is more than 1 cycles          ");
			$display ("--------------------------------------------------");
	        #(100);
			$finish;
		end
		else if (act_g==Make_drink)
        begin
            // $display("Checking make drink out data \n");
    		if ( (inf.complete!==complete_g) || (inf.err_msg!==err_msg_g))
            begin
				$display("-----------------------------------------------------------");
    	    	$display("                       FAIL Make drink                     ");
    	    	$display("    Golden complete : %6d    your complete : %6d ", complete_g, inf.complete);
    			$display("    Golden err_msg  : %6d    your err_msg  : %6d ", err_msg_g, inf.err_msg);
    			$display("-----------------------------------------------------------");
                $display("Expected box info: \n");
                display_box_info;
                display_current_golden_info;
                fail;
		        // #(100);
    			$finish;
    		end
    	end
		else if (act_g == Supply)
        begin
            // $display("Checking Supply out data \n");
    		if ( (inf.complete!==complete_g) || (inf.err_msg!==err_msg_g))
            begin
				$display("-----------------------------------------------------------");
    	    	$display("                           FAIL Supply                     ");
    	    	$display("    Golden complete : %6d    your complete : %6d ", complete_g, inf.complete);
    			$display("    Golden err_msg  : %6d    your err_msg  : %6d ", err_msg_g, inf.err_msg);
    			$display("-----------------------------------------------------------");
                $display("Expected box info: \n");
                display_box_info;
                display_current_golden_info;
                fail;
		        // #(100);
    			$finish;
    		end
        end
        else if(act_g == Check_Valid_Date)
        begin
            // $display("Checking Check valid date out data \n");
            if ( (inf.complete!==complete_g) || (inf.err_msg!==err_msg_g))
            begin
				$display("-----------------------------------------------------------");
    	    	$display("                           FAIL Check Valid date                     ");
    	    	$display("    Golden complete : %6d    your complete : %6d ", complete_g, inf.complete);
    			$display("    Golden err_msg  : %6d    your err_msg  : %6d ", err_msg_g, inf.err_msg);
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
	    z = z + 1;
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
    $display("                          Box number:%d                                                            ",no_box_g);
    $display("                          Black tea: hex =  %h, dec = %d", box_info_g.black_tea,box_info_g.black_tea);
    $display("                          Green tea: hex =  %h, dec = %d", box_info_g.green_tea,box_info_g.green_tea);
    $display("                          Milk: hex =  %h, dec = %d", box_info_g.milk,box_info_g.milk);
    $display("                          Pineapple Juice: hex =  %h, dec = %d", box_info_g.pineapple_juice,box_info_g.pineapple_juice);
    $display("                          Month: hex =  %h, dec = %d", box_info_g.M,box_info_g.M);
    $display("                          Day: hex =  %h, dec = %d", box_info_g.D,box_info_g.D);
    $display("=================================================================================================");
end
endtask


task get_box_info_task;
begin
    box_info_g.black_tea       = {golden_DRAM[BASE_Addr+no_box_g*8 + 7],golden_DRAM[BASE_Addr+no_box_g*8 + 6][7:4]};
	box_info_g.green_tea       = {golden_DRAM[BASE_Addr+no_box_g*8 + 6][3:0],golden_DRAM[BASE_Addr+no_box_g*8 + 5]};
	box_info_g.M               = golden_DRAM[BASE_Addr+no_box_g*8 + 4];
	box_info_g.milk            =  {golden_DRAM[BASE_Addr+no_box_g*8 + 3],golden_DRAM[BASE_Addr+no_box_g*8 + 2][7:4]};
	box_info_g.pineapple_juice =  {golden_DRAM[BASE_Addr+no_box_g*8 + 2][3:0],golden_DRAM[BASE_Addr+no_box_g*8 + 1]};
	box_info_g.D               =  golden_DRAM[BASE_Addr+no_box_g*8 + 0];
end
endtask

//================================================================
//  Display current golden info
//================================================================
task display_current_golden_info;
begin
    case(act_g)
    Make_drink:
    begin
    $display("=================================================================================================");
    $display("                                       Current golden info                                                   ");
    $display("                          Box number:%d                                                            ",no_box_g);
    $display("                          Type:  %s" , type_g);
    $display("                          Size:  %s" , size_g);
    $display("                          Month:  %d", date_g.M);
    $display("                          Day:  %d"  , date_g.D);
    $display("=================================================================================================");
    end
    Supply:
    begin
    $display("=================================================================================================");
    $display("                                       Current golden info                                                   ");
    $display("                          Box number:%d                                                            ",no_box_g);
    $display("                          Black tea:        %d", black_tea_sup_g);
    $display("                          Green tea:        %d", green_tea_sup_g);
    $display("                          Milk:             %d", milk_sup_g);
    $display("                          Pineapple juice:  %d", pineapple_juice_sup_g);
    $display("                          Month:  %d", date_g.M);
    $display("                          Day:  %d", date_g.D);
    $display("=================================================================================================");
    end
    Check_Valid_Date:
    begin
    $display("=================================================================================================");
    $display("                                       Current golden info                                                   ");
    $display("                          Box number:%d                                                            ",no_box_g);
    $display("                          Month:  %d", date_g.M);
    $display("                          Day:  %d", date_g.D);
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
    inf.D = act_g;
    @(negedge clk);
    inf.sel_action_valid = 1'b0;
    inf.D = 'bx;
    task_delaying;

    // Generate Types, 8 types
    inf.type_valid = 1'b1;
    r_bev_type.randomize();

    // Golden type selection 8 types
    // type_g = r_bev_type.bev_type;

    case(make_drink_cnt%8)
    0:  type_g = Black_Tea;
    1:  type_g = Milk_Tea ;
    2:  type_g = Extra_Milk_Tea;
    3:  type_g = Green_Tea;
    4:  type_g = Green_Milk_Tea;
    5:  type_g = Pineapple_Juice;
    6:  type_g = Super_Pineapple_Tea;
    7:  type_g = Super_Pineapple_Milk_Tea ;
    endcase

    inf.D  = type_g;
    @(negedge clk);
    inf.type_valid = 1'b0;
    inf.D = 'bx;
    task_delaying;

	// Generate Size, 3 sizes
    inf.size_valid = 1'b1;
    r_bev_size.randomize();
    // size_g = r_bev_size.bev_size;

    case(make_drink_cnt%3)
    0: size_g = L;
    1: size_g = M;
    2: size_g = S;
    endcase
    make_drink_cnt++;

    // Golden size selection, 3 sizes
    inf.D  = size_g;
    @(negedge clk);
    inf.size_valid = 1'b0;
    inf.D = 'bx;
    task_delaying;

	// Give Today's Date
    inf.date_valid = 1'b1;
    r_date.randomize();
    date_g.D = r_date.day;
    date_g.M = r_date.month;

    inf.D  = {3'b0,date_g.M,date_g.D};
    @(negedge clk);
    inf.date_valid = 1'b0;
    inf.D = 'bx;
    task_delaying;

	// Box #No.
    inf.box_no_valid= 1'b1;
    r_box_num.randomize();
    no_box_g = r_box_num.box_num;
    // no_box_g = 7;
    inf.D  = no_box_g;
    @(negedge clk);
    inf.box_no_valid = 1'b0;
    inf.D = 'bx;
    task_delaying;

    // Generate golden signals for output check uses
    // Pull out data from the ingredient box

    get_box_info_task;
    complete_g = 1'b1;
    err_msg_g  = No_Err;

    // First check expieration date
    if((box_info_g.M > date_g.M) || ((box_info_g.M == date_g.M) && (box_info_g.D >= date_g.D)))
    begin
        // Then determine the drink I want to make
        case(type_g)
        Black_Tea:begin // Black tea 1
            temp_black_tea = box_info_g.black_tea;
            // Determine the size
            case(size_g)
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
               err_msg_g  = No_Ing;
               complete_g = 1'b0;
            end
            else
            begin
                // Update the golden box info
                box_info_g.black_tea = temp_black_tea;
            end
        end
        Milk_Tea:begin // Black tea 3, Milk 1
            temp_black_tea = box_info_g.black_tea;
            temp_milk      = box_info_g.milk;
            // Determine the size
            case(size_g)
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
               err_msg_g  = No_Ing;
               complete_g = 1'b0;
            end
            else // Update the golden box info
            begin
                box_info_g.black_tea = temp_black_tea;
                box_info_g.milk      = temp_milk;
            end
        end
        Extra_Milk_Tea:begin
            temp_black_tea = box_info_g.black_tea;
            temp_milk      = box_info_g.milk;
            // Determine the size
            case(size_g)
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
               err_msg_g  = No_Ing;
               complete_g = 1'b0;
            end
            else // Update the golden box info
            begin
                box_info_g.black_tea = temp_black_tea;
                box_info_g.milk      = temp_milk;
            end
        end
        Green_Tea:begin
            temp_green_tea = box_info_g.green_tea;
            // Determine the size
            case(size_g)
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
               err_msg_g  = No_Ing;
               complete_g = 1'b0;
            end
            else // Update the golden box info
            begin
                box_info_g.green_tea = temp_green_tea;
            end
        end
        Green_Milk_Tea:begin
            temp_green_tea = box_info_g.green_tea;
            temp_milk      = box_info_g.milk;
            // Determine the size
            case(size_g)
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
               err_msg_g  = No_Ing;
               complete_g = 1'b0;
            end
            else // Update the golden box info
            begin
                box_info_g.green_tea = temp_green_tea;
                box_info_g.milk      = temp_milk;
            end
        end
        Pineapple_Juice:begin
            temp_pineapple_juice = box_info_g.pineapple_juice;
            // Determine the size
            case(size_g)
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
               err_msg_g  = No_Ing;
               complete_g = 1'b0;
            end
            else // Update the golden box info
            begin
                box_info_g.pineapple_juice = temp_pineapple_juice;
            end
        end
        Super_Pineapple_Tea:
        begin
            temp_black_tea       = box_info_g.black_tea;
            temp_pineapple_juice = box_info_g.pineapple_juice;
            // Determine the size
            case(size_g)
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
               err_msg_g  = No_Ing;
               complete_g = 1'b0;
            end
            else // Update the golden box info
            begin
                box_info_g.pineapple_juice = temp_pineapple_juice;
                box_info_g.black_tea            = temp_black_tea;
            end
        end
        Super_Pineapple_Milk_Tea:
        begin
            temp_black_tea       = box_info_g.black_tea;
            temp_pineapple_juice = box_info_g.pineapple_juice;
            temp_milk            = box_info_g.milk;
            // Determine the size
            case(size_g)
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
               err_msg_g  = No_Ing;
               complete_g = 1'b0;
            end
            else // Enough to make drink update the golden box info
            begin
                box_info_g.pineapple_juice      = temp_pineapple_juice;
                box_info_g.black_tea            = temp_black_tea;
                box_info_g.milk                 = temp_milk;
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
        err_msg_g  = No_Exp;
        complete_g = 1'b0;
    end
    // $display("Expected value writing back to DRAM\n");
    // update_dram_info_task;
    // display_box_info;
end
endtask
//================================================================
//  Supply
//================================================================
int black_tea_sup_g;
int green_tea_sup_g;
int milk_sup_g;
int pineapple_juice_sup_g;

task supply_task;
begin
    // Generate Input actions
	inf.sel_action_valid = 1'b1;
    inf.D = act_g;
    @(negedge clk);
    inf.sel_action_valid = 1'b0;
    inf.D = 'bx;
    task_delaying;

    // Giving date
	inf.date_valid = 1'b1;
    r_date.randomize();
    r_date.randomize();
    date_g.D = r_date.day;
    date_g.M = r_date.month;
    inf.D  = {3'b0,date_g.M,date_g.D};
    @(negedge clk);
    inf.date_valid = 1'b0;
    inf.D = 'bx;
    task_delaying;
    r_box_num.randomize();
    r_box_num.randomize();

    // Giving box #no.
	inf.box_no_valid = 1'b1;
    no_box_g = r_box_num.box_num;
    inf.D  = no_box_g;
    @(negedge clk);
    inf.box_no_valid = 1'b0;
    inf.D = 'bx;
    task_delaying;
    r_supply_amt.randomize();
    r_supply_amt.randomize();

    //Black Tea
	inf.box_sup_valid = 1'b1;
    black_tea_sup_g = r_supply_amt.supply_amt;
    inf.D  = black_tea_sup_g;
    @(negedge clk);
    inf.box_sup_valid = 1'b0;
    inf.D = 'bx;
    task_delaying;
    r_supply_amt.randomize();
    r_supply_amt.randomize();

    //Green Tea
	inf.box_sup_valid = 1'b1;
    green_tea_sup_g = r_supply_amt.supply_amt;
    inf.D  = green_tea_sup_g;
    @(negedge clk);
    inf.box_sup_valid = 1'b0;
    inf.D = 'bx;
    task_delaying;

    //Milk
	inf.box_sup_valid = 1'b1;
    r_supply_amt.randomize();
    r_supply_amt.randomize();
    milk_sup_g = r_supply_amt.supply_amt;
    inf.D  = milk_sup_g;
    @(negedge clk);
    inf.box_sup_valid = 1'b0;
    inf.D = 'bx;
    task_delaying;
    r_supply_amt.randomize();
    r_supply_amt.randomize();

    //Pineapple juice
	inf.box_sup_valid = 1'b1;
    pineapple_juice_sup_g = r_supply_amt.supply_amt;
    inf.D  = pineapple_juice_sup_g;
    @(negedge clk);
    inf.box_sup_valid = 1'b0;
    inf.D = 'bx;
    task_delaying;

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
    complete_g = 1'b1;

    // Generate golden result
    temp_black_tea       = box_info_g.black_tea;
    temp_green_tea       = box_info_g.green_tea;
    temp_milk            = box_info_g.milk;
    temp_pineapple_juice = box_info_g.pineapple_juice;

    // Add the supplies
    temp_black_tea += black_tea_sup_g;
    temp_green_tea += green_tea_sup_g;
    temp_milk      += milk_sup_g;
    temp_pineapple_juice += pineapple_juice_sup_g;

    if(temp_black_tea > 4095 || temp_green_tea > 4095 || temp_milk > 4095 || temp_pineapple_juice > 4095)
    begin
        err_msg_g  = Ing_OF;
        complete_g = 1'b0;
    end
    else
    begin
        err_msg_g  = No_Err;
        complete_g = 1'b1;
    end

    if(temp_black_tea>4095) box_info_g.black_tea = 4095; else box_info_g.black_tea = temp_black_tea;

    if(temp_green_tea>4095) box_info_g.green_tea = 4095; else box_info_g.green_tea = temp_green_tea;

    if(temp_milk>4095)      box_info_g.milk = 4095; else box_info_g.milk = temp_milk;

    if(temp_pineapple_juice>4095) box_info_g.pineapple_juice = 4095; else box_info_g.pineapple_juice = temp_pineapple_juice;

    // The date must also gets updated when supplying
    box_info_g.M = date_g.M;
    box_info_g.D = date_g.D;
end
endtask


task task_delaying ;
begin
	r_delay.randomize();
	for( j=0 ; j<r_delay.delay ; j++ )
    begin
        @(negedge clk);
    end
end
endtask
//================================================================
//  Check valid date
//================================================================
task valid_date_check_task;
begin
    r_date.randomize();
    date_g.D = r_date.day;
    date_g.M = r_date.month;

    // Generate Input actions
	inf.sel_action_valid = 1'b1;
    inf.D = {10'b0,act_g};
    @(negedge clk);
    inf.sel_action_valid = 1'b0;
    inf.D = 'bx;
    task_delaying;

    // Give Today's Date
    inf.date_valid = 1'b1;


    inf.D  = {3'b0,date_g.M,date_g.D};
    @(negedge clk);
    inf.date_valid = 1'b0;
    inf.D = 'bx;
    task_delaying;

    // Box #No.
    inf.box_no_valid= 1'b1;
    r_box_num.randomize();
    no_box_g = r_box_num.box_num;
    // no_box_g = 7;
    inf.D  = no_box_g;
    @(negedge clk);
    inf.box_no_valid = 1'b0;
    inf.D = 'bx;
    task_delaying;

    // Golden signals for output check uses
    // Pull out data from the ingredient box
    get_box_info_task;
    // display_box_info;
    // Perform opeartion according to these ingredients.
    complete_g = 1'b1;


    // Start checking dates
    if((box_info_g.M > date_g.M) ||(box_info_g.M == date_g.M && box_info_g.D >= date_g.D))
    begin
        complete_g = 1'b1;
        err_msg_g  = No_Err;
    end
    else
    begin
        complete_g = 1'b0;
        err_msg_g  = No_Exp;
    end
end
endtask



task update_dram_info_task;
begin
    golden_DRAM[BASE_Addr+no_box_g*8 + 7]      = box_info_g.black_tea[11:4];
    golden_DRAM[BASE_Addr+no_box_g*8 + 6][7:4] = box_info_g.black_tea[3:0];
	golden_DRAM[BASE_Addr+no_box_g*8 + 6][3:0] = box_info_g.green_tea[11:8];
    golden_DRAM[BASE_Addr+no_box_g*8 + 5]      = box_info_g.green_tea[7:0];
    golden_DRAM[BASE_Addr+no_box_g*8 + 4]      = box_info_g.M;
    golden_DRAM[BASE_Addr+no_box_g*8 + 3]      = box_info_g.milk[11:4];
    golden_DRAM[BASE_Addr+no_box_g*8 + 2][7:4] = box_info_g.milk[3:0];
    golden_DRAM[BASE_Addr+no_box_g*8 + 2][3:0] = box_info_g.pineapple_juice[11:8];
    golden_DRAM[BASE_Addr+no_box_g*8 + 1]      = box_info_g.pineapple_juice[7:0];
    golden_DRAM[BASE_Addr+no_box_g*8 + 0]      = box_info_g.D;
end
endtask

task YOU_PASS_task;begin
$display ("----------------------------------------------------------------------------------------------------------------------");
$display ("                                                  Congratulations                                                     ");
$display ("                                           You have passed all patterns!                                              ");
$display ("                                                                                                                      ");
$display ("                                        Your execution cycles   = %5d cycles                                          ", cycles_sum);
$display ("                                        Your clock period       = %.1f ns                                             ", `CYCLE_TIME);
$display ("                                        Total latency           = %.1f ns                                             ", cycles_sum*`CYCLE_TIME );
$display ("----------------------------------------------------------------------------------------------------------------------");
$finish;
end endtask

task fail; begin
$display("====================================================================================");
$display("                                      Wrong Answer                                  ");
$display("====================================================================================");
end endtask


task random_gap_task ;
begin
	r_gap.randomize();
	for( j=0 ; j<r_gap.gap ; j++ )
    begin
        @(negedge clk);
    end
end
endtask

endprogram
