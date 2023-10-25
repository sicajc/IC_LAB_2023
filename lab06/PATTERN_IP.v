`define CYCLE_TIME 20.0

module PATTERN #(parameter IP_WIDTH = 8)(
    //Output Port
    IN_character,
	IN_weight,
    //Input Port
	OUT_character
);
// ========================================
// Input & Output
// ========================================
output reg [IP_WIDTH*4-1:0] IN_character;
output reg [IP_WIDTH*5-1:0] IN_weight;

input [IP_WIDTH*4-1:0] OUT_character;

// ========================================
// Parameter
// ========================================
integer PATNUM = 1000;
integer SEED = 3213;
integer patcount;
integer file_in, file_out, cnt_in, cnt_out;
integer i, j;
reg clk;
real	CYCLE = `CYCLE_TIME;

reg [3:0] character_golden[0:IP_WIDTH-1];
reg [4:0] weight_temp[0:IP_WIDTH-1];
reg [IP_WIDTH*4-1:0] golden;

//================================================================
// design
//================================================================

always	#(CYCLE/2.0) clk = ~clk;
initial	clk = 0;

initial begin
    IN_character = 'bx;
    IN_weight = 'bx;

    for(patcount = 0; patcount < PATNUM; patcount = patcount + 1)
	begin
		gen_data;
		gen_golden;
		check_ans;
	end

    display_pass;
    $finish;
end

reg value;

task gen_data;
begin
    for(i = 0;i < IP_WIDTH*4; i = i+1) begin
        value = $random(SEED);
        value = value % 'd2;
        // $display("value = %d", value);
        IN_character[i] = value;
    end
    for(j = 0; j < IP_WIDTH*5; j = j+1) begin
        value = $random(SEED);
        value = value % 'd2;
        IN_weight[j] = value;
    end

    for(i = 0;i < IP_WIDTH; i = i+1)
        character_golden[i] = IN_character[i*4 +:4];
    for(j = 0; j < IP_WIDTH; j = j+1)
        weight_temp[j]      = IN_weight[j*5 +:5];
end
endtask
//
task gen_golden;
begin
    //golden,uses bubble sort
    for(i=0;i<IP_WIDTH;i=i+1)
        for(j=0;j<IP_WIDTH;j=j+1)
            if(weight_temp[j] < weight_temp[j+1])
            begin
                // Weight swapped also characters get swapped
                weight_temp[j] <= weight_temp[j+1];
                weight_temp[j+1] <= weight_temp[j];

                character_golden[j] <= character_golden[j+1];
                character_golden[j+1] <= character_golden[j];
            end
end
endtask
///
task check_ans; begin
    for(i=0;i<IP_WIDTH;i=i+1)
    begin
       golden[i*4 +:4] = character_golden[i];
    end

    if(OUT_character!==golden)
    begin
        display_fail;
        $display ("-------------------------------------------------------------------");
		$display ("*                            PATTERN NO.%4d 	                ",patcount);
        $display ("             answer should be : %h , your answer is : %h           ",golden, OUT_character);
        $display ("-------------------------------------------------------------------");
        #(100);
        // $finish;
    end
    else
        $display ("             Pass Pattern NO. %d          ", patcount);

end endtask



task display_fail;
begin
        $display("\n");
        $display("\n");
        $display("        ----------------------------               ");
        $display("        --                        --       |\__||  ");
        $display("        --  OOPS!!                --      / X,X  | ");
        $display("        --                        --    /_____   | ");
        $display("        --  Simulation Failed!!   --   /^ ^ ^ \\  |");
        $display("        --                        --  |^ ^ ^ ^ |w| ");
        $display("        ----------------------------   \\m___m__|_|");
        $display("\n");
end
endtask

task display_pass;
begin
        $display("\n");
        $display("\n");
        $display("        ----------------------------               ");
        $display("        --                        --       |\__||  ");
        $display("        --  Congratulations !!    --      / O.O  | ");
        $display("        --                        --    /_____   | ");
        $display("        --  Simulation PASS!!     --   /^ ^ ^ \\  |");
        $display("        --                        --  |^ ^ ^ ^ |w| ");
        $display("        ----------------------------   \\m___m__|_|");
        $display("\n");
end
endtask

endmodule