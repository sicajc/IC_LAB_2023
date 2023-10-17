//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2023 ICLAB Fall Course
//   Lab03      : BRIDGE
//   Author     : YEH SHUN LIANG
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : BRIDGE.v
//   Module Name : BRIDGE
//   Release version : v1.0 (Release Date: Sep-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module BRIDGE(
           // Input Signals
           clk,
           rst_n,
           in_valid,
           direction,
           addr_dram,
           addr_sd,
           // Output Signals
           out_valid,
           out_data,
           // DRAM Signals
           AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
           AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP,
           // SD Signals
           MISO,
           MOSI
       );

// Input Signals
input clk, rst_n;
input in_valid;
input direction;
input [12:0] addr_dram;
input [15:0] addr_sd;

// Output Signals
output reg out_valid;
output reg [7:0] out_data;

// DRAM Signals
// write address channel
output reg [31:0] AW_ADDR;
output reg AW_VALID;
input AW_READY;
// write data channel
output reg W_VALID;
output reg [63:0] W_DATA;
input W_READY;
// write response channel
input B_VALID;
input [1:0] B_RESP;
output reg B_READY;
// read address channel
output reg [31:0] AR_ADDR;
output reg AR_VALID;
input AR_READY;
// read data channel
input [63:0] R_DATA;
input R_VALID;
input [1:0] R_RESP;
output reg R_READY;

// SD Signals
input MISO;
output reg MOSI;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
reg[15:0] current_ST,next_ST;

localparam  IDLE                = 16'b0000_0000_0000_0001;
localparam  RD_PATTERN_DATA     = 16'b0000_0000_0000_0010;
localparam  AXI_READ_ADDR       = 16'b0000_0000_0000_0100;
localparam  AXI_READ_DATA       = 16'b0000_0000_0000_1000;
localparam  AXI_WRITE_ADDR      = 16'b0000_0000_0001_0000;
localparam  AXI_WRITE_DATA      = 16'b0000_0000_0010_0000;
localparam  AXI_WRITE_RESP      = 16'b0000_0000_0100_0000;
localparam  SEND_COMMAND        = 16'b0000_0000_1000_0000;
localparam  WAIT_SD_RESP        = 16'b0000_0001_0000_0000;
localparam  WAIT_8_CYCLE        = 16'b0000_0010_0000_0000;
localparam  WAIT_START_TOKEN    = 16'b0000_0100_0000_0000;
localparam  SEND_DATA_TO_SD     = 16'b0000_1000_0000_0000;
localparam  WAIT_SD_DATA_RESP   = 16'b0001_0000_0000_0000;
localparam  GET_DATA_FROM_SD    = 16'b0010_0000_0000_0000;
localparam  OUTPUT_STAGE        = 16'b0100_0000_0000_0000;

wire ST_IDLE                = current_ST[0] ;
wire ST_RD_PATTERN_DATA     = current_ST[1] ;
wire ST_AXI_READ_ADDR       = current_ST[2] ;
wire ST_AXI_READ_DATA       = current_ST[3] ;
wire ST_AXI_WRITE_ADDR      = current_ST[4] ;
wire ST_AXI_WRITE_DATA      = current_ST[5] ;
wire ST_AXI_WRITE_RESP      = current_ST[6] ;
wire ST_SEND_COMMAND        = current_ST[7] ;
wire ST_WAIT_SD_RESP        = current_ST[8] ;
wire ST_WAIT_8_CYCLE        = current_ST[9] ;
wire ST_WAIT_START_TOKEN    = current_ST[10] ;
wire ST_SEND_DATA_TO_SD     = current_ST[11] ;
wire ST_WAIT_SD_DATA_RESP   = current_ST[12] ;
wire ST_GET_DATA_FROM_SD    = current_ST[13] ;
wire ST_OUTPUT_STAGE        = current_ST[14] ;

//==============================================//
//           reg & wire declaration             //
//==============================================//
reg[12:0] addr_dram_ff;
reg[15:0] addr_sd_ff;
reg[63:0] data_to_sd_ff,data_to_sd_ff2;
reg[63:0] data_from_sd_ff;
reg[39:0] command_ff;
reg dir_ff;
reg[15:0] cnt;
reg data_resp_f_ff;

reg[6:0] crc7;
reg[15:0] crc16;
wire sending_crc7_f  = (cnt<=7) && (cnt>0) && ST_SEND_COMMAND;
wire sending_crc16_f = (cnt<=15) &&  ST_SEND_DATA_TO_SD;
wire crc7_data_out  = crc7[6];
wire crc16_data_out = crc16[15];
wire crc7_data_in   = command_ff[39];
wire crc16_data_in  = data_to_sd_ff[63];


//==============================================//
//           flags                              //
//==============================================//
wire SD_TO_DRAM_f                               = dir_ff == 1;
wire DRAM_TO_SD_f                               = dir_ff == 0;
wire axi_rd_addr_tx_f                           = AR_VALID && AR_READY;
wire axi_rd_data_tx_f                           = (R_RESP ==2'b00) && R_VALID && R_READY;
wire cmd_senf_f                                 = cnt == 0  && ST_SEND_COMMAND;
wire sd_responed_f                              = cnt == 7  && ST_WAIT_SD_RESP;
wire waited_8_cycle_f                           = cnt == 0  && ST_WAIT_8_CYCLE;
wire data_sent_to_sd_f                          = cnt == 0 && ST_SEND_DATA_TO_SD;
wire data_received_from_sd_f                    = cnt == 0 && ST_GET_DATA_FROM_SD;
wire axi_wr_addr_tx_f                           = AW_VALID && AW_READY ;
wire axi_wr_data_tx_f                           = W_VALID && W_READY;
wire axi_wr_resp_tx_f                           = B_VALID && B_READY && B_RESP == 2'b00;
wire data_responed_not_busy_f                   = cnt == 0 && MISO == 1 && ST_WAIT_SD_DATA_RESP;
wire out_done_f                                 = cnt == 7 && ST_OUTPUT_STAGE;


//==============================================//
//                  FSM                     //
//==============================================//
always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        current_ST <= IDLE;
    end
    else
    begin
        current_ST <= next_ST;
    end
end

always @(*)
begin:MAIN_CTR
    next_ST = current_ST;
    case (current_ST)
        IDLE:
        begin
            next_ST = in_valid ? RD_PATTERN_DATA : IDLE;
        end
        RD_PATTERN_DATA:
        begin
            next_ST = DRAM_TO_SD_f ? AXI_READ_ADDR : SEND_COMMAND;
        end
        AXI_READ_ADDR:
        begin
            next_ST = axi_rd_addr_tx_f ? AXI_READ_DATA : AXI_READ_ADDR;
        end
        AXI_READ_DATA:
        begin
            next_ST = axi_rd_data_tx_f ? SEND_COMMAND :AXI_READ_DATA;
        end
        SEND_COMMAND:
        begin
            next_ST = cmd_senf_f    ? WAIT_SD_RESP : SEND_COMMAND;
        end
        WAIT_SD_RESP:
        begin
            next_ST = sd_responed_f ? WAIT_8_CYCLE : WAIT_SD_RESP;
        end
        WAIT_8_CYCLE:
        begin
            next_ST = waited_8_cycle_f ? (SD_TO_DRAM_f ? WAIT_START_TOKEN: SEND_DATA_TO_SD) : WAIT_8_CYCLE;
        end
        WAIT_START_TOKEN:
        begin
            next_ST = (MISO == 0) ? GET_DATA_FROM_SD : WAIT_START_TOKEN;
        end
        SEND_DATA_TO_SD:
        begin
            next_ST = data_sent_to_sd_f ? WAIT_SD_DATA_RESP : SEND_DATA_TO_SD;
        end
        GET_DATA_FROM_SD:
        begin
            next_ST = data_received_from_sd_f ? AXI_WRITE_ADDR : GET_DATA_FROM_SD;
        end
        AXI_WRITE_ADDR:
        begin
            next_ST = axi_wr_addr_tx_f ? AXI_WRITE_DATA : AXI_WRITE_ADDR;
        end
        AXI_WRITE_DATA:
        begin
            next_ST = axi_wr_data_tx_f ? AXI_WRITE_RESP: AXI_WRITE_DATA;
        end
        AXI_WRITE_RESP:
        begin
            next_ST = axi_wr_resp_tx_f ? OUTPUT_STAGE: AXI_WRITE_RESP;
        end
        WAIT_SD_DATA_RESP:
        begin
            next_ST = data_responed_not_busy_f ? OUTPUT_STAGE : WAIT_SD_DATA_RESP;
        end
        OUTPUT_STAGE:
        begin
            next_ST = out_done_f ? IDLE : OUTPUT_STAGE;
        end
    endcase
end



integer idx;
always @(posedge clk or negedge rst_n)
begin:DATAPATH
    if(~rst_n)
    begin
        out_valid  <= 0 ;
        out_data   <= 0 ;
        AW_ADDR    <= 0 ;
        AW_VALID   <= 0 ;
        W_VALID    <= 0 ;
        W_DATA     <= 0 ;
        B_READY    <= 0 ;
        AR_ADDR    <= 0 ;
        AR_VALID   <= 0 ;
        R_READY    <= 0 ;
        MOSI       <= 1 ;
        dir_ff     <= 0 ;
        cnt        <= 0 ;
        // Since nWave would not display the 0 of the bit.
        command_ff <= 40'b0100_0000_0000_0000_0000_0000_0000_0000_0000_0000;
        data_to_sd_ff      <= 0;
        data_to_sd_ff2     <= 0;
        data_from_sd_ff    <= 0;
        data_resp_f_ff     <= 0;
    end
    else
    begin
        case (current_ST)
            IDLE:
            begin
                if(in_valid)
                begin
                    dir_ff      <= direction;
                    addr_dram_ff<= addr_dram;
                    addr_sd_ff  <= addr_sd;
                end
                else
                begin
                    out_valid <= 0 ;
                    out_data  <= 0 ;
                    AW_ADDR   <= 0 ;
                    AW_VALID  <= 0 ;
                    W_VALID   <= 0 ;
                    W_DATA    <= 0 ;
                    B_READY   <= 0 ;
                    AR_ADDR   <= 0 ;
                    AR_VALID  <= 0 ;
                    R_READY   <= 0 ;
                    MOSI      <= 1 ;
                    command_ff <= 40'b0100_0000_0000_0000_0000_0000_0000_0000_0000_0000;
                    data_resp_f_ff <= 0;
                end
            end
            RD_PATTERN_DATA:
            begin
                cnt <= 47;
                if(DRAM_TO_SD_f)
                begin
                    command_ff[37:32] <= 6'd24;
                end
                else if(SD_TO_DRAM_f)
                begin
                    command_ff[37:32] <= 6'd17;
                end
                command_ff[31:0]  <= {{16{1'b0}},addr_sd_ff};
            end
            AXI_READ_ADDR:
            begin
                if(axi_rd_addr_tx_f)
                begin
                    AR_VALID <= 0;
                    AR_ADDR  <= 0;
                end
                else
                begin
                    AR_VALID <= 1;
                    AR_ADDR  <= addr_dram_ff;
                end
            end
            AXI_READ_DATA:
            begin
                if(axi_rd_data_tx_f)
                begin
                    R_READY <= 0;
                    data_to_sd_ff <= R_DATA;
                    data_to_sd_ff2 <= R_DATA;
                end
                else
                begin
                    R_READY <= 1;
                end
            end
            SEND_COMMAND:
            begin
                // First wait until crc7 finish calculation
                for(idx=1;idx<=39;idx=idx+1)
                begin
                    command_ff[idx] <= command_ff[idx-1];
                end

                if(cmd_senf_f)
                begin
                    cnt <= 0;
                end
                else
                begin
                    cnt <= cnt-1;
                end

                // Sending out 48 bits of data start_bit,trans_bit,command,32_address,7_crc7,end_bit
                if(cmd_senf_f)
                begin
                    MOSI <= 1;
                end
                else if(cnt>=8)
                begin
                    //Sending the upper command out
                    MOSI <= command_ff[39];
                end
                else if(sending_crc7_f)
                begin
                    // Sending the CRC7 out
                    MOSI <= crc7_data_out;
                end
                else if(cnt==0)
                begin
                    // The end bit
                    MOSI <= 1;
                end
            end
            WAIT_SD_RESP:
            begin
                if(sd_responed_f)
                begin
                    cnt <= 7;
                end
                else
                begin
                    if(MISO == 0)
                    begin
                        cnt <= cnt + 1;
                    end
                    else
                    begin
                        cnt <= 0;
                    end
                end
            end
            WAIT_8_CYCLE:
            begin
                if(waited_8_cycle_f)
                begin
                    if(DRAM_TO_SD_f)
                    begin
                        cnt <= 86;
                    end
                    else if(SD_TO_DRAM_f)
                    begin
                        cnt <= 79;
                    end
                end
                else
                begin
                    cnt <= cnt - 1;
                end
            end
            SEND_DATA_TO_SD:
            begin
                // First wait until crc16 finish processing
                // Linear shifter
                if(cnt>=16 && (cnt<=79))
                begin
                    for(idx=1;idx<=63;idx=idx+1)
                    begin
                        data_to_sd_ff[idx] <=data_to_sd_ff[idx-1];
                    end
                end

                if(data_sent_to_sd_f)
                begin
                    cnt <= 7;
                end
                else
                begin
                    cnt <= cnt -1;
                end

                if(cnt == 80)
                begin
                    MOSI  <= 0;
                end
                else if(cnt>=16 && (cnt<=79))
                begin
                    // First send 64 bits data
                    MOSI <= data_to_sd_ff[63];
                end
                else if(sending_crc16_f)
                begin
                    // Then sent 16 bits crc16
                    MOSI <= crc16_data_out;
                end
                else
                begin
                    MOSI <= 1;
                end
            end
            GET_DATA_FROM_SD:
            begin
                //After waited start token, receiving data from MISO
                // Linear shifter,receive data from MISO
                if((cnt>=16) && (cnt <=79))
                begin
                    data_from_sd_ff[0] <= MISO;
                    for(idx=0;idx<63;idx=idx+1)
                    begin
                        data_from_sd_ff[idx+1] <= data_from_sd_ff[idx];
                    end
                end

                if(data_received_from_sd_f)
                begin
                    cnt <= 0;
                end
                else
                begin
                    cnt <= cnt - 1;
                end
            end
            AXI_WRITE_ADDR:
            begin
                if(axi_wr_addr_tx_f)
                begin
                    AW_ADDR  <= 0;
                    AW_VALID <= 0;
                end
                else
                begin
                    AW_ADDR  <= addr_dram_ff;
                    AW_VALID <= 1;
                end
            end
            AXI_WRITE_DATA:
            begin
                if(axi_wr_data_tx_f)
                begin
                    W_VALID <= 0;
                    W_DATA  <= 0;
                end
                else
                begin
                    W_VALID <= 1;
                    W_DATA  <= data_from_sd_ff;
                end
            end
            AXI_WRITE_RESP:
            begin
                if(axi_wr_resp_tx_f)
                begin
                    B_READY <= 0;
                end
                else
                begin
                    B_READY <= 1;
                end
                cnt <= 0;
            end
            WAIT_SD_DATA_RESP:
            begin
                MOSI <= 1;
                if(data_responed_not_busy_f)
                begin
                    data_resp_f_ff <= 0;
                end
                else if(MISO == 0)
                begin
                    data_resp_f_ff <= 1;
                end

                if(data_responed_not_busy_f)
                begin
                    cnt <= 0;
                end
                else if(cnt == 0)
                begin
                    cnt <= cnt;
                end
                else if(data_resp_f_ff)
                begin
                    cnt <= cnt - 1;
                end
                else
                begin
                    cnt <= 7;
                end
            end
            OUTPUT_STAGE:
            begin
                // Since out_data is 8 bit ports, needs to send out the data in different cycles
                out_valid <= 1;
                if(DRAM_TO_SD_f)
                begin
                    out_data <= data_to_sd_ff2[(63 - cnt*8)-:8];
                end
                else if(SD_TO_DRAM_f)
                begin
                    out_data <= data_from_sd_ff[(63 - cnt*8)-:8];
                end
                cnt <= cnt + 1;
            end
        endcase
    end
end

always @(posedge clk or negedge rst_n)
begin:CRC7
    if(~rst_n)
    begin
        crc7 <= 0;
    end
    else if(ST_IDLE)
    begin
        crc7 <= 0;
    end
    else if(ST_SEND_COMMAND)
    begin
        if(~sending_crc7_f)
        begin
            //crc7 datapath
            crc7[0] <= crc7_data_out ^ crc7_data_in;
            crc7[1] <= crc7[0];
            crc7[2] <= crc7[1];
            crc7[3] <= crc7[2] ^ (crc7_data_out ^ crc7_data_in);
            crc7[4] <= crc7[3];
            crc7[5] <= crc7[4];
            crc7[6] <= crc7[5];
        end
        else
        begin
            for(idx=1; idx<=7;idx=idx+1)
            begin
                crc7[idx] <= crc7[idx-1];
            end
        end
    end
end


always @(posedge clk or negedge rst_n)
begin:CRC16
    if(~rst_n)
    begin
        crc16 <= 0 ;
    end
    else if(ST_IDLE)
    begin
        crc16 <= 0;
    end
    else if(ST_SEND_DATA_TO_SD)
    begin
        if(sending_crc16_f)
        begin
            for(idx=1; idx<=15;idx=idx+1)
            begin
                crc16[idx] <= crc16[idx-1];
            end
        end
        else if(cnt<=79)
        begin
            crc16[0] <= crc16_data_out ^ crc16_data_in;
            crc16[1] <= crc16[0];
            crc16[2] <= crc16[1];
            crc16[3] <= crc16[2];
            crc16[4] <= crc16[3];
            crc16[5] <= crc16[4] ^ (crc16_data_out ^ crc16_data_in);
            crc16[6] <= crc16[5];
            crc16[7] <= crc16[6];
            crc16[8] <= crc16[7];
            crc16[9] <= crc16[8];
            crc16[10] <= crc16[9];
            crc16[11] <= crc16[10];
            crc16[12] <= crc16[11] ^ (crc16_data_out ^ crc16_data_in);
            crc16[13] <= crc16[12];
            crc16[14] <= crc16[13];
            crc16[15] <= crc16[14];
        end
    end
end


endmodule