//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NYCU ED430
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2021 Fall
//   Midterm Proejct            : MRA  
//   Author                     : Lin-Hung, Lai
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : MRA.v
//   Module Name : MRA
//   Release version : V1.0 (Release Date: 2021-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module MRA(
	// CHIP IO
	clk            	,	
	rst_n          	,	
	in_valid       	,	
	frame_id        ,	
	net_id         	,	  
	loc_x          	,	  
    loc_y         	,
	cost	 		,		
	busy         	,

    // AXI4 IO
	     arid_m_inf,
	   araddr_m_inf,
	    arlen_m_inf,
	   arsize_m_inf,
	  arburst_m_inf,
	  arvalid_m_inf,
	  arready_m_inf,
	
	      rid_m_inf,
	    rdata_m_inf,
	    rresp_m_inf,
	    rlast_m_inf,
	   rvalid_m_inf,
	   rready_m_inf,
	
	     awid_m_inf,
	   awaddr_m_inf,
	   awsize_m_inf,
	  awburst_m_inf,
	    awlen_m_inf,
	  awvalid_m_inf,
	  awready_m_inf,
	
	    wdata_m_inf,
	    wlast_m_inf,
	   wvalid_m_inf,
	   wready_m_inf,
	
	      bid_m_inf,
	    bresp_m_inf,
	   bvalid_m_inf,
	   bready_m_inf 
);
// ===============================================================
//  					Parameter Declaration 
// ===============================================================
parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32;    // DO NOT modify AXI4 Parameter
parameter NUM_ROW = 64, NUM_COLUMN = 64; 				
parameter MAX_NUM_MACRO = 15;


// ===============================================================
//  					Input / Output 
// ===============================================================

// << CHIP io port with system >>
input 			  	clk,rst_n;
input 			   	in_valid;
input  [4:0] 		frame_id;
input  [3:0]       	net_id;     
input  [5:0]       	loc_x; 
input  [5:0]       	loc_y; 
output wire [13:0] 	cost;
output wire         busy;       
  
// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
       Your AXI-4 interface could be designed as a bridge in submodule,
	   therefore I declared output of AXI as wire.  
	   Ex: AXI4_interface AXI4_INF(...);
*/

// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)	axi read address channel 
output wire [ID_WIDTH-1:0]      arid_m_inf;
output wire [1:0]            arburst_m_inf;
output wire [2:0]             arsize_m_inf;
output wire [7:0]              arlen_m_inf;
output wire                  arvalid_m_inf;
input  wire                  arready_m_inf;
output reg  [ADDR_WIDTH-1:0]  araddr_m_inf;
// ------------------------
// (2)	axi read data channel 
input  wire [ID_WIDTH-1:0]       rid_m_inf;
input  wire                   rvalid_m_inf;
output wire                   rready_m_inf;
input  wire [DATA_WIDTH-1:0]   rdata_m_inf;
input  wire                    rlast_m_inf;
input  wire [1:0]              rresp_m_inf;
// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1) 	axi write address channel 
output wire [ID_WIDTH-1:0]      awid_m_inf;
output wire [1:0]            awburst_m_inf;
output wire [2:0]             awsize_m_inf;
output wire [7:0]              awlen_m_inf;
output wire                  awvalid_m_inf;
input  wire                  awready_m_inf;
output reg  [ADDR_WIDTH-1:0]  awaddr_m_inf;
// -------------------------
// (2)	axi write data channel 
output wire                   wvalid_m_inf;
input  wire                   wready_m_inf;
output wire [DATA_WIDTH-1:0]   wdata_m_inf;
output reg                     wlast_m_inf;
// -------------------------
// (3)	axi write response channel 
input  wire  [ID_WIDTH-1:0]      bid_m_inf;
input  wire                   bvalid_m_inf;
output wire                   bready_m_inf;
input  wire  [1:0]             bresp_m_inf;
// -----------------------------

// ===============================================================
//  					Finite State Machine
// ===============================================================

reg [2:0] cur_state, nxt_state;

parameter IDLE           = 3'd0;
parameter DRAM_READ_MAP  = 3'd1;
parameter COMPUTE        = 3'd2;
parameter RETRACE        = 3'd3;
parameter DRAM_WRITE     = 3'd4;



// ===============================================================
//  					Variable Declare
// ===============================================================
integer i, j, k;


// ===============================================================
//  					FLAGS
// ===============================================================


reg retrace_write_flag, retrace_write_flag_d1;
reg read_weight_done, read_weight_done_d1;
reg read_weight_done_and_retrace_d1, read_weight_done_and_retrace_d2, 
    read_weight_done_and_retrace_d3, read_weight_done_and_retrace_d4,read_weight_done_and_retrace_d5;
reg step_flag, step_flag_d1;
wire compute_done;
wire retrace_done;
reg in_valid_d1;

reg in_source_bool;



wire idle_flag              = cur_state == IDLE;
wire dram_read_map_flag     = cur_state == DRAM_READ_MAP;
wire nxt_dram_read_map_flag = nxt_state == DRAM_READ_MAP && !dram_read_map_flag;
wire compute_flag           = cur_state == COMPUTE;
wire nxt_compute_flag       = nxt_state == COMPUTE && !compute_flag;
reg compute_flag_d1, compute_flag_d2;
wire retrace_flag           = cur_state == RETRACE;
wire nxt_retrace_flag       = nxt_state == RETRACE && !retrace_flag;
reg  retrace_flag_d1, retrace_flag_d2;
wire dram_write_flag        = cur_state == DRAM_WRITE;
wire nxt_dram_write_flag    = nxt_state == DRAM_WRITE && !dram_write_flag;


always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		in_valid_d1 <= 1'b0;
	else
		in_valid_d1 <= in_valid;
end


always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		step_flag_d1 <= 1'b0;
	else
		step_flag_d1 <= step_flag;
end


always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		compute_flag_d1 <= 1'b0;
		compute_flag_d2 <= 1'b0;
	end else begin
		compute_flag_d1 <= compute_flag;
		compute_flag_d2 <= compute_flag_d1;
	end
end

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		read_weight_done_d1 <= 1'b0;
	else
		read_weight_done_d1 <= read_weight_done;
end

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		read_weight_done_and_retrace_d1 <= 1'b0;
		read_weight_done_and_retrace_d2 <= 1'b0;
		read_weight_done_and_retrace_d3 <= 1'b0;
		read_weight_done_and_retrace_d4 <= 1'b0;
		read_weight_done_and_retrace_d5 <= 1'b0;
	end else begin
		read_weight_done_and_retrace_d1 <= read_weight_done && retrace_flag;
		read_weight_done_and_retrace_d2 <= read_weight_done_and_retrace_d1;
		read_weight_done_and_retrace_d3 <= read_weight_done_and_retrace_d2;
		read_weight_done_and_retrace_d4 <= read_weight_done_and_retrace_d3;
		read_weight_done_and_retrace_d5 <= read_weight_done_and_retrace_d4;
	end
end



always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		retrace_flag_d1 <= 1'b0;
		retrace_flag_d2 <= 1'b0;
	end else begin
		retrace_flag_d1 <= retrace_flag;
		retrace_flag_d2 <= retrace_flag_d1;
	end
end


// ===============================================================
//  					Input Register
// ===============================================================
reg [4:0] frame_id_r;
reg [3:0] net_id_r [0:14];
reg [5:0] source_x_r [0:14];
reg [5:0] source_y_r [0:14];
reg [5:0] sink_x_r [0:14];
reg [5:0] sink_y_r [0:14];


wire [5:0] source_x, source_x_nxt;
wire [5:0] source_y, source_y_nxt;
wire [5:0] sink_x;
wire [5:0] sink_y;




// ===============================================================
//  					Counter / Others
// ===============================================================

reg [6:0] cnt, location_map_cnt, location_map_cnt_nxt;
reg       path_cnt, path_cnt_d1;
reg [3:0] process_num, process_num_nxt;
reg [3:0] target_num;
reg [3:0] cur_target;


reg [5:0] retrace_x_r, retrace_x_nxt, retrace_x_r_d1, retrace_x_r_d2;
reg [5:0] retrace_y_r, retrace_y_nxt;

wire signed [6:0] retrace_x_m_1 = retrace_x_r-1;
wire signed [6:0] retrace_x_p_1 = retrace_x_r+1;
wire signed [6:0] retrace_y_m_1 = retrace_y_r-1;
wire signed [6:0] retrace_y_p_1 = retrace_y_r+1;


always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		path_cnt_d1 <= 1'b0;
	else
		path_cnt_d1 <= path_cnt;
end


always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		retrace_x_r_d1 <= 6'b0;
		retrace_x_r_d2 <= 6'b0;
	end else begin
		retrace_x_r_d1 <= retrace_x_r;
		retrace_x_r_d2 <= retrace_x_r_d1;
	end
end



reg [127:0] write_back_target;



// ===============================================================
//  					Data Register
// ===============================================================

reg [1:0] map_state_nxt [0:63][0:63];  // 0:empty, 1: Blocked, 2:state_1, 3:state_2
reg [1:0] map_state_r [0:63][0:63];  // 0:empty, 1: Blocked, 2:state_1, 3:state_2


// ===============================================================
//  					Output Register
// ===============================================================

reg [13:0] total_cost;

assign cost = total_cost;

// ===============================================================
//  					SRAM 
// ===============================================================

wire [127:0] Q_w, Q_m;
wire wen_w, wen_m;
wire [6:0] addr_w, addr_m;
wire [127:0] D_w, D_m;

reg [127:0] weight_Q_r;
wire [3:0] weight_4b;


RA1SH LOCATION_MAP (.Q(Q_m),.CLK(clk),.CEN(1'b0),.WEN(wen_m),.A(addr_m),.D(D_m),.OEN(1'b0));   //128-bit x 128
RA1SH WEIGHT       (.Q(Q_w),.CLK(clk),.CEN(1'b0),.WEN(wen_w),.A(addr_w),.D(D_w),.OEN(1'b0));   //128-bit x 128


// ===============================================================
//  					AXI4 Interfaces
// ===============================================================


// << Burst & ID >>
assign arid_m_inf    = 4'd0; 			// fixed id to 0 
assign arburst_m_inf = 2'd1;		// fixed mode to INCR mode 
assign arsize_m_inf  = 3'b100;		// fixed size to 2^4 = 16 Bytes 
assign arlen_m_inf   = 8'd127;

// << Burst & ID >>
assign awid_m_inf    = 4'd0;
assign awburst_m_inf = 2'd1;
assign awsize_m_inf  = 3'b100;
assign awlen_m_inf   = 8'd127;


reg axi_arvalid;
reg axi_rready;
reg axi_awvalid;
reg axi_wvalid;
reg axi_bready;

assign arvalid_m_inf = axi_arvalid;
assign rready_m_inf = axi_rready;
assign awvalid_m_inf = axi_awvalid;
assign wvalid_m_inf = axi_wvalid;
assign bready_m_inf = axi_bready;






////////////////////////////////////////////////////////////////////

assign busy = !in_valid_d1 && !idle_flag;




// ===============================================================
//  					Input Register Logic
// ===============================================================

assign source_x_nxt = source_x_r[process_num_nxt];
assign source_y_nxt = source_y_r[process_num_nxt];
assign source_x   = source_x_r[process_num];
assign source_y   = source_y_r[process_num];
assign sink_x     = sink_x_r[process_num];
assign sink_y     = sink_y_r[process_num];




always@(*)
	cur_target = net_id_r[process_num];


always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
	    frame_id_r <= 5'b0;
	else
	    if(in_valid)
			frame_id_r <= frame_id;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
	begin
		for(i=0;i<15;i=i+1)
		begin
			source_x_r[i] <= 5'b0;
			source_y_r[i] <= 5'b0;
		end
	end else begin
	    if(in_valid && in_source_bool)
		begin
			source_x_r[cnt] <= loc_x;
			source_y_r[cnt] <= loc_y;
		end 
	end
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
	begin
		for(i=0;i<15;i=i+1)
		begin
			sink_x_r[i] <= 5'b0;
			sink_y_r[i] <= 5'b0;
			net_id_r[i] <= 4'b0;
		end
	end else begin
	    if(in_valid && ~in_source_bool)
		begin
			sink_x_r[cnt] <= loc_x;
			sink_y_r[cnt] <= loc_y;
			net_id_r[cnt] <= net_id;
		end 
	end
end






always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
		process_num <= 4'b0;
	else 
	    process_num <= process_num_nxt;
end

always@(*)
begin
	if(retrace_done && retrace_flag)
		process_num_nxt = process_num + 1;
	else if(idle_flag)
		process_num_nxt = 4'b0;
	else
		process_num_nxt = process_num;

end


always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
		target_num <= 4'b0;
	else 
	    if(in_valid)
			target_num <= cnt;
end


// ===============================================================
//  					64 x 2 5-bit comparator
// ===============================================================



reg [5:0] comp_x_op, comp_y_op;



always@(*)
begin
	if(~compute_flag_d1 && compute_flag)
	begin
		comp_x_op = source_x;
		comp_y_op = source_y;
	end else if(~compute_flag_d2 && compute_flag_d1)
	begin
		comp_x_op = sink_x;
		comp_y_op = sink_y;
	end else if(retrace_flag)
	begin
		comp_x_op = retrace_x_r;
		comp_y_op = retrace_y_r;
	end else begin
		comp_x_op = 6'b0;
		comp_y_op = 6'b0;
	end

end


// ===============================================================
//  					64 x 64 2-bit XOR
// ===============================================================







always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
	    cur_state <= IDLE;
	else
	    cur_state <= nxt_state;
end



always@(*)
begin
	case(cur_state)
		IDLE:
			if(in_valid)
				nxt_state = DRAM_READ_MAP;
			else
				nxt_state = cur_state;
		DRAM_READ_MAP:
			if(rlast_m_inf)
				nxt_state = COMPUTE;
			else
				nxt_state = cur_state;
		COMPUTE:
			if(compute_done)
				nxt_state = RETRACE;
			else
				nxt_state = cur_state;
		RETRACE:
			if(retrace_done)
				if(process_num == target_num)
					nxt_state = DRAM_WRITE;
				else
					nxt_state = COMPUTE;
			else
				nxt_state = cur_state;
		DRAM_WRITE:
			if(bvalid_m_inf) 
				nxt_state = IDLE;
			else
				nxt_state = cur_state;
		default:
			nxt_state = cur_state;
	endcase
end



assign compute_done = map_state_r[sink_y][sink_x][1] && compute_flag;
assign retrace_done = retrace_x_r == source_x && retrace_y_r == source_y;




assign weight_4b = weight_Q_r[retrace_x_r_d2[4:0]*4 +: 4];


always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		total_cost <= 14'b0;
	else begin
		if(in_valid)
			total_cost <= 14'b0;

		else if(read_weight_done_and_retrace_d5 && retrace_flag_d2 && retrace_write_flag_d1)
			total_cost <= total_cost + weight_4b ;
	end
end



always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
		for(i=0;i<64;i=i+1)
		    for(j=0;j<64;j=j+1)
				map_state_r[i][j] <= 2'd0;
	else begin
		for(i=0;i<64;i=i+1)
		    for(j=0;j<64;j=j+1)
				map_state_r[i][j] <= map_state_nxt[i][j];
	end
end

always@(*)
begin
	if(~compute_flag_d2 && compute_flag_d1) //set the sink to 0 at the second cycle of COMPUTE state
	begin
		for(i=2;i<62;i=i+1)
			for(j=2;j<62;j=j+1)
				if(comp_y_op == i && comp_x_op == j)
					map_state_nxt[i][j] = 2'd0;
				else
					map_state_nxt[i][j] = map_state_r[i][j];
		for(i=0;i<2;i=i+1)
			for(j=0;j<64;j=j+1)
				map_state_nxt[i][j] = map_state_r[i][j];
		for(i=62;i<64;i=i+1)
			for(j=0;j<64;j=j+1)
				map_state_nxt[i][j] = map_state_r[i][j];
		
		for(i=2;i<64;i=i+1)
			for(j=0;j<2;j=j+1)
				map_state_nxt[i][j] = map_state_r[i][j];
		for(i=2;i<64;i=i+1)
			for(j=62;j<64;j=j+1)
				map_state_nxt[i][j] = map_state_r[i][j];
	end else if(~compute_flag_d1 && compute_flag)   //set the source to 2 at the first cycle of compute
	begin
		for(i=2;i<62;i=i+1)
			for(j=2;j<62;j=j+1)
				if(comp_y_op == i && comp_x_op == j)
					map_state_nxt[i][j] = 2'd2;
				else
					map_state_nxt[i][j] = map_state_r[i][j];
		for(i=0;i<2;i=i+1)
			for(j=0;j<64;j=j+1)
				map_state_nxt[i][j] = map_state_r[i][j];
		for(i=62;i<64;i=i+1)
			for(j=0;j<64;j=j+1)
				map_state_nxt[i][j] = map_state_r[i][j];
		
		for(i=2;i<64;i=i+1)
			for(j=0;j<2;j=j+1)
				map_state_nxt[i][j] = map_state_r[i][j];
		for(i=2;i<64;i=i+1)
			for(j=62;j<64;j=j+1)
				map_state_nxt[i][j] = map_state_r[i][j];
	end else if(retrace_done)
	begin
		for(i=0;i<64;i=i+1)
			for(j=0;j<64;j=j+1)
				map_state_nxt[i][j] = {1'b0, {(~map_state_r[i][j][1]) & map_state_r[i][j][0]}};//{2{&map_state_r[i][j]}};
					
	end else if(dram_read_map_flag && rvalid_m_inf)
	begin
				
		for(i=32;i<64;i=i+1)
			map_state_nxt[63][i] = {1'b0,|rdata_m_inf[(i-32)*4 +: 4]};

		for(i=0;i<63;i=i+1)
			for(j=0;j<32;j=j+1)
				map_state_nxt[i][j]  = map_state_r[i][j+32];
		for(i=0;i<63;i=i+1)
			for(j=32;j<64;j=j+1)
				map_state_nxt[i][j] = map_state_r[i+1][j-32];
		for(i=0;i<32;i=i+1)
			map_state_nxt[63][i] = map_state_r[63][i+32];
		

	end else if(compute_flag)  //Lee's Algorithm
	begin
		for(i=1;i<63;i=i+1)
			for(j=1;j<63;j=j+1)
				if(map_state_r[i][j] == 2'd0 && ( map_state_r[i-1][j][1] | map_state_r[i+1][j][1] | map_state_r[i][j-1][1] | map_state_r[i][j+1][1]))
					map_state_nxt[i][j] = {1'b1,path_cnt};
				else
					map_state_nxt[i][j] = map_state_r[i][j];
		for(j=1;j<63;j=j+1)
		begin
			if(map_state_r[0][j] == 2'd0 && ( map_state_r[0][j-1][1] | map_state_r[0][j+1][1] | map_state_r[1][j][1]))
				map_state_nxt[0][j] = {1'b1,path_cnt};
			else
				map_state_nxt[0][j] = map_state_r[0][j];
				
			if(map_state_r[63][j] == 2'd0 && ( map_state_r[63][j-1][1] | map_state_r[63][j+1][1] | map_state_r[62][j][1]))
				map_state_nxt[63][j] = {1'b1,path_cnt};
			else
				map_state_nxt[63][j] = map_state_r[63][j];
		end
		
		for(i=1;i<63;i=i+1)
		begin
			if(map_state_r[i][0] == 2'd0 && ( map_state_r[i-1][0][1] | map_state_r[i+1][0][1] | map_state_r[i][1][1]))
				map_state_nxt[i][0] = {1'b1,path_cnt};
			else
				map_state_nxt[i][0] = map_state_r[i][0];
				
			if(map_state_r[i][63] == 2'd0 && ( map_state_r[i-1][63][1] | map_state_r[i+1][63][1] | map_state_r[i][62][1]))
				map_state_nxt[i][63] = {1'b1,path_cnt};
			else
				map_state_nxt[i][63] = map_state_r[i][63];
		end
		
		if(map_state_r[0][0] == 2'd0 && ( map_state_r[0][1][1] | map_state_r[1][0][1]))
			map_state_nxt[0][0] = {1'b1,path_cnt};
		else
			map_state_nxt[0][0] = map_state_r[0][0];
			
		if(map_state_r[0][63] == 2'd0 && ( map_state_r[0][62][1] | map_state_r[1][63][1]))
			map_state_nxt[0][63] = {1'b1,path_cnt};
		else
			map_state_nxt[0][63] = map_state_r[0][63];
			
		if(map_state_r[63][0] == 2'd0 && ( map_state_r[62][0][1] | map_state_r[63][1][1]))
			map_state_nxt[63][0] = {1'b1,path_cnt};
		else
			map_state_nxt[63][0] = map_state_r[63][0];
			
		if(map_state_r[63][63] == 2'd0 && ( map_state_r[62][63][1] | map_state_r[63][62][1]))
			map_state_nxt[63][63] = {1'b1,path_cnt};
		else
			map_state_nxt[63][63] = map_state_r[63][63];
			
	end else if(retrace_flag && read_weight_done)
		for(i=0;i<64;i=i+1)
			for(j=0;j<64;j=j+1)
				if(comp_y_op == i && comp_x_op == j)
					map_state_nxt[i][j] = 2'd1;
				else
					map_state_nxt[i][j] = map_state_r[i][j];
	else
		for(i=0;i<64;i=i+1)
			for(j=0;j<64;j=j+1)
				map_state_nxt[i][j] = map_state_r[i][j];
			
end






always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		read_weight_done <= 1'b0;
	else begin
		if(rlast_m_inf && !dram_read_map_flag)
			read_weight_done <= 1'b1;
		else if(idle_flag)
			read_weight_done <= 1'b0;
	end
end




always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		step_flag <= 1'b0;
	else begin
		if(retrace_done)
			step_flag <= 1'b0;
		else if(compute_done)
			step_flag <= step_flag_d1;
		else if((compute_flag && compute_flag_d1 && !compute_done) || (retrace_flag && read_weight_done && retrace_write_flag))
			step_flag <= ~step_flag;
	end
end


always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		retrace_x_r <= 6'b0;
	else 
		retrace_x_r <= retrace_x_nxt;
end


reg [1:0] direction;

always@(*)
begin
	if(!retrace_y_p_1[6] && (map_state_r[retrace_y_p_1[5:0]][retrace_x_r] == {{1'b1,path_cnt}}))  //down
		direction = 2'b00;
	else if(!retrace_y_m_1[6] && (map_state_r[retrace_y_m_1[5:0]][retrace_x_r] == {{1'b1,path_cnt}})) //up
		direction = 2'b01;
	else if(!retrace_x_p_1[6] && (map_state_r[retrace_y_r][retrace_x_p_1[5:0]] == {{1'b1,path_cnt}})) //right
		direction = 2'b10;
	else
		direction = 2'b11;
end 



always@(*)
begin
	if(retrace_write_flag)
		retrace_x_nxt = retrace_x_r;
	else if(read_weight_done_and_retrace_d1)//if(retrace_flag && read_weight_done_d1)  //first cycle of retrace is the sink itself
	begin
		case(direction)
			2'b00: retrace_x_nxt = retrace_x_r;
			2'b01: retrace_x_nxt = retrace_x_r;
			2'b10: retrace_x_nxt = retrace_x_p_1;
			2'b11: retrace_x_nxt = retrace_x_m_1;
		endcase
	end else
		retrace_x_nxt = sink_x;
end



always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		retrace_y_r <= 6'b0;
	else 
		retrace_y_r <= retrace_y_nxt;
end

always@(*)
begin
	if(retrace_write_flag)
		retrace_y_nxt = retrace_y_r;
	else if(read_weight_done_and_retrace_d1)//if(retrace_flag && read_weight_done_d1)
	begin
		case(direction)
			2'b00: retrace_y_nxt = retrace_y_p_1;
			2'b01: retrace_y_nxt = retrace_y_m_1;
			2'b10: retrace_y_nxt = retrace_y_r;
			2'b11: retrace_y_nxt = retrace_y_r;
		endcase
	end else
		retrace_y_nxt = sink_y;
end



always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		path_cnt <= 1'b0;
	else begin
		if(retrace_done)
			path_cnt <= 1'b0;
		else if(compute_done)
			path_cnt <= path_cnt_d1;
		else if((compute_flag && compute_flag_d1 && !compute_done) || (retrace_flag && read_weight_done && retrace_write_flag))
		begin
			case({path_cnt,step_flag})
				2'b00:
					if(compute_flag && compute_flag_d1)
						path_cnt <= 1'b0;
					else
						path_cnt <= 1'b1;
				2'b01:
					if(compute_flag && compute_flag_d1)
						path_cnt <= 1'b1;
					else
						path_cnt <= 1'b0;
				2'b10:
					if(compute_flag && compute_flag_d1)
						path_cnt <= 1'b1;
					else
						path_cnt <= 1'b0;
				2'b11:
					if(compute_flag && compute_flag_d1)
						path_cnt <= 1'b0;
					else
						path_cnt <= 1'b1;
			endcase
		end
	end
end
	

// ===============================================================
//  			             Weight SRAM Logic
// ===============================================================


assign D_w = rdata_m_inf;
assign wen_w  = !(rvalid_m_inf && !dram_read_map_flag);
assign addr_w = wen_w ? {retrace_y_r,retrace_x_r[5]} : cnt;  


always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		weight_Q_r <= 128'b0;
	else if(dram_write_flag)
		weight_Q_r <= Q_m;
	else
		weight_Q_r <= Q_w;
end



// ===============================================================
//  			          Location Map SRAM Logic
// ===============================================================


assign D_m = retrace_flag ? write_back_target : rdata_m_inf;
assign wen_m  = !(rvalid_m_inf && dram_read_map_flag || retrace_flag && retrace_write_flag_d1);
assign addr_m = retrace_flag ? {retrace_y_r,retrace_x_r[5]} : 
				wready_m_inf ? location_map_cnt_nxt :
				location_map_cnt;



always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		retrace_write_flag <= 1'b0;
	else
		if(retrace_flag && read_weight_done)
			retrace_write_flag <= ~retrace_write_flag;
		else
			retrace_write_flag <= 1'b0;
end
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		retrace_write_flag_d1 <= 1'b0;
	else
		retrace_write_flag_d1 <= retrace_write_flag;
end



always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		location_map_cnt <= 7'b0;
	else
		location_map_cnt <= location_map_cnt_nxt;
end

always@(*)
begin
	if((rvalid_m_inf && dram_read_map_flag) || wready_m_inf)
		location_map_cnt_nxt = location_map_cnt + 1;
	else if(idle_flag)
		location_map_cnt_nxt = 7'b0;
	else
		location_map_cnt_nxt = location_map_cnt;
end


always@(*)
begin
	for(i=0;i<32;i=i+1)
		if(retrace_x_r[4:0] == i)
			write_back_target[i*4 +: 4] = cur_target;
		else
			write_back_target[i*4 +: 4] = Q_m[i*4 +: 4];//location_map[retrace_y_r][retrace_x_r[5]][i*4 +: 4];
end




// ===============================================================
//  					AXI4 Signal
// ===============================================================

always@(*)
begin
	if(axi_arvalid)
		if(dram_read_map_flag)
			araddr_m_inf = {{16'b 0000_0000_0000_0001}, frame_id_r , 11'b0};
		else
			araddr_m_inf = {{16'b 0000_0000_0000_0010}, frame_id_r , 11'b0};
	else
		araddr_m_inf = 32'b0;
end
	



always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		axi_arvalid <= 1'b0;
	else
		if(nxt_dram_read_map_flag || (!read_weight_done && nxt_compute_flag))
			axi_arvalid <= 1'b1;
		else if(arvalid_m_inf && arready_m_inf)
			axi_arvalid <= 1'b0;
end

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		axi_rready <= 1'b0;
	else
		if(arvalid_m_inf && arready_m_inf)
			axi_rready <= 1'b1;
		else if(rlast_m_inf)
			axi_rready <= 1'b0;
end





always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		axi_awvalid <= 1'b0;
	else
		if(nxt_dram_write_flag)
			axi_awvalid <= 1'b1;
		else if(awvalid_m_inf && awready_m_inf)
			axi_awvalid <= 1'b0;
end



always@(*)
begin
	if(axi_awvalid)
		awaddr_m_inf = {{16'b 0000_0000_0000_0001}, frame_id_r , 11'b0};
	else
		awaddr_m_inf = 32'b0;
end


assign wdata_m_inf = weight_Q_r;
//assign wlast_m_inf = wvalid_m_inf && location_map_cnt == 7'd127;
reg first_write;

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		wlast_m_inf <= 1'b0;
	else
		if(wlast_m_inf && wready_m_inf)
			wlast_m_inf <= 1'b0;
		else if(wvalid_m_inf && location_map_cnt == 7'd127)
			wlast_m_inf <= 1'b1;

end

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		axi_wvalid <= 1'b0;
	else
		if(wready_m_inf && (wlast_m_inf || first_write))
			axi_wvalid <= 1'b0;
		else if((awvalid_m_inf && awready_m_inf) || wready_m_inf)
			axi_wvalid <= 1'b1;

end


always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		first_write <= 1'b0;
	else
		if(idle_flag)
			first_write <= 1'b1;
		else if(first_write && wready_m_inf)
			first_write <= 1'b0;
end



always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		axi_bready <= 1'b0;
	else
		if(wready_m_inf && wlast_m_inf)
			axi_bready <= 1'b1;
		else if(bvalid_m_inf)
			axi_bready <= 1'b0;
end


always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		cnt <= 7'b0;
	else
		if((rvalid_m_inf && !dram_read_map_flag))
			cnt <= cnt + 1;
		else if(in_valid && ~in_source_bool)
			cnt <= cnt + 1;
		else if( compute_flag || in_valid)
			cnt <= cnt;
		else
			cnt <= 7'b0;
end


always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		in_source_bool <= 1'b0;
	else
		if(in_valid)
			in_source_bool <= ~in_source_bool;
		else
			in_source_bool <= 1'b1;
end




/*
// ===============================================================
//  					DEBUG LOGIC
// ===============================================================

reg [10:0] read_map_cycle;
reg [10:0] compute_cycle;
reg [10:0] retrace_cycle;
//reg [3:0] location [0:63][0:63];






always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		compute_cycle <= 11'b0;
	else if(in_valid || retrace_flag)
		compute_cycle <= 11'b0;
	else if(compute_flag)
		compute_cycle <= compute_cycle + 1;
end

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		retrace_cycle <= 11'b0;
	else if(in_valid || compute_flag)
		retrace_cycle <= 11'b0;
	else if(retrace_flag && read_weight_done)
		retrace_cycle <= retrace_cycle + 1;
end




always@(posedge clk)
begin
	if(compute_flag )
	begin
		$display(" Compute_CYCLE %3d", compute_cycle);
		$display(" Target:       %3d", cur_target);
		$display(" sink_x:       %3d", sink_x);
		$display(" sink_y:       %3d", sink_y);
		$display(" -------------");
		for(i=0;i<64;i=i+1)
		begin
			for(j=0;j<64;j=j+1)
				$write("%1d", map_state_r[i][j]);
			$display(" ");
		end
		$display(" -------------");
	end

end


always@(posedge clk)
begin
	if(retrace_flag && read_weight_done )
	begin
		if(retrace_cycle < 100)
		begin
		$display(" RETRACE %3d", retrace_cycle);
		$display(" Target:       %3d", cur_target);
		$display(" sink_x:       %3d", sink_x);
		$display(" sink_y:       %3d", sink_y);
		$display(" retrace_x_r:  %3d", retrace_x_r);
		$display(" retrace_y_r:  %3d", retrace_y_r);
		$display(" -------------");
		for(i=0;i<64;i=i+1)
		begin
			for(j=0;j<64;j=j+1)
				$write("%1d", map_state_r[i][j]);
			$display(" ");
		end
		$display(" -------------");
		
		
		end else
			$finish;
	end

end
*/

endmodule


