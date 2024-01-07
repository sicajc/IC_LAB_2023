//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2021 Final Project: Customized ISA Processor
//   Author              : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CPU.v
//   Module Name : CPU.v
//   Release version : V1.0 (Release Date: 2021-May)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CPU(

				clk,
			  rst_n,

		   IO_stall,

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
       bready_m_inf,

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
       rready_m_inf

);
// Input port
input  wire clk, rst_n;
// Output port
output reg  IO_stall;

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal)(),
  therefore I declared output of AXI as wire in CPU
*/

// axi write address channel
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  reg  [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  reg [WRIT_NUMBER-1:0]                 awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel
output  reg  [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  reg  [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  reg  [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  reg [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  reg [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  reg [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  reg [DRAM_NUMBER-1:0]                 rready_m_inf;
// -----------------------------

//
/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below(), you must get the fail in this lab.
*/

reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;



reg[10:0] ic_in_addr_ff;
reg       ic_out_valid;
reg[15:0] ic_out_inst_wr;

reg       dc_in_valid;
reg[10:0] dc_in_addr_ff;
reg[15:0] dc_in_data_ff;
reg       dc_in_write;
reg       dc_out_valid_ff;
reg[15:0] dc_out_data_ff;


wire signed[15:0] d_cache_d_out,d_cache_d_out0,d_cache_d_out1;
reg[6:0]  d_cache_addr;
reg signed[15:0] d_cache_d_in;
reg d_cache_we0,d_cache_we1;


reg[1:0] d_cache_valid_ff;


//================================================================
//  AXI 4
//================================================================
//####################################################
//               STATES
//####################################################
reg[13:0] main_cur_st,main_next_st;

localparam IF_1             = 14'b0000_0000_0000_01;
localparam IF_WAIT_MEM      = 14'b0000_0000_0000_10;
localparam ID               = 14'b0000_0000_0001_00;
localparam SLT_EX           = 14'b0000_0000_0010_00;
localparam ADD_EX           = 14'b0000_0000_0100_00;
localparam SUB_EX           = 14'b0000_0000_1000_00;
localparam MULT_EX          = 14'b0000_0001_0000_00;
localparam R_WB             = 14'b0000_0010_0000_00;
localparam LW_EX            = 14'b0000_0100_0000_00;
localparam SW_EX            = 14'b0000_1000_0000_00;
localparam BEQ_EX           = 14'b0001_0000_0000_00;
localparam LW_MEM_WAIT      = 14'b0010_0000_0000_00;
localparam SW_MEM_WAIT      = 14'b0100_0000_0000_00;
localparam MEM_WB           = 14'b1000_0000_0000_00;

wire st_IF_1 = main_cur_st[0];
wire st_IF_WAIT_MEM = main_cur_st[1];
wire st_ID = main_cur_st[2];
wire st_SLT_EX = main_cur_st[3];
wire st_ADD_EX = main_cur_st[4];
wire st_SUB_EX = main_cur_st[5];
wire st_MULT_EX = main_cur_st[6];
wire st_R_WB = main_cur_st[7];
wire st_LW_EX = main_cur_st[8];
wire st_SW_EX = main_cur_st[9];
wire st_BEQ_EX = main_cur_st[10];
wire st_LW_MEM_WAIT = main_cur_st[11];
wire st_SW_MEM_WAIT = main_cur_st[12];
wire st_MEM_WB = main_cur_st[13];


reg[4:0] inst_cache_cur_st,inst_cache_nxt_st;
localparam IC_IDLE                               = 5'b0_0001;
localparam IC_CHECK                              = 5'b0_0010;
localparam IC_AXI_RD_ADDR                        = 5'b0_0100;
localparam IC_AXI_RD_DATA_UPDATE_CASH            = 5'b0_1000;
localparam IC_OUTPUT                             = 5'b1_0000;


wire st_IC_IDLE                         = inst_cache_cur_st[0];
wire st_IC_CHECK                        = inst_cache_cur_st[1];
wire st_IC_AXI_RD_ADDR                  = inst_cache_cur_st[2];
wire st_IC_AXI_RD_DATA_UPDATE_CASH      = inst_cache_cur_st[3];
wire st_IC_OUTPUT                       = inst_cache_cur_st[4];


reg[9:0] data_cache_cur_st,data_cache_nxt_st;
localparam DC_IDLE                               = 10'b00_0000_0001;
localparam DC_CHECK                              = 10'b00_0000_0010;
localparam DC_AXI_RD_ADDR                        = 10'b00_0000_0100;
localparam DC_AXI_RD_DATA_UPDATE_CASH            = 10'b00_0000_1000;
localparam DC_AXI_WR_ADDR                        = 10'b00_0001_0000;
localparam DC_AXI_WR_DATA                        = 10'b00_0010_0000;
localparam DC_AXI_WR_RESP                        = 10'b00_0100_0000;
localparam DC_OUTPUT                             = 10'b00_1000_0000;
localparam DC_WRITE_SRAM                         = 10'b01_0000_0000;
localparam DC_CHECK_WR                           = 10'b10_0000_0000;


wire st_DC_IDLE                                     = data_cache_cur_st[0];
wire st_DC_CHECK                                    = data_cache_cur_st[1];
wire st_DC_AXI_RD_ADDR                              = data_cache_cur_st[2];
wire st_DC_AXI_RD_DATA_UPDATE_CASH                  = data_cache_cur_st[3];
wire st_DC_AXI_WR_ADDR                              = data_cache_cur_st[4];
wire st_DC_AXI_WR_DATA                              = data_cache_cur_st[5];
wire st_DC_AXI_WR_RESP                              = data_cache_cur_st[6];
wire st_DC_OUTPUT                                   = data_cache_cur_st[7];
wire st_DC_WRITE_SRAM                               = data_cache_cur_st[8];
wire st_DC_CHECK_WR                                 = data_cache_cur_st[9];

//================================================================
//   AXI interfaces
//================================================================
//======================
//   AXI RD
//======================
reg[7:0] axi_burst_cnt;
// instruction read and data read
wire axi_inst_rd_addr_done_f = arvalid_m_inf[1] && arready_m_inf[1];
wire axi_data_rd_addr_done_f = arvalid_m_inf[0] && arready_m_inf[0];

wire axi_inst_rd_data_done_f = rvalid_m_inf[1]  && rready_m_inf[1] && rlast_m_inf[1];
wire axi_data_rd_data_done_f = rvalid_m_inf[0]  && rready_m_inf[0] && rlast_m_inf[0];

wire axi_inst_rd_data_tran_f = rvalid_m_inf[1] && rready_m_inf[1];
wire axi_data_rd_data_tran_f = rvalid_m_inf[0] && rready_m_inf[0];

wire axi_wr_data_tran_f = wvalid_m_inf && wready_m_inf;


//======================
//   AXI WR
//======================
// data write only
wire axi_wr_addr_done_f = awvalid_m_inf && awready_m_inf;
wire axi_wr_data_done_f = wlast_m_inf   && wvalid_m_inf && wready_m_inf;
wire axi_wr_responed_f  = bvalid_m_inf  && bready_m_inf;

//####################################################
//               reg & wire
//####################################################
reg [15:0] pc_ff;
reg signed[15:0] ir_ff;
reg signed[15:0] reg_data1_ff;
reg signed[15:0] reg_data2_ff;
reg signed[15:0] alu_out_ff,alu_out_wr;
reg signed[15:0] dmem_data_ff;

wire[2:0] opcode = ir_ff[15:13] ;
wire[3:0] rs     = ir_ff[12: 9] ;
wire[3:0] rt     = ir_ff[ 8: 5] ;
wire[3:0] rd     = ir_ff[ 4: 1] ;
wire func   = ir_ff[0] ;
wire[4:0] imm    = ir_ff[ 4: 0] ;
wire[15:0] address = { 3'b000 , ir_ff[12:0] } ;
wire signed[15:0] sign_ex_imm  = $signed(imm);

// instruction cache
reg       ic_in_valid;

wire instr_mult_next_f = main_next_st == MULT_EX;
wire seq_mult_done_f;

wire signed[15:0] seq_mult_in1,seq_mult_in2,seq_mult_product;

//####################################################
//               current_instruction
//####################################################
wire inst_ADD       = opcode == 3'b000 && func == 1'b0;
wire inst_SUB       = opcode == 3'b000 && func == 1'b1;
wire inst_SLT       = opcode == 3'b001 && func == 1'b0;
wire inst_MULT      = opcode == 3'b001 && func == 1'b1;
wire inst_LOAD      = opcode == 3'b010;
wire inst_STORE     = opcode == 3'b011;
wire inst_BEQ       = opcode == 3'b100;
wire inst_J         = opcode == 3'b101;


wire branch_equal_f = reg_data1_ff == reg_data2_ff;
//####################################################
//               MAIN PROCESSOR
//####################################################
//####################################################
//               MAIN Control
//####################################################
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        main_cur_st <= IF_1;
    end
    else
    begin
        main_cur_st <= main_next_st;
    end
end

wire inst_out_valid_f  = ic_out_valid;
wire data_read_done_f  = st_DC_OUTPUT;
wire data_write_done_f = axi_wr_responed_f ;

always @(*)
begin
    main_next_st = main_cur_st;
    case(main_cur_st)
        IF_1:
        begin
            main_next_st = IF_WAIT_MEM;
        end
        IF_WAIT_MEM:
        begin
            main_next_st = inst_out_valid_f ? ID : IF_WAIT_MEM;
        end
        ID:
        begin
            case(opcode)
            3'b000://R-types
                if(func == 1'b0)
                    main_next_st = ADD_EX;
                else
                    main_next_st = SUB_EX;
            3'b001:
                if(func == 1'b0)
                    main_next_st = SLT_EX;
                else
                    main_next_st = MULT_EX;
            3'b010: //LW
                main_next_st = LW_EX;
            3'b011: //SW
                main_next_st = SW_EX;
            3'b100: //BEQ
                main_next_st = BEQ_EX;
            3'b101: //J
                main_next_st = IF_1;
            default:
                main_next_st = SLT_EX;
            endcase
        end
        MULT_EX:
        begin
            main_next_st = seq_mult_done_f ? R_WB : MULT_EX;
        end
        SLT_EX,ADD_EX,SUB_EX:
        begin
            main_next_st = R_WB;
        end
        R_WB:
        begin
            main_next_st = IF_1;
        end
        LW_EX:
        begin
            main_next_st = LW_MEM_WAIT;
        end
        SW_EX:
        begin
            main_next_st = SW_MEM_WAIT;
        end
        BEQ_EX:
        begin
            main_next_st = IF_1;
        end
        LW_MEM_WAIT:
        begin
            main_next_st = data_read_done_f  ?  MEM_WB : LW_MEM_WAIT;
        end
        SW_MEM_WAIT:
        begin
            main_next_st = data_write_done_f ?  IF_1 : SW_MEM_WAIT;
        end
        MEM_WB:
        begin
            main_next_st = IF_1;
        end
    endcase
end

//####################################################
//               I/O stall
//####################################################
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        IO_stall <= 1;
    end
    else if(st_R_WB || st_MEM_WB || st_BEQ_EX || (st_ID&&opcode == 3'b101) || (st_SW_MEM_WAIT && data_write_done_f))
    begin
        IO_stall <= 0;
    end
    else
    begin
        IO_stall <= 1;
    end
end

// ic invalid
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        ic_in_valid <= 0;
    end
    else if(main_next_st == IF_WAIT_MEM || st_IF_WAIT_MEM)
    begin
        ic_in_valid <= st_IC_OUTPUT ? 0 : 1;
    end
    else
    begin
        ic_in_valid <= 0;
    end
end
// dc invalid
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        dc_in_valid <= 0;
    end
    else if(main_next_st == LW_MEM_WAIT || main_next_st == SW_MEM_WAIT || st_LW_MEM_WAIT || st_SW_MEM_WAIT)
    begin
        dc_in_valid <= st_DC_OUTPUT || data_write_done_f ? 0 : 1;
    end
end

// dc in write
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        dc_in_write <= 0;
    end
    else if(st_IF_1)
    begin
        dc_in_write <= 0;
    end
    else if(st_SW_EX)
    begin
        dc_in_write <= 1;
    end
end

//####################################################
//               DATAPATH
//####################################################
// pc
parameter signed OFFSET = 16'h1000;

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        pc_ff <= OFFSET;
    end
    else if(st_ID && inst_J)
    begin
        pc_ff <= address >> 1;
    end
    else if(st_ID || (st_BEQ_EX&&branch_equal_f))
    begin
        pc_ff <= alu_out_wr;
    end
end

//================================================================
//   IR_FF
//================================================================
// reg[15:0] inst_out_ff;

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        ir_ff <= 0;
    end
    else if(st_IC_OUTPUT)
    begin
        ir_ff <= ic_out_inst_wr;
    end
end

// regdata1
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        reg_data1_ff <= 0;
    end
    else
    begin
        case(rs)
            4'b0000: reg_data1_ff <= core_r0;
            4'b0001: reg_data1_ff <= core_r1;
            4'b0010: reg_data1_ff <= core_r2;
            4'b0011: reg_data1_ff <= core_r3;
            4'b0100: reg_data1_ff <= core_r4;
            4'b0101: reg_data1_ff <= core_r5;
            4'b0110: reg_data1_ff <= core_r6;
            4'b0111: reg_data1_ff <= core_r7;
            4'b1000: reg_data1_ff <= core_r8;
            4'b1001: reg_data1_ff <= core_r9;
            4'b1010: reg_data1_ff <= core_r10;
            4'b1011: reg_data1_ff <= core_r11;
            4'b1100: reg_data1_ff <= core_r12;
            4'b1101: reg_data1_ff <= core_r13;
            4'b1110: reg_data1_ff <= core_r14;
            4'b1111: reg_data1_ff <= core_r15;
            default: reg_data1_ff <= 0;
        endcase
    end
end

// regdata2
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        reg_data2_ff <= 0;
    end
    else
    begin
        case(rt)
            4'b0000: reg_data2_ff <= core_r0;
            4'b0001: reg_data2_ff <= core_r1;
            4'b0010: reg_data2_ff <= core_r2;
            4'b0011: reg_data2_ff <= core_r3;
            4'b0100: reg_data2_ff <= core_r4;
            4'b0101: reg_data2_ff <= core_r5;
            4'b0110: reg_data2_ff <= core_r6;
            4'b0111: reg_data2_ff <= core_r7;
            4'b1000: reg_data2_ff <= core_r8;
            4'b1001: reg_data2_ff <= core_r9;
            4'b1010: reg_data2_ff <= core_r10;
            4'b1011: reg_data2_ff <= core_r11;
            4'b1100: reg_data2_ff <= core_r12;
            4'b1101: reg_data2_ff <= core_r13;
            4'b1110: reg_data2_ff <= core_r14;
            4'b1111: reg_data2_ff <= core_r15;
            default: reg_data2_ff <= 0;
        endcase
    end
end

//================================================================
//   ALU
//================================================================
wire EX_ST = st_ADD_EX || st_SUB_EX || st_SLT_EX  || st_LW_EX || st_SW_EX || st_BEQ_EX;

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        alu_out_ff <= 0;
    end
    else if(st_MULT_EX && seq_mult_done_f)
    begin
        alu_out_ff <= seq_mult_product;
    end
    else if(EX_ST || st_ID)
    begin
        alu_out_ff <= alu_out_wr;
    end
end


assign seq_mult_in1 = reg_data1_ff;
assign seq_mult_in2 = reg_data2_ff;


reg st_MULT_EX_d1;

wire multstart;
assign multstart = st_MULT_EX & ~st_MULT_EX_d1;

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        st_MULT_EX_d1 <= 1'b0;
    end
    else
    begin
        st_MULT_EX_d1 <= st_MULT_EX;
    end
end
wire signed[31:0] mult_product_inst;

assign seq_mult_product = mult_product_inst[15:0];
DW_mult_seq_inst seq_mult(.inst_clk(clk), .inst_rst_n(rst_n), .inst_hold(1'b0),
.inst_start(multstart), .inst_a(seq_mult_in1),
.inst_b(seq_mult_in2), .complete_inst(seq_mult_done_f), .product_inst(mult_product_inst));

always @(*)
begin
    alu_out_wr = 0;
    case(main_cur_st)
        ID:
        begin
            alu_out_wr = pc_ff + 16'd1;
        end
        ADD_EX:
        begin
            alu_out_wr = reg_data1_ff + reg_data2_ff;
        end
        SUB_EX:
        begin
            alu_out_wr = reg_data1_ff - reg_data2_ff;
        end
        SLT_EX:
        begin
            alu_out_wr = (reg_data1_ff < reg_data2_ff) ? $signed(16'd1) : $signed(16'd0);
        end
        LW_EX:
        begin
            alu_out_wr = reg_data1_ff + sign_ex_imm;
        end
        SW_EX:
        begin
            alu_out_wr = reg_data1_ff + sign_ex_imm;
        end
        BEQ_EX:
        begin
            alu_out_wr = pc_ff + sign_ex_imm;
        end
        SW_MEM_WAIT,LW_MEM_WAIT:
        begin
            //sign(rs+immediate)×2+offset
            alu_out_wr = (alu_out_ff <<< 1) + OFFSET;
        end
        default:
        begin
            alu_out_wr = 0;
        end
    endcase
end

reg signed[15:0] alu_out_wr_d1;
always @(posedge clk)
begin
    alu_out_wr_d1 <= alu_out_wr;
end


wire signed[15:0] data_mem_in_addr = alu_out_wr;
wire signed[15:0] data_mem_in_data = alu_out_ff;

//================================================================
//   dmem data ff
//================================================================
reg signed[15:0] mem_data_out_ff;
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        dmem_data_ff <= 0;
    end
    else if(st_DC_OUTPUT)
    begin
        dmem_data_ff <= d_cache_d_out;
    end
end

//================================================================
//   CORE_REG
//================================================================
always @(posedge clk or negedge rst_n)
begin
    if (~rst_n)
    begin
        core_r0 <= 0 ;
    end
    else if(st_R_WB && rd==0)
    begin
        core_r0 <= alu_out_ff;
    end
    else if(st_MEM_WB && rt==0)
    begin
        core_r0 <= dmem_data_ff;
    end
end


always @(posedge clk or negedge rst_n)
begin
    if (~rst_n)
    begin
        core_r1 <= 0 ;
    end
    else if(st_R_WB && rd==1)
    begin
        core_r1 <= alu_out_ff;
    end
    else if(st_MEM_WB && rt==1)
    begin
        core_r1 <= dmem_data_ff;
    end
end


always @(posedge clk or negedge rst_n)
begin
    if (~rst_n)
    begin
        core_r2 <= 0 ;
    end
    else if(st_R_WB && rd==2)
    begin
        core_r2 <= alu_out_ff;
    end
    else if(st_MEM_WB && rt==2)
    begin
        core_r2 <= dmem_data_ff;
    end
end


always @(posedge clk or negedge rst_n)
begin
    if (~rst_n)
    begin
        core_r3 <= 0 ;
    end
    else if(st_R_WB && rd==3)
    begin
        core_r3 <= alu_out_ff;
    end
    else if(st_MEM_WB && rt==3)
    begin
        core_r3 <= dmem_data_ff;
    end
end


always @(posedge clk or negedge rst_n)
begin
    if (~rst_n)
    begin
        core_r4 <= 0 ;
    end
    else if(st_R_WB && rd==4)
    begin
        core_r4 <= alu_out_ff;
    end
    else if(st_MEM_WB && rt==4)
    begin
        core_r4 <= dmem_data_ff;
    end
end


always @(posedge clk or negedge rst_n)
begin
    if (~rst_n)
    begin
        core_r5 <= 0 ;
    end
    else if(st_R_WB && rd==5)
    begin
        core_r5 <= alu_out_ff;
    end
    else if(st_MEM_WB && rt==5)
    begin
        core_r5 <= dmem_data_ff;
    end
end


always @(posedge clk or negedge rst_n)
begin
    if (~rst_n)
    begin
        core_r6 <= 0 ;
    end
    else if(st_R_WB && rd==6)
    begin
        core_r6 <= alu_out_ff;
    end
    else if(st_MEM_WB && rt==6)
    begin
        core_r6 <= dmem_data_ff;
    end
end


always @(posedge clk or negedge rst_n)
begin
    if (~rst_n)
    begin
        core_r7 <= 0 ;
    end
    else if(st_R_WB && rd==7)
    begin
        core_r7 <= alu_out_ff;
    end
    else if(st_MEM_WB && rt==7)
    begin
        core_r7 <= dmem_data_ff;
    end
end


always @(posedge clk or negedge rst_n)
begin
    if (~rst_n)
    begin
        core_r8 <= 0 ;
    end
    else if(st_R_WB && rd==8)
    begin
        core_r8 <= alu_out_ff;
    end
    else if(st_MEM_WB && rt==8)
    begin
        core_r8 <= dmem_data_ff;
    end
end


always @(posedge clk or negedge rst_n)
begin
    if (~rst_n)
    begin
        core_r9 <= 0 ;
    end
    else if(st_R_WB && rd==9)
    begin
        core_r9 <= alu_out_ff;
    end
    else if(st_MEM_WB && rt==9)
    begin
        core_r9 <= dmem_data_ff;
    end
end


always @(posedge clk or negedge rst_n)
begin
    if (~rst_n)
    begin
        core_r10 <= 0 ;
    end
    else if(st_R_WB && rd==10)
    begin
        core_r10 <= alu_out_ff;
    end
    else if(st_MEM_WB && rt==10)
    begin
        core_r10 <= dmem_data_ff;
    end
end


always @(posedge clk or negedge rst_n)
begin
    if (~rst_n)
    begin
        core_r11 <= 0 ;
    end
    else if(st_R_WB && rd==11)
    begin
        core_r11 <= alu_out_ff;
    end
    else if(st_MEM_WB && rt==11)
    begin
        core_r11 <= dmem_data_ff;
    end
end


always @(posedge clk or negedge rst_n)
begin
    if (~rst_n)
    begin
        core_r12 <= 0 ;
    end
    else if(st_R_WB && rd==12)
    begin
        core_r12 <= alu_out_ff;
    end
    else if(st_MEM_WB && rt==12)
    begin
        core_r12 <= dmem_data_ff;
    end
end



always @(posedge clk or negedge rst_n)
begin
    if (~rst_n)
    begin
        core_r13 <= 0 ;
    end
    else if(st_R_WB && rd==13)
    begin
        core_r13 <= alu_out_ff;
    end
    else if(st_MEM_WB && rt==13)
    begin
        core_r13 <= dmem_data_ff;
    end
end



always @(posedge clk or negedge rst_n)
begin
    if (~rst_n)
    begin
        core_r14 <= 0 ;
    end
    else if(st_R_WB && rd==14)
    begin
        core_r14 <= alu_out_ff;
    end
    else if(st_MEM_WB && rt==14)
    begin
        core_r14 <= dmem_data_ff;
    end
end

always @(posedge clk or negedge rst_n)
begin
    if (~rst_n)
    begin
        core_r15 <= 0 ;
    end
    else if(st_R_WB && rd==15)
    begin
        core_r15 <= alu_out_ff;
    end
    else if(st_MEM_WB && rt==15)
    begin
        core_r15 <= dmem_data_ff;
    end
end

//================================================================
//   Instruction Memory
//================================================================
//======================
//   inner reg/wire
//======================
reg[6:0]  i_cache_addr;
wire [15:0] i_cache_d_out0,i_cache_d_out1;
reg signed[15:0] i_cache_d_in;
reg i_cache_we0,i_cache_we1;

reg[3:0] i_cache_tag_ff[0:1];
reg[1:0] i_cache_valid_ff;
reg ic_recently_used_ff;


// wire ic_hit_f  = (i_cache_valid_ff == 1'b1) && (i_cache_tag_ff == ic_in_addr_ff[10:7]);

wire ic0_hit_f = (i_cache_valid_ff[0] == 1'b1) && (i_cache_tag_ff[0] == ic_in_addr_ff[10:7]);
wire ic1_hit_f = (i_cache_valid_ff[1] == 1'b1) && (i_cache_tag_ff[1] == ic_in_addr_ff[10:7]);

wire ic_hit_f = ic0_hit_f || ic1_hit_f;

wire ic_block_to_replace = ~ic_recently_used_ff;

//======================
//   MAIN IC Control
//======================
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        inst_cache_cur_st <= IC_IDLE;
    end
    else
    begin
        inst_cache_cur_st <= inst_cache_nxt_st;
    end
end

always @(*)
begin
    inst_cache_nxt_st = inst_cache_cur_st;
    case(inst_cache_cur_st)
    IC_IDLE:
    begin
        inst_cache_nxt_st = ic_in_valid ? IC_CHECK : IC_IDLE;
    end
    IC_CHECK:
    begin
        inst_cache_nxt_st = ic_hit_f ? IC_OUTPUT : IC_AXI_RD_ADDR;
    end
    IC_OUTPUT:
    begin
        inst_cache_nxt_st = IC_IDLE;
    end
    IC_AXI_RD_ADDR:
    begin
        inst_cache_nxt_st = axi_inst_rd_addr_done_f ? IC_AXI_RD_DATA_UPDATE_CASH : IC_AXI_RD_ADDR;
    end
    IC_AXI_RD_DATA_UPDATE_CASH:
    begin
        inst_cache_nxt_st = axi_inst_rd_data_done_f ? IC_CHECK : IC_AXI_RD_DATA_UPDATE_CASH;
    end
    endcase
end

//======================
//   Valid and tags
//======================
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        i_cache_valid_ff[0] <= 1'b0;
        i_cache_valid_ff[1] <= 1'b0;
    end
    else if(st_IC_AXI_RD_ADDR)
    begin
        if(ic_block_to_replace == 1'b1)
            i_cache_valid_ff[1] <= 1'b1;
        else
            i_cache_valid_ff[0] <= 1'b1;
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        i_cache_tag_ff[0] <= 4'd0;
        i_cache_tag_ff[1] <= 4'd0;
    end
    else if(st_IC_AXI_RD_ADDR)
    begin
        if(ic_block_to_replace == 1'b1)
            i_cache_tag_ff[1] <= ic_in_addr_ff[10:7];
        else
            i_cache_tag_ff[0] <= ic_in_addr_ff[10:7];
    end
end

wire[15:0] pc_to_mem_addr = pc_ff << 1;

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        ic_in_addr_ff <= 0;
    end
    else if(ic_in_valid)
    begin
        ic_in_addr_ff <= pc_to_mem_addr[11:1];
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        ic_recently_used_ff <= 0;
    end
    else if(st_IC_CHECK)
    begin
        if(ic0_hit_f)
            ic_recently_used_ff <= 1'b0;
        else if(ic1_hit_f)
            ic_recently_used_ff <= 1'b1;
    end
end


SRAM_128x16 I_0CACHE(.A0(i_cache_addr[0]),.A1(i_cache_addr[1]),.A2(i_cache_addr[2]),.A3(i_cache_addr[3]),
                    .A4(i_cache_addr[4]),.A5(i_cache_addr[5]),.A6(i_cache_addr[6]),
                    .DO0(i_cache_d_out0[0]),.DO1(i_cache_d_out0[1]),.DO2(i_cache_d_out0[2]),.DO3(i_cache_d_out0[3]),
                    .DO4(i_cache_d_out0[4]),.DO5(i_cache_d_out0[5]),.DO6(i_cache_d_out0[6]),
                    .DO7(i_cache_d_out0[7]),.DO8(i_cache_d_out0[8]),.DO9(i_cache_d_out0[9]),
                    .DO10(i_cache_d_out0[10]),.DO11(i_cache_d_out0[11]),
                    .DO12(i_cache_d_out0[12]),.DO13(i_cache_d_out0[13]),.DO14(i_cache_d_out0[14]),.DO15(i_cache_d_out0[15]),
                    .DI0(i_cache_d_in[0]),.DI1(i_cache_d_in[1]),.DI2(i_cache_d_in[2]),
                    .DI3(i_cache_d_in[3]),.DI4(i_cache_d_in[4]),.DI5(i_cache_d_in[5]),
                    .DI6(i_cache_d_in[6]),.DI7(i_cache_d_in[7]),.DI8(i_cache_d_in[8]),.DI9(i_cache_d_in[9]),
                    .DI10(i_cache_d_in[10]),.DI11(i_cache_d_in[11]),.DI12(i_cache_d_in[12]),.DI13(i_cache_d_in[13]),
                    .DI14(i_cache_d_in[14]),.DI15(i_cache_d_in[15]),
                    .CK(clk),.WEB(i_cache_we0),.OE(1'b1),.CS(1'b1));

SRAM_128x16 I_1CACHE(.A0(i_cache_addr[0]),.A1(i_cache_addr[1]),.A2(i_cache_addr[2]),.A3(i_cache_addr[3]),
                    .A4(i_cache_addr[4]),.A5(i_cache_addr[5]),.A6(i_cache_addr[6]),
                    .DO0(i_cache_d_out1[0]),.DO1(i_cache_d_out1[1]),.DO2(i_cache_d_out1[2]),.DO3(i_cache_d_out1[3]),
                    .DO4(i_cache_d_out1[4]),.DO5(i_cache_d_out1[5]),.DO6(i_cache_d_out1[6]),
                    .DO7(i_cache_d_out1[7]),.DO8(i_cache_d_out1[8]),.DO9(i_cache_d_out1[9]),
                    .DO10(i_cache_d_out1[10]),.DO11(i_cache_d_out1[11]),
                    .DO12(i_cache_d_out1[12]),.DO13(i_cache_d_out1[13]),.DO14(i_cache_d_out1[14]),.DO15(i_cache_d_out1[15]),
                    .DI0(i_cache_d_in[0]),.DI1(i_cache_d_in[1]),.DI2(i_cache_d_in[2]),
                    .DI3(i_cache_d_in[3]),.DI4(i_cache_d_in[4]),.DI5(i_cache_d_in[5]),
                    .DI6(i_cache_d_in[6]),.DI7(i_cache_d_in[7]),.DI8(i_cache_d_in[8]),.DI9(i_cache_d_in[9]),
                    .DI10(i_cache_d_in[10]),.DI11(i_cache_d_in[11]),.DI12(i_cache_d_in[12]),.DI13(i_cache_d_in[13]),
                    .DI14(i_cache_d_in[14]),.DI15(i_cache_d_in[15]),
                    .CK(clk),.WEB(i_cache_we1),.OE(1'b1),.CS(1'b1));

wire[15:0] i_cache_d_out = ic0_hit_f ? i_cache_d_out0 : i_cache_d_out1;

// I-Cache i/o controlls
always @(*)
begin
    if(st_IC_AXI_RD_DATA_UPDATE_CASH && axi_inst_rd_data_tran_f)
    begin
        // Write data
        if(ic0_hit_f)
        begin
            i_cache_we0 = 1'b0;
            i_cache_we1 = 1'b1;
        end
        else
        begin
            i_cache_we0 = 1'b1;
            i_cache_we1 = 1'b0;
        end
    end
    else
    begin
        i_cache_we0 = 1'b1;
        i_cache_we1 = 1'b1;
    end
end

always @(*)
begin
    if(st_IC_AXI_RD_DATA_UPDATE_CASH && axi_inst_rd_data_tran_f)
    begin
        // Write data
        i_cache_addr = axi_burst_cnt; // 0~127
        i_cache_d_in = rdata_m_inf[DRAM_NUMBER * DATA_WIDTH-1:DATA_WIDTH];
    end
    else
    begin
        i_cache_addr = ic_in_addr_ff[6:0];
        i_cache_d_in = 0;
    end
end

//======================
//   Output
//======================
always @(*)
begin
    if(st_IC_OUTPUT)
    begin
        ic_out_inst_wr  = i_cache_d_out;
        ic_out_valid = 1;
    end
    else
    begin
        ic_out_inst_wr  = i_cache_d_out;
        ic_out_valid = 0;
    end
end

//================================================================
//   Data Memory
//================================================================
//======================
//   address & data in
//======================
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        dc_in_addr_ff  <= 0;
        dc_in_data_ff  <= alu_out_ff;
    end
    else if(dc_in_valid)
    begin
        //Probably incorrect here
        dc_in_addr_ff  <= alu_out_wr[11:1];

        if(dc_in_write == 1'b1)
        begin
            dc_in_data_ff  <= reg_data2_ff;
        end
        else
        begin
            dc_in_data_ff  <= alu_out_ff;
        end
    end
end

//======================
//   flags
//======================
// reg d_cache_valid_ff;
reg[3:0] d_cache_tag_ff[0:1];
reg dc_recently_used_ff;

wire[3:0] dc_curr_tag = dc_in_addr_ff[10:7];

wire dc0_hit_f = (d_cache_valid_ff[0] == 1'b1) && (d_cache_tag_ff[0] == dc_curr_tag);
wire dc1_hit_f = (d_cache_valid_ff[1] == 1'b1) && (d_cache_tag_ff[1] == dc_curr_tag);

wire dc_hit_f  = dc0_hit_f || dc1_hit_f;
wire dc_block_to_replace = ~dc_recently_used_ff;
//======================
//   Valid & tags
//======================
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        d_cache_valid_ff[0] <= 1'b0;
        d_cache_valid_ff[1] <= 1'b0;
    end
    else if(st_DC_AXI_RD_ADDR)
    begin
        if(dc_block_to_replace == 1'b1)
            d_cache_valid_ff[1] <= 1'b1;
        else
            d_cache_valid_ff[0] <= 1'b1;
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        d_cache_tag_ff[0] <= 0;
        d_cache_tag_ff[1] <= 0;
    end
    else if(st_DC_AXI_RD_ADDR)
    begin
        if(dc_block_to_replace == 1'b1)
            d_cache_tag_ff[1] <= dc_curr_tag;
        else
            d_cache_tag_ff[0] <= dc_curr_tag;
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        dc_recently_used_ff <= 0;
    end
    else if(st_DC_CHECK)
    begin
        if(dc0_hit_f)
            dc_recently_used_ff <= 1'b0;
        else if(dc1_hit_f)
            dc_recently_used_ff <= 1'b1;
    end
end

//======================
//   MAIN D-Cache Control
//======================
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        data_cache_cur_st <= DC_IDLE;
    end
    else
    begin
        data_cache_cur_st <= data_cache_nxt_st;
    end
end

always @(*)
begin
    data_cache_nxt_st = data_cache_cur_st;
    case(data_cache_cur_st)
    DC_IDLE:
    begin
        if(dc_in_valid)
        begin
            if(dc_in_write == 1'b0)
            begin
                data_cache_nxt_st = DC_CHECK;
            end
            else
            begin
                data_cache_nxt_st = DC_CHECK_WR;
            end
        end
    end
    DC_CHECK_WR:
    begin
        data_cache_nxt_st = dc_hit_f ? DC_WRITE_SRAM : DC_AXI_WR_ADDR;
    end
    DC_CHECK:
    begin
        data_cache_nxt_st = dc_hit_f ? DC_OUTPUT : DC_AXI_RD_ADDR;
    end
    DC_OUTPUT:
    begin
        data_cache_nxt_st = DC_IDLE;
    end
    DC_AXI_RD_ADDR:
    begin
        data_cache_nxt_st = axi_data_rd_addr_done_f ? DC_AXI_RD_DATA_UPDATE_CASH : DC_AXI_RD_ADDR;
    end
    DC_AXI_RD_DATA_UPDATE_CASH:
    begin
        data_cache_nxt_st = axi_data_rd_data_done_f ? DC_CHECK : DC_AXI_RD_DATA_UPDATE_CASH;
    end
    DC_WRITE_SRAM:
    begin
        data_cache_nxt_st = DC_AXI_WR_ADDR;
    end
    DC_AXI_WR_ADDR:
    begin
        data_cache_nxt_st = axi_wr_addr_done_f ? DC_AXI_WR_DATA : DC_AXI_WR_ADDR;
    end
    DC_AXI_WR_DATA:
    begin
        data_cache_nxt_st = axi_wr_data_done_f ? DC_AXI_WR_RESP : DC_AXI_WR_DATA;
    end
    DC_AXI_WR_RESP:
    begin
        data_cache_nxt_st = axi_wr_responed_f  ? DC_IDLE : DC_AXI_WR_RESP;
    end
    endcase
end



SRAM_128x16 D_0CACHE( .A0(d_cache_addr[0]),.A1(d_cache_addr[1]),.A2(d_cache_addr[2]),.A3(d_cache_addr[3]),.A4(d_cache_addr[4]),
                    .A5(d_cache_addr[5]),.A6(d_cache_addr[6]),
                    .DO0(d_cache_d_out0[0]),.DO1(d_cache_d_out0[1]),.DO2(d_cache_d_out0[2]),.DO3(d_cache_d_out0[3]),
                    .DO4(d_cache_d_out0[4]),.DO5(d_cache_d_out0[5]),.DO6(d_cache_d_out0[6]),
                    .DO7(d_cache_d_out0[7]),.DO8(d_cache_d_out0[8]),.DO9(d_cache_d_out0[9]),
                    .DO10(d_cache_d_out0[10]),.DO11(d_cache_d_out0[11]),
                    .DO12(d_cache_d_out0[12]),.DO13(d_cache_d_out0[13]),.DO14(d_cache_d_out0[14]),
                    .DO15(d_cache_d_out0[15]),
                    .DI0(d_cache_d_in[0]),.DI1(d_cache_d_in[1]),.DI2(d_cache_d_in[2]),
                    .DI3(d_cache_d_in[3]),.DI4(d_cache_d_in[4]),.DI5(d_cache_d_in[5]),
                    .DI6(d_cache_d_in[6]),.DI7(d_cache_d_in[7]),.DI8(d_cache_d_in[8]),.DI9(d_cache_d_in[9]),
                    .DI10(d_cache_d_in[10]),.DI11(d_cache_d_in[11]),.DI12(d_cache_d_in[12]),
                    .DI13(d_cache_d_in[13]),.DI14(d_cache_d_in[14]),.DI15(d_cache_d_in[15]),
                    .CK(clk),.WEB(d_cache_we0),.OE(1'b1),.CS(1'b1));

SRAM_128x16 D_1CACHE( .A0(d_cache_addr[0]),.A1(d_cache_addr[1]),.A2(d_cache_addr[2]),.A3(d_cache_addr[3]),.A4(d_cache_addr[4]),
                    .A5(d_cache_addr[5]),.A6(d_cache_addr[6]),
                    .DO0(d_cache_d_out1[0]),.DO1(d_cache_d_out1[1]),.DO2(d_cache_d_out1[2]),.DO3(d_cache_d_out1[3]),
                    .DO4(d_cache_d_out1[4]),.DO5(d_cache_d_out1[5]),.DO6(d_cache_d_out1[6]),
                    .DO7(d_cache_d_out1[7]),.DO8(d_cache_d_out1[8]),.DO9(d_cache_d_out1[9]),
                    .DO10(d_cache_d_out1[10]),.DO11(d_cache_d_out1[11]),
                    .DO12(d_cache_d_out1[12]),.DO13(d_cache_d_out1[13]),.DO14(d_cache_d_out1[14]),
                    .DO15(d_cache_d_out1[15]),
                    .DI0(d_cache_d_in[0]),.DI1(d_cache_d_in[1]),.DI2(d_cache_d_in[2]),
                    .DI3(d_cache_d_in[3]),.DI4(d_cache_d_in[4]),.DI5(d_cache_d_in[5]),
                    .DI6(d_cache_d_in[6]),.DI7(d_cache_d_in[7]),.DI8(d_cache_d_in[8]),.DI9(d_cache_d_in[9]),
                    .DI10(d_cache_d_in[10]),.DI11(d_cache_d_in[11]),.DI12(d_cache_d_in[12]),
                    .DI13(d_cache_d_in[13]),.DI14(d_cache_d_in[14]),.DI15(d_cache_d_in[15]),
                    .CK(clk),.WEB(d_cache_we1),.OE(1'b1),.CS(1'b1));

assign d_cache_d_out = dc0_hit_f ? d_cache_d_out0 : d_cache_d_out1;
//=============================
//   D-Cache i/o controlls
//=============================
always @(*)
begin
    if((st_DC_AXI_RD_DATA_UPDATE_CASH && axi_data_rd_data_tran_f)||st_DC_WRITE_SRAM)
    begin
        // Write data
        if(dc0_hit_f)
        begin
            d_cache_we0 = 1'b0;
            d_cache_we1 = 1'b1;
        end
        else
        begin
            d_cache_we0 = 1'b1;
            d_cache_we1 = 1'b0;
        end
    end
    else
    begin
        d_cache_we0 = 1'b1;
        d_cache_we1 = 1'b1;
    end
end

always @(*)
begin
    if(st_DC_AXI_RD_DATA_UPDATE_CASH && axi_data_rd_data_tran_f)
    begin
        //Writes
        d_cache_addr = axi_burst_cnt;
        d_cache_d_in = rdata_m_inf[DATA_WIDTH-1:0];
    end
    else if(st_DC_WRITE_SRAM) // Something goes wrong here?
    begin
        //Writes
        d_cache_addr = dc_in_addr_ff[6:0];
        d_cache_d_in = dc_in_data_ff;
    end
    else
    begin
        // Reads
        d_cache_addr = dc_in_addr_ff[6:0];
        d_cache_d_in = 0;
    end
end

//======================
//   Outputs
//======================
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        dc_out_valid_ff <= 0;
        dc_out_data_ff  <= 0;
    end
    else if(st_DC_OUTPUT)
    begin
        dc_out_valid_ff <= 1;
        dc_out_data_ff  <= d_cache_d_out;
    end
end

//================================================================
//   AXI Interfaces
//================================================================
// constant AXI 4 signals
// Same for both instr and data
//inst
//read address
assign arid_m_inf[DRAM_NUMBER * ID_WIDTH-1:ID_WIDTH] = 0;
assign arlen_m_inf[DRAM_NUMBER * 7 -1:7]   = 7'b111_1111 ;
assign arsize_m_inf[DRAM_NUMBER * 3 -1:3]  = 3'b001 ;
assign arburst_m_inf[DRAM_NUMBER * 2 -1:2] = 2'b01 ;

assign rid_m_inf = 0;

//data
//read address
assign arid_m_inf[ID_WIDTH-1:0] = 0;
assign arlen_m_inf[7 -1:0]   = 7'b111_1111 ;
assign arsize_m_inf[3 -1:0]  = 3'b001 ;
assign arburst_m_inf[2 -1:0] = 2'b01 ;

//write address
assign awid_m_inf  = 0 ;
assign awlen_m_inf = 7'd0 ;
assign awsize_m_inf = 3'b001 ;
assign awburst_m_inf = 2'b01 ;

//========================
//   Instruction read
//========================

//Write address channel
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        awaddr_m_inf  <= 0;
        awvalid_m_inf <= 0;
    end
    else if(st_DC_AXI_WR_ADDR)
    begin
        awaddr_m_inf  <=  axi_wr_addr_done_f ? 0: alu_out_wr_d1;
        awvalid_m_inf <=  axi_wr_addr_done_f ? 0: 1'b1;
    end
end



// Write data channel
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        wlast_m_inf <= 0;
    end
    else if(st_DC_AXI_WR_DATA)
    begin
        wlast_m_inf <= 1;
    end
    else
    begin
        wlast_m_inf <= 0;
    end
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        wdata_m_inf  <= 0;
        wvalid_m_inf <= 0;
    end
    else if(st_DC_AXI_WR_DATA)
    begin
        wdata_m_inf  <= dc_in_data_ff;
        wvalid_m_inf <= 1'b1;
    end
    else
    begin
        wdata_m_inf  <= 0;
        wvalid_m_inf <= 1'b0;
    end
end

//Write Response channel
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
        bready_m_inf <= 0;
    else if(st_DC_AXI_WR_RESP)
        bready_m_inf <= 1'b1;
    else
        bready_m_inf <= 1'b0;
end

wire[10:0] ic_block_start_addr = ic_in_addr_ff - ic_in_addr_ff[6:0];
wire[10:0] dc_block_start_addr = dc_in_addr_ff - dc_in_addr_ff[6:0];

// Read address
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        arvalid_m_inf <= 0;
        araddr_m_inf  <= 0;
    end
    else if(st_IC_AXI_RD_ADDR)
    begin
        arvalid_m_inf[1] <= axi_inst_rd_addr_done_f ? 0 : 1;
        araddr_m_inf[DRAM_NUMBER * ADDR_WIDTH-1:ADDR_WIDTH] <= axi_inst_rd_addr_done_f ? 0 :
        {16'b0,4'b0001,ic_block_start_addr,1'b0};
    end
    else if(st_DC_AXI_RD_ADDR)
    begin
        arvalid_m_inf[0] <= axi_data_rd_addr_done_f ? 0 : 1;
        araddr_m_inf[ADDR_WIDTH-1:0]  <= axi_data_rd_addr_done_f ? 0 :
         {16'b0,4'b0001,dc_block_start_addr,1'b0};
    end
    else
    begin
        arvalid_m_inf <= 0;
        araddr_m_inf  <= 0;
    end
end

// read data
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        rready_m_inf <= 0;
    end
    else if(st_DC_AXI_RD_DATA_UPDATE_CASH)
    begin
        rready_m_inf[0] <= axi_data_rd_data_done_f ? 1'b0 : 1'b1;
    end
    else if(st_IC_AXI_RD_DATA_UPDATE_CASH)
    begin
        rready_m_inf[1] <= axi_inst_rd_data_done_f ? 1'b0 : 1'b1;
    end
    else
    begin
        rready_m_inf <= 0;
    end
end

// axi burst cnt
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
        axi_burst_cnt <= 0;
    else if(axi_data_rd_data_done_f || axi_inst_rd_data_done_f || axi_wr_data_done_f)
        axi_burst_cnt <= 0;
    else if(axi_data_rd_data_tran_f || axi_inst_rd_data_tran_f || axi_wr_data_tran_f)
        axi_burst_cnt <= axi_burst_cnt + 1;
end



endmodule


module DW_mult_seq_inst(inst_clk, inst_rst_n, inst_hold, inst_start, inst_a,
inst_b, complete_inst, product_inst );
parameter inst_a_width = 16;
parameter inst_b_width = 16;
parameter inst_tc_mode = 1;
parameter inst_num_cyc = 5;
parameter inst_rst_mode = 1;
parameter inst_input_mode = 0;
parameter inst_output_mode = 1;
parameter inst_early_start = 0;
// Please add +incdir+$SYNOPSYS/dw/sim_ver+ to your verilog simulator
// command line (for simulation).
input inst_clk;
input inst_rst_n;
input inst_hold;
input inst_start;
input [inst_a_width-1 : 0] inst_a;
input [inst_b_width-1 : 0] inst_b;
output complete_inst;
output [inst_a_width+inst_b_width-1 : 0] product_inst;
// Instance of DW_mult_seq
DW_mult_seq #(inst_a_width,inst_b_width,inst_tc_mode,inst_num_cyc,
inst_rst_mode,inst_input_mode,inst_output_mode,inst_early_start)
U1 (.clk(inst_clk),
.rst_n(inst_rst_n),
.hold(inst_hold),
.start(inst_start),
.a(inst_a),
.b(inst_b),
.complete(complete_inst),
.product(product_inst) );
endmodule
