module BEV(input clk, INF.BEV_inf inf);
import usertype::*;
// This file contains the definition of several state machines used in the BEV (Beverage) System RTL design.
// The state machines are defined using SystemVerilog enumerated types.
// The state machines are:
// - state_t: used to represent the overall state of the BEV system
//
// Each enumerated type defines a set of named states that the corresponding process can be in.
typedef enum logic [3:0]{
    IDLE,
    MAKE_DRINK_TYPE,
    MAKE_DRINK_SIZE,
    RD_DATES,
    RD_BOX_NO,
    GET_SUPPLIES,
    RD_DRAM,
    MAKE_DRINK,
    SUPPLY,
    CHECK_DATE,
    WB_DRAM,
    OUT_MSG
} state_t;
parameter BASE_Addr = 65536 ;

// REGISTERS
state_t state, nstate;

Action      cur_act;
Error_Msg   error_result;
Error_Msg   error_result_ff;
Bev_Type    bev_type_ff;
Bev_Size    bev_size_ff;
Date        date_ff;
Bev_Bal     bev_barrel_ff;


logic[8:0] box_no_ff;
logic[8:0] black_tea_amt_ff,green_tea_amt_ff,milk_amt_ff,pineapple_juice_amt_ff;



logic complete_ff,complete_wr;
logic[2:0] cnt;

logic make_drink_f  = cur_act == Make_drink;
logic supply_f      = cur_act == Supply;
logic check_valid_f = cur_act == Check_Valid_Date;
logic supply_received_f = cnt == 3 && inf.box_sup_valid;
logic make_drink_err_f  = error_result == No_Exp || error_result == No_Ing;
logic supply_err_f      = error_result == Ing_OF;
logic check_date_err_f  = error_result == No_Exp;

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
            if(make_drink_f || check_valid_f)
                nstate = RD_DRAM;
            else if(supply_f)
                nstate = GET_SUPPLIES;
            else
                nstate = RD_BOX_NO;
        end
        GET_SUPPLIES:
        begin
            nstate = supply_received_f ? RD_DRAM : GET_SUPPLIES;
        end
        RD_DRAM:
        begin
            if(inf.C_out_valid)
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
            nstate = make_drink_err_f ? OUT_MSG : WB_DRAM;
        end
        CHECK_DATE:
        begin
            nstate = OUT_MSG;
        end
        SUPPLY:
        begin
            nstate = WB_DRAM;
        end
        WB_DRAM:
        begin
            nstate = inf.C_out_valid ? OUT_MSG : WB_DRAM;
        end
        OUT_MSG:
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
    else if(state == GET_SUPPLIES)
    begin
        if(supply_received_f)
            cnt <= 0;
        else if(inf.box_sup_valid)
            cnt <= cnt + 1;
    end
end

// Datapath
always_ff @( posedge clk or negedge inf.rst_n )
begin: Inputs
    if(~inf.rst_n)
    begin
        cur_act     <= Make_drink;
        bev_type_ff <= Black_Tea;
        bev_size_ff <= S;
        date_ff     <= 0;
        box_no_ff   <= 0;
        black_tea_amt_ff<=0;
        green_tea_amt_ff<=0;
        milk_amt_ff<=0;
        pineapple_juice_amt_ff<=0;
    end
    else
    begin
        case(state)
        IDLE:
        begin
            if(inf.sel_action_valid) cur_act <= inf.D.d_act;
        end
        MAKE_DRINK_TYPE:
        begin
            if(inf.type_valid) bev_type_ff <= inf.D.d_type;
        end
        MAKE_DRINK_SIZE:
        begin
            if(inf.size_valid) bev_size_ff <= inf.D.d_size;
        end
        RD_DATES:
        begin
            if(inf.date_valid) date_ff <= inf.D.d_date;
        end
        RD_BOX_NO:
        begin
            if(inf.box_sup_valid) box_no_ff <= inf.D.d_box_no;
        end
        GET_SUPPLIES:
        begin
            if(inf.box_sup_valid)
            begin
                case(cnt)
                0: black_tea_amt_ff <= inf.D.d_ing;
                1: green_tea_amt_ff <= inf.D.d_ing;
                2: milk_amt_ff <= inf.D.d_ing;
                3: pineapple_juice_amt_ff <= inf.D.d_ing;
                endcase
            end
        end
        endcase
    end
end

//Outputs, complete, err_msg,out valid
always_ff @( posedge clk or negedge inf.rst_n )
begin
    if(~inf.rst_n)
    begin
        inf.out_valid <= 0;
        inf.err_msg   <= No_Err;
        inf.complete  <= 0;
    end
    else if(state == IDLE)
    begin
        inf.out_valid <= 0;
        inf.err_msg   <= No_Err;
        inf.complete  <= 0;
    end
    else if(state == OUT_MSG)
    begin
        inf.out_valid <= 1;
        inf.err_msg   <= error_result_ff;
        inf.complete  <= complete_ff;
    end
end

logic[7:0] box_addr;
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
    else if(state == RD_DRAM)
    begin
        if(inf.C_out_valid)
        begin
            inf.C_addr <= 0;
            inf.C_r_wb <= 0;
            valid_hold_f <= 0;
        end
        else
        begin
            inf.C_addr <= box_addr;
            inf.C_r_wb <= 1;
            // Restrict C invalid for only 1 cycle
            valid_hold_f   <= (inf.C_in_valid == 1) ? 1 : 0;
            inf.C_in_valid <= valid_hold_f ? 0 : 1;
        end
    end
    else if(state == WB_DRAM)
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
            valid_hold_f   <= (inf.C_in_valid == 1) ? 1 : 0;
            inf.C_in_valid <= valid_hold_f ? 0 : 1;
        end
    end
end

// Write back register
always_ff @( posedge clk or negedge inf.rst_n )
begin
    if(~inf.rst_n)
        inf.C_data_w <= 0;
    else if(state == IDLE)
        inf.C_data_w <= 0;
    else if(state == WB_DRAM)
        inf.C_data_w <= bev_barrel_ff;
    else
        inf.C_data_w <= 0;
end

// Make drink, supply, check date logics.
always_comb
begin
    // Initilization
    complete_wr     = 1'b1;
    error_result = No_Err;

    case({make_drink_f,supply_f,check_valid_f})
    3'b100:
    begin

    end
    3'b010:
    begin

    end
    3'b001:
    begin

    end
    default:
    begin
        complete_wr     = 1'b1;
        error_result = No_Err;
    end
    endcase
end

always_ff @( posedge clk or negedge inf.rst_n )
begin
    if(~inf.rst_n)
    begin
        complete_ff <= 1'b1;
        error_result_ff <= No_Err;
    end
    else if(state==IDLE)
    begin
        complete_ff <= 1'b1;
        error_result_ff <= No_Err;
    end
    else if(state == MAKE_DRINK || state == CHECK_DATE || state == SUPPLY)
    begin
        complete_ff <= complete_wr;
        error_result_ff <= error_result;
    end
end

endmodule