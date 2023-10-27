//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : SORT_IP.v
//   	Module Name : SORT_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module SORT_IP#(parameter IP_WIDTH = 8) (
    // Input signals
    IN_character, IN_weight,
    // Output signals
    OUT_character
);

// ===============================================================
// Input & Output
// ===============================================================
input [IP_WIDTH*4-1:0]  IN_character;
input [IP_WIDTH*5-1:0]  IN_weight;

output reg[IP_WIDTH*4-1:0] OUT_character;


reg [3:0] character_golden[0:IP_WIDTH-1];
reg [4:0] weight_temp[0:IP_WIDTH-1];

// ===============================================================
// Design
// ===============================================================
generate
    if(IP_WIDTH==8)
    begin
        reg[3:0] cg_temp;
        reg[4:0] w_temp;
        integer idx,jdx;

        always @(*)
        begin
            cg_temp = 0;
            w_temp  = 0;

            for(idx = 0;idx < 8; idx = idx+1)
                character_golden[idx] = IN_character[idx*4 +:4];
            for(jdx = 0; jdx < 8; jdx = jdx+1)
                weight_temp[jdx]      = IN_weight[jdx*5 +:5];

            //golden,uses bubble sort
            for(idx=0;idx<8;idx=idx+1)
                for(jdx=0;jdx<8;jdx=jdx+1)
                    if(weight_temp[jdx] < weight_temp[jdx+1])
                    begin
                    // Weight swapped also characters get swapped
                    w_temp = weight_temp[jdx];
                    weight_temp[jdx] = weight_temp[jdx+1];
                    weight_temp[jdx+1] = w_temp;

                    cg_temp   = character_golden[jdx];
                    character_golden[jdx] = character_golden[jdx+1];
                    character_golden[jdx+1] = cg_temp;
                    end

            for(idx=0;idx<8;idx=idx+1)
            begin
               OUT_character[idx*4 +:4] = character_golden[idx];
            end
        end
    end
    else if(IP_WIDTH==7)
    begin
        reg[3:0] cg_temp;
        reg[4:0] w_temp;
        integer idx,jdx;

        always @(*)
        begin
            cg_temp = 0;
            w_temp  = 0;

            for(idx = 0;idx < 7; idx = idx+1)
                character_golden[idx] = IN_character[idx*4 +:4];
            for(jdx = 0; jdx < 7; jdx = jdx+1)
                weight_temp[jdx]      = IN_weight[jdx*5 +:5];

            //golden,uses bubble sort
            for(idx=0;idx<7;idx=idx+1)
                for(jdx=0;jdx<7;jdx=jdx+1)
                    if(weight_temp[jdx] < weight_temp[jdx+1])
                    begin
                    // Weight swapped also characters get swapped
                    w_temp = weight_temp[jdx];
                    weight_temp[jdx] = weight_temp[jdx+1];
                    weight_temp[jdx+1] = w_temp;

                    cg_temp   = character_golden[jdx];
                    character_golden[jdx] = character_golden[jdx+1];
                    character_golden[jdx+1] = cg_temp;
                    end

            for(idx=0;idx<7;idx=idx+1)
            begin
               OUT_character[idx*4 +:4] = character_golden[idx];
            end
        end
    end
    else if(IP_WIDTH==6)
    begin
        reg[3:0] cg_temp;
        reg[4:0] w_temp;
        integer idx,jdx;

        always @(*)
        begin
            cg_temp = 0;
            w_temp  = 0;

            for(idx = 0;idx < 6; idx = idx+1)
                character_golden[idx] = IN_character[idx*4 +:4];
            for(jdx = 0; jdx < 6; jdx = jdx+1)
                weight_temp[jdx]      = IN_weight[jdx*5 +:5];

            //golden,uses bubble sort
            for(idx=0;idx<6;idx=idx+1)
                for(jdx=0;jdx<6;jdx=jdx+1)
                    if(weight_temp[jdx] < weight_temp[jdx+1])
                    begin
                    // Weight swapped also characters get swapped
                    w_temp = weight_temp[jdx];
                    weight_temp[jdx] = weight_temp[jdx+1];
                    weight_temp[jdx+1] = w_temp;

                    cg_temp   = character_golden[jdx];
                    character_golden[jdx] = character_golden[jdx+1];
                    character_golden[jdx+1] = cg_temp;
                    end

            for(idx=0;idx<6;idx=idx+1)
            begin
               OUT_character[idx*4 +:4] = character_golden[idx];
            end
        end
    end
    else if(IP_WIDTH==5)
    begin
        reg[3:0] cg_temp;
        reg[4:0] w_temp;
        integer idx,jdx;

        always @(*)
        begin
            cg_temp = 0;
            w_temp  = 0;

            for(idx = 0;idx < 5; idx = idx+1)
                character_golden[idx] = IN_character[idx*4 +:4];
            for(jdx = 0; jdx < 5; jdx = jdx+1)
                weight_temp[jdx]      = IN_weight[jdx*5 +:5];

            //golden,uses bubble sort
            for(idx=0;idx<5;idx=idx+1)
                for(jdx=0;jdx<5;jdx=jdx+1)
                    if(weight_temp[jdx] < weight_temp[jdx+1])
                    begin
                    // Weight swapped also characters get swapped
                    w_temp = weight_temp[jdx];
                    weight_temp[jdx] = weight_temp[jdx+1];
                    weight_temp[jdx+1] = w_temp;

                    cg_temp   = character_golden[jdx];
                    character_golden[jdx] = character_golden[jdx+1];
                    character_golden[jdx+1] = cg_temp;
                    end

            for(idx=0;idx<5;idx=idx+1)
            begin
               OUT_character[idx*4 +:4] = character_golden[idx];
            end
        end
    end
    else if(IP_WIDTH==4)
    begin
        reg[3:0] cg_temp;
        reg[4:0] w_temp;
        integer idx,jdx;

        always @(*)
        begin
            cg_temp = 0;
            w_temp  = 0;

            for(idx = 0;idx < 4; idx = idx+1)
                character_golden[idx] = IN_character[idx*4 +:4];
            for(jdx = 0; jdx < 4; jdx = jdx+1)
                weight_temp[jdx]      = IN_weight[jdx*5 +:5];

            //golden,uses bubble sort
            for(idx=0;idx<4;idx=idx+1)
                for(jdx=0;jdx<4;jdx=jdx+1)
                    if(weight_temp[jdx] < weight_temp[jdx+1])
                    begin
                    // Weight swapped also characters get swapped
                    w_temp = weight_temp[jdx];
                    weight_temp[jdx] = weight_temp[jdx+1];
                    weight_temp[jdx+1] = w_temp;

                    cg_temp   = character_golden[jdx];
                    character_golden[jdx] = character_golden[jdx+1];
                    character_golden[jdx+1] = cg_temp;
                    end

            for(idx=0;idx<4;idx=idx+1)
            begin
               OUT_character[idx*4 +:4] = character_golden[idx];
            end
        end
    end
    else if(IP_WIDTH==3)
    begin
        reg[3:0] cg_temp;
        reg[4:0] w_temp;
        integer idx,jdx;

        always @(*)
        begin
            cg_temp = 0;
            w_temp  = 0;

            for(idx = 0;idx < 3; idx = idx+1)
                character_golden[idx] = IN_character[idx*4 +:4];
            for(jdx = 0; jdx < 3; jdx = jdx+1)
                weight_temp[jdx]      = IN_weight[jdx*5 +:5];

            //golden,uses bubble sort
            for(idx=0;idx<3;idx=idx+1)
                for(jdx=0;jdx<3;jdx=jdx+1)
                    if(weight_temp[jdx] <= weight_temp[jdx+1])
                    begin
                    // Weight swapped also characters get swapped
                    w_temp = weight_temp[jdx];
                    weight_temp[jdx] = weight_temp[jdx+1];
                    weight_temp[jdx+1] = w_temp;

                    cg_temp   = character_golden[jdx];
                    character_golden[jdx] = character_golden[jdx+1];
                    character_golden[jdx+1] = cg_temp;
                    end

            for(idx=0;idx<3;idx=idx+1)
            begin
               OUT_character[idx*4 +:4] = character_golden[(IP_WIDTH-1)-idx];
            end
        end
    end
endgenerate
endmodule