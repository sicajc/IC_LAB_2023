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
output reg [13:0] 	cost;
output wire         busy;

// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)	axi read address channel
output wire [ID_WIDTH-1:0]      arid_m_inf;
output wire [1:0]            arburst_m_inf;
output wire [2:0]             arsize_m_inf;
output reg [7:0]              arlen_m_inf;
output reg                  arvalid_m_inf;
input  wire                  arready_m_inf;
output reg  [ADDR_WIDTH-1:0]  araddr_m_inf;
// ------------------------
// (2)	axi read data channel
input  wire [ID_WIDTH-1:0]       rid_m_inf;
input  wire                   rvalid_m_inf;
output reg                   rready_m_inf;
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
output reg                  awvalid_m_inf;
input  wire                  awready_m_inf;
output reg  [ADDR_WIDTH-1:0]  awaddr_m_inf;
// -------------------------
// (2)	axi write data channel
output reg                   wvalid_m_inf;
input  wire                   wready_m_inf;
output reg [DATA_WIDTH-1:0]   wdata_m_inf;
output reg                     wlast_m_inf;
// -------------------------
// (3)	axi write response channel
input  wire  [ID_WIDTH-1:0]      bid_m_inf;
input  wire                   bvalid_m_inf;
output reg                   bready_m_inf;
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
parameter AXI_W_ADDR                   = 5'd7;
parameter AXI_W_DATA                   = 5'd8;
parameter AXI_W_RESP                   = 5'd9;
parameter OUTPUT                       = 5'd10;


wire st_IDLE        = cur_state == IDLE;
wire st_RD_NET_INFO = cur_state == RD_NET_INFO;
wire st_AXI_RD_ADDR = cur_state == AXI_RD_ADDR;
wire st_AXI_RD_DATA = cur_state == AXI_RD_DATA;
wire st_FILL_PATH   = cur_state == FILL_PATH;
wire st_RETRACE     = cur_state == RETRACE;
wire st_CLEAR_MAP   = cur_state == CLEAR_MAP_LOAD_TARGET;
wire st_AXI_W_ADDR  = cur_state == AXI_W_ADDR;
wire st_AXI_W_DATA  = cur_state == AXI_W_DATA;
wire st_AXI_W_RESP  = cur_state == AXI_W_RESP;
wire st_OUTPUT      = cur_state == OUTPUT;
// ===============================================================
//  					Variable Declare
// ===============================================================
integer i, j, k;
reg in_valid_d1;

reg [4:0] frame_id_ff;
reg [5:0] cur_target_cnt;
reg [5:0] num_of_target_ff;
reg [5:0] rd_cnt;
reg [3:0] net_id_rf [0:14];
reg [5:0] source_x_rf [0:14];
reg [5:0] source_y_rf [0:14];
reg [5:0] sink_x_rf [0:14];
reg [5:0] sink_y_rf [0:14];

wire [3:0] cur_net_id   = net_id_rf[cur_target_cnt];
wire [5:0] cur_source_x = source_x_rf[cur_target_cnt];
wire [5:0] cur_source_y = source_y_rf[cur_target_cnt];
wire [5:0] cur_sink_x   = sink_x_rf[cur_target_cnt];
wire [5:0] cur_sink_y   = sink_y_rf[cur_target_cnt];

reg[1:0] path_map_matrix_rf[0:63][0:63];
reg[1:0] path_map_matrix_wr[0:63][0:63];

reg[5:0] cur_yptr,cur_xptr;
reg[8:0] location_addr_cnt;

reg[6:0] loc_mem_addr,weight_mem_addr;
wire[127:0] loc_mem_rd,weight_mem_rd;
reg[127:0] loc_mem_wr,weight_mem_wr;
reg loc_mem_we,weight_mem_we;

reg[1:0] sram_read_write_cnt;
reg sram_read_d1;

wire retrace_replace_wb_f = sram_read_write_cnt == 2;


wire retrace_sram_give_addr_f = sram_read_write_cnt == 0 && st_RETRACE;
wire[7:0] retrace_sram_rd_addr = (cur_yptr*64 + cur_xptr)/32;

reg[127:0] retrace_sram_loc_wb;


wire axi_wr_addr_tx_f   = awvalid_m_inf && awready_m_inf;
wire axi_wr_data_tx_f   = wready_m_inf  && wvalid_m_inf;
wire axi_wr_data_done_f = wlast_m_inf   && wready_m_inf && wvalid_m_inf;
wire axi_wr_resp_f      = bvalid_m_inf  && bready_m_inf;

reg loc_wb_valid_d1,wb_data_last_d1;

wire wb_data_last_f = location_addr_cnt == 127 && st_AXI_W_DATA;
wire loc_wb_valid_f = st_AXI_W_DATA;


// ===============================================================
//  					FLAGS
// ===============================================================
assign busy = ~in_valid_d1 && ~st_IDLE && ~st_OUTPUT;
wire axi_rd_addr_tx_f       = arvalid_m_inf && arready_m_inf;
reg axi_rd_addr_tx_d1;

wire axi_rd_data_done_f     = rlast_m_inf && rvalid_m_inf && rready_m_inf;
reg axi_rd_data_done_d1;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        axi_rd_data_done_d1 <= 0;
    else
        axi_rd_data_done_d1 <= axi_rd_data_done_f;
end

wire fill_path_done_f       = path_map_matrix_rf[cur_sink_y][cur_sink_x][1] == 1;
wire retrace_path_done_f    = path_map_matrix_rf[cur_source_y][cur_source_x] == 1;
wire routing_done_f         = cur_target_cnt == (num_of_target_ff);
reg rd_weight_map_f;
reg[1:0] cnt;


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
        rd_weight_map_f <= 0;
    else if(st_IDLE)
        rd_weight_map_f <= 0;
    else if(axi_rd_data_done_f)
        rd_weight_map_f <= 1;
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
       if(~in_valid) nxt_state = AXI_RD_ADDR;
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
         if(rd_weight_map_f)
         begin
            nxt_state = FILL_PATH;
         end
         else
         begin
            nxt_state = AXI_RD_ADDR;
         end
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
       if(routing_done_f)
       begin
            nxt_state = AXI_W_ADDR;
       end
       else
       begin
            nxt_state = FILL_PATH;
       end
    end
    AXI_W_ADDR:
    begin
        if(axi_wr_addr_tx_f) nxt_state = AXI_W_DATA;
    end
    AXI_W_DATA:
    begin
        if(axi_wr_data_done_f) nxt_state = AXI_W_RESP;
    end
    AXI_W_RESP:
    begin
        if(axi_wr_resp_f) nxt_state = OUTPUT;
    end
    OUTPUT:
    begin
        nxt_state = IDLE;
    end
    endcase
end
reg fill_path_map_d1,fill_path_map_d2, fill_path_map_d3;
reg rd_weight_map_d1;
always @(posedge clk)
begin
    rd_weight_map_d1 <= rd_weight_map_f;
end

// ===============================================================
//  					AXI READ
// ===============================================================
// << Burst & ID >>
assign arid_m_inf    = 4'd0; 			// fixed id to 0
assign arburst_m_inf = 2'd1;		// fixed mode to INCR mode
assign arsize_m_inf  = 3'b100;		// fixed size to 2^4 = 16 Bytes
assign arlen_m_inf   = 8'd127;


wire axi_rd_data_tx_f = rvalid_m_inf && rready_m_inf;
reg  axi_rd_data_tx_d1;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        axi_rd_addr_tx_d1 <= 0;
    else
        axi_rd_data_tx_d1 <= axi_rd_data_tx_f;
end

reg[127:0] dram_data_in_ff;

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        // AXI read addr
        arvalid_m_inf <= 0;
        araddr_m_inf  <= 0;

        // AXI read data
        rready_m_inf  <= 0;
        dram_data_in_ff <= 0;
    end
    else if(st_IDLE)
    begin
        arvalid_m_inf <= 0;
        araddr_m_inf  <= 0;
        dram_data_in_ff <= 0;
    end
    else if(st_AXI_RD_ADDR)
    begin
        if(axi_rd_addr_tx_f)
        begin
            arvalid_m_inf <= 0;
            araddr_m_inf <= 0;
        end
        else
        begin
            arvalid_m_inf <= 1;
            if(rd_weight_map_f)
            begin
                araddr_m_inf <= {{16'b0000_0000_0000_0010}, frame_id_ff , 11'b0};
            end
            else
            begin
                araddr_m_inf <= {{16'b0000_0000_0000_0001}, frame_id_ff , 11'b0};
            end
        end
    end
    else if(st_AXI_RD_DATA)
    begin
        rready_m_inf <= 1;
        if(axi_rd_data_tx_f)
        begin
            dram_data_in_ff <= rdata_m_inf;
        end
    end
    else
    begin

    end
end
// ===============================================================
//  					AXI WRITE
// ===============================================================
// << Burst & ID >>
assign awid_m_inf    = 4'd0;
assign awburst_m_inf = 2'd1;
assign awsize_m_inf  = 3'b100;
assign awlen_m_inf   = 8'd127;


always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        // AXI wr addr
        awaddr_m_inf <= 0;
        awvalid_m_inf <= 0;

        // AXI wr data
        wdata_m_inf  <= 0;
        wlast_m_inf  <= 0;
        wvalid_m_inf <= 0;

        // wr resp
        bready_m_inf <= 0;
    end
    else if(st_AXI_W_ADDR)
    begin
        if(axi_wr_addr_tx_f)
        begin
            awaddr_m_inf  <= 0;
            awvalid_m_inf <= 0;
        end
        else
        begin
            awaddr_m_inf  <= {{16'b0000_0000_0000_0001}, frame_id_ff , 11'b0};
            awvalid_m_inf <= 1;
        end
    end
    else if(st_AXI_W_DATA)
    begin
        if(axi_wr_data_done_f)
        begin
            wvalid_m_inf <= 0;
            wdata_m_inf  <= 0;
            wlast_m_inf  <= 0;
        end
        else
        begin
            wvalid_m_inf <= loc_wb_valid_d1;
            wdata_m_inf  <= loc_wb_valid_d1 ? loc_mem_rd : 0;
            wlast_m_inf  <= wb_data_last_d1;
        end
    end
    else if(st_AXI_W_RESP)
    begin
        bready_m_inf <= axi_wr_resp_f ? 0 : 1;
    end
end

reg[7:0] location_addr_cnt_d1;
wire loc_wb_wait_dram_f = ((location_addr_cnt == 2) && ~axi_wr_data_tx_f);

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        loc_wb_valid_d1 <= 0;
        wb_data_last_d1 <= 0;
        location_addr_cnt_d1 <= 0;
    end
    else if(st_AXI_W_DATA)
    begin
        loc_wb_valid_d1 <=       loc_wb_valid_f;
        wb_data_last_d1 <=       wb_data_last_f;
        location_addr_cnt_d1 <=  loc_wb_wait_dram_f ? location_addr_cnt_d1:
        location_addr_cnt;
    end
end

// ===============================================================
//  				    SUB CONTROL
// ===============================================================
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        cur_target_cnt <= 0;
        rd_cnt     <= 0;
        cur_yptr <= 0;
        cur_xptr <= 0;
        location_addr_cnt <= 0;
        num_of_target_ff <= 0;
        sram_read_write_cnt <= 0;
        cnt <= 0;
    end
    else
    begin
        case(cur_state)
        IDLE:
        begin
            if(in_valid)
            begin
                rd_cnt <= 1;
            end
            else
            begin
                rd_cnt <= 0;
            end

            cur_target_cnt <= 0;
            num_of_target_ff <= 0;
            cur_yptr <= 0;
            cur_xptr <= 0;
            location_addr_cnt <= 0;
            cnt <= 0;
            sram_read_write_cnt <= 0;
        end
        RD_NET_INFO:
        begin
            if(in_valid)
                rd_cnt <= rd_cnt + 1;

            if(rd_cnt[0] == 1)
            begin
                num_of_target_ff <= num_of_target_ff + 1;
            end
        end
        AXI_RD_DATA:
        begin
            if(location_addr_cnt == 127 && axi_rd_data_done_d1)
                location_addr_cnt <= 0;
            else if(axi_rd_data_tx_d1)
                location_addr_cnt <= location_addr_cnt + 1;

            cnt <= 1;
        end
        FILL_PATH:
        begin
            if(fill_path_done_f)
            begin
                cnt <= cnt - 1;
            end
            else if(~fill_path_done_f && fill_path_map_d3)
            begin
                cnt <= cnt + 1;
            end
        end
        RETRACE:
        begin
            // Give addr, SRAM delay1, SRAM delay2, Fill data then WB
            if(retrace_path_done_f)
                sram_read_write_cnt <= 0;
            else if(sram_read_write_cnt == 2)
                sram_read_write_cnt <= 0;
            else
                sram_read_write_cnt <= sram_read_write_cnt + 1;
            //fill data and write back
            if(retrace_path_done_f)
                cnt <= 1;
            else if(retrace_replace_wb_f)
            begin
                cnt <= cnt - 1;
            end

            if(routing_done_f)
                cur_target_cnt <= 0;
            else if(retrace_path_done_f)
                cur_target_cnt <= cur_target_cnt + 1;
        end
        endcase
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        frame_id_ff <= 0;

        for(i=0;i<16;i=i+1)
        begin
            net_id_rf[i] <= 0;
            sink_x_rf[i] <= 0;
            sink_y_rf[i] <= 0;
            source_x_rf[i] <= 0;
            source_y_rf[i] <= 0;
        end
    end
    else if(st_IDLE)
    begin
        if(in_valid)
        begin
            frame_id_ff <= frame_id;
            source_x_rf[num_of_target_ff] <= loc_x;
            source_y_rf[num_of_target_ff] <= loc_y;
        end
    end
    else if(st_RD_NET_INFO && in_valid)
    begin
        if(rd_cnt[0] == 0)
        begin
            source_x_rf[num_of_target_ff] <= loc_x;
            source_y_rf[num_of_target_ff] <= loc_y;
        end
        else
        begin
            net_id_rf[num_of_target_ff] <= net_id;
            sink_x_rf[num_of_target_ff] <= loc_x;
            sink_y_rf[num_of_target_ff] <= loc_y;
        end
    end
end
// ===============================================================
//  				    PATH MAP
// ===============================================================


always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
    begin
        fill_path_map_d1 <= 0;
        fill_path_map_d2 <= 0;
        fill_path_map_d3 <= 0;
    end
    else
    begin
        fill_path_map_d1 <= st_FILL_PATH;
        fill_path_map_d2 <= fill_path_map_d1;
        fill_path_map_d3 <= fill_path_map_d2;
    end
end

wire[1:0] nxt_count = cnt - 1;

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        cur_target_cnt <= 0;
        rd_cnt     <= 0;
        cur_yptr <= 0;
        cur_xptr <= 0;
        location_addr_cnt <= 0;
        num_of_target_ff <= 0;
    end
    else
    begin
        case(cur_state)
        IDLE:
        begin
            if(in_valid)
            begin
                rd_cnt <= 1;
            end
            else
            begin
                rd_cnt <= 0;
            end

            cur_target_cnt <= 0;
            num_of_target_ff <= 0;
            cur_yptr <= 0;
            cur_xptr <= 0;
            location_addr_cnt <= 0;
        end
        RD_NET_INFO:
        begin
            if(in_valid)
                rd_cnt <= rd_cnt + 1;

            if(rd_cnt[0] == 1)
            begin
                num_of_target_ff <= num_of_target_ff + 1;
            end
        end
        AXI_RD_ADDR:
        begin
            if(location_addr_cnt == 127)
            begin
                 location_addr_cnt <= 0;
            end
        end
        AXI_RD_DATA:
        begin
            if(location_addr_cnt == 127)
                location_addr_cnt <= 0;
            else if(axi_rd_data_tx_d1)
                location_addr_cnt <= location_addr_cnt + 1;
        end
        FILL_PATH:
        begin
            cur_yptr <= cur_sink_y;
            cur_xptr <= cur_sink_x;
        end
        RETRACE:
        begin
            if(retrace_replace_wb_f)
            begin
                case(nxt_count)
                'd2,'d3:
                begin
                    if(path_map_matrix_rf[cur_yptr+1][cur_xptr] == 3)
                        cur_yptr <= cur_yptr + 1;
                    else if(path_map_matrix_rf[cur_yptr-1][cur_xptr] == 3)
                        cur_yptr <= cur_yptr - 1;
                    else if(path_map_matrix_rf[cur_yptr][cur_xptr+1] == 3)
                        cur_xptr <= cur_xptr + 1;
                    else if(path_map_matrix_rf[cur_yptr][cur_xptr-1] == 3)
                        cur_xptr <= cur_xptr - 1;
                end
                'd0,'d1:
                begin
                    if(path_map_matrix_rf[cur_yptr+1][cur_xptr] == 2)
                        cur_yptr <= cur_yptr + 1;
                    else if(path_map_matrix_rf[cur_yptr-1][cur_xptr] == 2)
                        cur_yptr <= cur_yptr - 1;
                    else if(path_map_matrix_rf[cur_yptr][cur_xptr+1] == 2)
                        cur_xptr <= cur_xptr + 1;
                    else if(path_map_matrix_rf[cur_yptr][cur_xptr-1] == 2)
                        cur_xptr <= cur_xptr - 1;
                end
                endcase
            end
        end
        AXI_W_ADDR:
        begin
            location_addr_cnt <= 0;
        end
        AXI_W_DATA:
        begin
            if(wb_data_last_f)
            begin
                location_addr_cnt <= location_addr_cnt;
            end
            else if(axi_wr_addr_tx_f)
            begin
                location_addr_cnt <= location_addr_cnt + 1;
            end
            else if(loc_wb_wait_dram_f)
            begin
                location_addr_cnt <= location_addr_cnt;
            end
            else
            begin
                location_addr_cnt <= location_addr_cnt + 1;
            end
        end
        endcase
    end
end

// ===============================================================
//  					PATH MAP
// ===============================================================
reg path_rd_cnt;
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        for(i=0;i<64;i=i+1)
            for(j=0;j<64;j=j+1)
                path_map_matrix_rf[i][j] <= 0;
    end
    else if(st_IDLE)
    begin
        for(i=0;i<64;i=i+1)
            for(j=0;j<64;j=j+1)
                path_map_matrix_rf[i][j] <= 0;
    end
    else
    begin
        for(i=0;i<64;i=i+1)
            for(j=0;j<64;j=j+1)
                path_map_matrix_rf[i][j] <= path_map_matrix_wr[i][j];
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
        path_rd_cnt <= 0;
    else if(st_IDLE)
        path_rd_cnt <= 0;
    else if(axi_rd_data_tx_d1)
        path_rd_cnt <= ~path_rd_cnt;
end

reg[1:0] cur_encode_val;
always @(*)
begin
    //Initilization
     for(i=0;i<64;i=i+1)
            for(j=0;j<64;j=j+1)
                path_map_matrix_wr[i][j] = path_map_matrix_rf[i][j];

    // Fill path
    if(axi_rd_data_tx_d1 && ~rd_weight_map_f)
    begin
        if(~path_rd_cnt)
            for(j=0;j<32;j=j+1)
            begin
                path_map_matrix_wr[location_addr_cnt/2][j] = {1'b0,|dram_data_in_ff[j*4 +: 4]};
            end
        else
            for(j=0;j<32;j=j+1)
            begin
                path_map_matrix_wr[location_addr_cnt/2][j+32] = {1'b0,|dram_data_in_ff[j*4 +: 4]};
            end
    end
    else if(fill_path_map_d3 && st_FILL_PATH)
    begin
        // 1~63
        for(i=1;i<63;i=i+1)
            for(j=1;j<63;j=j+1)
                if(path_map_matrix_rf[i][j] == 2'b0 && (path_map_matrix_rf[i+1][j][1] ==1'b1 || path_map_matrix_rf[i-1][j][1] ==1'b1
                || path_map_matrix_rf[i][j+1][1] ==1'b1 || path_map_matrix_rf[i][j-1][1] ==1'b1))
                begin
                    path_map_matrix_wr[i][j] = cur_encode_val;
                end
        // Upper boundary
        for(j=1;j<63;j=j+1)
            if(path_map_matrix_rf[0][j] == 2'b0 && (path_map_matrix_rf[1][j][1] ==1'b1 || path_map_matrix_rf[0][j+1][1] ==1'b1
                || path_map_matrix_rf[0][j-1][1] ==1'b1))
            begin
                path_map_matrix_wr[0][j] = cur_encode_val;
            end

        // Lower boundary
        for(j=1;j<63;j=j+1)
            if(path_map_matrix_rf[63][j] == 2'b0 && (path_map_matrix_rf[62][j][1] ==1'b1 || path_map_matrix_rf[63][j+1][1] ==1'b1
                || path_map_matrix_rf[63][j-1][1] ==1'b1))
            begin
                path_map_matrix_wr[63][j] = cur_encode_val;
            end

        // Left boundary
        for(i=1;i<63;i=i+1)
            if(path_map_matrix_rf[i][0] == 2'b0 && (path_map_matrix_rf[i-1][0][1] ==1'b1 || path_map_matrix_rf[i+1][0][1] ==1'b1
                || path_map_matrix_rf[i][1][1] ==1'b1))
            begin
                path_map_matrix_wr[i][0] = cur_encode_val;
            end

        // Right boundary
        for(i=1;i<63;i=i+1)
            if(path_map_matrix_rf[i][63] == 2'b0 && (path_map_matrix_rf[i-1][63][1] ==1'b1 || path_map_matrix_rf[i+1][63][1] ==1'b1
                || path_map_matrix_rf[i][62][1] ==1'b1))
            begin
                path_map_matrix_wr[i][63] = cur_encode_val;
            end

        // Upper left
        if(path_map_matrix_rf[0][0] == 0 && (path_map_matrix_rf[0][1][1] == 1 || path_map_matrix_rf[1][0][1] == 1))
            path_map_matrix_wr[0][0] = cur_encode_val;
        // Lower left
        if(path_map_matrix_rf[63][0] == 0 && (path_map_matrix_rf[63][1][1] == 1 || path_map_matrix_rf[62][0][1] == 1))
            path_map_matrix_wr[63][0] = cur_encode_val;
        // Lower right
        if(path_map_matrix_rf[63][63] == 0 && (path_map_matrix_rf[62][63][1] == 1 || path_map_matrix_rf[63][62][1] == 1))
            path_map_matrix_wr[63][63] = cur_encode_val;
        // Upper right
        if(path_map_matrix_rf[0][63] == 0 && (path_map_matrix_rf[0][62][1] == 1 || path_map_matrix_rf[1][63][1] == 1))
            path_map_matrix_wr[0][63] = cur_encode_val;
    end
    else if(fill_path_map_d2 && st_FILL_PATH)
    begin
        path_map_matrix_wr[cur_sink_y][cur_sink_x] = 0;
    end
    else if(fill_path_map_d1 && st_FILL_PATH)
    begin
        path_map_matrix_wr[cur_source_y][cur_source_x] = 2;
    end

    // Retrace
    if(st_RETRACE && retrace_replace_wb_f)
    begin
        path_map_matrix_wr[cur_yptr][cur_xptr] = 1;
    end

    if(st_CLEAR_MAP)
    begin
         for(i=0;i<64;i=i+1)
            for(j=0;j<64;j=j+1)
                if(path_map_matrix_rf[i][j][1]==1'b1)
                    path_map_matrix_wr[i][j] = 0;
    end
end


always @(*)
begin
    cur_encode_val = 0;
    case(cnt)
    'd0: cur_encode_val = 2;
    'd1: cur_encode_val = 2;
    'd2: cur_encode_val = 3;
    'd3: cur_encode_val = 3;
    endcase
end


reg[127:0] loc_data_out_ff;
reg[127:0] weight_data_out_ff;

wire loc_sram_output_f = sram_read_write_cnt == 1;
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        weight_data_out_ff <= 0;
        loc_data_out_ff    <= 0;
    end
    else if(st_IDLE)
    begin
        weight_data_out_ff <= 0;
        loc_data_out_ff <= 0;
    end
    else if(loc_sram_output_f)
    begin
        weight_data_out_ff <= weight_mem_rd;
        loc_data_out_ff <= loc_mem_rd;
    end
end

reg[3:0] weight;

// Fill replace wb
always @(*)
begin
    weight = 0;

    for(i=0;i<32;i=i+1)
		if(cur_xptr[4:0] == i)
        begin
			retrace_sram_loc_wb[i*4 +: 4] = cur_net_id;
            weight       = weight_data_out_ff[i*4+:4];
        end
		else
        begin
			retrace_sram_loc_wb[i*4 +: 4] = loc_data_out_ff[i*4 +: 4];
        end
end
// ===============================================================
//  					weight MAC_ff
// ===============================================================
reg[14:0] weight_mac_ff;

wire current_is_source_dst_f = (cur_xptr == cur_source_x && cur_yptr == cur_source_y)
|| (cur_xptr == cur_sink_x && cur_yptr == cur_sink_y);

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
        weight_mac_ff <= 0;
    else if(st_IDLE)
        weight_mac_ff <= 0;
    else if(retrace_replace_wb_f && ~current_is_source_dst_f)
        weight_mac_ff <= weight_mac_ff + weight;
end

// ===============================================================
//  					Output signals
// ===============================================================
always @(posedge clk or negedge rst_n) begin
	if(~rst_n)
	begin
		cost <=0;
	end
    else if(st_IDLE)
    begin
        cost <= 0;
    end
	else
	begin
        cost <= weight_mac_ff;
	end
end
// ===============================================================
//  					Memory addr
// ===============================================================

always@(*)
begin
    loc_mem_addr = 0;
    weight_mem_addr = 0;
    loc_mem_we = 1;
    weight_mem_we = 1;
    loc_mem_wr = 0;
    weight_mem_wr = 0;

    if(axi_rd_data_tx_d1)
    begin
        if(~rd_weight_map_d1)
        begin
            loc_mem_we = 0;
            loc_mem_addr = location_addr_cnt;
            loc_mem_wr   = dram_data_in_ff;
        end
        else
        begin
            weight_mem_we = 0;
            weight_mem_addr = location_addr_cnt;
            weight_mem_wr   = dram_data_in_ff;
        end
    end

    // Retrace
    if(retrace_sram_give_addr_f)
    begin
        loc_mem_we    = 1;
        loc_mem_addr = retrace_sram_rd_addr;
    end

    if(retrace_replace_wb_f)
    begin
        loc_mem_we   = 0;
        loc_mem_addr = retrace_sram_rd_addr;
        loc_mem_wr   = retrace_sram_loc_wb;
    end

    if(st_RETRACE)
    begin
        weight_mem_we = 1;
        weight_mem_addr = retrace_sram_rd_addr;
    end

    // Location map WB DRAM
    if(st_AXI_W_DATA)
    begin
        loc_mem_we   = 1;
        loc_mem_addr = location_addr_cnt;
    end
end


SRAM_128x128 Location_map_mem(.A0(loc_mem_addr[0]),.A1(loc_mem_addr[1]),.A2(loc_mem_addr[2]),
                    .A3(loc_mem_addr[3]),.A4(loc_mem_addr[4]),.A5(loc_mem_addr[5]),.A6(loc_mem_addr[6]),.
                     DO0(loc_mem_rd[0]),.DO1(loc_mem_rd[1]),.DO2(loc_mem_rd[2]),.DO3(loc_mem_rd[3]),.DO4(loc_mem_rd[4]),.DO5(loc_mem_rd[5]),.DO6(loc_mem_rd[6]),.
                     DO7(loc_mem_rd[7]),.DO8(loc_mem_rd[8]),.DO9(loc_mem_rd[9]),.DO10(loc_mem_rd[10]),.DO11(loc_mem_rd[11]),.DO12(loc_mem_rd[12]),.DO13(loc_mem_rd[13]),.DO14(loc_mem_rd[14]),.DO15(loc_mem_rd[15]),.
                     DO16(loc_mem_rd[16]),.DO17(loc_mem_rd[17]),.DO18(loc_mem_rd[18]),.DO19(loc_mem_rd[19]),.DO20(loc_mem_rd[20]),.DO21(loc_mem_rd[21]),.DO22(loc_mem_rd[22]),.DO23(loc_mem_rd[23]),.
                     DO24(loc_mem_rd[24]),.DO25(loc_mem_rd[25]),.DO26(loc_mem_rd[26]),.DO27(loc_mem_rd[27]),.DO28(loc_mem_rd[28]),.DO29(loc_mem_rd[29]),.DO30(loc_mem_rd[30]),.DO31(loc_mem_rd[31]),.
                     DO32(loc_mem_rd[32]),.DO33(loc_mem_rd[33]),.DO34(loc_mem_rd[34]),.DO35(loc_mem_rd[35]),.DO36(loc_mem_rd[36]),.DO37(loc_mem_rd[37]),.DO38(loc_mem_rd[38]),.DO39(loc_mem_rd[39]),.
                     DO40(loc_mem_rd[40]),.DO41(loc_mem_rd[41]),.DO42(loc_mem_rd[42]),.DO43(loc_mem_rd[43]),.DO44(loc_mem_rd[44]),.DO45(loc_mem_rd[45]),.DO46(loc_mem_rd[46]),.DO47(loc_mem_rd[47]),.
                     DO48(loc_mem_rd[48]),.DO49(loc_mem_rd[49]),.DO50(loc_mem_rd[50]),.DO51(loc_mem_rd[51]),.DO52(loc_mem_rd[52]),.DO53(loc_mem_rd[53]),.DO54(loc_mem_rd[54]),.DO55(loc_mem_rd[55]),.
                     DO56(loc_mem_rd[56]),.DO57(loc_mem_rd[57]),.DO58(loc_mem_rd[58]),.DO59(loc_mem_rd[59]),.DO60(loc_mem_rd[60]),.DO61(loc_mem_rd[61]),.DO62(loc_mem_rd[62]),.DO63(loc_mem_rd[63]),.
                     DO64(loc_mem_rd[64]),.DO65(loc_mem_rd[65]),.DO66(loc_mem_rd[66]),.DO67(loc_mem_rd[67]),.DO68(loc_mem_rd[68]),.DO69(loc_mem_rd[69]),.DO70(loc_mem_rd[70]),.DO71(loc_mem_rd[71]),.
                     DO72(loc_mem_rd[72]),.DO73(loc_mem_rd[73]),.DO74(loc_mem_rd[74]),.DO75(loc_mem_rd[75]),.DO76(loc_mem_rd[76]),.DO77(loc_mem_rd[77]),.DO78(loc_mem_rd[78]),.DO79(loc_mem_rd[79]),.
                     DO80(loc_mem_rd[80]),.DO81(loc_mem_rd[81]),.DO82(loc_mem_rd[82]),.DO83(loc_mem_rd[83]),.DO84(loc_mem_rd[84]),.DO85(loc_mem_rd[85]),.DO86(loc_mem_rd[86]),.DO87(loc_mem_rd[87]),.
                     DO88(loc_mem_rd[88]),.DO89(loc_mem_rd[89]),.DO90(loc_mem_rd[90]),.DO91(loc_mem_rd[91]),.DO92(loc_mem_rd[92]),.DO93(loc_mem_rd[93]),.DO94(loc_mem_rd[94]),.DO95(loc_mem_rd[95]),.
                     DO96(loc_mem_rd[96]),.DO97(loc_mem_rd[97]),.DO98(loc_mem_rd[98]),.DO99(loc_mem_rd[99]),.DO100(loc_mem_rd[100]),.DO101(loc_mem_rd[101]),.DO102(loc_mem_rd[102]),.DO103(loc_mem_rd[103]),.
                     DO104(loc_mem_rd[104]),.DO105(loc_mem_rd[105]),.DO106(loc_mem_rd[106]),.DO107(loc_mem_rd[107]),.DO108(loc_mem_rd[108]),.DO109(loc_mem_rd[109]),.DO110(loc_mem_rd[110]),.
                     DO111(loc_mem_rd[111]),.DO112(loc_mem_rd[112]),.DO113(loc_mem_rd[113]),.DO114(loc_mem_rd[114]),.DO115(loc_mem_rd[115]),.DO116(loc_mem_rd[116]),.DO117(loc_mem_rd[117]),.
                     DO118(loc_mem_rd[118]),.DO119(loc_mem_rd[119]),.DO120(loc_mem_rd[120]),.DO121(loc_mem_rd[121]),.DO122(loc_mem_rd[122]),.DO123(loc_mem_rd[123]),.DO124(loc_mem_rd[124]),.
                     DO125(loc_mem_rd[125]),.DO126(loc_mem_rd[126]),.DO127(loc_mem_rd[127]),
                     .DI0(loc_mem_wr[0]),.DI1(loc_mem_wr[1]),.DI2(loc_mem_wr[2]),.DI3(loc_mem_wr[3]),.DI4(loc_mem_wr[4]),.
                     DI5(loc_mem_wr[5]),.DI6(loc_mem_wr[6]),.DI7(loc_mem_wr[7]),.DI8(loc_mem_wr[8]),.DI9(loc_mem_wr[9]),.DI10(loc_mem_wr[10]),.DI11(loc_mem_wr[11]),.DI12(loc_mem_wr[12]),.DI13(loc_mem_wr[13]),.DI14(loc_mem_wr[14]),.
                     DI15(loc_mem_wr[15]),.DI16(loc_mem_wr[16]),.DI17(loc_mem_wr[17]),.DI18(loc_mem_wr[18]),.DI19(loc_mem_wr[19]),.DI20(loc_mem_wr[20]),.DI21(loc_mem_wr[21]),.DI22(loc_mem_wr[22]),.
                     DI23(loc_mem_wr[23]),.DI24(loc_mem_wr[24]),.DI25(loc_mem_wr[25]),.DI26(loc_mem_wr[26]),.DI27(loc_mem_wr[27]),.DI28(loc_mem_wr[28]),.DI29(loc_mem_wr[29]),.DI30(loc_mem_wr[30]),.
                     DI31(loc_mem_wr[31]),.DI32(loc_mem_wr[32]),.DI33(loc_mem_wr[33]),.DI34(loc_mem_wr[34]),.DI35(loc_mem_wr[35]),.DI36(loc_mem_wr[36]),.DI37(loc_mem_wr[37]),.DI38(loc_mem_wr[38]),.
                     DI39(loc_mem_wr[39]),.DI40(loc_mem_wr[40]),.DI41(loc_mem_wr[41]),.DI42(loc_mem_wr[42]),.DI43(loc_mem_wr[43]),.DI44(loc_mem_wr[44]),.DI45(loc_mem_wr[45]),.DI46(loc_mem_wr[46]),.
                     DI47(loc_mem_wr[47]),.DI48(loc_mem_wr[48]),.DI49(loc_mem_wr[49]),.DI50(loc_mem_wr[50]),.DI51(loc_mem_wr[51]),.DI52(loc_mem_wr[52]),.DI53(loc_mem_wr[53]),.DI54(loc_mem_wr[54]),.
                     DI55(loc_mem_wr[55]),.DI56(loc_mem_wr[56]),.DI57(loc_mem_wr[57]),.DI58(loc_mem_wr[58]),.DI59(loc_mem_wr[59]),.DI60(loc_mem_wr[60]),.DI61(loc_mem_wr[61]),.DI62(loc_mem_wr[62]),.
                     DI63(loc_mem_wr[63]),.DI64(loc_mem_wr[64]),.DI65(loc_mem_wr[65]),.DI66(loc_mem_wr[66]),.DI67(loc_mem_wr[67]),.DI68(loc_mem_wr[68]),.DI69(loc_mem_wr[69]),.DI70(loc_mem_wr[70]),.
                     DI71(loc_mem_wr[71]),.DI72(loc_mem_wr[72]),.DI73(loc_mem_wr[73]),.DI74(loc_mem_wr[74]),.DI75(loc_mem_wr[75]),.DI76(loc_mem_wr[76]),.DI77(loc_mem_wr[77]),.DI78(loc_mem_wr[78]),.
                     DI79(loc_mem_wr[79]),.DI80(loc_mem_wr[80]),.DI81(loc_mem_wr[81]),.DI82(loc_mem_wr[82]),.DI83(loc_mem_wr[83]),.DI84(loc_mem_wr[84]),.DI85(loc_mem_wr[85]),.DI86(loc_mem_wr[86]),.
                     DI87(loc_mem_wr[87]),.DI88(loc_mem_wr[88]),.DI89(loc_mem_wr[89]),.DI90(loc_mem_wr[90]),.DI91(loc_mem_wr[91]),.DI92(loc_mem_wr[92]),.DI93(loc_mem_wr[93]),.DI94(loc_mem_wr[94]),.
                     DI95(loc_mem_wr[95]),.DI96(loc_mem_wr[96]),.DI97(loc_mem_wr[97]),.DI98(loc_mem_wr[98]),.DI99(loc_mem_wr[99]),.DI100(loc_mem_wr[100]),.DI101(loc_mem_wr[101]),.DI102(loc_mem_wr[102]),.
                     DI103(loc_mem_wr[103]),.DI104(loc_mem_wr[104]),.DI105(loc_mem_wr[105]),.DI106(loc_mem_wr[106]),.DI107(loc_mem_wr[107]),.DI108(loc_mem_wr[108]),.DI109(loc_mem_wr[109]),.
                     DI110(loc_mem_wr[110]),.DI111(loc_mem_wr[111]),.DI112(loc_mem_wr[112]),.DI113(loc_mem_wr[113]),.DI114(loc_mem_wr[114]),.DI115(loc_mem_wr[115]),.DI116(loc_mem_wr[116]),.
                     DI117(loc_mem_wr[117]),.DI118(loc_mem_wr[118]),.DI119(loc_mem_wr[119]),.DI120(loc_mem_wr[120]),.DI121(loc_mem_wr[121]),.DI122(loc_mem_wr[122]),.DI123(loc_mem_wr[123]),.
                     DI124(loc_mem_wr[124]),.DI125(loc_mem_wr[125]),.DI126(loc_mem_wr[126]),.DI127(loc_mem_wr[127]),.CK(clk),.WEB(loc_mem_we),.OE(1'b1),.CS(1'b1));


SRAM_128x128 Weight_map_mem(.A0(weight_mem_addr[0]),.A1(weight_mem_addr[1]),.A2(weight_mem_addr[2]),
                    .A3(weight_mem_addr[3]),.A4(weight_mem_addr[4]),.A5(weight_mem_addr[5]),.A6(weight_mem_addr[6]),.
                     DO0(weight_mem_rd[0]),.DO1(weight_mem_rd[1]),.DO2(weight_mem_rd[2]),.DO3(weight_mem_rd[3]),.DO4(weight_mem_rd[4]),.DO5(weight_mem_rd[5]),.DO6(weight_mem_rd[6]),.
                     DO7(weight_mem_rd[7]),.DO8(weight_mem_rd[8]),.DO9(weight_mem_rd[9]),.DO10(weight_mem_rd[10]),.DO11(weight_mem_rd[11]),.DO12(weight_mem_rd[12]),.DO13(weight_mem_rd[13]),.DO14(weight_mem_rd[14]),.DO15(weight_mem_rd[15]),.
                     DO16(weight_mem_rd[16]),.DO17(weight_mem_rd[17]),.DO18(weight_mem_rd[18]),.DO19(weight_mem_rd[19]),.DO20(weight_mem_rd[20]),.DO21(weight_mem_rd[21]),.DO22(weight_mem_rd[22]),.DO23(weight_mem_rd[23]),.
                     DO24(weight_mem_rd[24]),.DO25(weight_mem_rd[25]),.DO26(weight_mem_rd[26]),.DO27(weight_mem_rd[27]),.DO28(weight_mem_rd[28]),.DO29(weight_mem_rd[29]),.DO30(weight_mem_rd[30]),.DO31(weight_mem_rd[31]),.
                     DO32(weight_mem_rd[32]),.DO33(weight_mem_rd[33]),.DO34(weight_mem_rd[34]),.DO35(weight_mem_rd[35]),.DO36(weight_mem_rd[36]),.DO37(weight_mem_rd[37]),.DO38(weight_mem_rd[38]),.DO39(weight_mem_rd[39]),.
                     DO40(weight_mem_rd[40]),.DO41(weight_mem_rd[41]),.DO42(weight_mem_rd[42]),.DO43(weight_mem_rd[43]),.DO44(weight_mem_rd[44]),.DO45(weight_mem_rd[45]),.DO46(weight_mem_rd[46]),.DO47(weight_mem_rd[47]),.
                     DO48(weight_mem_rd[48]),.DO49(weight_mem_rd[49]),.DO50(weight_mem_rd[50]),.DO51(weight_mem_rd[51]),.DO52(weight_mem_rd[52]),.DO53(weight_mem_rd[53]),.DO54(weight_mem_rd[54]),.DO55(weight_mem_rd[55]),.
                     DO56(weight_mem_rd[56]),.DO57(weight_mem_rd[57]),.DO58(weight_mem_rd[58]),.DO59(weight_mem_rd[59]),.DO60(weight_mem_rd[60]),.DO61(weight_mem_rd[61]),.DO62(weight_mem_rd[62]),.DO63(weight_mem_rd[63]),.
                     DO64(weight_mem_rd[64]),.DO65(weight_mem_rd[65]),.DO66(weight_mem_rd[66]),.DO67(weight_mem_rd[67]),.DO68(weight_mem_rd[68]),.DO69(weight_mem_rd[69]),.DO70(weight_mem_rd[70]),.DO71(weight_mem_rd[71]),.
                     DO72(weight_mem_rd[72]),.DO73(weight_mem_rd[73]),.DO74(weight_mem_rd[74]),.DO75(weight_mem_rd[75]),.DO76(weight_mem_rd[76]),.DO77(weight_mem_rd[77]),.DO78(weight_mem_rd[78]),.DO79(weight_mem_rd[79]),.
                     DO80(weight_mem_rd[80]),.DO81(weight_mem_rd[81]),.DO82(weight_mem_rd[82]),.DO83(weight_mem_rd[83]),.DO84(weight_mem_rd[84]),.DO85(weight_mem_rd[85]),.DO86(weight_mem_rd[86]),.DO87(weight_mem_rd[87]),.
                     DO88(weight_mem_rd[88]),.DO89(weight_mem_rd[89]),.DO90(weight_mem_rd[90]),.DO91(weight_mem_rd[91]),.DO92(weight_mem_rd[92]),.DO93(weight_mem_rd[93]),.DO94(weight_mem_rd[94]),.DO95(weight_mem_rd[95]),.
                     DO96(weight_mem_rd[96]),.DO97(weight_mem_rd[97]),.DO98(weight_mem_rd[98]),.DO99(weight_mem_rd[99]),.DO100(weight_mem_rd[100]),.DO101(weight_mem_rd[101]),.DO102(weight_mem_rd[102]),.DO103(weight_mem_rd[103]),.
                     DO104(weight_mem_rd[104]),.DO105(weight_mem_rd[105]),.DO106(weight_mem_rd[106]),.DO107(weight_mem_rd[107]),.DO108(weight_mem_rd[108]),.DO109(weight_mem_rd[109]),.DO110(weight_mem_rd[110]),.
                     DO111(weight_mem_rd[111]),.DO112(weight_mem_rd[112]),.DO113(weight_mem_rd[113]),.DO114(weight_mem_rd[114]),.DO115(weight_mem_rd[115]),.DO116(weight_mem_rd[116]),.DO117(weight_mem_rd[117]),.
                     DO118(weight_mem_rd[118]),.DO119(weight_mem_rd[119]),.DO120(weight_mem_rd[120]),.DO121(weight_mem_rd[121]),.DO122(weight_mem_rd[122]),.DO123(weight_mem_rd[123]),.DO124(weight_mem_rd[124]),.
                     DO125(weight_mem_rd[125]),.DO126(weight_mem_rd[126]),.DO127(weight_mem_rd[127]),
                     .DI0(weight_mem_wr[0]),.DI1(weight_mem_wr[1]),.DI2(weight_mem_wr[2]),.DI3(weight_mem_wr[3]),.DI4(weight_mem_wr[4]),.
                     DI5(weight_mem_wr[5]),.DI6(weight_mem_wr[6]),.DI7(weight_mem_wr[7]),.DI8(weight_mem_wr[8]),.DI9(weight_mem_wr[9]),.DI10(weight_mem_wr[10]),.DI11(weight_mem_wr[11]),.DI12(weight_mem_wr[12]),.DI13(weight_mem_wr[13]),.DI14(weight_mem_wr[14]),.
                     DI15(weight_mem_wr[15]),.DI16(weight_mem_wr[16]),.DI17(weight_mem_wr[17]),.DI18(weight_mem_wr[18]),.DI19(weight_mem_wr[19]),.DI20(weight_mem_wr[20]),.DI21(weight_mem_wr[21]),.DI22(weight_mem_wr[22]),.
                     DI23(weight_mem_wr[23]),.DI24(weight_mem_wr[24]),.DI25(weight_mem_wr[25]),.DI26(weight_mem_wr[26]),.DI27(weight_mem_wr[27]),.DI28(weight_mem_wr[28]),.DI29(weight_mem_wr[29]),.DI30(weight_mem_wr[30]),.
                     DI31(weight_mem_wr[31]),.DI32(weight_mem_wr[32]),.DI33(weight_mem_wr[33]),.DI34(weight_mem_wr[34]),.DI35(weight_mem_wr[35]),.DI36(weight_mem_wr[36]),.DI37(weight_mem_wr[37]),.DI38(weight_mem_wr[38]),.
                     DI39(weight_mem_wr[39]),.DI40(weight_mem_wr[40]),.DI41(weight_mem_wr[41]),.DI42(weight_mem_wr[42]),.DI43(weight_mem_wr[43]),.DI44(weight_mem_wr[44]),.DI45(weight_mem_wr[45]),.DI46(weight_mem_wr[46]),.
                     DI47(weight_mem_wr[47]),.DI48(weight_mem_wr[48]),.DI49(weight_mem_wr[49]),.DI50(weight_mem_wr[50]),.DI51(weight_mem_wr[51]),.DI52(weight_mem_wr[52]),.DI53(weight_mem_wr[53]),.DI54(weight_mem_wr[54]),.
                     DI55(weight_mem_wr[55]),.DI56(weight_mem_wr[56]),.DI57(weight_mem_wr[57]),.DI58(weight_mem_wr[58]),.DI59(weight_mem_wr[59]),.DI60(weight_mem_wr[60]),.DI61(weight_mem_wr[61]),.DI62(weight_mem_wr[62]),.
                     DI63(weight_mem_wr[63]),.DI64(weight_mem_wr[64]),.DI65(weight_mem_wr[65]),.DI66(weight_mem_wr[66]),.DI67(weight_mem_wr[67]),.DI68(weight_mem_wr[68]),.DI69(weight_mem_wr[69]),.DI70(weight_mem_wr[70]),.
                     DI71(weight_mem_wr[71]),.DI72(weight_mem_wr[72]),.DI73(weight_mem_wr[73]),.DI74(weight_mem_wr[74]),.DI75(weight_mem_wr[75]),.DI76(weight_mem_wr[76]),.DI77(weight_mem_wr[77]),.DI78(weight_mem_wr[78]),.
                     DI79(weight_mem_wr[79]),.DI80(weight_mem_wr[80]),.DI81(weight_mem_wr[81]),.DI82(weight_mem_wr[82]),.DI83(weight_mem_wr[83]),.DI84(weight_mem_wr[84]),.DI85(weight_mem_wr[85]),.DI86(weight_mem_wr[86]),.
                     DI87(weight_mem_wr[87]),.DI88(weight_mem_wr[88]),.DI89(weight_mem_wr[89]),.DI90(weight_mem_wr[90]),.DI91(weight_mem_wr[91]),.DI92(weight_mem_wr[92]),.DI93(weight_mem_wr[93]),.DI94(weight_mem_wr[94]),.
                     DI95(weight_mem_wr[95]),.DI96(weight_mem_wr[96]),.DI97(weight_mem_wr[97]),.DI98(weight_mem_wr[98]),.DI99(weight_mem_wr[99]),.DI100(weight_mem_wr[100]),.DI101(weight_mem_wr[101]),.DI102(weight_mem_wr[102]),.
                     DI103(weight_mem_wr[103]),.DI104(weight_mem_wr[104]),.DI105(weight_mem_wr[105]),.DI106(weight_mem_wr[106]),.DI107(weight_mem_wr[107]),.DI108(weight_mem_wr[108]),.DI109(weight_mem_wr[109]),.
                     DI110(weight_mem_wr[110]),.DI111(weight_mem_wr[111]),.DI112(weight_mem_wr[112]),.DI113(weight_mem_wr[113]),.DI114(weight_mem_wr[114]),.DI115(weight_mem_wr[115]),.DI116(weight_mem_wr[116]),.
                     DI117(weight_mem_wr[117]),.DI118(weight_mem_wr[118]),.DI119(weight_mem_wr[119]),.DI120(weight_mem_wr[120]),.DI121(weight_mem_wr[121]),.DI122(weight_mem_wr[122]),.DI123(weight_mem_wr[123]),.
                     DI124(weight_mem_wr[124]),.DI125(weight_mem_wr[125]),.DI126(weight_mem_wr[126]),.DI127(weight_mem_wr[127]),.CK(clk),.WEB(weight_mem_we),.OE(1'b1),.CS(1'b1));

endmodule
