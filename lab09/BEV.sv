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
Error_Msg   err_result;
Error_Msg   err_result_ff;
Bev_Type    bev_type_ff;
Bev_Size    bev_size_ff;
Date        date_ff;
Bev_Bal     bev_barrel_ff;
Bev_dram_in dram_data_ff;
Bev_dram_in dram_result_wr;

logic[8:0] box_no_ff;
logic[11:0] black_tea_amt_ff,green_tea_amt_ff,milk_amt_ff,pineapple_juice_amt_ff;


logic complete_ff,complete_wr;
logic[2:0] cnt;

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
                    nstate = RD_DRAM;
                else if(supply_f)
                    nstate = GET_SUPPLIES;
            end
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
            cnt <= cnt;
        else if(inf.box_sup_valid)
            cnt <= cnt + 1;
    end
    else if(state == IDLE)
    begin
        cnt <= 0;
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
            if(inf.box_no_valid) box_no_ff <= inf.D.d_box_no;
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
        inf.err_msg   <= err_result_ff;
        inf.complete  <= complete_ff;
    end
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
            inf.C_addr <= box_no_ff;
            inf.C_r_wb <= 1;
            // Restrict C invalid for only 1 cycle
            valid_hold_f   <= 1;

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
            valid_hold_f   <= 1;
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
        inf.C_data_w <= dram_data_ff;
    else
        inf.C_data_w <= 0;
end

logic expired_f;
assign expired_f = ~((dram_data_ff.M > date_ff.M) || (dram_data_ff.M == date_ff.M && dram_data_ff.D >= date_ff.D));

logic signed[13:0] temp_black_tea_amt,temp_green_tea_amt,temp_milk_amt,temp_pineapple_juice_amt;

logic black_tea_of_f;
logic green_tea_of_f;
logic milk_of_f;
logic pineapple_juice_of_f;

logic black_tea_run_out_f;
logic green_tea_run_out_f;
logic milk_run_out_f;
logic pineapple_juice_run_out_f;

assign black_tea_of_f            =                  temp_black_tea_amt > 4095;
assign green_tea_of_f            =                  temp_green_tea_amt > 4095;
assign milk_of_f                 =                  temp_milk_amt      > 4095;
assign pineapple_juice_of_f      =                  temp_pineapple_juice_amt > 4095;

assign black_tea_run_out_f            =             temp_black_tea_amt < 0;
assign green_tea_run_out_f            =             temp_green_tea_amt < 0;
assign milk_run_out_f                 =             temp_milk_amt      < 0;
assign pineapple_juice_run_out_f      =             temp_pineapple_juice_amt < 0;


parameter S_size = 480;
parameter M_size = 720;
parameter L_size = 960;

// Make drink, supply, check date logics.
always_comb
begin
    // Initilization
    complete_wr     = 1'b1;
    err_result = No_Err;

    temp_black_tea_amt       = dram_data_ff.black_tea;
    temp_green_tea_amt       = dram_data_ff.green_tea;
    temp_milk_amt            = dram_data_ff.milk;
    temp_pineapple_juice_amt = dram_data_ff.pineapple_juice;

    case({make_drink_f,supply_f,check_valid_f})
    3'b100:
    begin
        if(expired_f)
        begin
           // Initilization
           complete_wr     = 1'b0;
           err_result    = No_Exp;
        end
        else
        begin
            case(bev_type_ff)
            Black_Tea:
            begin
                temp_black_tea_amt = dram_data_ff.black_tea;

                case(bev_size_ff)
                S:
                begin
                    temp_black_tea_amt -= S_size;
                end
                M:
                begin
                    temp_black_tea_amt -= M_size;
                end
                L:
                begin
                    temp_black_tea_amt -= L_size;
                end
                endcase

                if(black_tea_run_out_f)
                begin
                    complete_wr = 1'b0;
                    err_result = No_Ing;
                end
            end
            Milk_Tea:
            begin
                temp_black_tea_amt = dram_data_ff.black_tea;
                temp_milk_amt      = dram_data_ff.milk;

                case(bev_size_ff)
                S:
                begin
                    temp_black_tea_amt -= (S_size/4)*3;
                    temp_milk_amt      -= (S_size/4)*1;
                end
                M:
                begin
                    temp_black_tea_amt -= (M_size/4)*3;
                    temp_milk_amt      -= (M_size/4)*1;

                end
                L:
                begin
                    temp_black_tea_amt -= (L_size/4)*3;
                    temp_milk_amt      -= (L_size/4)*1;
                end
                endcase

                if(black_tea_run_out_f || milk_run_out_f)
                begin
                    complete_wr = 1'b0;
                    err_result = No_Ing;
                end
            end
            Extra_Milk_Tea:
            begin
                temp_black_tea_amt = dram_data_ff.black_tea;
                temp_milk_amt      = dram_data_ff.milk;

                case(bev_size_ff)
                S:
                begin
                    temp_black_tea_amt -= (S_size/2)*1;
                    temp_milk_amt      -= (S_size/2)*1;
                end
                M:
                begin
                    temp_black_tea_amt -= (M_size/2)*1;
                    temp_milk_amt      -= (M_size/2)*1;
                end
                L:
                begin
                    temp_black_tea_amt -= (L_size/2)*1;
                    temp_milk_amt      -= (L_size/2)*1;
                end
                endcase

                if(black_tea_run_out_f || milk_run_out_f)
                begin
                    complete_wr = 1'b0;
                    err_result = No_Ing;
                end
            end
            Green_Tea:
            begin
                temp_green_tea_amt = dram_data_ff.green_tea;
                case(bev_size_ff)
                S:
                begin
                    temp_green_tea_amt -= S_size;
                end
                M:
                begin
                    temp_green_tea_amt -= M_size;
                end
                L:
                begin
                    temp_green_tea_amt -= L_size;
                end
                endcase

                if(green_tea_run_out_f)
                begin
                    complete_wr = 1'b0;
                    err_result = No_Ing;
                end
            end
            Green_Milk_Tea:
            begin
                temp_green_tea_amt = dram_data_ff.green_tea;
                temp_milk_amt      = dram_data_ff.milk;

                case(bev_size_ff)
                S:
                begin
                    temp_green_tea_amt -= (S_size/2);
                    temp_milk_amt      -= (S_size/2);
                end
                M:
                begin
                    temp_green_tea_amt -= (M_size/2);
                    temp_milk_amt      -= (M_size/2);
                end
                L:
                begin
                    temp_green_tea_amt -= (L_size/2);
                    temp_milk_amt      -= (L_size/2);
                end
                endcase

                if(green_tea_run_out_f || milk_run_out_f)
                begin
                    complete_wr = 1'b0;
                    err_result = No_Ing;
                end
            end
            Pineapple_Juice:
            begin
                temp_pineapple_juice_amt = dram_data_ff.pineapple_juice;
                case(bev_size_ff)
                S:
                begin
                    temp_pineapple_juice_amt -= S_size;
                end
                M:
                begin
                    temp_pineapple_juice_amt -= M_size;
                end
                L:
                begin
                    temp_pineapple_juice_amt -= L_size;
                end
                endcase

                if(pineapple_juice_run_out_f)
                begin
                    complete_wr = 1'b0;
                    err_result = No_Ing;
                end
            end
            Super_Pineapple_Tea:
            begin
                temp_black_tea_amt       = dram_data_ff.black_tea;
                temp_pineapple_juice_amt = dram_data_ff.pineapple_juice;
                case(bev_size_ff)
                S:
                begin
                    temp_black_tea_amt          -= (S_size/2)*1 ;
                    temp_pineapple_juice_amt    -= (S_size/2)*1 ;
                end
                M:
                begin
                    temp_black_tea_amt          -= (M_size/2)*1 ;
                    temp_pineapple_juice_amt    -= (M_size/2)*1 ;
                end
                L:
                begin
                    temp_black_tea_amt          -= (L_size/2)*1;
                    temp_pineapple_juice_amt    -= (L_size/2)*1;
                end
                endcase

                if(pineapple_juice_run_out_f || black_tea_run_out_f)
                begin
                    complete_wr = 1'b0;
                    err_result = No_Ing;
                end
            end
            Super_Pineapple_Milk_Tea:
            begin
                temp_black_tea_amt = dram_data_ff.black_tea;
                temp_pineapple_juice_amt = dram_data_ff.pineapple_juice;
                temp_milk_amt  = dram_data_ff.milk;

                case(bev_size_ff)
                S:
                begin
                    temp_black_tea_amt          -= (S_size/4)*2;
                    temp_pineapple_juice_amt    -= (S_size/4)*1;
                    temp_milk_amt               -= (S_size/4)*1;
                end
                M:
                begin
                    temp_black_tea_amt          -= (M_size/4)*2;
                    temp_pineapple_juice_amt    -= (M_size/4)*1;
                    temp_milk_amt               -= (M_size/4)*1;
                end
                L:
                begin
                    temp_black_tea_amt          -= (L_size/4)*2;
                    temp_pineapple_juice_amt    -= (L_size/4)*1;
                    temp_milk_amt               -= (L_size/4)*1;
                end
                endcase

                if(pineapple_juice_run_out_f || black_tea_run_out_f || milk_run_out_f)
                begin
                    complete_wr = 1'b0;
                    err_result = No_Ing;
                end
            end
            endcase
        end
    end
    3'b010:
    begin
        temp_black_tea_amt       = black_tea_amt_ff + dram_data_ff.black_tea;
        temp_green_tea_amt       = green_tea_amt_ff + dram_data_ff.green_tea;
        temp_milk_amt            = milk_amt_ff      + dram_data_ff.milk;
        temp_pineapple_juice_amt = pineapple_juice_amt_ff + dram_data_ff.pineapple_juice;

        if(milk_of_f||black_tea_of_f||green_tea_of_f||pineapple_juice_of_f)
        begin
            complete_wr  = 1'b0;
            err_result = Ing_OF;
        end
    end
    3'b001:
    begin
       if(expired_f)
       begin
          // Initilization
          complete_wr     = 1'b0;
          err_result    = No_Exp;
       end
    end
    default:
    begin
        complete_wr     = 1'b1;
        err_result = No_Err;
    end
    endcase
end

always_ff @( posedge clk or negedge inf.rst_n )
begin
    if(~inf.rst_n)
    begin
        complete_ff <= 1'b1;
        err_result_ff <= No_Err;
    end
    else if(state==IDLE)
    begin
        complete_ff <= 1'b1;
        err_result_ff <= No_Err;
    end
    else if(state == MAKE_DRINK || state == CHECK_DATE || state == SUPPLY)
    begin
        complete_ff <= complete_wr;
        err_result_ff <= err_result;
    end
end

//Dram data in
always_ff @( posedge clk or negedge inf.rst_n )
begin
    if(~inf.rst_n)
        dram_data_ff <= 0;
    else if(inf.C_out_valid && state==RD_DRAM)
        dram_data_ff <= inf.C_data_r;
    else if(state == SUPPLY)
    begin
        dram_data_ff.black_tea       <= black_tea_of_f ? 4095 : temp_black_tea_amt;
        dram_data_ff.green_tea       <= green_tea_of_f ? 4095 : temp_green_tea_amt;
        dram_data_ff.milk            <= milk_of_f      ? 4095 : temp_milk_amt;
        dram_data_ff.pineapple_juice <= pineapple_juice_of_f ? 4095 : temp_pineapple_juice_amt;
        dram_data_ff.M               <= date_ff.M;
        dram_data_ff.D               <= date_ff.D;
    end
    else if(state == MAKE_DRINK)
    begin
        if(~(milk_run_out_f || black_tea_run_out_f || green_tea_run_out_f || pineapple_juice_run_out_f))
        begin
            dram_data_ff.black_tea       <= temp_black_tea_amt;
            dram_data_ff.green_tea       <= temp_green_tea_amt;
            dram_data_ff.milk            <= temp_milk_amt;
            dram_data_ff.pineapple_juice <= temp_pineapple_juice_amt;
        end
    end
end

endmodule