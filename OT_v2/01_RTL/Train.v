module Train(
    //Input Port
    clk,
    rst_n,
	in_valid,
	data,

    //Output Port
    out_valid,
	result
);

input        clk;
input 	     in_valid;
input        rst_n;
input  [3:0] data;
output   reg out_valid;
output   reg result;

localparam IDLE = 6'd0;
localparam RD_DATA = 6'd1;
localparam INSERT_TRAIN = 6'd2;
localparam COMPARE      = 6'd3;
localparam LOAD_NEW_CURRENT = 6'd4;

reg[4:0] cur_state,next_state;

wire ST_IDLE =  cur_state == IDLE;
wire ST_RD_DATA =  cur_state == RD_DATA;
wire ST_INSERT_TRAIN =  cur_state == INSERT_TRAIN;
wire ST_COMPARE =  cur_state == COMPARE;
wire ST_LOAD_NEW_CURRENT = cur_state == LOAD_NEW_CURRENT;

reg[4:0] cnt;
reg[4:0] number_of_carriages_ff;
reg[4:0] order_ptr;
reg[4:0] in_train_cnt;
reg[4:0] desired_order_rf[0:10];
reg[4:0] stack[0:10];
reg[4:0] stack_ptr;
reg[4:0] current_target_ff;
reg result_ff;

integer i;

// Conditions
wire rd_done_f         = cnt == (number_of_carriages_ff -1)  && ST_RD_DATA;
wire completed_order_f = order_ptr == number_of_carriages_ff-1 && ST_COMPARE;
wire train_inserted_f  = in_train_cnt > current_target_ff  && (ST_INSERT_TRAIN || ST_LOAD_NEW_CURRENT);
wire[4:0] stack_top = (stack_ptr == 0) ? stack[0] : stack[stack_ptr-1];
wire wrong_top_value_f = current_target_ff != stack_top  && ST_COMPARE;

//FSM
always@(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        cur_state <= IDLE;
    end
    else
    begin
        case(cur_state)
        IDLE:              cur_state <= in_valid ? RD_DATA : IDLE;
        RD_DATA:           cur_state <= rd_done_f ? INSERT_TRAIN : RD_DATA;
        INSERT_TRAIN:      cur_state <= completed_order_f ? IDLE : (train_inserted_f ? COMPARE:INSERT_TRAIN);
        COMPARE:           cur_state <= completed_order_f ? IDLE : (wrong_top_value_f ? IDLE : LOAD_NEW_CURRENT);
        LOAD_NEW_CURRENT:  cur_state <= train_inserted_f ?  COMPARE : INSERT_TRAIN;
        endcase
    end
end

//DATAPATH
always@(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        order_ptr <= 0;
        stack_ptr <= 0;
        in_train_cnt <= 0;
        cnt <= 0;
        current_target_ff <= 0;
        number_of_carriages_ff <= 0;
        out_valid <= 0;
        result <= 0;

        for(i=0;i<11;i=i+1)
        begin
            stack[i] <= 0;
            desired_order_rf[i] <= 0;
        end
    end
    else
    begin
        case(cur_state)
        IDLE:
            begin
                if(in_valid)
                    number_of_carriages_ff <= data;
                else
                    number_of_carriages_ff <= 0;

                order_ptr <= 0;
                stack_ptr <= 0;
                in_train_cnt <= 1;
                cnt <= 0;
                current_target_ff <= 0;
                out_valid <= 0;
                result <= 0;

                for(i=0;i<11;i=i+1)
                begin
                    stack[i] <= 0;
                    desired_order_rf[i] <= 0;
                end
            end
        RD_DATA:
        begin
            desired_order_rf[cnt] <= data;
            cnt <= cnt + 1;
            current_target_ff <= desired_order_rf[0];
        end
        INSERT_TRAIN:
        begin
            if(~train_inserted_f)
            begin
                stack[stack_ptr] <= in_train_cnt;
                stack_ptr <= stack_ptr + 1;
            end

            if(train_inserted_f)
                in_train_cnt <= current_target_ff+1;
            else
                in_train_cnt <= in_train_cnt + 1;
        end
        COMPARE:
        begin
            order_ptr         <= order_ptr + 1;
            if(~(stack_ptr == 0))
                stack_ptr         <= stack_ptr - 1;

            current_target_ff <= desired_order_rf[order_ptr+1];

            if(completed_order_f)
            begin
                out_valid <= 1;
                result    <= 1;
            end
            else if(wrong_top_value_f)
            begin
                out_valid <= 1;
                result    <= 0;
            end
            else
            begin
                out_valid <= 0;
                result    <= 0;
            end
        end
        LOAD_NEW_CURRENT:
        begin

        end
        endcase
    end
end

endmodule