module sign_div(
    in1,
    in2,
    result
);

input signed[3:0] in1,in2;
output signed[3:0] result;

assign result = in1/in2;

reg signed[MULTS_OUT-1:0]  mult1_out_d;
reg signed[MULTS_OUT-1:0]  mult0_out_d;

endmodule