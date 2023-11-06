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

reg [4:0] cur_state, nxt_state;

parameter IDLE                         = 5'd0;
parameter RD_NET_INFO                  = 5'd1;
parameter AXI_RD_ADDR                  = 5'd2;
parameter AXI_RD_DATA                  = 5'd3;
parameter FILL_PATH                    = 5'd4;
parameter RETRACE                      = 5'd5;
parameter CLEAR_MAP_LOAD_TARGET        = 5'd6;

wire st_IDLE = cur_state == IDLE;
wire st_RD_NET_INFO = cur_state == RD_NET_INFO;
wire st_AXI_RD_ADDR = cur_state == AXI_RD_ADDR;
wire st_AXI_RD_DATA = cur_state == AXI_RD_DATA;
wire st_FILL_PATH = cur_state == FILL_PATH;
wire st_RETRACE = cur_state == RETRACE;
wire st_CLEAR_MAP = cur_state == CLEAR_MAP_LOAD_TARGET;

// ===============================================================
//  					Variable Declare
// ===============================================================
integer i, j, k;
reg in_valid_d1;

reg [4:0] frame_id_ff;
reg [5:0] target_cnt;
reg [5:0] rd_cnt;
reg [5:0] num_of_target_ff;
reg [3:0] net_id_rf [0:14];
reg [5:0] source_x_rf [0:14];
reg [5:0] source_y_rf [0:14];
reg [5:0] sink_x_rf [0:14];
reg [5:0] sink_y_rf [0:14];

wire [5:0] cur_source_x = source_x_rf[target_cnt];
wire [5:0] cur_source_y = source_y_rf[target_cnt];
wire [5:0] cur_sink_x   = sink_x_rf[target_cnt];
wire [5:0] cur_sink_y   = sink_y_rf[target_cnt];

reg[1:0] path_map_matrix[0:63][0:63];
reg[1:0] path_map_matrix_wr[0:63][0:63];

reg[5:0] cur_yptr,cur_xptr;
reg[8:0] location_addr_cnt;


// ===============================================================
//  					FLAGS
// ===============================================================
wire busy = ~in_valid_d1 && ~st_IDLE;
wire axi_rd_addr_tx_f       = arvalid_m_inf && arready_m_inf;
reg axi_rd_addr_tx_d1;

wire axi_rd_data_done_f     = rlast_m_inf && rvalid_m_inf && rready_m_inf;
wire fill_path_done_f       = path_map_matrix[cur_sink_y][cur_sink_x][1] == 1;
wire retrace_path_done_f    = path_map_matrix[cur_source_y][cur_source_x][1] == 1;
wire routing_done_f         = target_cnt == num_of_target_ff;
reg weight_map_rd_f;


always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
    begin
		in_valid_d1 <= 1'b0;
        axi_rd_addr_tx_d1 <= 0;
    end
	else
    begin
		in_valid_d1 <= in_valid;
        axi_rd_addr_tx_d1 <= axi_rd_addr_tx_f; // For 1 cycle delay dram data reading
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
        weight_map_rd_f <= 0;
    else if(axi_rd_data_done_f)
        weight_map_rd_f <= 1;
end



// ===============================================================
//  					MAIN FSM
// ===============================================================
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        cur_state <= IDLE;
    end
    else
    begin
        cur_state <= nxt_state;
    end
end

always @(*)
begin
    nxt_state = cur_state;
    case(cur_state)
    IDLE:
    begin
       if(in_valid) nxt_state = RD_NET_INFO;
    end
    RD_NET_INFO:
    begin
       if(~in_valid) nxt_state = BUILD_TREE;
    end
    AXI_RD_ADDR:
    begin
       if(axi_rd_addr_tx_f)
            nxt_state = AXI_RD_DATA;
    end
    AXI_RD_DATA:
    begin
       if(axi_rd_data_done_f)
       begin
         if(weight_map_rd_f)
            nxt_state = FILL_PATH;
       end
    end
    FILL_PATH:
    begin
       if(fill_path_done_f)  nxt_state = RETRACE;
    end
    RETRACE:
    begin
       if(retrace_path_done_f)  nxt_state = CLEAR_MAP_LOAD_TARGET;
    end
    CLEAR_MAP_LOAD_TARGET:
    begin
       if(routing_done_f) ;
    end
    endcase
end

// ===============================================================
//  				    SUB CONTROL
// ===============================================================
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        target_cnt <= 0;
        rd_cnt     <= 0;
        cur_yptr <= 0;
        cur_xptr <= 0;
        location_addr_cnt <= 0;
    end
    else
    begin
        case(cur_state)
        IDLE:
        begin
            if(in_valid)
            begin
                rd_cnt <= 0;
            end
            else
            begin
                rd_cnt <=0 ;
            end

            target_cnt <= 0;
            cur_yptr <= 0;
            cur_xptr <= 0;
            location_addr_cnt <= 0;
        end
        RD_NET_INFO:
        begin
            if(in_valid)
                rd_cnt <= rd_cnt + 1;

            if(rd_cnt[0] == 1)
                target_cnt <= target_cnt + 1;
        end
        AXI_RD_DATA:
        begin

        end
        endcase
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        for(i=0;i<16;i=i+1)
        begin
            net_id_rf[i] <= 0;
            sink_x_rf[i] <= 0;
            sink_y_rf[i] <= 0;
            source_x_rf[i] <= 0;
            source_y_rf[i] <= 0;
        end
    end
    else if(st_RD_NET_INFO)
    begin
        if(rd_cnt[0] == 0)
        begin
            source_x_rf[target_cnt] <= loc_x;
            source_y_rf[target_cnt] <= loc_y;
        end
        else
        begin
            net_id_rf[target_cnt] <= frame_id;
            sink_x_rf[target_cnt] <= loc_x;
            sink_y_rf[target_cnt] <= loc_y;
        end
    end
end





// ===============================================================
//  					Counter / Others
// ===============================================================


endmodule
