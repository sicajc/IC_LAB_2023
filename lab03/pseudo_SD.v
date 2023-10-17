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
//   File Name   : pseudo_SD.v
//   Module Name : pseudo_SD
//   Release version : v1.0 (Release Date: Sep-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module pseudo_SD (
           clk,
           MOSI,
           MISO
       );

input clk;
input MOSI;
output reg MISO;

parameter SD_p_r = "../00_TESTBED/SD_init.dat";
localparam UNIT = 8;
integer cnti;
integer cntj;
integer interval;
integer count;
integer SEED = 1234;

reg[6:0] crc7;
reg[15:0] crc16_golden,crc16_data_in;

reg[47:0] received_command;
reg start_bit,trans_bit,end_bit;
reg[63:0] sd_card_data_out,sd_card_data_in;
reg[7:0] data_response;
reg[7:0] data_block;
integer flag;
reg[5:0]  command;
reg[31:0] argument;
reg[6:0] crc7_design;
reg[6:0] crc7_golden;

reg [63:0] SD [0:65535];
initial
    $readmemh(SD_p_r, SD);

localparam READ  = 17;
localparam WRITE = 24;

initial
begin
    while(1)
    begin
        // $display("In loop");
        MISO = 1;
        if(MOSI === 0) // Starting bit 0
        begin
            receiving_command_task;
            delay_8_task;
            response_task;
            if(command == READ)
            begin
                delay_32_task;
                read_op_task;
            end
            else if(command == WRITE)
            begin
                write_op_task;
            end
            else
            begin
                //Command format should be correct, neither read or write
                $display ("SPEC SD-1 FAIL");

                YOU_FAIL_task;
                repeat(5)  @(posedge clk);
                $finish;
            end
            MISO = 1;
        end
        @(posedge clk);
    end
end


task receiving_command_task;
    begin
        // $display("Receiving command task");
        // Start receiving data
        cnti = 0;
        while(cnti < 48)
        begin

            // $display("----------------Receiving data-----------------");
            received_command[47 - cnti] = MOSI;

            if(cnti == 47) break;

            cnti = cnti + 1;


            @(posedge clk);
        end

        $display("cnti = %d",cnti);

        // $display("----------------Checking Command Prompt-----------------");
        // Extract correspondent portion out and check crc7design with crc7 golden
        start_bit    = received_command[47];
        trans_bit    = received_command[46];
        command      = received_command[45:40];
        argument     = received_command[39:8];
        crc7_design  = received_command[7:1];
        end_bit      = received_command[0];

        $display("Address to Write: %d" , argument);

        //Check start bit and transmission bit
        if(start_bit !== 0 || trans_bit !== 1)
        begin
            // in valid command read in
            $display ("SPEC SD-1 FAIL");
            $display ("===========Start bit, transmission bit wrong=========");
            $display ("start_bit = %d, trans_bit = %d",start_bit,trans_bit);
            YOU_FAIL_task;
            repeat(5)  @(posedge clk);
            $finish;
        end

        //Check command value is 17 or 24?
        if(command !== READ & command !== WRITE)
        begin
            // in valid command read in
            $display ("SPEC SD-1 FAIL");
            $display ("===========Command value invalid==========");
            $display ("command = %d \n",command);
            YOU_FAIL_task;
            repeat(5)  @(posedge clk);
            $finish;
        end

        // Check if command argument is within range
        if(argument>65535)
        begin
            // command address is over 65535
            $display ("SPEC SD-2 FAIL");
            $display ("===========Command argument out of range=========");
            $display ("argument = %d \n",argument);
            YOU_FAIL_task;
            repeat(5)  @(posedge clk);
            $finish;
        end

        // Check end bit
        if(end_bit !== 1'b1)
        begin
            // End bit does not equal to 1
            $display ("SPEC SD-1 FAIL");

            $display ("===========End bit does not equal to 1=========");
            $display ("argument = %d \n",argument);

            YOU_FAIL_task;
            repeat(5)  @(posedge clk);
            $finish;
        end

        crc7_golden = CRC7({start_bit,trans_bit,command,argument});
        // Check CRC7
        if(crc7_design !== crc7_golden)
        begin
            // crc7 of design does not equal to crc7 by golden
            $display ("SPEC SD-3 FAIL");
            $display ("===========crc7 is not the same=========");
            $display ("crc7_design = %d \n , expected = %d \n",crc7_design,crc7_golden);

            YOU_FAIL_task;
            repeat(5)  @(posedge clk);
            $finish;
        end
        count = 0;
    end
endtask

reg[10:0] gap;

task delay_8_task;
    begin
        gap = $random(SEED);
        gap = gap%9;
        // $display("Delaying:%d",gap*UNIT);
        repeat(gap*UNIT)
        begin
        // $display("Delay time at: %d",$time);
        @(posedge clk);
        end
    end
endtask

task response_task;
begin
    MISO = 0;
    // $display("Current count: %d" , count);
    repeat(8) @(posedge clk);
    MISO = 1;
end
endtask

task delay_32_task;
    begin
        // Must assign the random value to gap
        gap = $random(SEED);
        gap = gap%32+1;
        repeat(gap*UNIT) @(posedge clk);
    end
endtask

task read_op_task;
    begin
        $display("===============Reading from SD card============");
        // send start token 0xfe
        cnti = 0;
        for(cnti = 0; cnti < 8 ; cnti = cnti+1)
        begin
            MISO = 1;

            if(cnti == 7)
            begin
                MISO = 0;
            end
            @(posedge clk);
        end

        $display("Reading from address : %d",argument);
        sd_card_data_out = u_SD.SD[argument];
        $display("Data read out: %h",sd_card_data_out);

        // Starting sending data block
        for(cnti = 0 ;cnti < 64 ; cnti = cnti+1)
        begin
            MISO = sd_card_data_out[63-cnti];
            @(posedge clk);
        end

        // Send CRC-16-CCITT out
        crc16_golden = CRC16_CCITT(sd_card_data_out);
        for(cnti = 0; cnti < 16 ; cnti = cnti+1)
        begin
            MISO = crc16_golden[15 - cnti];
            @(posedge clk);
        end

    end
endtask

task write_op_task;
    begin
        cnti = 7; // cycle
        cntj = 0; // units
        interval = 0;
        data_block  = 0;

        // Check the start token 0xFE, wait for 1~32 units
        // First must check if the interval is 1~32 units = 8 ~ 256, a multiple of 8
        // Thus must take value with 8 data as a group then check for 0xFE
        while(1)
        begin
            if(MOSI === 0)
            begin
               @(posedge clk);
               break;
            end // it meets 0XFE
            interval = interval + 1;
            @(posedge clk);
            // $display("Interval: %d",interval);
        end
        interval = interval - 8;

        if(interval % 8 !== 0  || interval < 8 || interval > 256)
        begin
            // transmission time incorrect
            $display ("SPEC SD-5 FAIL");
            $display ("Current interval is: %d",interval);
            $display ("===========Transmission time incorrect not multiple of 8=========");
            $finish;
        end
        // $stop;

        // Receiving the data block
        for(cnti = 0; cnti < 64 ; cnti = cnti + 1)
        begin
            sd_card_data_in[63 - cnti] = MOSI;
            @(posedge clk);
        end

        $display("Read in data blocks: %h", sd_card_data_in);

        // Reading in the CRC 16
        for(cnti = 0; cnti < 16 ; cnti = cnti + 1)
        begin
            crc16_data_in[15-cnti] = MOSI;
            if(cnti == 15) break;
            @(posedge clk);
        end

        crc16_golden = CRC16_CCITT(sd_card_data_in);
        // Check CRC16
        if(crc16_golden !== crc16_data_in)
        begin
            // transmission time incorrect
            $display ("SPEC SD-4 FAIL");
            $display ("CRC16 DATA IN: %h" , crc16_data_in);
            $display ("CRC16 golden  : %h" , crc16_golden);
            $display ("===========CRC 16 WRONG=========");
            $finish;
        end

        // $display("SD card data in addr %d: %h",argument,SD[argument]);

        // Wait 0 time units
        // Do data response
        data_response = 8'b0000_0101;
        for(cnti = 0; cnti < 8 ; cnti = cnti + 1)
        begin
            MISO = data_response[7-cnti];
            @(posedge clk);
        end

        //Wait for 0~32 units. If next input does not come in, busy keep low
        MISO = 0;
        gap = $random(SEED);
        gap = gap%32;
        repeat(gap*UNIT) @(posedge clk);

        //Writing into SD card
        SD[argument] = sd_card_data_in;
    end
endtask

//////////////////////////////////////////////////////////////////////


task YOU_FAIL_task;
    begin
        $display("*                              FAIL!                                    *");
        $display("*                 Error message from pseudo_SD.v                        *");
    end
endtask

function automatic [6:0] CRC7;  // Return 7-bit result
    input [39:0] data;  // 40-bit data input
    reg [6:0] crc;
    integer i;
    reg data_in, data_out;
    parameter polynomial = 7'h9;  // x^7 + x^3 + 1

    begin
        crc = 7'd0;
        for (i = 0; i < 40; i = i + 1)
        begin
            data_in = data[39-i];
            data_out = crc[6];
            crc = crc << 1;  // Shift the CRC
            if (data_in ^ data_out)
            begin
                crc = crc ^ polynomial;
            end
        end
        CRC7 = crc;
    end
endfunction

function automatic [15:0] CRC16_CCITT;
    input[63:0] data;
    reg[15:0] crc;
    integer i;
    reg data_in, data_out;
    parameter polynomial = 16'h1021;  // x^16 + x^12 + x^5 + 1

    begin
        crc = 16'd0;
        // Try to implement CRC-16-CCITT function by yourself.
        for (i = 0; i < 64; i = i + 1)
        begin
            data_in = data[63-i];
            data_out = crc[15];
            crc = crc << 1;  // Shift the CRC
            if (data_in ^ data_out)
            begin
                crc = crc ^ polynomial;
            end
        end
        CRC16_CCITT = crc;
    end
endfunction

endmodule
