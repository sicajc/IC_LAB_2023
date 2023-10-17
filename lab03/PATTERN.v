`ifdef RTL
    `define CYCLE_TIME 40.0
`endif
`ifdef GATE
    `define CYCLE_TIME 40.0
`endif

// `define RTL

`include "../00_TESTBED/pseudo_DRAM.v"
`include "../00_TESTBED/pseudo_SD.v"

module PATTERN(
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

/* Input for design */
output reg        clk, rst_n;
output reg        in_valid;
output reg        direction;
output reg [12:0] addr_dram;
output reg [15:0] addr_sd;

/* Output for pattern */
input        out_valid;
input  [7:0] out_data;

// DRAM Signals
// write address channel
input [31:0] AW_ADDR;
input AW_VALID;
output AW_READY;
// write data channel
input W_VALID;
input [63:0] W_DATA;
output W_READY;
// write response channel
output B_VALID;
output [1:0] B_RESP;
input B_READY;
// read address channel
input [31:0] AR_ADDR;
input AR_VALID;
output AR_READY;
// read data channel
output [63:0] R_DATA;
output R_VALID;
output [1:0] R_RESP;
input R_READY;

// SD Signals
output MISO;
input MOSI;

localparam  DRAM_TO_SD = 0;
localparam  SD_TO_DRAM = 1;
real CYCLE = `CYCLE_TIME;

integer pat_read;
integer PAT_NUM;
integer total_latency, cycles;
integer i_pat;
integer num_of_data;
integer temp;
integer cnt;
integer mode;
integer gap;
integer SEED = 1234;

reg[31:0] golden_dram_addr;
reg[31:0] golden_sd_addr;
reg[63:0] golden_data;
reg[63:0] golden_data_sd,golden_data_dram;


//================================================================
//  clock
//================================================================
always  #(`CYCLE_TIME/2.0)  clk = ~clk ;
initial
    clk = 0 ;

initial
begin
    pat_read = $fopen("../00_TESTBED/Input.txt", "r");

    // Initialize signals
    in_valid  = 0;
    direction = 'bx;
    addr_dram = 'bx;
    addr_sd   = 'bx;
    rst_n     =  1;

    reset_signal_task;

    i_pat = 0;
    total_latency = 0;
    $fscanf(pat_read, "%d\n", PAT_NUM);

    for (i_pat = 1; i_pat <= PAT_NUM; i_pat = i_pat + 1)
    begin
        $display("=============================================");
        $display("PATTERN NO: %d" , i_pat);
        $display("=============================================");
        input_task;
        wait_out_valid_task;
        check_ans_task;

        delay_task;

        total_latency = total_latency + cycles;
        $display("PASS PATTERN NO.%4d", i_pat);
    end

    $fclose(pat_read);

    $writememh("../00_TESTBED/DRAM_final.dat", u_DRAM.DRAM);
    $writememh("../00_TESTBED/SD_final.dat", u_SD.SD);
    YOU_PASS_task;
end

//////////////////////////////////////////////////////////////////////
// Write your own task here
//////////////////////////////////////////////////////////////////////
task reset_signal_task;
    begin
        force clk = 0 ;
        #(1.0 * `CYCLE_TIME);
        rst_n = 0;
        #(100.0);
        if((out_valid!==0)||(out_data!==0) || (AW_ADDR !==0) || (AW_VALID !== 0) || (W_VALID !== 0) ||
                (W_DATA !== 0) || (B_READY !== 0 ) || (AR_ADDR !== 0)|| (AR_VALID!==0)||(R_READY!==0)||(MOSI !==1))
        begin
            // Spec Main-1
            // The reset signal (rst_n) would be given only once at the beginning of simulation.
            // All output signals should be reset after the reset signal is asserted.
            $display ("SPEC MAIN-1 FAIL");

            YOU_FAIL_task;
            $finish;
        end
        #(1.0);
        rst_n = 1 ;

        #(2.0);
        release clk;
    end
endtask

task input_task;
    begin
        in_valid = 1;

        if(out_data !== 0 && out_valid ===0)
        begin
            // SPEC MAIN-2, The out_data should be reset when your out_valid is low.
            $display ("SPEC MAIN-2 FAIL");

            YOU_FAIL_task;
            repeat(5)  @(negedge clk);
            $finish;
        end

        // Read in the 3 data from file, feed in values in 1 cycle
        temp = $fscanf(pat_read, "%d\n", direction);
        temp = $fscanf(pat_read, "%d\n", addr_dram);
        temp = $fscanf(pat_read, "%d\n", addr_sd);

        $display("====================INPUT===================");
        $display("direction:%d \n" , direction);
        $display("addr_dram:%d\n" , addr_dram);
        $display("addr_sd:%d\n" , addr_sd);
        $display("====================GOLDEN===================");
        if(direction == 0)
        begin
            $display("golden data:%h \n" ,u_DRAM.DRAM[addr_dram]);
        end
        else
        begin
            $display("golden data:%h \n" ,u_SD.SD[addr_sd]);
        end

        // Find the golden first here
        mode = direction;
        golden_dram_addr = addr_dram;
        golden_sd_addr   = addr_sd;

        @(negedge clk);

        // Pull in_valid down
        in_valid = 0;
        direction = 'bx;
        addr_dram = 'bx;
        addr_sd   = 'bx;
    end
endtask

task check_ans_task;
    begin
        cnt = 0;
        while(out_valid === 1)
        begin
            if(MISO === 0)
            begin
                // Busy should not overlap with out valid!
                $display ("SPEC MAIN-6 FAIL");
                $display ("Busy should not overlap with out valid");
                YOU_FAIL_task;
                repeat(5)  @(negedge clk);
                $finish;
            end

            if(cnt == 8)
            begin
                // The out_valid and out_data must be asserted for 8 cycles only
                $display ("SPEC MAIN-4 FAIL");

                YOU_FAIL_task;
                repeat(5)  @(negedge clk);
                $finish;
            end

            golden_data_sd   = u_SD.SD[golden_sd_addr];
            // $display("Golden data sd sd: %h" , golden_data_sd);
            golden_data_dram = u_DRAM.DRAM[golden_dram_addr];
            // $display("Golden data dram: %h" , golden_data_dram);

            // Check if data is the same in DRAM and SD
            if( u_SD.SD[golden_sd_addr] !== u_DRAM.DRAM[golden_dram_addr])
            begin
                // Value in DRAM and SD shall be the same
                $display ("SPEC MAIN-6 FAIL");
                $display("DRAM addr    : %d"  ,golden_dram_addr);
                $display("SD  addr     : %d"  ,golden_sd_addr);
                $display("Data in DRAM : %h"  ,u_DRAM.DRAM[golden_dram_addr]);
                $display("Data in SD   : %h"  ,u_SD.SD[golden_sd_addr]);

                YOU_FAIL_task;
                repeat(5)  @(negedge clk);
                $finish;
            end

            // Golden check if the data read from DRAM and write to SD card is correct
            if(mode === DRAM_TO_SD)
            begin
                golden_data = u_DRAM.DRAM[golden_dram_addr];
                if(out_data !== golden_data[(63 - cnt*8)-:8])
                begin
                    // out_data shall be correct when out_valid is high
                    $display ("SPEC MAIN-5 FAIL");
                    $display("Golden data: %h",golden_data);

                    YOU_FAIL_task;
                    repeat(5)  @(negedge clk);
                    $finish;
                end
            end
            else
            begin
                // Check if the data read from SD card and write to DRAM is correct
                golden_data = u_SD.SD[golden_sd_addr];
                if(out_data !== golden_data[(63 - cnt*8)-:8])
                begin
                    // out_data shall be correct when out_valid is high
                    $display ("SPEC MAIN-5 FAIL");
                    $display("Golden data: %h",golden_data);

                    YOU_FAIL_task;
                    repeat(5)  @(negedge clk);
                    $finish;
                end
            end

            cnt = cnt + 1;
            @(negedge clk);
        end

        if(cnt !== 8)
        begin
            // The out_valid and out_data must be asserted for 8 cycles
            $display ("SPEC MAIN-4 FAIL");

            YOU_FAIL_task;
            repeat(5)  @(negedge clk);
            $finish;
        end

        if(out_data !== 0 && in_valid === 0)
        begin
            // SPEC MAIN-2, The out_data should be reset when your out_valid is low.
            $display ("SPEC MAIN-2 FAIL");

            YOU_FAIL_task;
            repeat(5)  @(negedge clk);
            $finish;
        end
    end
endtask

task wait_out_valid_task;
    begin
        cycles = 0 ;
        while( out_valid!==1 )
        begin
            cycles = cycles + 1 ;
            if (out_data!==0 & in_valid === 0)
            begin
                // SPEC MAIN-2
                // The out should be reset whenever your out_valid isn’t high.
                $display("SPEC MAIN-2 FAIL");

                repeat(5)  @(negedge clk);
                YOU_FAIL_task;
                $finish;
            end
            if (cycles==10000)
            begin
                // SPEC MAIN-3
                // The execution cycle is limited in 10000 cycles.
                // The cycle is the clock cycles between the falling edge of
                // the last cycle of in_valid and the rising edge of the out_valid.
                $display ("SPEC MAIN-3 FAIL");
                $display("The execution cycle is limited in 10000 cycles.");

                repeat(5)  @(negedge clk);
                YOU_FAIL_task;
                $finish;
            end
            @(negedge clk);
        end
        // $display("DRAM addr    : %d"  ,golden_dram_addr);
        // $display("SD  addr     : %d"  ,golden_sd_addr);
        // $display("Data in DRAM : %h"  ,u_DRAM.DRAM[golden_dram_addr]);
        // $display("Data in SD   : %h"  ,u_SD.SD[golden_sd_addr]);
    end
endtask

task delay_task ;
    begin
        // Must assign the random value to gap
        gap = $random(SEED);
        gap = gap%3 + 2;
        while(gap !== 0 )
        begin
            gap = gap - 1;
            if (out_data!==0 & in_valid === 0)
            begin
                // SPEC MAIN-2
                // The out should be reset whenever your out_valid isn’t high.
                $display("SPEC MAIN-2 FAIL");

                repeat(5)  @(negedge clk);
                YOU_FAIL_task;
                $finish;
            end
            @(negedge clk);
        end
    end
endtask

//////////////////////////////////////////////////////////////////////

task YOU_PASS_task;
    begin
        $display("*************************************************************************");
        $display("*                         Congratulations!                              *");
        $display("*                Your execution cycles = %5d cycles          *", total_latency);
        $display("*                Your clock period = %.1f ns          *", CYCLE);
        $display("*                Total Latency = %.1f ns          *", total_latency*CYCLE);
        $display("*************************************************************************");
        $finish;
    end
endtask

task YOU_FAIL_task;
    begin
        $display("*                              FAIL!                                    *");
        $display("*                    Error message from PATTERN.v                       *");
    end
endtask

pseudo_DRAM u_DRAM (
                .clk(clk),
                .rst_n(rst_n),
                // write address channel
                .AW_ADDR(AW_ADDR),
                .AW_VALID(AW_VALID),
                .AW_READY(AW_READY),
                // write data channel
                .W_VALID(W_VALID),
                .W_DATA(W_DATA),
                .W_READY(W_READY),
                // write response channel
                .B_VALID(B_VALID),
                .B_RESP(B_RESP),
                .B_READY(B_READY),
                // read address channel
                .AR_ADDR(AR_ADDR),
                .AR_VALID(AR_VALID),
                .AR_READY(AR_READY),
                // read data channel
                .R_DATA(R_DATA),
                .R_VALID(R_VALID),
                .R_RESP(R_RESP),
                .R_READY(R_READY)
            );

pseudo_SD u_SD (
              .clk(clk),
              .MOSI(MOSI),
              .MISO(MISO)
          );

endmodule
