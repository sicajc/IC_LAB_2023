//############################################################################
//   2023 ICLAB Fall Course
//   Lab05       : CPU
//   Author      : Jyun-wei, Su
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   Brief       : Customized ISA Processor
//   Rev         :
//############################################################################
`ifdef RTL
	`define CYCLE_TIME 3.6
	`define RTL_GATE
`elsif GATE
	`define CYCLE_TIME 3.6
	`define RTL_GATE
`elsif CHIP
	`define CYCLE_TIME 3.8
	`define CHIP_POST
`elsif POST
	`define CYCLE_TIME 3.8
	`define CHIP_POST
`endif


`ifdef FUNC
`define PAT_NUM 828
`define MAX_WAIT_READY_CYCLE 2000
`endif
`ifdef PERF
`define PAT_NUM 828
`define MAX_WAIT_READY_CYCLE 100000
`endif


`include "../00_TESTBED/MEM_MAP_define.v"
`include "../00_TESTBED/pseudo_DRAM_data.v"
`include "../00_TESTBED/pseudo_DRAM_inst.v"

module PATTERN(
    			clk,
			  rst_n,
		   IO_stall,


         awid_s_inf,
       awaddr_s_inf,
       awsize_s_inf,
      awburst_s_inf,
        awlen_s_inf,
      awvalid_s_inf,
      awready_s_inf,

        wdata_s_inf,
        wlast_s_inf,
       wvalid_s_inf,
       wready_s_inf,

          bid_s_inf,
        bresp_s_inf,
       bvalid_s_inf,
       bready_s_inf,

         arid_s_inf,
       araddr_s_inf,
        arlen_s_inf,
       arsize_s_inf,
      arburst_s_inf,
      arvalid_s_inf,

      arready_s_inf,
          rid_s_inf,
        rdata_s_inf,
        rresp_s_inf,
        rlast_s_inf,
       rvalid_s_inf,
       rready_s_inf
    );

//---------------------------------------------------------------------
//   PORT DECLARATION
//---------------------------------------------------------------------
parameter ID_WIDTH=4, DATA_WIDTH=16, ADDR_WIDTH=32, DRAM_NUMBER=2, WRIT_NUMBER=1;

output reg			clk,rst_n;
input				IO_stall;

// axi write address channel
input wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_s_inf;
input wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_s_inf;
input wire [WRIT_NUMBER * 3 -1:0]            awsize_s_inf;
input wire [WRIT_NUMBER * 2 -1:0]           awburst_s_inf;
input wire [WRIT_NUMBER * 7 -1:0]             awlen_s_inf;
input wire [WRIT_NUMBER-1:0]                awvalid_s_inf;
output wire [WRIT_NUMBER-1:0]               awready_s_inf;
// axi write data channel
input wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_s_inf;
input wire [WRIT_NUMBER-1:0]                  wlast_s_inf;
input wire [WRIT_NUMBER-1:0]                 wvalid_s_inf;
output wire [WRIT_NUMBER-1:0]                wready_s_inf;
// axi write response channel
output wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_s_inf;
output wire [WRIT_NUMBER * 2 -1:0]             bresp_s_inf;
output wire [WRIT_NUMBER-1:0]             	  bvalid_s_inf;
input wire [WRIT_NUMBER-1:0]                  bready_s_inf;
// -----------------------------
// axi read address channel
input wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_s_inf;
input wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_s_inf;
input wire [DRAM_NUMBER * 7 -1:0]            arlen_s_inf;
input wire [DRAM_NUMBER * 3 -1:0]           arsize_s_inf;
input wire [DRAM_NUMBER * 2 -1:0]          arburst_s_inf;
input wire [DRAM_NUMBER-1:0]               arvalid_s_inf;
output wire [DRAM_NUMBER-1:0]              arready_s_inf;
// -----------------------------
// axi read data channel
output wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_s_inf;
output wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_s_inf;
output wire [DRAM_NUMBER * 2 -1:0]             rresp_s_inf;
output wire [DRAM_NUMBER-1:0]                  rlast_s_inf;
output wire [DRAM_NUMBER-1:0]                 rvalid_s_inf;
input wire [DRAM_NUMBER-1:0]                  rready_s_inf;
// -----------------------------

pseudo_DRAM_data u_DRAM_data(

  	.clk(clk),
  	.rst_n(rst_n),
	.   awid_s_inf(   awid_s_inf[3:0]	),
	. awaddr_s_inf( awaddr_s_inf[31:0]	),
	. awsize_s_inf( awsize_s_inf[2:0]	),
	.awburst_s_inf(awburst_s_inf[1:0]	),
	.  awlen_s_inf(  awlen_s_inf[6:0]	),
	.awvalid_s_inf(awvalid_s_inf[0]		),
	.awready_s_inf(awready_s_inf[0]		),

	.  wdata_s_inf(  wdata_s_inf[15:0]	),
	.  wlast_s_inf(  wlast_s_inf[0]		),
	. wvalid_s_inf( wvalid_s_inf[0]		),
	. wready_s_inf( wready_s_inf[0]		),

	.    bid_s_inf(    bid_s_inf[3:0]	),
	.  bresp_s_inf(  bresp_s_inf[1:0]	),
	. bvalid_s_inf( bvalid_s_inf[0]		),
	. bready_s_inf( bready_s_inf[0]		),

	.   arid_s_inf(   arid_s_inf[3:0]	),
	. araddr_s_inf( araddr_s_inf[31:0]	),
	.  arlen_s_inf(  arlen_s_inf[6:0]	),
	. arsize_s_inf( arsize_s_inf[2:0]	),
	.arburst_s_inf(arburst_s_inf[1:0]	),
	.arvalid_s_inf(arvalid_s_inf[0]		),
	.arready_s_inf(arready_s_inf[0]		),

	.    rid_s_inf(    rid_s_inf[3:0]	),
	.  rdata_s_inf(  rdata_s_inf[15:0]	),
	.  rresp_s_inf(  rresp_s_inf[1:0]	),
	.  rlast_s_inf(  rlast_s_inf[0]		),
	. rvalid_s_inf( rvalid_s_inf[0]		),
	. rready_s_inf( rready_s_inf[0]		)

);


pseudo_DRAM_inst u_DRAM_inst(

  	.clk(clk),
  	.rst_n(rst_n),

	.   arid_s_inf(   arid_s_inf[7:4]	),
	. araddr_s_inf( araddr_s_inf[63:32]	),
	.  arlen_s_inf(  arlen_s_inf[13:7]	),
	. arsize_s_inf( arsize_s_inf[5:3]	),
	.arburst_s_inf(arburst_s_inf[3:2]	),
	.arvalid_s_inf(arvalid_s_inf[1]		),
	.arready_s_inf(arready_s_inf[1]		),

	.    rid_s_inf(    rid_s_inf[7:4]	),
	.  rdata_s_inf(  rdata_s_inf[31:16]	),
	.  rresp_s_inf(  rresp_s_inf[3:2]	),
	.  rlast_s_inf(  rlast_s_inf[1]		),
	. rvalid_s_inf( rvalid_s_inf[1]		),
	. rready_s_inf( rready_s_inf[1]		)

);

//================================================================
// clock
//================================================================
real	CYCLE = `CYCLE_TIME;
always	#(CYCLE/2.0) clk = ~clk;

//================================================================
// declare
//================================================================
integer		patcount;
integer		cycles, total_cycles;
integer		inst_num;
integer 	color_stage = 0, color, r = 5, g = 0, b = 0;
integer		i;

integer		golden_pc;

reg signed [4:0]imm;


reg			[15:0]golden_inst_data;
reg	signed	[11:0]golden_addr_t;
reg	signed	[31:0]golden_addr;
reg	signed	[31:0]golden_mult;
reg	signed	[15:0]golden_reg[0:15];

integer t;
//================================================================
// DRAM Inital
//================================================================
parameter DRAM_data_read = "../00_TESTBED/DRAM/DRAM_data.dat";

reg  [7:0] golden_DRAM_data[8191:4096];

initial begin
	$readmemh(DRAM_data_read, golden_DRAM_data);
	end


//================================================================
// initial
//================================================================
initial begin

	force clk = 0;
	golden_reset;
	rst_n = 1;
	reset_task;
	patcount = 0;
	total_cycles = 0;
	inst_num = 0;
	t=0;
	$display("");
	$display("");
	$display("-------------------------------------Pattern  Start-------------------------------------");
	@(negedge clk);
		while(golden_pc != 16'h07FF)begin
		// for(patcount = 0; patcount < `PAT_NUM; patcount = patcount + 1) begin
			ans_clc;
			wait_outvalid;
			check_ans;
			patcount = patcount+1;
			@(negedge clk);
			case(color_stage)
				0: begin
					r = r - 1;
					g = g + 1;
					if(r == 0) color_stage = 1;
				end
				1: begin
					g = g - 1;
					b = b + 1;
					if(g == 0) color_stage = 2;
				end
				2: begin
					b = b - 1;
					r = r + 1;
					if(b == 0) color_stage = 0;
				end
			endcase
			color = 16 + r*36 + g*6 + b;
			if(color < 100) $display("\033[38;5;%2dmPASS\tPATTERN NO.%4d\t\tgolden_pc NO.%4x\t\tgolden_inst_dram_address NO.%4x\033[00m\n", color, patcount,golden_pc, golden_pc*2+16'h1000);
			else $display("\033[38;5;%3dmPASS\tPATTERN NO.%4d\t\tgolden_pc NO.%4x\t\tgolden_inst_dram_address NO.%4x\033[00m\n", color, patcount,golden_pc, golden_pc*2+16'h1000);
		end
		ans_clc;
		wait_outvalid;
		check_ans;

	repeat(1) @(negedge clk);

	#(1000);
	display_pass;
	$finish;

end
//================================================================
// Answer calc
//================================================================

task ans_clc;
	begin
		golden_inst_data[7:0]	= u_DRAM_inst.DRAM_r[32'h0000_1000+golden_pc*2];
		golden_inst_data[15:8]	= u_DRAM_inst.DRAM_r[32'h0000_1000+golden_pc*2+1];
		imm = golden_inst_data[4:0];
		case(golden_inst_data[15:13])
		3'b000:begin
			if(golden_inst_data[0]==1)begin
				golden_reg[golden_inst_data[4:1]] = golden_reg[golden_inst_data[12:9]] - golden_reg[golden_inst_data[8:5]];
				$display("--------------SUB------------");
				end
			else begin
				golden_reg[golden_inst_data[4:1]] = golden_reg[golden_inst_data[12:9]] + golden_reg[golden_inst_data[8:5]];
				$display("--------------ADD------------");
				end
			golden_pc = golden_pc + 1;
		end
		3'b001:begin
			if(golden_inst_data[0]==1)begin
				golden_mult = golden_reg[golden_inst_data[12:9]] * golden_reg[golden_inst_data[8:5]];
				// golden_reg[golden_inst_data[4:1]] = {golden_mult[31],golden_mult[14:0]};
				golden_reg[golden_inst_data[4:1]] = golden_mult;
				$display("--------------MULT------------");
				// $display("golden_inst_data = %b",golden_inst_data);

			end
			else begin
				golden_reg[golden_inst_data[4:1]] = (golden_reg[golden_inst_data[12:9]] < golden_reg[golden_inst_data[8:5]])? 16'd1: 16'd0;
				$display("--------------Set Less Than------------");
			end
			golden_pc = golden_pc + 1;
		end
		3'b010:begin
			golden_addr = 	(golden_reg[golden_inst_data[12:9]] + imm)*2+4096;
			// $display("golden_reg[golden_inst_data[12:9]] = %h",golden_reg[golden_inst_data[12:9]]);
			// $display("imm = %h",imm);
			// $display("(golden_reg[golden_inst_data[12:9]] + imm)*2 = %h",(golden_reg[golden_inst_data[12:9]] + imm)*2);
			// $display("golden_addr = %h",golden_addr);
			if(golden_addr > 32'h0000_1fff || 32'h0000_1000 > golden_addr)begin
				display_fail;
				$display("----------------------------------------------------------------------------------------");
				$display("                                      No  function(Load)                                ");
				$display("----------------------------------------------------------------------------------------");
				$finish;
				end
			golden_reg[golden_inst_data[8:5]] = {golden_DRAM_data[golden_addr+1],golden_DRAM_data[golden_addr]};
			golden_pc = golden_pc + 1;
			$display("--------------Load------------");
		end
		3'b011:begin
			golden_addr = 	(golden_reg[golden_inst_data[12:9]] + imm)*2+4096;
			// $display("golden_reg[golden_inst_data[12:9]] = %h",golden_reg[golden_inst_data[12:9]]);
			// $display("imm = %h",imm);
			// $display("(golden_reg[golden_inst_data[12:9]] + imm)*2 = %h",(golden_reg[golden_inst_data[12:9]] + imm)*2);
			// $display("golden_addr = %h",golden_addr);
			if(golden_addr > 32'h0000_1fff || 32'h0000_1000 > golden_addr)begin
				display_fail;
				$display("----------------------------------------------------------------------------------------");
				$display("                                      No  function(Store)                               ");
				$display("----------------------------------------------------------------------------------------");
				$finish;
			end
			golden_DRAM_data[golden_addr] = golden_reg[golden_inst_data[8:5]][7:0];
			golden_DRAM_data[golden_addr+1] = golden_reg[golden_inst_data[8:5]][15:8];
			golden_pc = golden_pc + 1;
			$display("--------------Store------------");
			// $display("golden_reg[golden_inst_data[12:9]] = %h",golden_reg[golden_inst_data[12:9]]);
			// $display("(golden_reg[golden_inst_data[12:9]] + imm)*2 = %h",(golden_reg[golden_inst_data[12:9]] + imm)*2);
			// $display("golden_inst_data = %b",golden_inst_data);

			// $display("golden_reg[golden_inst_data[8:5]] = %h",golden_reg[golden_inst_data[8:5]]);
		end
		3'b100:begin
			if(golden_reg[golden_inst_data[8:5]] == golden_reg[golden_inst_data[12:9]])begin
				golden_pc = golden_pc + 1 + imm;
			end
			else begin
				golden_pc = golden_pc + 1;
			end
			$display("--------------Branch------------");
		end
		3'b101:begin
			golden_pc = golden_inst_data[11:1];
			$display("--------------Jump------------");
		end
		default:begin
			display_fail;
			$display("----------------------------------------------------------------------------------------");
			$display("--------------------------------------No  function--------------------------------------");
			$display("----------------------------------------------------------------------------------------");
			$finish;
			end
			endcase
		end
	endtask
//================================================================
// Wait outvalid task
//================================================================
task wait_outvalid;
	begin
		cycles = 0;
		while(IO_stall !== 0)begin
			if(cycles == `MAX_WAIT_READY_CYCLE) begin
				display_fail;
				$display("----------------------------------------------------------------------------------------");
				$display("                                    Pattern NO.%5d                                   ", patcount);
				$display("                      The execution latency are over %6d cycles                      ",`MAX_WAIT_READY_CYCLE);
				$display("----------------------------------------------------------------------------------------");
				repeat(2)@(negedge clk);
				$finish;
				end
			if((IO_stall === 1'bX) || ( IO_stall === 1'bZ)) begin
				display_fail;
				$display("----------------------------------------------------------------------------------------");
				$display("                                    Pattern NO.%5d                                   ", patcount);
				$display("                               IO_stall should be 0 or 1.                               ");
				$display("----------------------------------------------------------------------------------------");
				repeat(2)@(negedge clk);
				$finish;
				end
			@(negedge clk);
			cycles = cycles + 1;
			end
			inst_num = inst_num + 1;
		total_cycles = total_cycles + cycles;
		end
	endtask

//================================================================
// Output task
//================================================================
task check_ans;
	begin
		if(IO_stall === 0) begin
			if(	(My_CPU.core_r0 !== golden_reg[0]) || (My_CPU.core_r8  !== golden_reg[8 ]) ||
				(My_CPU.core_r1 !== golden_reg[1]) || (My_CPU.core_r9  !== golden_reg[9 ]) ||
				(My_CPU.core_r2 !== golden_reg[2]) || (My_CPU.core_r10 !== golden_reg[10]) ||
				(My_CPU.core_r3 !== golden_reg[3]) || (My_CPU.core_r11 !== golden_reg[11]) ||
				(My_CPU.core_r4 !== golden_reg[4]) || (My_CPU.core_r12 !== golden_reg[12]) ||
				(My_CPU.core_r5 !== golden_reg[5]) || (My_CPU.core_r13 !== golden_reg[13]) ||
				(My_CPU.core_r6 !== golden_reg[6]) || (My_CPU.core_r14 !== golden_reg[14]) ||
				(My_CPU.core_r7 !== golden_reg[7]) || (My_CPU.core_r15 !== golden_reg[15]) ) begin
				// display_fail;
				$display("----------------------------------------------------------------------------------------");
				$display("                                    Pattern NO.%5d                                   ", patcount);
				$display("  golden_reg[ 0]: %04h, golden_reg[ 1]: %04h, golden_reg[ 2]: %04h, golden_reg[ 3]: %04h ", golden_reg[0],golden_reg[1],golden_reg[2],golden_reg[3]);
				$display("    your_reg[ 0]: %04h,   your_reg[ 1]: %04h,   your_reg[ 2]: %04h,   your_reg[ 3]: %04h ", My_CPU.core_r0, My_CPU.core_r1, My_CPU.core_r2, My_CPU.core_r3);
				$display("  golden_reg[ 4]: %04h, golden_reg[ 5]: %04h, golden_reg[ 6]: %04h, golden_reg[ 7]: %04h ", golden_reg[4],golden_reg[5],golden_reg[6],golden_reg[7]);
				$display("    your_reg[ 4]: %04h,   your_reg[ 5]: %04h,   your_reg[ 6]: %04h,   your_reg[ 7]: %04h ", My_CPU.core_r4, My_CPU.core_r5, My_CPU.core_r6, My_CPU.core_r7);
				$display("  golden_reg[ 8]: %04h, golden_reg[ 9]: %04h, golden_reg[10]: %04h, golden_reg[11]: %04h ", golden_reg[8],golden_reg[9],golden_reg[10],golden_reg[11]);
				$display("    your_reg[ 8]: %04h,   your_reg[ 9]: %04h,   your_reg[10]: %04h,   your_reg[11]: %04h ", My_CPU.core_r8, My_CPU.core_r9, My_CPU.core_r10, My_CPU.core_r11);
				$display("  golden_reg[12]: %04h, golden_reg[13]: %04h, golden_reg[14]: %04h, golden_reg[15]: %04h ", golden_reg[12],golden_reg[13],golden_reg[14],golden_reg[15]);
				$display("    your_reg[12]: %04h,   your_reg[13]: %04h,   your_reg[14]: %04h,   your_reg[15]: %04h ", My_CPU.core_r12, My_CPU.core_r13, My_CPU.core_r14, My_CPU.core_r15);
				$display("----------------------------------------------------------------------------------------");
				@(negedge clk);
				$finish;
			end
			// if(inst_num == 10)begin
				inst_num = 0;
				for(i=4096;i<8192;i=i+2)begin
					if(u_DRAM_data.DRAM_r[i] !== golden_DRAM_data[i] || u_DRAM_data.DRAM_r[i+1] !== golden_DRAM_data[i+1])begin
						display_fail;
						$display("----------------------------------------------------------------------------------------");
						$display("                                    Pattern NO.%5d                                   ", patcount);
						$display("     ADDR:%4h   Your:%2h  Ans:%2h                              ",i, {u_DRAM_data.DRAM_r[i+1],u_DRAM_data.DRAM_r[i]}, {golden_DRAM_data[i+1],golden_DRAM_data[i]});
						$display("----------------------------------------------------------------------------------------");
						@(negedge clk);
						$finish;
					end
				end
			// end
		end
		// $display("Pattern %3d PASS",patcount);
	end
endtask


//================================================================
// Reset task
//================================================================

task golden_reset;
golden_pc = 0;
golden_addr = 16'h1000;
golden_inst_data = 16'h0;

for(int r = 0; r < 16; r = r + 1)begin
	golden_reg[r] = 0;
end

endtask

task reset_task;
	begin
		#(CYCLE);
			rst_n = 0;
		#(CYCLE);
			rst_n = 1 ;
			if(IO_stall === 1)begin
				end
			else begin
				display_fail;
				$display("----------------------------------------------------------------------------------------");
				$display("                 Output signal should be 1 after initial RESET at %3d ns                ", $time);
				$display("----------------------------------------------------------------------------------------");
				$finish ;
				end
			if(	(My_CPU.core_r0 !== 0) || (My_CPU.core_r8  !== 0) ||
				(My_CPU.core_r1 !== 0) || (My_CPU.core_r9  !== 0) ||
				(My_CPU.core_r2 !== 0) || (My_CPU.core_r10 !== 0) ||
				(My_CPU.core_r3 !== 0) || (My_CPU.core_r11 !== 0) ||
				(My_CPU.core_r4 !== 0) || (My_CPU.core_r12 !== 0) ||
				(My_CPU.core_r5 !== 0) || (My_CPU.core_r13 !== 0) ||
				(My_CPU.core_r6 !== 0) || (My_CPU.core_r14 !== 0) ||
				(My_CPU.core_r7 !== 0) || (My_CPU.core_r15 !== 0) ) begin
				$display("----------------------------------------------------------------------------------------");
				$display("                   registers should be 0 after initial RESET at %3d ns                  ", $time);
				$display("----------------------------------------------------------------------------------------");
				$finish ;
				end
		#(CYCLE);
			release clk;
		end
	endtask
//================================================================
// Display task
//================================================================
task display_fail;
	begin

    $display ("    .-----------.    ");
    $display ("    |.---------.|    ");
    $display ("    ||>Error#  ||    ");
    $display ("    ||         ||    ");
    $display ("    |'---------'|    ");
    $display ("  .-^-----------^-.  ");
    $display ("  | ---~          |  ");
    $display ("  '---------------'  ");
		end
	endtask

task display_pass;
	begin
		$display ("------------------------------------------------------------------");
		$display ("                     Congratulations!                             ");
		$display ("              You have passed all patterns!                       ");
		$display ("           Your execution cycles   = %5d cycles                   ", total_cycles);
		$display ("           Your clock period       = %.1f ns                      ", `CYCLE_TIME);
		$display ("           Total latency           = %.1f ns                      ", total_cycles*`CYCLE_TIME );
		$display ("------------------------------------------------------------------");

	end
	endtask
endmodule
