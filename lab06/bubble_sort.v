module moduleName #(
    parameters
) (
    ports
);

genvar i,j;

reg node[0:IP_WIDTH-1];

generate
always @(posedge clk)
begin
    for(i=0;i<IP_WIDTH;i=i+1)
        for(j=0;j<IP_WIDTH;j=j+1)
            if (node[j] < node[j+1]):

end
endgenerate



endmodule