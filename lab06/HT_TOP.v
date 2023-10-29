//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : HT_TOP.v
//   	Module Name : HT_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "SORT_IP.v"
//synopsys translate_on

module HT_TOP(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_weight,
	out_mode,
    // Output signals
    out_valid,
	out_code
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid, out_mode;
input [2:0] in_weight;

output reg out_valid, out_code;

// ===============================================================
// Reg & Wire Declaration
// ===============================================================
reg[5:0] cur_st, next_st;
parameter IP_WIDTH = 8;
localparam  IDLE          = 6'b000001;
localparam  RD_DATA       = 6'b000010;
localparam  SORT          = 6'b000100;
localparam  BUILD_TREE    = 6'b001000;
localparam  ENCODE        = 6'b010000;
localparam  OUTPUT        = 6'b100000;

wire ST_IDLE                 = cur_st[0];
wire ST_RD_DATA              = cur_st[1];
wire ST_SORT                 = cur_st[2];
wire ST_BUILD_TREE           = cur_st[3];
wire ST_ENCODE               = cur_st[4];
wire ST_OUTPUT               = cur_st[5];

localparam  A= 0;
localparam  B= 1;
localparam  C= 2;
localparam  E= 3;
localparam  I= 4;
localparam  L= 5;
localparam  O= 6;
localparam  V= 7;
localparam  LEAF = 15;
// ===============================================================
// Design
// ===============================================================
wire[6:0] cur_char_bit_count;
reg[6:0] cnt;
reg[6:0] tree_ptr;
reg[6:0] bit_cnt;
wire data_rd_f = cnt == 0 && ST_RD_DATA;
wire tree_built_f = cnt == 7 && ST_BUILD_TREE;
wire tree_encoded_f = cnt == 8 && ST_ENCODE;
wire char_outputted_f = bit_cnt == 0;
wire output_done_f  = cnt == 4 &&  char_outputted_f && ST_OUTPUT;

reg[4:0] current_char;

reg[4:0] char_rf[0:14];
reg[4:0] left_child_idx_rf[0:14];
reg[4:0] right_child_idx_rf[0:14];
reg[5:0] weight_rf[0:14];
reg[6:0] encode_bits_rf[0:14];
reg[5:0] bit_counts_rf[0:14];


reg[4:0] sorter_in_weight_rf[0:7];
reg[5:0] sorter_in_weight_wr[0:7];
reg[3:0] sorter_in_char_rf[0:7];
reg[5:0] char_out_rf[0:7];
wire[5:0] merged_node_weight = weight_rf[char_out_rf[0]] + weight_rf[char_out_rf[1]];

reg [IP_WIDTH*4-1:0]  IN_character;
reg [IP_WIDTH*5-1:0]  IN_weight;
wire [IP_WIDTH*4-1:0]  OUT_character;

reg[5:0] left_child_idx,right_child_idx,cur_bit_count,cur_code;


wire is_leaf_f = left_child_idx == LEAF && right_child_idx == LEAF;
reg[6:0] left_child_code;
reg[6:0] right_child_code;

reg[6:0] flag_map_rf[0:7];


reg[6:0] encode_bits_rf_wr[0:6];
reg[4:0] bit_counts_rf_wr[0:6];
reg[4:0] flag_map_rf_wr[0:6];

reg[6:0] flag_map;
reg[7:0] encode_bits;
reg[3:0] bit_counts;
reg[4:0] offset_idx;

integer i,j,idx,jdx;
reg out_mode_ff;
//---------------------------------------------------------------------
//      MAIN FSM
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        cur_st <= IDLE;
    end
    else
    begin
        cur_st <= next_st;
    end
end

always @(*)
begin
    next_st = cur_st;
    case(cur_st)
    IDLE:
    begin
       if(in_valid) next_st = RD_DATA;
    end
    RD_DATA:
    begin
       if(data_rd_f) next_st = SORT;
    end
    SORT:
    begin
       next_st = BUILD_TREE;
    end
    BUILD_TREE:
    begin
       if(tree_built_f)
            next_st = OUTPUT;
       else
            next_st = SORT;
    end
    OUTPUT:
    begin
       if(output_done_f)  next_st = IDLE;
    end
    endcase
end

//---------------------------------------------------------------------
//      SUB CTR
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        cnt <= 7;
        tree_ptr  <= 8;
        bit_cnt   <= 0;
        out_valid <= 0;
        out_code  <= 0;
        for(i=0;i<7;i=i+1)
            broadcast_flag[i] <= 0;
    end
    else if(ST_IDLE)
    begin
        if(in_valid)
        begin
            cnt <= cnt - 1;
        end
        else
        begin
            cnt <= 7;
        end

        tree_ptr <= 8;
        bit_cnt <= 0;
        out_valid <= 0;
        out_code  <= 0;
        for(i=0;i<7;i=i+1)
            broadcast_flag[i] <= 0;
    end
    else if(ST_RD_DATA)
    begin
        if(data_rd_f)
        begin
            cnt <= 0;
        end
        else if(in_valid)
        begin
            cnt <= cnt - 1;
        end
    end
    else if(ST_BUILD_TREE)
    begin
        if(tree_built_f)
        begin
            cnt <= 14;
            tree_ptr <= 8;
        end
        else
        begin
            cnt <= cnt + 1;
            tree_ptr <= tree_ptr + 1;
        end
    end
    else if(ST_OUTPUT)
    begin
        out_valid <= 1;
        if(bit_cnt == 0) // Handle the first load problem
            out_code  <= encode_bits_rf[current_char][cur_char_bit_count-1];
        else
            out_code  <= encode_bits_rf[current_char][bit_cnt];

        // Output the next char
        if(char_outputted_f)
        begin
            cnt <= cnt + 1;
            bit_cnt <= cur_char_bit_count-2;
        end
        else
        begin
            bit_cnt <= bit_cnt - 1;
        end
    end
end

assign cur_char_bit_count = bit_counts_rf[current_char];
always @(*)
begin
    current_char = 0;
    if(out_mode_ff == 0)
    begin
        case(cnt)
        'd0: current_char = I;
        'd1: current_char = L;
        'd2: current_char = O;
        'd3: current_char = V;
        'd4: current_char = E;
        endcase
    end
    else
    begin
        case(cnt)
        'd0: current_char = I;
        'd1: current_char = C;
        'd2: current_char = L;
        'd3: current_char = A;
        'd4: current_char = B;
        endcase
    end
end

//---------------------------------------------------------------------
//      DATAPATH
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        for(i=0;i<15;i=i+1)
        begin
            char_rf[i] <= i;
            left_child_idx_rf[i] <= LEAF;
            right_child_idx_rf[i] <= LEAF;
            weight_rf[i] <= 31;
            bit_counts_rf[i] <= 0;

            for(j=0;j<7;j=j+1)
                encode_bits_rf[i][j] <= 0;
        end

        for(i=0;i<8;i=i+1)
        begin
            sorter_in_char_rf[i]  <= 7 - i;
            sorter_in_weight_rf[i]<=0;
            char_out_rf[i] <= 0;
        end

        out_mode_ff <= 0;
    end
    else
    begin
        case(cur_st)
        IDLE:
        begin
            if(in_valid)
            begin
                char_rf[0]   <= 0;
                weight_rf[0] <= in_weight;
                sorter_in_weight_rf[7] <= in_weight;
                out_mode_ff <= out_mode;
            end
            else
            begin
                for(i=0;i<15;i=i+1)
                begin
                    left_child_idx_rf[i] <= LEAF;
                    right_child_idx_rf[i] <= LEAF;
                    weight_rf[i] <= 31;
                    bit_counts_rf[i] <= 0;

                    for(j=0;j<7;j=j+1)
                        encode_bits_rf[i][j] <= 0;
                end
                for(i=0;i<8;i=i+1)
                begin
                    sorter_in_char_rf[i]  <= 7 -i;
                    sorter_in_weight_rf[i]<=0;
                    char_out_rf[i] <= 0;
                end
            end
        end
        RD_DATA:
        begin
            if(in_valid)
            begin
                weight_rf[7-cnt]           <= in_weight;
                sorter_in_weight_rf[cnt] <= in_weight;
            end
        end
        SORT:
        begin
            for(i=0;i<8;i=i+1)
            begin
                // Higher index is smalle
                char_out_rf[i] <= OUT_character[i*4 +: 4];
            end
        end
        BUILD_TREE:
        begin
            if(~tree_built_f)
            begin
                // update sort weight in
                for(i=2;i<8;i=i+1)
                begin
                    if(char_out_rf[i] == LEAF)
                    begin
                        sorter_in_weight_rf[i] <= 31;
                    end
                    else
                    begin
                        sorter_in_weight_rf[i] <= weight_rf[char_out_rf[i]];
                    end
                end

                // update sort char in
                for(i=2;i<8;i=i+1)
                    sorter_in_char_rf[i] <= char_out_rf[i];

                sorter_in_char_rf[1] <= LEAF;
                sorter_in_weight_rf[1] <= 31;

                sorter_in_char_rf[0]   <= tree_ptr;
                sorter_in_weight_rf[0] <= merged_node_weight;
            end
            // Sub-tree
            weight_rf[tree_ptr]          <= merged_node_weight;

            // Updates infos
            for(i=0;i<8;i=i+1)
            begin
                encode_bits_rf[i] <= encode_bits_rf_wr[i];
                bit_counts_rf[i] <= bit_counts_rf_wr[i];
                flag_map_rf[i] <= flag_map_rf_wr[i];
            end
        end
        endcase
    end
end



always @(*)
begin
    // Temp variables
    flag_map     = 0;
    encode_bits  = 0;
    bit_counts   = 0;
    left_child_idx  = char_out_rf[0];
    right_child_idx = char_out_rf[1];
    offset_idx = tree_ptr - 8;

    // Initialization
    for(i=0;i<8;i=i+1)
    begin
        flag_map_rf_wr[i] = flag_map_rf[i];
        encode_bits_rf_wr[i] = encode_bits_rf[i];
        bit_counts_rf_wr[i] = bit_counts_rf[i];
    end


    // Left child
    if(left_child_idx < 8)
    begin
        flag_map    = flag_map_rf[left_child_idx];
        encode_bits = encode_bits_rf[left_child_idx];
        bit_counts  = bit_counts_rf[left_child_idx];

        flag_map[tree_ptr] = 1;
        encode_bits[bit_counts] = 0;

        flag_map_rf_wr[left_child_idx] = flag_map;
        encode_bits_rf_wr[left_child_idx] = encode_bits;
        bit_counts_rf_wr[left_child_idx] = bit_counts + 1;
    end
    else
    begin
        for(i=0;i<8;i=i+1)
        begin
            flag_map = tree_flag_map_rf[i];
            if(flag_map[left_child_idx-8] == 1)
            begin
                encode_bits = encode_bits_rf[i];
                bit_counts  = bit_counts_rf[i];

                flag_map[offset_idx] = 1;
                encode_bits[bit_counts] = 0;

                flag_map_rf_wr[i] = flag_map;
                encode_bits_rf_wr[i] = encode_bits;
                bit_counts_rf_wr[i] = bit_counts + 1;
            end
        end
    end

    // Right child
    if(left_child_idx < 8)
    begin
        flag_map    = flag_map_rf[right_child_idx];
        encode_bits = encode_bits_rf[right_child_idx];
        bit_counts  = bit_counts_rf[right_child_idx];

        flag_map[tree_ptr] = 1;
        encode_bits[bit_counts] = 0;

        flag_map_rf_wr[right_child_idx] = flag_map;
        encode_bits_rf_wr[right_child_idx] = encode_bits;
        bit_counts_rf_wr[right_child_idx] = bit_counts + 1;
    end
    else
    begin
        for(i=0;i<8;i=i+1)
        begin
            flag_map = tree_flag_map_rf[i];
            if(flag_map[right_child_idx-8] == 1)
            begin
                encode_bits = encode_bits_rf[i];
                bit_counts  = bit_counts_rf[i];

                flag_map[offset_idx] = 1;
                encode_bits[bit_counts] = 0;

                flag_map_rf_wr[i] = flag_map;
                encode_bits_rf_wr[i] = encode_bits;
                bit_counts_rf_wr[i] = bit_counts + 1;
            end
        end
    end
end

// ======================================================
// Input & Output Declaration
// ======================================================
// Note for the sorter
always @(*)
begin
    for(idx = 0;idx < IP_WIDTH; idx = idx+1)
        IN_character[idx*4 +:4] = sorter_in_char_rf[idx];
    for(jdx = 0; jdx < IP_WIDTH; jdx = jdx+1)
        IN_weight[jdx*5 +:5]    = sorter_in_weight_rf[jdx];
end

SORT_IP #(.IP_WIDTH(IP_WIDTH)) I_SORT_IP(.IN_character(IN_character), .IN_weight(IN_weight), .OUT_character(OUT_character));

endmodule