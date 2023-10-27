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
module SORT_IP #(parameter IP_WIDTH = 8) (
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

reg[4:0] cg_temp;
reg[3:0] w_temp;


genvar idx,jdx;
generate
    always @(*)
    begin
        for(idx = 0;idx < IP_WIDTH; idx = idx+1)
            character_golden[idx] = IN_character[idx*4 +:4];
        for(jdx = 0; jdx < IP_WIDTH; jdx = jdx+1)
            weight_temp[jdx]      = IN_weight[jdx*5 +:5];

        //golden,uses bubble sort
        for(idx=0;idx<IP_WIDTH;idx=idx+1)
            for(jdx=0;jdx<IP_WIDTH;jdx=jdx+1)
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

        for(idx=0;idx<IP_WIDTH;idx=idx+1)
        begin
           OUT_character[idx*4 +:4] = character_golden[idx];
        end
    end
endgenerate


endmodule