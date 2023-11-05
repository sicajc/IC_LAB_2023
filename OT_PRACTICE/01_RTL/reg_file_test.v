module TRIANGLE(
    clk,
    rst_n,
    in_valid,
    coord_x,
    coord_y,
    out_valid,
    out_length,
	out_incenter
);
//================================================================
//  INPUT AND OUTPUT DECLARATION
//================================================================
input wire clk, rst_n, in_valid;
input wire [4:0] coord_x, coord_y;
output reg out_valid;
output reg [12:0] out_length, out_incenter;
//================================================================
//  Wires & Registers
//================================================================
reg[1:0] path_map_rf[0:63][0:63];
reg[6:0] cntx,cnty;

integer i,j;
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        path_map_rf[i][j] <= 0;
        cntx<=0;cnty<=0;
        out_valid <= 0;
        out_incenter <= 0;
    end
    else
    begin
        path_map_rf[cntx][cnty] <= in_valid;
        cntx <= cntx + 1;
        cnty <= cnty + 1;
        out_incenter <= path_map_rf[cntx][cnty];
    end
end



endmodule