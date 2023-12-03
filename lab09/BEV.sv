module BEV(input clk, INF.BEV_inf inf);
import usertype::*;
// This file contains the definition of several state machines used in the BEV (Beverage) System RTL design.
// The state machines are defined using SystemVerilog enumerated types.
// The state machines are:
// - state_t: used to represent the overall state of the BEV system

// Each enumerated type defines a set of named states that the corresponding process can be in.
typedef enum logic [11:0]{
    IDLE = 12'b0000_0000_0001,
    MAKE_DRINK_TYPE = 12'b0000_0000_0010,
    MAKE_DRINK_SIZE = 12'b0000_0000_0100,
    RD_DATES = 12'b0000_0000_1000,
    RD_BOX_NO = 12'b0000_0001_0000,
    GET_SUPPLIES = 12'b0000_0010_0000,
    WAIT_WB_BRIDGE = 12'b0000_0100_0000,
    RD_DRAM = 12'b0000_1000_0000,
    MAKE_DRINK = 12'b0001_0000_0000,
    SUPPLY = 12'b0010_0000_0000,
    CHECK_DATE = 12'b0100_0000_0000,
    WB_DRAM = 12'b1000_0000_0000
} state_t;
parameter BASE_Addr = 65536 ;

// REGISTERS
state_t state, nstate;

wire st_IDLE = state[0];
wire st_MAKE_DRINK_TYPE = state[1];
wire st_MAKE_DRINK_SIZE = state[2];
wire st_RD_DATES = state[3];
wire st_RD_BOX_NO = state[4];
wire st_GET_SUPPLIES = state[5];
wire st_WAIT_WB_BRIDGE = state[6];
wire st_RD_DRAM = state[7];
wire st_MAKE_DRINK = state[8];
wire st_SUPPLY = state[9];
wire st_CHECK_DATE = state[10];
wire st_WB_DRAM = state[11];

Action      cur_act;
Error_Msg   err_result;
Error_Msg   err_result_ff;
Bev_Type    bev_type_ff;
Bev_Size    bev_size_ff;
Date        date_ff;
Bev_Bal     bev_barrel_ff;
Bev_dram_in dram_data_ff;
Bev_dram_in dram_result_wr;

logic[7:0] box_no_ff;
logic[11:0] black_tea_amt_ff,green_tea_amt_ff,milk_amt_ff,pineapple_juice_amt_ff;

logic complete_ff,complete_wr;
logic[1:0] cnt;

logic make_drink_f  ;
assign make_drink_f = cur_act == Make_drink;
logic supply_f      ;
assign supply_f     = cur_act == Supply;
logic check_valid_f ;
assign check_valid_f = cur_act == Check_Valid_Date;

logic supply_received_f ;
assign supply_received_f = cnt == 3 && inf.box_sup_valid;
logic make_drink_err_f  ;
assign make_drink_err_f = err_result == No_Exp || err_result == No_Ing;
logic supply_err_f     ;
assign supply_err_f  = err_result == Ing_OF;

logic check_date_err_f ;
assign check_date_err_f  = err_result == No_Exp;

logic wb_busy_flag_ff;
logic rd_busy_flag_ff;

// STATE MACHINE
always_ff @( posedge clk or negedge inf.rst_n) begin : TOP_FSM_SEQ
    if (!inf.rst_n) state <= IDLE;
    else state <= nstate;
end

always_comb
begin
    nstate = state;
    case(state)
        IDLE:
        begin
            if(inf.sel_action_valid)
            begin
                if(inf.D.d_act == Make_drink)
                    nstate = MAKE_DRINK_TYPE;
                else if(inf.D.d_act == Supply || inf.D.d_act == Check_Valid_Date)
                    nstate = RD_DATES;
                else
                    nstate = IDLE;
            end
        end
        MAKE_DRINK_TYPE:
        begin
            nstate = inf.type_valid ? MAKE_DRINK_SIZE : MAKE_DRINK_TYPE;
        end
        MAKE_DRINK_SIZE:
        begin
            nstate = inf.size_valid ? RD_DATES : MAKE_DRINK_SIZE;
        end
        RD_DATES:
        begin
            nstate = inf.date_valid ? RD_BOX_NO : RD_DATES;
        end
        RD_BOX_NO:
        begin
            if(inf.box_no_valid)
            begin
                if(make_drink_f || check_valid_f)
                    nstate = WAIT_WB_BRIDGE;
                else if(supply_f)
                    nstate = GET_SUPPLIES;
            end
        end
        GET_SUPPLIES:
        begin
            nstate = supply_received_f ? WAIT_WB_BRIDGE : GET_SUPPLIES;
        end
        WAIT_WB_BRIDGE:
        begin
            nstate = wb_busy_flag_ff ? WAIT_WB_BRIDGE : RD_DRAM;
        end
        RD_DRAM:
        begin
            if(inf.C_out_valid||~rd_busy_flag_ff)
            begin
                if(make_drink_f)
                    nstate = MAKE_DRINK;
                else if(check_valid_f)
                    nstate = CHECK_DATE;
                else
                    nstate = SUPPLY;
            end
            else
            begin
                nstate = RD_DRAM;
            end
        end
        MAKE_DRINK:
        begin
            nstate = make_drink_err_f ? IDLE : WB_DRAM;
        end
        CHECK_DATE:
        begin
            nstate = IDLE;
        end
        SUPPLY:
        begin
            nstate = WB_DRAM;
        end
        WB_DRAM:
        begin
            nstate = IDLE;
        end
        default: nstate = IDLE;
    endcase
end

always_ff @( posedge clk or negedge inf.rst_n )
begin
    if(~inf.rst_n)
    begin
        cnt <= 0;
    end
    else if(st_GET_SUPPLIES)
    begin
        if(supply_received_f)
            cnt <= cnt;
        else if(inf.box_sup_valid)
            cnt <= cnt + 1;
    end
    else if(st_IDLE)
    begin
        cnt <= 0;
    end
end

logic rd_enable_f;
assign rd_enable_f = (st_WAIT_WB_BRIDGE || st_GET_SUPPLIES) && ~wb_busy_flag_ff;

// Datapath, rewrite this seperately and remove rst_n
always_ff @( posedge clk)
begin
    if(inf.sel_action_valid && st_IDLE)
    begin
        cur_act <= inf.D.d_act;
    end
end
always_ff @( posedge clk )
begin
    if(inf.type_valid && st_MAKE_DRINK_TYPE) bev_type_ff <= inf.D.d_type;
end
always_ff @( posedge clk )
begin
   if(inf.size_valid && st_MAKE_DRINK_SIZE) bev_size_ff <= inf.D.d_size;
end
always_ff @( posedge clk )
begin
   if(inf.date_valid && st_RD_DATES) date_ff <= inf.D.d_date;
end
always_ff @( posedge clk )
begin
    if(inf.box_no_valid && st_RD_BOX_NO) box_no_ff <= inf.D.d_box_no;
end

always_ff @( posedge clk )
begin
    if(inf.box_sup_valid && st_GET_SUPPLIES)
    begin
        case(cnt)
        0: black_tea_amt_ff <= inf.D.d_ing;
        1: green_tea_amt_ff <= inf.D.d_ing;
        2: milk_amt_ff <= inf.D.d_ing;
        3: pineapple_juice_amt_ff <= inf.D.d_ing;
        endcase
    end
end

//Outputs, complete, err_msg,out valid.
always_ff @( posedge clk or negedge inf.rst_n )
begin
    if(~inf.rst_n)
    begin
        inf.out_valid <= 0;
        inf.err_msg   <= No_Err;
        inf.complete  <= 0;
    end
    else if(st_IDLE || st_WB_DRAM)
    begin
        inf.out_valid <= 0;
        inf.err_msg   <= No_Err;
        inf.complete  <= 0;
    end
    else if(st_MAKE_DRINK || st_CHECK_DATE || st_SUPPLY)
    begin
        inf.out_valid <= 1;
        inf.err_msg   <= err_result;
        inf.complete  <= complete_wr;
    end
end

// WB FLAG
always_ff @(  posedge clk or negedge inf.rst_n)
begin
    if(~inf.rst_n)
        wb_busy_flag_ff <= 0;
    else if(inf.C_out_valid)
        wb_busy_flag_ff <= 0;
    else if(nstate[11])
        wb_busy_flag_ff <= 1;
end


//RD flag
always_ff @(  posedge clk or negedge inf.rst_n)
begin
    if(~inf.rst_n)
        rd_busy_flag_ff <= 0;
    else if(inf.C_out_valid)
        rd_busy_flag_ff <= 0;
    else if(rd_enable_f)
        rd_busy_flag_ff <= 1;
end

// logic[7:0] box_addr;
logic valid_hold_f;

// AXI bridge and data
always_ff @( posedge clk or negedge inf.rst_n )
begin
    if(~inf.rst_n)
    begin
        inf.C_addr <= 0;
        inf.C_r_wb <= 0;
        inf.C_in_valid <= 0;
        valid_hold_f <= 0;
    end
    else if(rd_enable_f || rd_busy_flag_ff)
    begin
        if(inf.C_out_valid)
        begin
            inf.C_addr <= 0;
            inf.C_r_wb <= 0;
            valid_hold_f <= 0;
        end
        else
        begin
            inf.C_addr <= box_no_ff;
            inf.C_r_wb <= 1;
            // Restrict C invalid for only 1 cycle
            valid_hold_f   <= 1;
            inf.C_in_valid <= valid_hold_f ? 0 : 1;
        end
    end
    else if(wb_busy_flag_ff || nstate[11])
    begin
        if(inf.C_out_valid)
        begin
            inf.C_addr <= 0;
            inf.C_r_wb <= 0;
            valid_hold_f <= 0;
        end
        else
        begin
            inf.C_addr <= box_no_ff;
            inf.C_r_wb <= 0;
            // Restrict C invalid for only 1 cycle
            valid_hold_f   <= 1;
            inf.C_in_valid <= valid_hold_f ? 0 : 1;
        end
    end
end

// Write back register, removes this make it combinational to save area
always_comb
begin
    if(st_WB_DRAM)
        inf.C_data_w = dram_data_ff;
    else
        inf.C_data_w = 0;
end

logic expired_f;
assign expired_f = ~((dram_data_ff.M > date_ff.M) || (dram_data_ff.M == date_ff.M && dram_data_ff.D >= date_ff.D));

parameter S_size = 480;
parameter M_size = 720;
parameter L_size = 960;

logic signed[12:0] temp_MD_black_tea_amt,temp_MD_green_tea_amt,temp_MD_milk_amt,temp_MD_pineapple_juice_amt;
logic [12:0] temp_S_black_tea_amt,temp_S_green_tea_amt,temp_S_milk_amt,temp_S_pineapple_juice_amt;

logic black_tea_of_f;
logic green_tea_of_f;
logic milk_of_f;
logic pineapple_juice_of_f;

logic black_tea_run_out_f;
logic green_tea_run_out_f;
logic milk_run_out_f;
logic pineapple_juice_run_out_f;

assign black_tea_of_f                 =                  temp_S_black_tea_amt > 4095;
assign green_tea_of_f                 =                  temp_S_green_tea_amt > 4095;
assign milk_of_f                      =                  temp_S_milk_amt      > 4095;
assign pineapple_juice_of_f           =                  temp_S_pineapple_juice_amt > 4095;

assign black_tea_run_out_f            =             temp_MD_black_tea_amt < 0;
assign green_tea_run_out_f            =             temp_MD_green_tea_amt < 0;
assign milk_run_out_f                 =             temp_MD_milk_amt      < 0;
assign pineapple_juice_run_out_f      =             temp_MD_pineapple_juice_amt < 0;

// Make drink
always_comb
begin
    temp_MD_black_tea_amt       = dram_data_ff.black_tea;
    temp_MD_green_tea_amt       = dram_data_ff.green_tea;
    temp_MD_milk_amt            = dram_data_ff.milk;
    temp_MD_pineapple_juice_amt = dram_data_ff.pineapple_juice;

    case(bev_type_ff)
    Black_Tea:
    begin
        temp_MD_black_tea_amt = dram_data_ff.black_tea;
        case(bev_size_ff)
        S:
        begin
            temp_MD_black_tea_amt -= S_size;
        end
        M:
        begin
            temp_MD_black_tea_amt -= M_size;
        end
        L:
        begin
            temp_MD_black_tea_amt -= L_size;
        end
        endcase
    end
    Milk_Tea:
    begin
        temp_MD_black_tea_amt = dram_data_ff.black_tea;
        temp_MD_milk_amt      = dram_data_ff.milk;
        case(bev_size_ff)
        S:
        begin
            temp_MD_black_tea_amt -= (S_size/4)*3;
            temp_MD_milk_amt      -= (S_size/4)*1;
        end
        M:
        begin
            temp_MD_black_tea_amt -= (M_size/4)*3;
            temp_MD_milk_amt      -= (M_size/4)*1;
        end
        L:
        begin
            temp_MD_black_tea_amt -= (L_size/4)*3;
            temp_MD_milk_amt      -= (L_size/4)*1;
        end
        endcase
    end
    Extra_Milk_Tea:
    begin
        temp_MD_black_tea_amt = dram_data_ff.black_tea;
        temp_MD_milk_amt      = dram_data_ff.milk;
        case(bev_size_ff)
        S:
        begin
            temp_MD_black_tea_amt -= (S_size/2)*1;
            temp_MD_milk_amt      -= (S_size/2)*1;
        end
        M:
        begin
            temp_MD_black_tea_amt -= (M_size/2)*1;
            temp_MD_milk_amt      -= (M_size/2)*1;
        end
        L:
        begin
            temp_MD_black_tea_amt -= (L_size/2)*1;
            temp_MD_milk_amt      -= (L_size/2)*1;
        end
        endcase
    end
    Green_Tea:
    begin
        temp_MD_green_tea_amt = dram_data_ff.green_tea;
        case(bev_size_ff)
        S:
        begin
            temp_MD_green_tea_amt -= S_size;
        end
        M:
        begin
            temp_MD_green_tea_amt -= M_size;
        end
        L:
        begin
            temp_MD_green_tea_amt -= L_size;
        end
        endcase
    end
    Green_Milk_Tea:
    begin
        temp_MD_green_tea_amt = dram_data_ff.green_tea;
        temp_MD_milk_amt      = dram_data_ff.milk;
        case(bev_size_ff)
        S:
        begin
            temp_MD_green_tea_amt -= (S_size/2);
            temp_MD_milk_amt      -= (S_size/2);
        end
        M:
        begin
            temp_MD_green_tea_amt -= (M_size/2);
            temp_MD_milk_amt      -= (M_size/2);
        end
        L:
        begin
            temp_MD_green_tea_amt -= (L_size/2);
            temp_MD_milk_amt      -= (L_size/2);
        end
        endcase
    end
    Pineapple_Juice:
    begin
        temp_MD_pineapple_juice_amt = dram_data_ff.pineapple_juice;
        case(bev_size_ff)
        S:
        begin
            temp_MD_pineapple_juice_amt -= S_size;
        end
        M:
        begin
            temp_MD_pineapple_juice_amt -= M_size;
        end
        L:
        begin
            temp_MD_pineapple_juice_amt -= L_size;
        end
        endcase
    end
    Super_Pineapple_Tea:
    begin
        temp_MD_black_tea_amt       = dram_data_ff.black_tea;
        temp_MD_pineapple_juice_amt = dram_data_ff.pineapple_juice;
        case(bev_size_ff)
        S:
        begin
            temp_MD_black_tea_amt          -= (S_size/2)*1 ;
            temp_MD_pineapple_juice_amt    -= (S_size/2)*1 ;
        end
        M:
        begin
            temp_MD_black_tea_amt          -= (M_size/2)*1 ;
            temp_MD_pineapple_juice_amt    -= (M_size/2)*1 ;
        end
        L:
        begin
            temp_MD_black_tea_amt          -= (L_size/2)*1;
            temp_MD_pineapple_juice_amt    -= (L_size/2)*1;
        end
        endcase
    end
    Super_Pineapple_Milk_Tea:
    begin
        temp_MD_black_tea_amt = dram_data_ff.black_tea;
        temp_MD_pineapple_juice_amt = dram_data_ff.pineapple_juice;
        temp_MD_milk_amt  = dram_data_ff.milk;
        case(bev_size_ff)
        S:
        begin
            temp_MD_black_tea_amt          -= (S_size/4)*2;
            temp_MD_pineapple_juice_amt    -= (S_size/4)*1;
            temp_MD_milk_amt               -= (S_size/4)*1;
        end
        M:
        begin
            temp_MD_black_tea_amt          -= (M_size/4)*2;
            temp_MD_pineapple_juice_amt    -= (M_size/4)*1;
            temp_MD_milk_amt               -= (M_size/4)*1;
        end
        L:
        begin
            temp_MD_black_tea_amt          -= (L_size/4)*2;
            temp_MD_pineapple_juice_amt    -= (L_size/4)*1;
            temp_MD_milk_amt               -= (L_size/4)*1;
        end
        endcase
    end
    endcase
end

//Supply
always_comb
begin
    temp_S_black_tea_amt       = black_tea_amt_ff + dram_data_ff.black_tea;
    temp_S_green_tea_amt       = green_tea_amt_ff + dram_data_ff.green_tea;
    temp_S_milk_amt            = milk_amt_ff      + dram_data_ff.milk;
    temp_S_pineapple_juice_amt = pineapple_juice_amt_ff + dram_data_ff.pineapple_juice;
end

logic ing_ran_out_f;
logic ing_of_f;
assign ing_ran_out_f = pineapple_juice_run_out_f || black_tea_run_out_f || milk_run_out_f || green_tea_run_out_f;
assign ing_of_f      = milk_of_f||black_tea_of_f||green_tea_of_f||pineapple_juice_of_f;

// Error msg and complete
always_comb
begin
    if(make_drink_f)
    begin
        if(expired_f)
        begin
            complete_wr     = 1'b0;
            err_result      = No_Exp;
        end
        else if(ing_ran_out_f)
        begin
            complete_wr = 1'b0;
            err_result = No_Ing;
        end
        else
        begin
            complete_wr     = 1'b1;
            err_result = No_Err;
        end
    end
    else if(supply_f)
    begin
        if(ing_of_f)
        begin
            complete_wr  = 1'b0;
            err_result = Ing_OF;
        end
        else
        begin
            complete_wr     = 1'b1;
            err_result = No_Err;
        end
    end
    else if(check_valid_f)
    begin
        if(expired_f)
        begin
            complete_wr     = 1'b0;
            err_result      = No_Exp;
        end
        else
        begin
            complete_wr     = 1'b1;
            err_result = No_Err;
        end
    end
end

//Dram data in
always_ff @( posedge clk )
begin
    if(inf.C_out_valid)
        dram_data_ff <= inf.C_data_r;
    else if(st_SUPPLY)
    begin
        dram_data_ff.black_tea       <= black_tea_of_f ? 4095 : temp_S_black_tea_amt;
        dram_data_ff.green_tea       <= green_tea_of_f ? 4095 : temp_S_green_tea_amt;
        dram_data_ff.milk            <= milk_of_f      ? 4095 : temp_S_milk_amt;
        dram_data_ff.pineapple_juice <= pineapple_juice_of_f ? 4095 : temp_S_pineapple_juice_amt;
        dram_data_ff.M               <= date_ff.M;
        dram_data_ff.D               <= date_ff.D;
    end
    else if(st_MAKE_DRINK)
    begin
        dram_data_ff.black_tea       <= temp_MD_black_tea_amt;
        dram_data_ff.green_tea       <= temp_MD_green_tea_amt;
        dram_data_ff.milk            <= temp_MD_milk_amt;
        dram_data_ff.pineapple_juice <= temp_MD_pineapple_juice_amt;
    end
end

endmodule