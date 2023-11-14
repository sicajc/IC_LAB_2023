//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NYCU ED430
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Midterm Proejct            : MRA
//   Author                     : Lin-Hung, Lai
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : MRA.v
//   Module Name : MRA
//   Release version : V2.0 (Release Date: 2023-10)
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
//  					Input / Output
// ===============================================================

// << CHIP io port with system >>
input 			  	clk,rst_n;
input 			   	in_valid;
input  [4:0] 		frame_id;
input  [3:0]       	net_id;
input  [5:0]       	loc_x;
input  [5:0]       	loc_y;
output reg [13:0] 	cost;
output reg          busy;


parameter ID_WIDTH = 4, DATA_WIDTH = 128, ADDR_WIDTH = 32;    // AXI4 Parameter

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
output reg [ADDR_WIDTH-1:0]  araddr_m_inf;
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
output reg [ADDR_WIDTH-1:0]  awaddr_m_inf;
// -------------------------
// (2)	axi write data channel
output wire                   wvalid_m_inf;
input  wire                   wready_m_inf;
output reg [DATA_WIDTH-1:0]   wdata_m_inf;
output wire                    wlast_m_inf;
// -------------------------
// (3)	axi write response channel
input  wire  [ID_WIDTH-1:0]      bid_m_inf;
input  wire                   bvalid_m_inf;
output wire                   bready_m_inf;
input  wire  [1:0]             bresp_m_inf;
// -----------------------------

// << Burst & ID >>
assign arid_m_inf    = 4'd0; 		// fixed id to 0
assign arburst_m_inf = 2'd1;		// fixed mode to INCR mode
assign arsize_m_inf  = 3'b100;		// fixed size to 2^4 = 16 Bytes
assign arlen_m_inf   = 8'd127;

// << Burst & ID >>
assign awid_m_inf    = 4'd0;
assign awburst_m_inf = 2'd1;
assign awsize_m_inf  = 3'b100;
assign awlen_m_inf   = 8'd127;

reg arvalid;
reg rready;
reg awvalid;
reg wvalid;
reg bready;

assign arvalid_m_inf = arvalid;


assign rready_m_inf = rready;
assign awvalid_m_inf = awvalid;
assign wvalid_m_inf = wvalid;
assign bready_m_inf = bready;



//==============================================//
//       parameter & integer declaration        //
//==============================================//
genvar gj,gk;
integer i,j;

parameter IDLE			= 3'd0;
parameter READ_DRAM		= 3'd1;
parameter WRITE_SRAM_W 	= 3'd2;
parameter WRITE_SRAM_L 	= 3'd3;
parameter WAIT_PATH		= 3'd4;
parameter WRITE_DRAM	= 3'd5;
parameter DRAM_DATA		= 3'd6;
parameter OUT	        = 3'd7;

parameter WAVE			= 3'd1;
parameter MAP_INIT	    = 3'd2;
parameter WAIT_RETRACE 	= 3'd4;
parameter RETRACE 		= 3'd5;
parameter NEXT_NET		= 3'd6;



//==============================================//
//           reg & wire declaration             //
//==============================================//
reg [2:0]state;
reg [2:0]n_state;
reg [2:0]l_state;
reg [2:0]n_l_state;

reg location_finish;

reg [4:0] frame_id_save;

reg [3:0] net_id_save [0:15];
reg [3:0] n_net_id_save [0:15];
reg [5:0] loc_x_save [0:1][0:15];
reg [5:0] n_loc_x_save [0:1][0:15];
reg [5:0] loc_y_save [0:1][0:15];
reg [5:0] n_loc_y_save [0:1][0:15];

reg [3:0] total_net;



reg [4:0] count_in, n_count_in;
reg in_flag_01;

reg [127:0]write_sram_weight;
reg [127:0]write_sram_location;


wire [127:0]read_sram_weight_wire;
wire [127:0]read_sram_location_wire;

reg [127:0]read_sram_weight;
reg [127:0]read_sram_location;

reg web_weight;
reg web_location;
reg [6:0]sram_weight_addr;
reg [6:0]sram_location_addr;

reg [6:0] count_addr, n_count_addr;

reg [1:0] path_map[0:63][0:63];
reg [1:0] n_path_map[0:63][0:63];
wire [5:0] y_map;
assign y_map = count_addr / 2;

reg [1:0]count_wave;
reg [1:0]wave_num;

wire [5:0]current_sink_x;
wire [5:0]current_sink_y;
assign current_sink_x = loc_x_save[1][0];
assign current_sink_y = loc_y_save[1][0];

wire [5:0]current_source_x;
wire [5:0]current_source_y;
assign current_source_x = loc_x_save[0][0];
assign current_source_y = loc_y_save[0][0];

wire [3:0]current_net_id;
assign current_net_id = net_id_save[0];

wire [5:0]left_right;
assign left_right = (count_addr % 2 == 0)?6'd0: 6'd32;

reg [5:0]retrace_x;
reg [5:0]retrace_y;

reg two_cycle_flag;

reg [1:0]count_retrace;
// assign count_retrace = count_wave-3;
reg [1:0]retrace_num;

wire [1:0]endpoint_value;
assign endpoint_value = path_map[current_sink_y][current_sink_x];

wire retrace_over;
assign retrace_over = ((retrace_y == current_source_y) &&(retrace_x == current_source_x));

reg [1:0]end_count;

reg [3:0]current_cost;

assign wlast_m_inf = (count_addr == 127 && state == DRAM_DATA)? 1'b1:1'b0;

//==============================================//
//                  design                      //
//==============================================//

//FSM
always@* begin
	case (state)
        IDLE: begin
            n_state = (in_valid)?READ_DRAM:IDLE;
        end
        READ_DRAM:begin
			if(arready_m_inf) n_state = (!location_finish)?WRITE_SRAM_L:WRITE_SRAM_W;
            else n_state = READ_DRAM;
        end
		WRITE_SRAM_L:begin
            n_state = (rvalid_m_inf && rlast_m_inf)?READ_DRAM:WRITE_SRAM_L;
        end
        WRITE_SRAM_W:begin
            n_state = (rvalid_m_inf && rlast_m_inf)?WAIT_PATH:WRITE_SRAM_W;
        end
		WAIT_PATH:begin
			n_state = (total_net == 1 && l_state == NEXT_NET)?WRITE_DRAM:WAIT_PATH;
		end
		WRITE_DRAM:begin
            n_state = (awready_m_inf)?DRAM_DATA:WRITE_DRAM;
        end
		DRAM_DATA:begin
            n_state = (bvalid_m_inf)?OUT:DRAM_DATA;
        end
		OUT:begin
            n_state = IDLE;
        end

		// default	 : n_state = IDLE;
	endcase
end
always@ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
        state <= IDLE;
    end
	else state <= n_state;
end

//little FSM
always@* begin
	case (l_state)
        IDLE: begin
            n_l_state = (arready_m_inf && (!location_finish))?WRITE_SRAM_L:IDLE;
        end
		WRITE_SRAM_L:begin
            n_l_state = (rvalid_m_inf && rlast_m_inf)?MAP_INIT:WRITE_SRAM_L;
        end
		MAP_INIT:begin
            n_l_state = WAVE;
        end
		WAVE:begin
            n_l_state = (path_map[current_sink_y][current_sink_x] != 0)?( (state == WRITE_SRAM_W)?WAIT_RETRACE:RETRACE):WAVE;
        end
		WAIT_RETRACE:begin
			n_l_state = (rvalid_m_inf && rlast_m_inf)?RETRACE:WAIT_RETRACE;
		end
		RETRACE:begin
            n_l_state = (retrace_over)?NEXT_NET:RETRACE;
        end
		NEXT_NET:begin
            n_l_state = (total_net == 1)?IDLE:MAP_INIT;
		end

		default	 : n_l_state = IDLE;
	endcase
end
always@ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
        l_state <= IDLE;
    end
	else l_state <= n_l_state;
end

//frame_id_save
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) frame_id_save <= 0;
	else if(in_valid) frame_id_save <= frame_id;
	else frame_id_save <= frame_id_save;
end

//count_in
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        count_in <= 0;
    else
        count_in <= n_count_in;
end
always@*begin
	if((state == READ_DRAM || state == WRITE_SRAM_L) && in_valid && in_flag_01)begin
		n_count_in = count_in + 1;
	end
	else if(state == OUT) n_count_in = 0;
	else n_count_in = count_in;
end

//count_addr
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        count_addr <= 0;
    else
        count_addr <= n_count_addr;
end
always@*begin
	if(rvalid_m_inf)begin
		n_count_addr = count_addr + 1;
	end
	else if((state == DRAM_DATA && wready_m_inf)) n_count_addr = count_addr + 1;
	else n_count_addr = count_addr;
end

//count_wave
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        count_wave <= 1;
	else if (state == IDLE || l_state == MAP_INIT) count_wave <= 1;
	else if(l_state == WAVE) count_wave <= count_wave + 1;
    else
        count_wave <= count_wave;
end

//count_retrace
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        count_retrace <= 0;
	else if (l_state == WAVE && endpoint_value != 0) count_retrace <= count_wave - 2;
	else if(l_state == RETRACE && two_cycle_flag) count_retrace <= count_retrace - 1;
    else
        count_retrace <= count_retrace;
end

//end_count
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        end_count <= 0;
	else if(l_state == WAVE && endpoint_value != 0) end_count <= count_wave - 1;
    else
        end_count <= end_count;
end

//wave_num
always@(*) begin
	case(count_wave)
	2'd0: wave_num = 2'd2;
	2'd1: wave_num = 2'd2;
	2'd2: wave_num = 2'd3;
	2'd3: wave_num = 2'd3;
	endcase
end

//retrace_num
always@(*) begin
	case(count_retrace)
	2'd0: retrace_num = 2'd2;
	2'd1: retrace_num = 2'd2;
	2'd2: retrace_num = 2'd3;
	2'd3: retrace_num = 2'd3;
	endcase
end


//net_id_save, n_net_id_save
generate
    for(gk=0;gk<16;gk=gk+1)begin:genfornet_id_save
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)begin
                net_id_save[gk] <= 0;
            end
            else begin
                net_id_save[gk] <= n_net_id_save[gk];
            end
		end
    end
endgenerate
always@(*)begin
	for(i=0;i<16;i=i+1)begin
		if(count_in == i)begin
			n_net_id_save[i] = net_id;
		end
		else if(l_state == NEXT_NET) begin
			case(i)
				0 :n_net_id_save[i] = net_id_save[1];
				1 :n_net_id_save[i] = net_id_save[2];
				2 :n_net_id_save[i] = net_id_save[3];
				3 :n_net_id_save[i] = net_id_save[4];
				4 :n_net_id_save[i] = net_id_save[5];
				5 :n_net_id_save[i] = net_id_save[6];
				6 :n_net_id_save[i] = net_id_save[7];
				7 :n_net_id_save[i] = net_id_save[8];
				8 :n_net_id_save[i] = net_id_save[9];
				9 :n_net_id_save[i] = net_id_save[10];
				10:n_net_id_save[i] = net_id_save[11];
				11:n_net_id_save[i] = net_id_save[12];
				12:n_net_id_save[i] = net_id_save[13];
				13:n_net_id_save[i] = net_id_save[14];
				14:n_net_id_save[i] = net_id_save[15];
				15:n_net_id_save[i] = 0;
			endcase
		end
		else if(state == OUT) n_net_id_save[i] = 0;
		else begin
			n_net_id_save[i] = net_id_save[i];
		end
	end
end

//loc_x_save, n_loc_x_save, loc_y_save, n_loc_y_save
generate
    for(gk=0;gk<16;gk=gk+1)begin:genforloc
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)begin
                loc_x_save[0][gk] <= 0;
				loc_x_save[1][gk] <= 0;
				loc_y_save[0][gk] <= 0;
				loc_y_save[1][gk] <= 0;
            end
            else begin
                loc_x_save[0][gk] <= n_loc_x_save[0][gk];
				loc_x_save[1][gk] <= n_loc_x_save[1][gk];
				loc_y_save[0][gk] <= n_loc_y_save[0][gk];
				loc_y_save[1][gk] <= n_loc_y_save[1][gk];
            end
        end
    end
endgenerate
always@(*)begin
	for(i=0;i<16;i=i+1)begin
		if(count_in == i && in_valid)begin
			if(in_flag_01)begin
				n_loc_x_save[1][i] = loc_x;
				n_loc_x_save[0][i] = loc_x_save[0][i];
			end
			else begin
				n_loc_x_save[0][i] = loc_x;
				n_loc_x_save[1][i] = loc_x_save[1][i];

			end
			//n_loc_x_save[in_flag_01][i] = loc_x;
			//n_loc_x_save[~in_flag_01][i] = loc_x_save[~in_flag_01][i];
		end
		else if(l_state == NEXT_NET)begin
			case(i)
			0: begin
				n_loc_x_save[0][i] = loc_x_save[0][1];
				n_loc_x_save[1][i] = loc_x_save[1][1];
			end
			1: begin
				n_loc_x_save[0][i] = loc_x_save[0][2];
				n_loc_x_save[1][i] = loc_x_save[1][2];
			end
			2: begin
				n_loc_x_save[0][i] = loc_x_save[0][3];
				n_loc_x_save[1][i] = loc_x_save[1][3];
			end
			3: begin
				n_loc_x_save[0][i] = loc_x_save[0][4];
				n_loc_x_save[1][i] = loc_x_save[1][4];
			end
			4: begin
				n_loc_x_save[0][i] = loc_x_save[0][5];
				n_loc_x_save[1][i] = loc_x_save[1][5];
			end
			5: begin
				n_loc_x_save[0][i] = loc_x_save[0][6];
				n_loc_x_save[1][i] = loc_x_save[1][6];
			end
			6: begin
				n_loc_x_save[0][i] = loc_x_save[0][7];
				n_loc_x_save[1][i] = loc_x_save[1][7];
			end
			7: begin
				n_loc_x_save[0][i] = loc_x_save[0][8];
				n_loc_x_save[1][i] = loc_x_save[1][8];
			end
			8: begin
				n_loc_x_save[0][i] = loc_x_save[0][9];
				n_loc_x_save[1][i] = loc_x_save[1][9];
			end
			9: begin
				n_loc_x_save[0][i] = loc_x_save[0][10];
				n_loc_x_save[1][i] = loc_x_save[1][10];
			end
			10: begin
				n_loc_x_save[0][i] = loc_x_save[0][11];
				n_loc_x_save[1][i] = loc_x_save[1][11];
			end
			11: begin
				n_loc_x_save[0][i] = loc_x_save[0][12];
				n_loc_x_save[1][i] = loc_x_save[1][12];
			end
			12: begin
				n_loc_x_save[0][i] = loc_x_save[0][13];
				n_loc_x_save[1][i] = loc_x_save[1][13];
			end
			13: begin
				n_loc_x_save[0][i] = loc_x_save[0][14];
				n_loc_x_save[1][i] = loc_x_save[1][14];
			end
			14: begin
				n_loc_x_save[0][i] = loc_x_save[0][15];
				n_loc_x_save[1][i] = loc_x_save[1][15];
			end
			15:	begin
				n_loc_x_save[0][i] = 6'd0;
				n_loc_x_save[1][i] = 6'd0;
			end

			endcase
		end
		else if(state == OUT)begin
			n_loc_x_save[0][i] = 6'd0;
			n_loc_x_save[1][i] = 6'd0;
		end
		else begin
			n_loc_x_save[0][i] = loc_x_save[0][i];
			n_loc_x_save[1][i] = loc_x_save[1][i];
		end
	end
end
always@*begin
	for(i=0;i<16;i=i+1)begin
		if(count_in == i && in_valid)begin
			if(in_flag_01)begin
				n_loc_y_save[1][i] = loc_y;
				n_loc_y_save[0][i] = loc_y_save[0][i];
			end
			else begin
				n_loc_y_save[0][i] = loc_y;
				n_loc_y_save[1][i] = loc_y_save[1][i];
			end
		end
		else if(l_state == NEXT_NET)begin
			case(i)
			0: begin
				n_loc_y_save[0][i] = loc_y_save[0][1];
				n_loc_y_save[1][i] = loc_y_save[1][1];
			end
			1: begin
				n_loc_y_save[0][i] = loc_y_save[0][2];
				n_loc_y_save[1][i] = loc_y_save[1][2];
			end
			2: begin
				n_loc_y_save[0][i] = loc_y_save[0][3];
				n_loc_y_save[1][i] = loc_y_save[1][3];
			end
			3: begin
				n_loc_y_save[0][i] = loc_y_save[0][4];
				n_loc_y_save[1][i] = loc_y_save[1][4];
			end
			4: begin
				n_loc_y_save[0][i] = loc_y_save[0][5];
				n_loc_y_save[1][i] = loc_y_save[1][5];
			end
			5: begin
				n_loc_y_save[0][i] = loc_y_save[0][6];
				n_loc_y_save[1][i] = loc_y_save[1][6];
			end
			6: begin
				n_loc_y_save[0][i] = loc_y_save[0][7];
				n_loc_y_save[1][i] = loc_y_save[1][7];
			end
			7: begin
				n_loc_y_save[0][i] = loc_y_save[0][8];
				n_loc_y_save[1][i] = loc_y_save[1][8];
			end
			8: begin
				n_loc_y_save[0][i] = loc_y_save[0][9];
				n_loc_y_save[1][i] = loc_y_save[1][9];
			end
			9: begin
				n_loc_y_save[0][i] = loc_y_save[0][10];
				n_loc_y_save[1][i] = loc_y_save[1][10];
			end
			10: begin
				n_loc_y_save[0][i] = loc_y_save[0][11];
				n_loc_y_save[1][i] = loc_y_save[1][11];
			end
			11: begin
				n_loc_y_save[0][i] = loc_y_save[0][12];
				n_loc_y_save[1][i] = loc_y_save[1][12];
			end
			12: begin
				n_loc_y_save[0][i] = loc_y_save[0][13];
				n_loc_y_save[1][i] = loc_y_save[1][13];
			end
			13: begin
				n_loc_y_save[0][i] = loc_y_save[0][14];
				n_loc_y_save[1][i] = loc_y_save[1][14];
			end
			14: begin
				n_loc_y_save[0][i] = loc_y_save[0][15];
				n_loc_y_save[1][i] = loc_y_save[1][15];
			end
			15:	begin
				n_loc_y_save[0][i] = 6'd0;
				n_loc_y_save[1][i] = 6'd0;
			end
			default: begin
				n_loc_y_save[0][i] = loc_y_save[0][i];
				n_loc_y_save[1][i] = loc_y_save[1][i];
			end
			endcase
		end
		else if(state == OUT)begin
			n_loc_y_save[0][i] = 6'd0;
			n_loc_y_save[1][i] = 6'd0;
		end
		else begin
			n_loc_y_save[0][i] = loc_y_save[0][i];
			n_loc_y_save[1][i] = loc_y_save[1][i];
		end
	end
end


//in_flag_01
always@(posedge clk or negedge rst_n)begin
	if(!rst_n) in_flag_01 <= 0;
	else if(in_valid) in_flag_01 <= !in_flag_01;
	else in_flag_01 <= 0;
end

//two_cycle_flag
always@(posedge clk or negedge rst_n)begin
	if(!rst_n) two_cycle_flag <= 0;
	else if(l_state == RETRACE) two_cycle_flag <= !two_cycle_flag;
	else two_cycle_flag <= 0;
end

//arvalid
always @(*) begin
	if(state == READ_DRAM) begin
		arvalid = 1;
		if(!location_finish) araddr_m_inf = {{16'b 0000_0000_0000_0001}, frame_id_save , 11'b0};
		else araddr_m_inf = {{16'b 0000_0000_0000_0010}, frame_id_save , 11'b0};
	end
	else begin
		arvalid = 0;
		araddr_m_inf = 32'd0;
	end
end


//web_weight
always@(*)begin
	if (rvalid_m_inf && state == WRITE_SRAM_W) web_weight = 0;
	else web_weight = 1;
end

//write_sram_weight
always@(*)begin
	if (rvalid_m_inf && state == WRITE_SRAM_W) write_sram_weight = rdata_m_inf;
	else write_sram_weight = 0;
end

//sram_weight_addr
always@(*)begin
	if (rvalid_m_inf && state == WRITE_SRAM_W) sram_weight_addr = count_addr;
	else if(l_state == RETRACE) sram_weight_addr = 2*retrace_y + ((retrace_x >= 6'd32)? 1:0);
	else sram_weight_addr = 0;
end



//location_finish
always@(posedge clk or negedge rst_n)begin
	if(!rst_n) location_finish <= 0;
	else if(rvalid_m_inf && rlast_m_inf) location_finish <= 1;
	else if(state == OUT) location_finish <= 0;
	else location_finish <= location_finish;
end

//web_location
always@(*)begin
	if (rvalid_m_inf && state == WRITE_SRAM_L) web_location = 0;
	else if(l_state ==RETRACE) web_location = !two_cycle_flag;
	else web_location = 1;
end

//write_sram_location
always@(*)begin
	if (rvalid_m_inf && state == WRITE_SRAM_L) write_sram_location = rdata_m_inf;
	else if (l_state == RETRACE) begin
		for(i =0 ; i < 32; i=i+1)begin
			if(i == (retrace_x % 32)) begin
				write_sram_location[(i*4)] = current_net_id[0];
				write_sram_location[(i*4)+1] = current_net_id[1];
				write_sram_location[(i*4)+2] = current_net_id[2];
				write_sram_location[(i*4)+3] = current_net_id[3];
			end
			else begin
				write_sram_location[(i*4)] = read_sram_location_wire[(i*4)+0];
				write_sram_location[(i*4)+1] = read_sram_location_wire[(i*4)+1];
				write_sram_location[(i*4)+2] = read_sram_location_wire[(i*4)+2];
				write_sram_location[(i*4)+3] = read_sram_location_wire[(i*4)+3];
			end
		end
	end
	else write_sram_location = 0;
end

//sram_location_addr
always@(*)begin
	if (rvalid_m_inf && state == WRITE_SRAM_L) sram_location_addr = count_addr;
	else if(l_state == RETRACE) sram_location_addr = 2*retrace_y + ((retrace_x >=32)?1:0);
	else if(awready_m_inf || state == DRAM_DATA) sram_location_addr = n_count_addr;
	else sram_location_addr = 0;
end

//rready
always @(*) begin
	if(state == WRITE_SRAM_W || state == WRITE_SRAM_L) rready = 1;
	else rready = 0;
end



//path_map
// always@(posedge clk or negedge rst_n)begin
// 	if(!rst_n)begin
// 		for(i=0;i<64;i=i+1)begin
// 			for(j=0;j<64;j=j+1)begin
// 				path_map[i][j] <= 0;
// 			end
// 		end
// 	end
// 	else begin
// 		case(l_state)
// 		WRITE_SRAM_L: begin
// 			for(j=0;j<32;j=j+1)begin
// 				path_map[y_map][j+left_right] <= ((rdata_m_inf[(j)*4 +: 4]!= 0))? 2'd1:2'd0;
// 			end
// 		end
// 		MAP_INIT:begin
// 			path_map[loc_y_save[0][0]][loc_x_save[0][0]] <= 2'd2;
// 			path_map[loc_y_save[1][0]][loc_x_save[1][0]] <= 2'd0;
// 		end
// 		WAVE:begin
// 			for(i=0;i<64;i=i+1)begin
// 				for(j=0;j<64;j=j+1)begin
// 					if(i == 0 && j == 0)begin
// 						if(path_map[i][j][1])begin
// 							if(path_map[1][0] == 2'd0)path_map[0][1] <= wave_num;
// 							if(path_map[0][1] == 2'd0)path_map[1][0] <= wave_num;
// 						end
// 					end
// 					else if(i == 0 && j == 63 )begin
// 						if(path_map[i][j][1])begin
// 							if(path_map[0][62] == 2'd0)path_map[0][62] <= wave_num;
// 							if(path_map[1][63] == 2'd0)path_map[1][63] <= wave_num;
// 						end
// 					end
// 					else if(i == 63 && j == 0 )begin
// 						if(path_map[i][j][1])begin
// 							if(path_map[62][0] == 2'd0)path_map[62][0] <= wave_num;
// 							if(path_map[63][0] == 2'd0)path_map[63][0] <= wave_num;
// 						end
// 					end
// 					else if(i == 63 && j == 63 )begin
// 						if(path_map[i][j][1])begin
// 							if(path_map[63][62] == 2'd0)path_map[63][62] <= wave_num;
// 							if(path_map[62][63] == 2'd0)path_map[62][63] <= wave_num;
// 						end
// 					end

// 					else if(i == 0)begin
// 						if(path_map[i][j][1])begin
// 							if(path_map[0][j-1] == 2'd0)path_map[0][j-1] <= wave_num;
// 							if(path_map[0][j+1] == 2'd0)path_map[0][j+1] <= wave_num;
// 							if(path_map[1][j]   == 2'd0)path_map[1][j]   <= wave_num;
// 						end
// 					end
// 					else if(i == 63)begin
// 						if(path_map[i][j][1])begin
// 							if(path_map[63][j-1] == 2'd0)path_map[63][j-1] <= wave_num;
// 							if(path_map[63][j+1] == 2'd0)path_map[63][j+1] <= wave_num;
// 							if(path_map[62][j]   == 2'd0)path_map[62][j]   <= wave_num;
// 						end
// 					end
// 					else if(j == 0)begin
// 						if(path_map[i][j][1])begin
// 							if(path_map[i-1][0] == 2'd0)path_map[i-1][0] <= wave_num;
// 							if(path_map[i+1][0] == 2'd0)path_map[i+1][0] <= wave_num;
// 							if(path_map[i][1]   == 2'd0)path_map[i][1] <= wave_num;
// 						end
// 					end
// 					else if(j == 63)begin
// 						if(path_map[i][j][1])begin
// 							if(path_map[i-1][63] == 2'd0)path_map[i-1][63] <= wave_num;
// 							if(path_map[i+1][63] == 2'd0)path_map[i+1][63] <= wave_num;
// 							if(path_map[i][62]   == 2'd0)path_map[i][62]   <= wave_num;
// 						end
// 					end
// 					else begin
// 						if(path_map[i][j][1])begin
// 							if(path_map[i-1][j] == 2'd0)path_map[i-1][j] <= wave_num;
// 							if(path_map[i+1][j] == 2'd0)path_map[i+1][j] <= wave_num;
// 							if(path_map[i][j-1] == 2'd0)path_map[i][j-1] <= wave_num;
// 							if(path_map[i][j+1] == 2'd0)path_map[i][j+1] <= wave_num;
// 						end
// 					end

// 				end
// 			end



// 		end
// 		RETRACE:begin
// 			path_map[retrace_y][retrace_x] <= 1;
// 		end
// 		NEXT_NET:begin
// 			for(i=0;i<64;i=i+1)begin
// 				for(j=0;j<64;j=j+1)begin
// 					if(path_map[i][j][1])
// 						path_map[i][j] <= 0;
// 				end
// 			end
// 		end
// 		// default: begin
// 		// 	for(i=0;i<64;i=i+1)begin
// 		// 		for(j=0;j<64;j=j+1)begin
// 		// 			path_map[i][j] <= path_map[i][j];
// 		// 		end
// 		// 	end
// 		// end
// 		endcase
// 	end
// end
always @(posedge clk)
begin
    if(l_state == IDLE)
    begin
        for(i=0;i<64;i=i+1)
            for(j=0;j<64;j=j+1)
                path_map[i][j] <= 0;
    end
    else
    begin
        for(i=0;i<64;i=i+1)
            for(j=0;j<64;j=j+1)
                path_map[i][j] <= n_path_map[i][j];
    end
end
always @(*)
begin
    case(l_state)
		WRITE_SRAM_L: begin
			for(i=32;i<64;i=i+1)begin
				n_path_map[63][i] = {1'b0,|rdata_m_inf[(i-32)*4 +: 4]};
			end

			for(i=0;i<63;i=i+1)begin
				for(j=0;j<32;j=j+1)begin
					n_path_map[i][j]  = path_map[i][j+32];
				end
			end
			for(i=0;i<63;i=i+1)begin
				for(j=32;j<64;j=j+1)begin
					n_path_map[i][j] = path_map[i+1][j-32];
				end
			end
			for(i=0;i<32;i=i+1)begin
				n_path_map[63][i] = path_map[63][i+32];
			end
		end
		MAP_INIT:begin
			// n_path_map[loc_y_save[0][0]][loc_x_save[0][0]] = 2'd2;
			// n_path_map[loc_y_save[1][0]][loc_x_save[1][0]] = 2'd0;
			for(i=0;i<64;i=i+1)begin
				for(j=0;j<64;j=j+1)begin
					if(i == current_source_y && j == current_source_x)
						n_path_map[i][j] = 2'd2;
					else if(i == current_sink_y && j == current_sink_x)
						n_path_map[i][j] = 2'd0;
					else
						n_path_map[i][j] = path_map[i][j];
				end
			end
		end
		WAVE:begin

			if(path_map[0][0] == 2'd0 && (path_map[1][0][1] | path_map[0][1][1]))begin
				n_path_map[0][0] = wave_num;
			end
			else n_path_map[0][0] = path_map[0][0];

			if(path_map[0][63] == 2'd0 && (path_map[0][62][1] | path_map[1][63][1]))begin
					n_path_map[0][63] = wave_num;
			end
			else n_path_map[0][63] = path_map[0][63];

			if(path_map[63][0] == 2'd0 && (path_map[62][0][1] | path_map[63][0][1]))begin
					n_path_map[63][0] = wave_num;
			end
			else n_path_map[63][0] = path_map[63][0];


			if(path_map[63][63] == 2'd0 && (path_map[63][62][1] | path_map[62][63][1]))begin
					n_path_map[63][63] = wave_num;
			end
			else n_path_map[63][63] = path_map[63][63];


			for(j=1;j<63;j=j+1)begin
				if(path_map[0][j] == 2'd0 && (path_map[0][j-1][1] | path_map[0][j+1][1] | path_map[1][j][1]))begin
						n_path_map[0][j] = wave_num;
				end
				else n_path_map[0][j] = path_map[0][j];
			end
			for(j=1;j<63;j=j+1)begin
				if(path_map[63][j] == 2'd0 && (path_map[63][j-1][1] | path_map[63][j+1][1] | path_map[62][j][1]))begin
						n_path_map[63][j] = wave_num;
				end
				else n_path_map[63][j] = path_map[63][j];
			end

			for(i=1;i<63;i=i+1)begin
				if(path_map[i][0] == 2'd0 && (path_map[i-1][0][1] | path_map[i+1][0][1] | path_map[i][1][1]))begin
						n_path_map[i][0] = wave_num;
				end
				else n_path_map[i][0] = path_map[i][0];
			end
			for(i=1;i<63;i=i+1)begin
				if(path_map[i][63] == 2'd0 && (path_map[i-1][63][1] | path_map[i+1][63][1] | path_map[i][62][1]))begin
						n_path_map[i][63] = wave_num;
				end
				else n_path_map[i][63] = path_map[i][63];
			end

			for(i=1;i<63;i=i+1)begin
				for(j=1;j<63;j=j+1)begin
					if(path_map[i][j] == 2'd0 && (path_map[i-1][j][1] | path_map[i+1][j][1] | path_map[i][j-1][1] | path_map[i][j+1][1]))begin
							n_path_map[i][j] = wave_num;
					end
					else n_path_map[i][j] = path_map[i][j];
				end
			end
		end
		RETRACE:begin
			for(i=0;i<64;i=i+1)begin
				for(j=0;j<64;j=j+1)begin
					if(i == retrace_y && j == retrace_x)
						n_path_map[i][j] = 1;
					else
						n_path_map[i][j] = path_map[i][j];
				end
			end

		end
		NEXT_NET:begin
			for(i=0;i<64;i=i+1)begin
				for(j=0;j<64;j=j+1)begin
					if(path_map[i][j][1])
						n_path_map[i][j] = 0;
					else
						n_path_map[i][j] = path_map[i][j];
				end
			end
		end


		default: begin
			for(i=0;i<64;i=i+1)begin
				for(j=0;j<64;j=j+1)begin
					n_path_map[i][j] = path_map[i][j];
				end
			end
		end
	endcase
end






//retrace_x
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) retrace_x <= 0;
	else if(l_state == WAIT_RETRACE || l_state == WAVE) retrace_x <= current_sink_x;
	else if(l_state == RETRACE)begin
		if(path_map[retrace_y+1][retrace_x] == retrace_num && two_cycle_flag) retrace_x <= retrace_x;
		else if(path_map[retrace_y-1][retrace_x] == retrace_num && two_cycle_flag) retrace_x <= retrace_x;
		else if(path_map[retrace_y][retrace_x+1] == retrace_num && two_cycle_flag) retrace_x <= retrace_x+1;
		else if(path_map[retrace_y][retrace_x-1] == retrace_num && two_cycle_flag) retrace_x <= retrace_x-1;
	end
	else retrace_x <= 0;
end

//retrace_y
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) retrace_y <= 0;
	else if(l_state == WAIT_RETRACE || l_state == WAVE) retrace_y <= current_sink_y;
	else if(l_state == RETRACE)begin
		if(path_map[retrace_y+1][retrace_x] == retrace_num && two_cycle_flag) retrace_y <= retrace_y+1;
		else if(path_map[retrace_y-1][retrace_x] == retrace_num && two_cycle_flag) retrace_y <= retrace_y-1;
		else if(path_map[retrace_y][retrace_x+1] == retrace_num && two_cycle_flag) retrace_y <= retrace_y;
		else if(path_map[retrace_y][retrace_x-1] == retrace_num && two_cycle_flag) retrace_y <= retrace_y;
	end
	else retrace_y <= 0;
end


//current_cost
always@(*)begin
	if (l_state == RETRACE && !(retrace_x == current_sink_x && retrace_y == current_sink_y)) begin
		current_cost = read_sram_weight_wire[((retrace_x % 32)*4)+: 4];
	end
	else current_cost = 0;
end

//total_net
always@(posedge clk or negedge rst_n)begin
	if (!rst_n) begin
		total_net <= 0;
	end
	else if(in_valid) total_net <= count_in+1;
	else if(l_state == NEXT_NET) total_net <= total_net - 1;
	else total_net <= total_net;
end

//awaddr
always @(*) begin
	if(state == WRITE_DRAM) begin
		awaddr_m_inf = {{16'b 0000_0000_0000_0001}, frame_id_save , 11'b0};
		awvalid = 1;
	end
	else begin
		awaddr_m_inf = 32'd0;
		awvalid = 0;
	end
end

//wvalid write data valid
always @(*) begin
	if(state == DRAM_DATA) begin
		wvalid = 1;
		wdata_m_inf = read_sram_location_wire;
	end
	else begin
		wvalid = 0;
		wdata_m_inf = read_sram_location_wire;
	end
end

// always @(*) begin
// 	if(1)begin
// 		wdata_m_inf = read_sram_location_wire;
// 	end
// 	else begin
// 		wdata_m_inf = read_sram_location_wire;
// 	end
// end


//bready
always @(*) begin
	if(state == DRAM_DATA) bready = 1;
	else bready = 0;
end

//busy
// always @(posedge clk or negedge rst_n) begin
// 	if (!rst_n) busy <= 0;
// 	else if( ((state == IDLE) && (!location_finish)) || in_valid ) busy <= 0;
// 	else if(state == OUT) busy <= 0;
// 	else busy <= 1;
// end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) busy <= 1'b0;
	else begin
		if(state == OUT)
			busy <= 1'b0;
		else if( ((state == IDLE) && (!location_finish)) || in_valid )
			busy <= 1'b0;
		else begin
			busy <= 1'b1;
		end
	end
end

//cost
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) cost <= 0;
	else if(l_state == RETRACE && two_cycle_flag) cost <= cost + current_cost;
	else if(state == IDLE) cost <= 0;
	else cost <= cost;
end



SRAM_128_128_1 sw(.A0(sram_weight_addr[0]),.A1(sram_weight_addr[1]),.A2(sram_weight_addr[2]),.A3(sram_weight_addr[3]),.A4(sram_weight_addr[4]),.A5(sram_weight_addr[5]),.A6(sram_weight_addr[6]),
.DO0(read_sram_weight_wire[0]),.DO1(read_sram_weight_wire[1]),.DO2(read_sram_weight_wire[2]),.DO3(read_sram_weight_wire[3]),.DO4(read_sram_weight_wire[4]),.DO5(read_sram_weight_wire[5]),.DO6(read_sram_weight_wire[6]),.DO7(read_sram_weight_wire[7]),
.DO8(read_sram_weight_wire[8]),.DO9(read_sram_weight_wire[9]),.DO10(read_sram_weight_wire[10]),.DO11(read_sram_weight_wire[11]),.DO12(read_sram_weight_wire[12]),.DO13(read_sram_weight_wire[13]),.DO14(read_sram_weight_wire[14]),.DO15(read_sram_weight_wire[15]),
.DO16(read_sram_weight_wire[16]),.DO17(read_sram_weight_wire[17]),.DO18(read_sram_weight_wire[18]),.DO19(read_sram_weight_wire[19]),.DO20(read_sram_weight_wire[20]),.DO21(read_sram_weight_wire[21]),.DO22(read_sram_weight_wire[22]),.DO23(read_sram_weight_wire[23]),
.DO24(read_sram_weight_wire[24]),.DO25(read_sram_weight_wire[25]),.DO26(read_sram_weight_wire[26]),.DO27(read_sram_weight_wire[27]),.DO28(read_sram_weight_wire[28]),.DO29(read_sram_weight_wire[29]),.DO30(read_sram_weight_wire[30]),.DO31(read_sram_weight_wire[31]),
.DO32(read_sram_weight_wire[32]),.DO33(read_sram_weight_wire[33]),.DO34(read_sram_weight_wire[34]),.DO35(read_sram_weight_wire[35]),.DO36(read_sram_weight_wire[36]),.DO37(read_sram_weight_wire[37]),.DO38(read_sram_weight_wire[38]),.DO39(read_sram_weight_wire[39]),
.DO40(read_sram_weight_wire[40]),.DO41(read_sram_weight_wire[41]),.DO42(read_sram_weight_wire[42]),.DO43(read_sram_weight_wire[43]),.DO44(read_sram_weight_wire[44]),.DO45(read_sram_weight_wire[45]),.DO46(read_sram_weight_wire[46]),.DO47(read_sram_weight_wire[47]),
.DO48(read_sram_weight_wire[48]),.DO49(read_sram_weight_wire[49]),.DO50(read_sram_weight_wire[50]),.DO51(read_sram_weight_wire[51]),.DO52(read_sram_weight_wire[52]),.DO53(read_sram_weight_wire[53]),.DO54(read_sram_weight_wire[54]),.DO55(read_sram_weight_wire[55]),
.DO56(read_sram_weight_wire[56]),.DO57(read_sram_weight_wire[57]),.DO58(read_sram_weight_wire[58]),.DO59(read_sram_weight_wire[59]),.DO60(read_sram_weight_wire[60]),.DO61(read_sram_weight_wire[61]),.DO62(read_sram_weight_wire[62]),.DO63(read_sram_weight_wire[63]),
.DO64(read_sram_weight_wire[64]),.DO65(read_sram_weight_wire[65]),.DO66(read_sram_weight_wire[66]),.DO67(read_sram_weight_wire[67]),.DO68(read_sram_weight_wire[68]),.DO69(read_sram_weight_wire[69]),.DO70(read_sram_weight_wire[70]),.DO71(read_sram_weight_wire[71]),
.DO72(read_sram_weight_wire[72]),.DO73(read_sram_weight_wire[73]),.DO74(read_sram_weight_wire[74]),.DO75(read_sram_weight_wire[75]),.DO76(read_sram_weight_wire[76]),.DO77(read_sram_weight_wire[77]),.DO78(read_sram_weight_wire[78]),.DO79(read_sram_weight_wire[79]),
.DO80(read_sram_weight_wire[80]),.DO81(read_sram_weight_wire[81]),.DO82(read_sram_weight_wire[82]),.DO83(read_sram_weight_wire[83]),.DO84(read_sram_weight_wire[84]),.DO85(read_sram_weight_wire[85]),.DO86(read_sram_weight_wire[86]),.DO87(read_sram_weight_wire[87]),
.DO88(read_sram_weight_wire[88]),.DO89(read_sram_weight_wire[89]),.DO90(read_sram_weight_wire[90]),.DO91(read_sram_weight_wire[91]),.DO92(read_sram_weight_wire[92]),.DO93(read_sram_weight_wire[93]),.DO94(read_sram_weight_wire[94]),.DO95(read_sram_weight_wire[95]),
.DO96(read_sram_weight_wire[96]),.DO97(read_sram_weight_wire[97]),.DO98(read_sram_weight_wire[98]),.DO99(read_sram_weight_wire[99]),.DO100(read_sram_weight_wire[100]),.DO101(read_sram_weight_wire[101]),.DO102(read_sram_weight_wire[102]),.DO103(read_sram_weight_wire[103]),
.DO104(read_sram_weight_wire[104]),.DO105(read_sram_weight_wire[105]),.DO106(read_sram_weight_wire[106]),.DO107(read_sram_weight_wire[107]),.DO108(read_sram_weight_wire[108]),.DO109(read_sram_weight_wire[109]),.DO110(read_sram_weight_wire[110]),.DO111(read_sram_weight_wire[111]),
.DO112(read_sram_weight_wire[112]),.DO113(read_sram_weight_wire[113]),.DO114(read_sram_weight_wire[114]),.DO115(read_sram_weight_wire[115]),.DO116(read_sram_weight_wire[116]),.DO117(read_sram_weight_wire[117]),.DO118(read_sram_weight_wire[118]),.DO119(read_sram_weight_wire[119]),
.DO120(read_sram_weight_wire[120]),.DO121(read_sram_weight_wire[121]),.DO122(read_sram_weight_wire[122]),.DO123(read_sram_weight_wire[123]),.DO124(read_sram_weight_wire[124]),.DO125(read_sram_weight_wire[125]),.DO126(read_sram_weight_wire[126]),.DO127(read_sram_weight_wire[127]),

.DI0(write_sram_weight[0]),.DI1(write_sram_weight[1]),.DI2(write_sram_weight[2]),.DI3(write_sram_weight[3]),.DI4(write_sram_weight[4]),.DI5(write_sram_weight[5]),.DI6(write_sram_weight[6]),.DI7(write_sram_weight[7]),
.DI8(write_sram_weight[8]),.DI9(write_sram_weight[9]),.DI10(write_sram_weight[10]),.DI11(write_sram_weight[11]),.DI12(write_sram_weight[12]),.DI13(write_sram_weight[13]),.DI14(write_sram_weight[14]),.DI15(write_sram_weight[15]),
.DI16(write_sram_weight[16]),.DI17(write_sram_weight[17]),.DI18(write_sram_weight[18]),.DI19(write_sram_weight[19]),.DI20(write_sram_weight[20]),.DI21(write_sram_weight[21]),.DI22(write_sram_weight[22]),.DI23(write_sram_weight[23]),
.DI24(write_sram_weight[24]),.DI25(write_sram_weight[25]),.DI26(write_sram_weight[26]),.DI27(write_sram_weight[27]),.DI28(write_sram_weight[28]),.DI29(write_sram_weight[29]),.DI30(write_sram_weight[30]),.DI31(write_sram_weight[31]),
.DI32(write_sram_weight[32]),.DI33(write_sram_weight[33]),.DI34(write_sram_weight[34]),.DI35(write_sram_weight[35]),.DI36(write_sram_weight[36]),.DI37(write_sram_weight[37]),.DI38(write_sram_weight[38]),.DI39(write_sram_weight[39]),
.DI40(write_sram_weight[40]),.DI41(write_sram_weight[41]),.DI42(write_sram_weight[42]),.DI43(write_sram_weight[43]),.DI44(write_sram_weight[44]),.DI45(write_sram_weight[45]),.DI46(write_sram_weight[46]),.DI47(write_sram_weight[47]),
.DI48(write_sram_weight[48]),.DI49(write_sram_weight[49]),.DI50(write_sram_weight[50]),.DI51(write_sram_weight[51]),.DI52(write_sram_weight[52]),.DI53(write_sram_weight[53]),.DI54(write_sram_weight[54]),.DI55(write_sram_weight[55]),
.DI56(write_sram_weight[56]),.DI57(write_sram_weight[57]),.DI58(write_sram_weight[58]),.DI59(write_sram_weight[59]),.DI60(write_sram_weight[60]),.DI61(write_sram_weight[61]),.DI62(write_sram_weight[62]),.DI63(write_sram_weight[63]),
.DI64(write_sram_weight[64]),.DI65(write_sram_weight[65]),.DI66(write_sram_weight[66]),.DI67(write_sram_weight[67]),.DI68(write_sram_weight[68]),.DI69(write_sram_weight[69]),.DI70(write_sram_weight[70]),.DI71(write_sram_weight[71]),
.DI72(write_sram_weight[72]),.DI73(write_sram_weight[73]),.DI74(write_sram_weight[74]),.DI75(write_sram_weight[75]),.DI76(write_sram_weight[76]),.DI77(write_sram_weight[77]),.DI78(write_sram_weight[78]),.DI79(write_sram_weight[79]),
.DI80(write_sram_weight[80]),.DI81(write_sram_weight[81]),.DI82(write_sram_weight[82]),.DI83(write_sram_weight[83]),.DI84(write_sram_weight[84]),.DI85(write_sram_weight[85]),.DI86(write_sram_weight[86]),.DI87(write_sram_weight[87]),
.DI88(write_sram_weight[88]),.DI89(write_sram_weight[89]),.DI90(write_sram_weight[90]),.DI91(write_sram_weight[91]),.DI92(write_sram_weight[92]),.DI93(write_sram_weight[93]),.DI94(write_sram_weight[94]),.DI95(write_sram_weight[95]),
.DI96(write_sram_weight[96]),.DI97(write_sram_weight[97]),.DI98(write_sram_weight[98]),.DI99(write_sram_weight[99]),.DI100(write_sram_weight[100]),.DI101(write_sram_weight[101]),.DI102(write_sram_weight[102]),.DI103(write_sram_weight[103]),
.DI104(write_sram_weight[104]),.DI105(write_sram_weight[105]),.DI106(write_sram_weight[106]),.DI107(write_sram_weight[107]),.DI108(write_sram_weight[108]),.DI109(write_sram_weight[109]),.DI110(write_sram_weight[110]),.DI111(write_sram_weight[111]),
.DI112(write_sram_weight[112]),.DI113(write_sram_weight[113]),.DI114(write_sram_weight[114]),.DI115(write_sram_weight[115]),.DI116(write_sram_weight[116]),.DI117(write_sram_weight[117]),.DI118(write_sram_weight[118]),.DI119(write_sram_weight[119]),
.DI120(write_sram_weight[120]),.DI121(write_sram_weight[121]),.DI122(write_sram_weight[122]),.DI123(write_sram_weight[123]),.DI124(write_sram_weight[124]),.DI125(write_sram_weight[125]),.DI126(write_sram_weight[126]),.DI127(write_sram_weight[127]),
.CK(clk),.WEB(web_weight),.OE(1'b1),.CS(1'b1));


SRAM_128_128_1 sl(.A0(sram_location_addr[0]),.A1(sram_location_addr[1]),.A2(sram_location_addr[2]),.A3(sram_location_addr[3]),.A4(sram_location_addr[4]),.A5(sram_location_addr[5]),.A6(sram_location_addr[6]),
.DO0(read_sram_location_wire[0]),.DO1(read_sram_location_wire[1]),.DO2(read_sram_location_wire[2]),.DO3(read_sram_location_wire[3]),.DO4(read_sram_location_wire[4]),.DO5(read_sram_location_wire[5]),.DO6(read_sram_location_wire[6]),.DO7(read_sram_location_wire[7]),
.DO8(read_sram_location_wire[8]),.DO9(read_sram_location_wire[9]),.DO10(read_sram_location_wire[10]),.DO11(read_sram_location_wire[11]),.DO12(read_sram_location_wire[12]),.DO13(read_sram_location_wire[13]),.DO14(read_sram_location_wire[14]),.DO15(read_sram_location_wire[15]),
.DO16(read_sram_location_wire[16]),.DO17(read_sram_location_wire[17]),.DO18(read_sram_location_wire[18]),.DO19(read_sram_location_wire[19]),.DO20(read_sram_location_wire[20]),.DO21(read_sram_location_wire[21]),.DO22(read_sram_location_wire[22]),.DO23(read_sram_location_wire[23]),
.DO24(read_sram_location_wire[24]),.DO25(read_sram_location_wire[25]),.DO26(read_sram_location_wire[26]),.DO27(read_sram_location_wire[27]),.DO28(read_sram_location_wire[28]),.DO29(read_sram_location_wire[29]),.DO30(read_sram_location_wire[30]),.DO31(read_sram_location_wire[31]),
.DO32(read_sram_location_wire[32]),.DO33(read_sram_location_wire[33]),.DO34(read_sram_location_wire[34]),.DO35(read_sram_location_wire[35]),.DO36(read_sram_location_wire[36]),.DO37(read_sram_location_wire[37]),.DO38(read_sram_location_wire[38]),.DO39(read_sram_location_wire[39]),
.DO40(read_sram_location_wire[40]),.DO41(read_sram_location_wire[41]),.DO42(read_sram_location_wire[42]),.DO43(read_sram_location_wire[43]),.DO44(read_sram_location_wire[44]),.DO45(read_sram_location_wire[45]),.DO46(read_sram_location_wire[46]),.DO47(read_sram_location_wire[47]),
.DO48(read_sram_location_wire[48]),.DO49(read_sram_location_wire[49]),.DO50(read_sram_location_wire[50]),.DO51(read_sram_location_wire[51]),.DO52(read_sram_location_wire[52]),.DO53(read_sram_location_wire[53]),.DO54(read_sram_location_wire[54]),.DO55(read_sram_location_wire[55]),
.DO56(read_sram_location_wire[56]),.DO57(read_sram_location_wire[57]),.DO58(read_sram_location_wire[58]),.DO59(read_sram_location_wire[59]),.DO60(read_sram_location_wire[60]),.DO61(read_sram_location_wire[61]),.DO62(read_sram_location_wire[62]),.DO63(read_sram_location_wire[63]),
.DO64(read_sram_location_wire[64]),.DO65(read_sram_location_wire[65]),.DO66(read_sram_location_wire[66]),.DO67(read_sram_location_wire[67]),.DO68(read_sram_location_wire[68]),.DO69(read_sram_location_wire[69]),.DO70(read_sram_location_wire[70]),.DO71(read_sram_location_wire[71]),
.DO72(read_sram_location_wire[72]),.DO73(read_sram_location_wire[73]),.DO74(read_sram_location_wire[74]),.DO75(read_sram_location_wire[75]),.DO76(read_sram_location_wire[76]),.DO77(read_sram_location_wire[77]),.DO78(read_sram_location_wire[78]),.DO79(read_sram_location_wire[79]),
.DO80(read_sram_location_wire[80]),.DO81(read_sram_location_wire[81]),.DO82(read_sram_location_wire[82]),.DO83(read_sram_location_wire[83]),.DO84(read_sram_location_wire[84]),.DO85(read_sram_location_wire[85]),.DO86(read_sram_location_wire[86]),.DO87(read_sram_location_wire[87]),
.DO88(read_sram_location_wire[88]),.DO89(read_sram_location_wire[89]),.DO90(read_sram_location_wire[90]),.DO91(read_sram_location_wire[91]),.DO92(read_sram_location_wire[92]),.DO93(read_sram_location_wire[93]),.DO94(read_sram_location_wire[94]),.DO95(read_sram_location_wire[95]),
.DO96(read_sram_location_wire[96]),.DO97(read_sram_location_wire[97]),.DO98(read_sram_location_wire[98]),.DO99(read_sram_location_wire[99]),.DO100(read_sram_location_wire[100]),.DO101(read_sram_location_wire[101]),.DO102(read_sram_location_wire[102]),.DO103(read_sram_location_wire[103]),
.DO104(read_sram_location_wire[104]),.DO105(read_sram_location_wire[105]),.DO106(read_sram_location_wire[106]),.DO107(read_sram_location_wire[107]),.DO108(read_sram_location_wire[108]),.DO109(read_sram_location_wire[109]),.DO110(read_sram_location_wire[110]),.DO111(read_sram_location_wire[111]),
.DO112(read_sram_location_wire[112]),.DO113(read_sram_location_wire[113]),.DO114(read_sram_location_wire[114]),.DO115(read_sram_location_wire[115]),.DO116(read_sram_location_wire[116]),.DO117(read_sram_location_wire[117]),.DO118(read_sram_location_wire[118]),.DO119(read_sram_location_wire[119]),
.DO120(read_sram_location_wire[120]),.DO121(read_sram_location_wire[121]),.DO122(read_sram_location_wire[122]),.DO123(read_sram_location_wire[123]),.DO124(read_sram_location_wire[124]),.DO125(read_sram_location_wire[125]),.DO126(read_sram_location_wire[126]),.DO127(read_sram_location_wire[127]),

.DI0(write_sram_location[0]),.DI1(write_sram_location[1]),.DI2(write_sram_location[2]),.DI3(write_sram_location[3]),.DI4(write_sram_location[4]),.DI5(write_sram_location[5]),.DI6(write_sram_location[6]),.DI7(write_sram_location[7]),
.DI8(write_sram_location[8]),.DI9(write_sram_location[9]),.DI10(write_sram_location[10]),.DI11(write_sram_location[11]),.DI12(write_sram_location[12]),.DI13(write_sram_location[13]),.DI14(write_sram_location[14]),.DI15(write_sram_location[15]),
.DI16(write_sram_location[16]),.DI17(write_sram_location[17]),.DI18(write_sram_location[18]),.DI19(write_sram_location[19]),.DI20(write_sram_location[20]),.DI21(write_sram_location[21]),.DI22(write_sram_location[22]),.DI23(write_sram_location[23]),
.DI24(write_sram_location[24]),.DI25(write_sram_location[25]),.DI26(write_sram_location[26]),.DI27(write_sram_location[27]),.DI28(write_sram_location[28]),.DI29(write_sram_location[29]),.DI30(write_sram_location[30]),.DI31(write_sram_location[31]),
.DI32(write_sram_location[32]),.DI33(write_sram_location[33]),.DI34(write_sram_location[34]),.DI35(write_sram_location[35]),.DI36(write_sram_location[36]),.DI37(write_sram_location[37]),.DI38(write_sram_location[38]),.DI39(write_sram_location[39]),
.DI40(write_sram_location[40]),.DI41(write_sram_location[41]),.DI42(write_sram_location[42]),.DI43(write_sram_location[43]),.DI44(write_sram_location[44]),.DI45(write_sram_location[45]),.DI46(write_sram_location[46]),.DI47(write_sram_location[47]),
.DI48(write_sram_location[48]),.DI49(write_sram_location[49]),.DI50(write_sram_location[50]),.DI51(write_sram_location[51]),.DI52(write_sram_location[52]),.DI53(write_sram_location[53]),.DI54(write_sram_location[54]),.DI55(write_sram_location[55]),
.DI56(write_sram_location[56]),.DI57(write_sram_location[57]),.DI58(write_sram_location[58]),.DI59(write_sram_location[59]),.DI60(write_sram_location[60]),.DI61(write_sram_location[61]),.DI62(write_sram_location[62]),.DI63(write_sram_location[63]),
.DI64(write_sram_location[64]),.DI65(write_sram_location[65]),.DI66(write_sram_location[66]),.DI67(write_sram_location[67]),.DI68(write_sram_location[68]),.DI69(write_sram_location[69]),.DI70(write_sram_location[70]),.DI71(write_sram_location[71]),
.DI72(write_sram_location[72]),.DI73(write_sram_location[73]),.DI74(write_sram_location[74]),.DI75(write_sram_location[75]),.DI76(write_sram_location[76]),.DI77(write_sram_location[77]),.DI78(write_sram_location[78]),.DI79(write_sram_location[79]),
.DI80(write_sram_location[80]),.DI81(write_sram_location[81]),.DI82(write_sram_location[82]),.DI83(write_sram_location[83]),.DI84(write_sram_location[84]),.DI85(write_sram_location[85]),.DI86(write_sram_location[86]),.DI87(write_sram_location[87]),
.DI88(write_sram_location[88]),.DI89(write_sram_location[89]),.DI90(write_sram_location[90]),.DI91(write_sram_location[91]),.DI92(write_sram_location[92]),.DI93(write_sram_location[93]),.DI94(write_sram_location[94]),.DI95(write_sram_location[95]),
.DI96(write_sram_location[96]),.DI97(write_sram_location[97]),.DI98(write_sram_location[98]),.DI99(write_sram_location[99]),.DI100(write_sram_location[100]),.DI101(write_sram_location[101]),.DI102(write_sram_location[102]),.DI103(write_sram_location[103]),
.DI104(write_sram_location[104]),.DI105(write_sram_location[105]),.DI106(write_sram_location[106]),.DI107(write_sram_location[107]),.DI108(write_sram_location[108]),.DI109(write_sram_location[109]),.DI110(write_sram_location[110]),.DI111(write_sram_location[111]),
.DI112(write_sram_location[112]),.DI113(write_sram_location[113]),.DI114(write_sram_location[114]),.DI115(write_sram_location[115]),.DI116(write_sram_location[116]),.DI117(write_sram_location[117]),.DI118(write_sram_location[118]),.DI119(write_sram_location[119]),
.DI120(write_sram_location[120]),.DI121(write_sram_location[121]),.DI122(write_sram_location[122]),.DI123(write_sram_location[123]),.DI124(write_sram_location[124]),.DI125(write_sram_location[125]),.DI126(write_sram_location[126]),.DI127(write_sram_location[127]),
.CK(clk),.WEB(web_location),.OE(1'b1),.CS(1'b1));
endmodule
