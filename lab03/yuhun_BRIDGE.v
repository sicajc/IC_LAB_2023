//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2023 ICLAB Fall Course
//   Lab03      : BRIDGE
//   Author     : Ting-Yu Chang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : BRIDGE_encrypted.v
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
parameter IDLE			= 4'd0;
parameter DRAM_SD		= 4'd1;
parameter SD_DRAM		= 4'd2;

parameter READ_DRAM		= 4'd3;
parameter WAIT_DRAM 	= 4'd4;
parameter WRITE_COMMAND	= 4'd5;
parameter WAIT_RESP		= 4'd6;
parameter WRITE_DATA 	= 4'd7;
parameter CHECK_DATARESP= 4'd8;
parameter OUT 			= 4'd9;

parameter READ_COMMAND	= 4'd10;
parameter WAIT_RESP_DRAM= 4'd11;
parameter READ_DATA	    = 4'd12;
parameter WRITE_DRAM	= 4'd13;
parameter WRITE_DATA_DRAM= 4'd14;
parameter WAIT_BRESP    = 4'd15;


// reg [3:0]state;
// reg [3:0]n_state;

reg [3:0]state_d2s;
reg [3:0]n_state_d2s;

reg [3:0]state_s2d;
reg [3:0]n_state_s2d;


//==============================================//
//           reg & wire declaration             //
//==============================================//
reg [12:0] addr_dram_save;
reg [15:0] addr_sd_save;
reg  direction_save;

reg [12:0] n_addr_dram_save;
reg [15:0] n_addr_sd_save;
reg  n_direction_save;

reg [5:0] count_command;//n
reg [4:0]count_resp;//n
reg [6:0]count_data;//n
reg [8:0]count_data_resp;//n
reg [3:0]count_out;//n
reg [5:0]n_count_command;//n
reg [4:0]n_count_resp;//n
reg [6:0]n_count_data;//n
reg [8:0]n_count_data_resp;//n
reg [3:0]n_count_out;//n
reg [63:0]data_dram;

reg [47:0]write_command_reg;
wire [6:0]crc7_out;

reg [7:0]response_reg;

reg [87:0]write_data_reg;
wire [15:0]crc16_out;

reg [7:0]data_response_reg;

wire [5:0]command_17_24;
assign command_17_24 = (direction_save)?6'd17:6'd24;

reg [87:0]data_sd;
reg [6:0]count_data_sd;//n
reg [6:0]n_count_data_sd;//n
wire [15:0]crc16_check;
reg [8:0]count_w_valid;//n
reg [8:0]n_count_w_valid;//n
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        count_command <= 0;
    else
        count_command<= n_count_command;

end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        count_resp <= 0;
    else
        count_resp<= n_count_resp;

end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        count_data <= 0;
    else
        count_data<= n_count_data;

end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        count_data_resp <= 0;
    else
        count_data_resp<= n_count_data_resp;

end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        count_out <= 0;
    else
        count_out<= n_count_out;

end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        count_data_sd <= 0;
    else
        count_data_sd<= n_count_data_sd;

end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        count_w_valid <= 0;
    else
        count_w_valid<= n_count_w_valid;

end

//==============================================//
//                  design                      //
//==============================================//
//next_state
// always@* begin
// 	case (state)
// 		IDLE: begin
//             n_state = (direction_save)?SD_DRAM:DRAM_SD;
//             // count_command = 0;
//             // count_resp = 0;
//             // count_data = 1;
//             // count_data_resp = 0;
//             // count_out = 0;
//             // count_data_sd = 0;
//             // count_w_valid = 0;
//         end
//         DRAM_SD: begin
//             n_state = (state_d2s == IDLE)?IDLE:DRAM_SD;
//         end
//         SD_DRAM: begin
//             n_state = (state_s2d == IDLE)?IDLE:SD_DRAM;
//         end
// 		default	 : n_state = IDLE;
// 	endcase
// end

// //current_state
// always@ (posedge clk or negedge rst_n) begin
// 	if (!rst_n) begin
//         state <= IDLE;
//     end
// 	else state <= n_state;
// end


always@* begin
	case (state_d2s)
        IDLE: begin
            n_state_d2s = (in_valid&&direction || direction_save)?IDLE:READ_DRAM;

        end
        READ_DRAM:begin
            n_state_d2s = (AR_READY)?WAIT_DRAM:READ_DRAM;
        end
        WAIT_DRAM:begin
            n_state_d2s = (R_VALID && R_READY)?WRITE_COMMAND:WAIT_DRAM;
        end
        WRITE_COMMAND:begin
            n_state_d2s = (MISO == 0)?WAIT_RESP:WRITE_COMMAND;
        end
        WAIT_RESP:begin
            n_state_d2s = (count_resp == 15)?WRITE_DATA:WAIT_RESP;
        end
        WRITE_DATA:begin
            n_state_d2s = (count_data == 88)?CHECK_DATARESP:WRITE_DATA;
        end
        CHECK_DATARESP:begin
            n_state_d2s = ((count_data_resp > 7) && MISO == 1)?OUT:CHECK_DATARESP;
        end
        OUT :begin
            n_state_d2s = (count_out == 8)?IDLE:OUT;
        end
		default	 : n_state_d2s = IDLE;
	endcase
end
always@ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
        state_d2s <= IDLE;
    end
	else state_d2s <= n_state_d2s;
end

always@* begin
	case (state_s2d)
        IDLE: begin
            n_state_s2d = (in_valid&&!direction || !direction_save)?IDLE:READ_COMMAND;
            // count_command = 0;
            // count_resp = 0;
            // count_data = 1;
            // count_data_resp = 0;
            // count_out = 0;
        end
        READ_COMMAND:begin
            n_state_s2d = (MISO==0)?WAIT_RESP_DRAM:READ_COMMAND;
        end
        WAIT_RESP_DRAM:begin
            n_state_s2d = (count_resp == 16)?READ_DATA:WAIT_RESP_DRAM;
        end
        READ_DATA:begin
            // n_state_s2d = (count_data_sd == 88 && (crc16_check == data_sd[15:0]))?WRITE_DRAM:WAIT_RESP_DRAM;
            n_state_s2d = (count_data_sd == 88 )?WRITE_DRAM:READ_DATA;
        end
        WRITE_DRAM:begin
            n_state_s2d = (AW_READY)?WRITE_DATA_DRAM:WRITE_DRAM;
        end
        WRITE_DATA_DRAM:begin
            n_state_s2d = (W_READY)?WAIT_BRESP:WRITE_DATA_DRAM;
        end
        WAIT_BRESP:begin
            n_state_s2d = ((B_RESP==0)&&B_VALID)?OUT:WAIT_BRESP;
        end
        OUT :begin
            n_state_s2d = (count_out == 8)?IDLE:OUT;
        end
		default	 : n_state_s2d = IDLE;
	endcase
end
always@ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
        state_s2d <= IDLE;
    end
	else state_s2d <= n_state_s2d;
end


//AR_ADDR
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) AR_ADDR <= 0;
	else if(state_d2s == READ_DRAM && n_state_d2s == READ_DRAM ) AR_ADDR <= {19'd0,addr_dram_save};
	else AR_ADDR <= 0;
end


//AR_VALID
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) AR_VALID <= 0;
	else if(state_d2s == READ_DRAM&& n_state_d2s == READ_DRAM) AR_VALID <= 1;
	else AR_VALID <= 0;
end


//R_READY
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) R_READY <= 0;
	else if(n_state_d2s == WAIT_DRAM) R_READY <= 1;
	else R_READY <= 0;
end

//save data from R_DATA
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) data_dram <= 0;
	else if(R_VALID) data_dram <= R_DATA;
	else data_dram <= data_dram;
end




//addr_save
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
        addr_dram_save <= 0;
        addr_sd_save <= 0;
        direction_save <= 0;
    end

	else begin
        addr_dram_save <= n_addr_dram_save;
        addr_sd_save <= n_addr_sd_save;
        direction_save <= n_direction_save;
    end
end
always @(*) begin
	if(in_valid) begin
        n_addr_dram_save = addr_dram;
        n_addr_sd_save = addr_sd;
        n_direction_save = direction;
    end
	else begin
        n_addr_dram_save = addr_dram_save;
        n_addr_sd_save = addr_sd_save;
        n_direction_save = direction_save;
    end
end


CRC7 c1({2'b01,command_17_24,16'b0,addr_sd_save}, crc7_out);
//write_command_reg
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) write_command_reg <= 0;
	// else if(state_d2s == OUT) out_data <= data_dram;
	else write_command_reg <= {2'b01,command_17_24,16'b0,addr_sd_save,crc7_out, 1'b1};
end

//count_command
always @(*) begin
	if(state_d2s == WRITE_COMMAND) n_count_command = count_command+1;
    else if(state_s2d == READ_COMMAND) n_count_command = count_command+1;
	else n_count_command = 0;
end


//count_resp
always @(*) begin
	if(n_state_d2s == WAIT_RESP) n_count_resp = count_resp+1;
    else if(n_state_s2d == WAIT_RESP_DRAM) n_count_resp = count_resp+1;
	else n_count_resp = 0;
end

//response_reg
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) response_reg <= 0;
	else if(n_state_d2s == WAIT_RESP && count_resp<8) response_reg[7-count_resp] <= MISO;
    else if(n_state_d2s == WAIT_RESP_DRAM && count_resp<8) response_reg[7-count_resp] <= MISO;
	else response_reg <= response_reg;
end

CRC16_CCITT c2(data_dram, crc16_out);
//write_data_reg
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) write_data_reg <= 0;
	// else if(state_d2s == OUT) out_data <= data_dram;
	else write_data_reg <= {8'b11111110,data_dram,crc16_out};
end
//count_data
always @(*) begin
	if(n_state_d2s == WRITE_DATA) n_count_data = count_data+1;
	else n_count_data = 0;
end

//count_data_resp
always @(*) begin
	if(state_d2s == CHECK_DATARESP) n_count_data_resp = count_data_resp+1;
	else n_count_data_resp = 0;
end
//data_response_reg
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) data_response_reg <= 0;
	else if(state_d2s == CHECK_DATARESP && count_data_resp<8) data_response_reg[7-count_data_resp] <= MISO;
	else data_response_reg <= data_response_reg;
end

//count_data_sd
always @(*) begin
    if(n_state_s2d == READ_DATA) begin
        if(count_data_sd>87)n_count_data_sd = 0;
        else n_count_data_sd = count_data_sd+1;
        // count_data_sd <= count_data_sd+1;
    end
    // else if(count_data_sd > 88) count_data_sd= 0;
	else n_count_data_sd = 0;
end

//data_sd
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) data_sd <= 0;
	else if(n_state_s2d == READ_DATA && count_data_sd<88) data_sd[87-count_data_sd] <= MISO;
	else data_sd <= data_sd;
end

CRC16_CCITT c3(data_sd[79:16], crc16_check);


//MOSI
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) MOSI <= 1;
	// else if(state_d2s == OUT) out_data <= data_dram;
    else if(state_d2s == WRITE_COMMAND && (count_command<48))begin
        MOSI <= write_command_reg[47 - count_command];
    end
    else if(state_d2s == WRITE_COMMAND && (count_command == 48))begin
        MOSI <= 1;
    end
    else if(n_state_d2s == WRITE_DATA && response_reg == 8'b0 )begin
        MOSI <= write_data_reg[87 - count_data];
        // $display("in write_data if, MOSI");
        // $display("write_command_reg[87 - count_data] = %b", write_command_reg[87 - count_data]);
    end
    else if(n_state_d2s == CHECK_DATARESP)begin
        MOSI <= 1;
    end

    else if (state_s2d == READ_COMMAND && (count_command < 48))begin
        MOSI <= write_command_reg[47 - count_command];
    end
    else if(state_s2d == READ_COMMAND && (count_command == 48))begin
        MOSI <= 1;
        // $display("in if");
    end
	else MOSI <= MOSI;
end


//AW_ADDR
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) AW_ADDR <= 0;
	else if(state_s2d == WRITE_DRAM && n_state_s2d == WRITE_DRAM) AW_ADDR <= {19'd0,addr_dram_save};
	else AW_ADDR <= 0;
end

//AW_VALID
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) AW_VALID <= 0;
	else if(state_s2d == WRITE_DRAM&& n_state_s2d == WRITE_DRAM) AW_VALID <= 1;
	else AW_VALID <= 0;
end

//count_w_valid
always @(*) begin
	if(state_s2d == WRITE_DATA_DRAM) n_count_w_valid = count_w_valid+1;
	else n_count_w_valid = 0;
end

//W_VALID
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) W_VALID <= 0;
    else if (count_w_valid==98)W_VALID <= 1;
	else if(W_READY) W_VALID <= 1;
	else W_VALID <= 0;
end

//W_DATA
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) W_DATA <= 0;
    else if (count_w_valid==98)W_DATA <= data_sd[79:16];
	else if(W_READY) W_DATA <= data_sd[79:16];
	else W_DATA <= 0;
end

//B_READY
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) B_READY <= 0;
	else if(state_s2d == WAIT_BRESP && n_state_s2d == WAIT_BRESP) B_READY <= 1;
	else B_READY <= 0;
end

//count_out
always @(*) begin
	if(n_state_d2s == OUT || n_state_s2d == OUT) n_count_out = count_out+1;

	else n_count_out = 0;
end
reg [7:0]out_data_reg[0:7];
always@*begin
    if(direction_save)begin
        out_data_reg[0] = data_sd[79:72];
        out_data_reg[1] = data_sd[71:64];
        out_data_reg[2] = data_sd[63:56];
        out_data_reg[3] = data_sd[55:48];
        out_data_reg[4] = data_sd[47:40];
        out_data_reg[5] = data_sd[39:32];
        out_data_reg[6] = data_sd[31:24];
        out_data_reg[7] = data_sd[23:16];
    end
    else begin
    out_data_reg[0] = data_dram[63:56];
    out_data_reg[1] = data_dram[55:48];
    out_data_reg[2] = data_dram[47:40];
    out_data_reg[3] = data_dram[39:32];
    out_data_reg[4] = data_dram[31:24];
    out_data_reg[5] = data_dram[23:16];
    out_data_reg[6] = data_dram[15:8];
    out_data_reg[7] = data_dram[7:0];
    end
end
//out_valid
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) out_valid <= 0;
	else if(n_state_d2s == OUT || n_state_s2d == OUT) begin
        out_valid <=1;
    end
	else out_valid <= 0;
end


//out_data
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) out_data <= 0;
	else if(n_state_d2s == OUT || n_state_s2d == OUT ) begin
        out_data <= out_data_reg[count_out];
    end
	else out_data <= 0;
end



endmodule


module CRC7(data, CRC7_out);  // Return 7-bit result
    input [39:0] data;  // 40-bit data input
    output reg [6:0] CRC7_out;
    reg [6:0] crc;
    integer i;
    reg data_in, data_out;
    parameter polynomial = 7'h9;  // x^7 + x^3 + 1
    always@*begin
        crc = 7'd0;
        for (i = 0; i < 40; i = i + 1) begin
            data_in = data[39-i];
            data_out = crc[6];
            crc = crc << 1;  // Shift the CRC
            if (data_in ^ data_out) begin
                crc = crc ^ polynomial;
            end
        end
        CRC7_out = crc;
    end
endmodule

module CRC16_CCITT(data, CRC16_out);
    // Try to implement CRC-16-CCITT function by yourself.
    input [63:0] data;  // 40-bit data input
    output reg [15:0] CRC16_out;
    reg [15:0] crc;
    integer i;
    reg data_in, data_out;
    parameter polynomial = 16'h1021;  // x^7 + x^3 + 1

    always@*begin
        crc = 16'd0;
        for (i = 0; i < 64; i = i + 1) begin
            data_in = data[63-i];
            data_out = crc[15];
            crc = crc << 1;  // Shift the CRC
            if (data_in ^ data_out) begin
                crc = crc ^ polynomial;
            end
        end
        CRC16_out = crc;
    end

endmodule