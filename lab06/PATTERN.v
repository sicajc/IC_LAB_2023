//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab05 Exercise		: HT
//   Author     		: YEH SHUN LIANG (sicajc.st12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//   Release version : V1.0 (Release Date: 2023-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################



`define CYCLE_TIME 10.0

module PATTERN(
    // Output signals
    clk,
	rst_n,
	in_valid,
    in_weight,
	out_mode,
    // Input signals
    out_valid,
	out_code
);

// ========================================
// Input & Output
// ========================================
output reg clk, rst_n, in_valid, out_mode;
output reg [2:0] in_weight;

input out_valid, out_code;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------

real CYCLE = `CYCLE_TIME;
integer pat_read, ans_read, file;
integer PAT_NUM;
integer total_latency, latency;
integer i_pat,i,j;
integer idx_count;
integer golden_size;
reg[1:0] input_matrix_size_idx;

//================================================================
// clock
//================================================================
initial clk = 0;
always #(CYCLE/2.0) clk = ~clk;

//================================================================
// initial
//================================================================
initial begin
  pat_read = $fopen("../00_TESTBED/input.txt", "r");
  ans_read = $fopen("../00_TESTBED/output.txt", "r");
  reset_signal_task;

  i_pat = 0;
  total_latency = 0;
  idx_count = 0;
  file = $fscanf(pat_read, "%d\n", PAT_NUM);

  for (i_pat = 1; i_pat <= PAT_NUM; i_pat = i_pat + 1) begin
    input_task;
    wait_out_valid_task;
    check_ans_task;

    total_latency = total_latency + latency;
    $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %4d,\033[m",i_pat , latency);
  end
  $fclose(pat_read);

  YOU_PASS_task;
end

initial begin
  while(1) begin
    if((out_valid === 0) && (out_valid !== 0))
    begin
      $display("***********************************************************************");
      $display("*  Error                                                              *");
      $display("*  The out_data should be reset when out_valid is low.                *");
      $display("***********************************************************************");
      YOU_FAIL_task;
      repeat(2)@(negedge clk);
      $finish;
    end
    if((in_valid === 1) && (out_valid === 1))
    begin
      $display("***********************************************************************");
      $display("*  Error                                                              *");
      $display("*  The out_valid cannot overlap with in_valid.                        *");
      $display("***********************************************************************");
      YOU_FAIL_task;
      repeat(2)@(negedge clk);
      $finish;
    end
    @(negedge clk);
  end
end

//================================================================
// task
//================================================================
task reset_signal_task;
begin
  rst_n    = 1;
  force clk= 0;
  #(0.5 * CYCLE);
  rst_n = 0;
  in_valid  = 1'b0;
  out_mode  = 1'bx;
  in_weight = 'bx;

  #(10 * CYCLE);
  if( (out_valid !== 0) || (out_code !== 0) )
  begin
    $display("***********************************************************************");
    $display("*  Error                                                              *");
    $display("*  Output signal should reset after initial RESET                     *");
    $display("***********************************************************************");
    YOU_FAIL_task;
    $finish;
  end
  #(CYCLE);  rst_n=1;
  #(CYCLE);  release clk;

  repeat(4) @(negedge clk);
end
endtask

task input_task;
begin
  in_valid = 1;
  // Read in the matrix size
  file = $fscanf(pat_read, "%d\n",out_mode);
  file = $fscanf(pat_read, "%d\n",in_weight);
  @(negedge clk);
  out_mode = 1'bx;

  for(i=0;i<7;i=i+1)
  begin
    file = $fscanf(pat_read, "%d\n",in_weight);
    @(negedge clk);
  end
  in_valid = 0;
  in_weight = 1'bx;
end
endtask

task wait_out_valid_task;
begin
  latency = -1;
  while(out_valid !== 1) begin
    latency = latency + 1;
    if(latency >= 2000)
    begin
      $display("***********************************************************************");
      $display("*  Error                                                              *");
      $display("*  The execution latency are over  2000  cycles.                      *");
      $display("***********************************************************************");
      YOU_FAIL_task;
      repeat(2)@(negedge clk);
      $finish;
    end
    @(negedge clk);
  end
  total_latency = total_latency + latency;
end
endtask


reg[50:0] golden_encoded_bit;
reg[50:0] reversed_golden;
task check_ans_task;
begin
  file = $fscanf(ans_read,"%d",golden_size);
  golden_encoded_bit = 'dx;

  // Read golden bits in
  for(i=0; i<golden_size ; i=i+1)
  begin
    file = $fscanf(ans_read,"%b",golden_encoded_bit[i]);
  end

  for(i=0; i<golden_size ; i=i+1)
  begin
    reversed_golden[50-i] = golden_encoded_bit[i];
  end

  //Check golden bits
  for(i=0; i<golden_size ; i=i+1)
  begin
      if(out_code !== golden_encoded_bit[i])
      begin
         $display("***********************************************************************");
         $display("*  Error                                                              *");
         $display("*  The out_data should be correct when out_valid is high              *");
         $display("*  The out_data of %d th output    is wrong                               *",i+1);
         $display("*  Golden       : %1b                    , yours : %1b   , *",golden_encoded_bit[i],out_code);
         $display("*  Golden       : %26b                   *",reversed_golden);
         $display("***********************************************************************");
         YOU_FAIL_task;
         repeat(2)@(negedge clk);
         $finish;
      end

      if(out_valid !== 1)
      begin
         $display("***********************************************************************");
         $display("*  Error                                                              *");
         $display("*  Out valid should remains when there are more data for output       *");
         $display("***********************************************************************");
         YOU_FAIL_task;
         repeat(2)@(negedge clk);
         $finish;
      end
      @(negedge clk);
  end

  if(out_valid !== 0  || out_code !== 0)
  begin
          $display("***********************************************************************");
          $display("*  Error                                                              *");
          $display("*  Output signal should reset after outputting the data               *");
          $display("***********************************************************************");
          repeat(2)@(negedge clk);
          YOU_FAIL_task;
          $finish;
  end
  repeat(4)@(negedge clk);
end
endtask


task YOU_FAIL_task;begin
$display("***********************************************************************");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⣫⣵⣶⣯⡹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⣰⣿⣿⣿⣿⣧⢹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠇⣿⣿⣿⣿⣿⣿⡞⣿⣿⣿OH NO~SOMETHING GOES WRONG⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢰⣿⣿⣿⣿⣿⣿⣧⢹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⣾⡿⣫⣿⣭⡛⢫⣷⣶⣝⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁⣿⢸⣿⣿⣽⡿⣽⣿⣽⣿⢺⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢸⣿⣮⣛⣿⣟⣵⣯⣛⣛⡡⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⣿⣿⣿⠿⠋⠉⠀⠀⠈⠙⢿⡎⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢸⣿⣿⠋⠀⠀⠀⠀⠀⠀⠀⠈⢳⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⣾⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢇⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢁⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡜⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⣸⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣷⡹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢱⣿⣿⣤⣄⣀⣀⣀⣀⣀⠀⠀⣤⣤⣤⣶⣿⡏⡹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⣰⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣯⣿⣷⣄⠹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⣸⣿⣿⣿⠟⣹⣿⣿⣿⣿⡾⠿⢟⡛⠃⠤⠍⠐⠒⠒⠒⣀⠹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢱⣿⣿⣿⢏⣼⣿⠿⢛⠩⣕⡀⠉⠀⠀⠀⠀⠀⠀⠀⣀⣠⣿⣧⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠸⣿⣿⢃⠾⡋⢕⣨⣶⣿⣿⣿⣄⣠⡴⠀⠀⠀⠀⠀⢹⣿⣿⣿⡌⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⡛⠃⠴⣨⣾⣿⣿⣿⣿⣿⣿⣿⠛⠧⠀⠀⢀⠀⠠⠚⣩⣿⣿⡗⠀⠙⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⢨⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣦⣤⡀⢀⣠⣴⣾⣿⣿⣿⢃⣾⣿⣷⣮⡹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣌⠿⣿⣿⣿⣿⣿⣿⠟⠙⢿⡟⠻⠟⣛⣈⠿⢟⣉⡻⠿⠃⠿⣿⣿⠿⠿⣣⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣭⣛⣻⠿⠏⠀⠀⠈⠀⢠⣾⣿⣿⣷⣎⢻⣿⣿⣿⣶⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣦⣤⣀⣛⡿⠿⠿⠿⢋⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("***********************************************************************");


end
endtask


task YOU_PASS_task; begin
  $display("***********************************************************************");
  $display("*                           \033[0;32mCongratulations!\033[m                          *");
  $display("*  Your execution cycles = %18d   cycles                *", total_latency);
  $display("*  Your clock period     = %20.1f ns                    *", CYCLE);
  $display("*  Total Latency         = %20.1f ns                    *", total_latency*CYCLE);
  $display("***********************************************************************");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠿⠛⠛⠛⠛⠛⠛⠿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠁⣀⣴⣶⣶⣾⣷⣷⣦⡀⠀⠀⢹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⢀⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⢀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠁⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠛⢋⣀⣀⣤⣮⣿⣿⣿⡿⠿⠿⠿⠿⠿⠿⠛⠋⣠⣾⣿⣿⣿You Pass the Lab⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣄⠀⠻⣶⣿⣿⣿⠿⠛⠉⣀⣤⣤⣶⣶⣶⣤⠀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿MAYBE         ⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣤⠄⠀⠀⠀⢾⡿⠟⠛⠋⣉⣉⣈⣁⠀⠘⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠉⢠⣤⠆⠀⡀⠈⣤⣴⣾⣿⣿⣿⣿⣿⣿⣦⡌⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁⣀⡄⠀⠁⣴⡞⢁⣾⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣆⠙⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣿⡇⢠⣾⣿⢃⣾⣿⣧⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⠘⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣛⣛⣛⣛⣛⠁⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣆⠀⣽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣻⢀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠛⢛⣀⠙⠛⢛⡿⢛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⣸⣿⠻⣿⣿⠟⢉⣉⣉⡛⠻⢿⣿⣿⡟⠀⠐⠻⣿⣿⣶⡀⠐⣚⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⠀⣿⡗⠠⡍⠁⣰⣿⣿⡿⠉⡀⠀⠹⣿⡇⠀⠀⠁⠈⢿⣿⣿⡄⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢹⢠⣿⡛⠒⠀⢠⣿⣿⣿⣀⣀⠀⠀⠀⠘⡀⠀⠀⠀⠀⠀⠹⣿⣿⡄⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⣸⣿⣿⣿⢸⢸⣿⣿⣿⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⡇⠸⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁⣿⣿⣿⣿⣼⠈⣿⣿⣿⡀⢠⠀⠀⠀⠀⠐⣦⡀⠀⠀⠀⣠⡿⢋⣠⣤⡁⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⢠⣿⣿⣿⣿⣿⡆⢸⣿⣿⣧⡈⠳⣤⣀⠀⢠⣿⣧⣀⠠⠾⡟⣠⣾⣿⣿⡇⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠇⣼⣿⣿⣿⣿⠿⢋⣠⣭⣭⣭⣉⠲⢶⡶⠀⣸⣿⣿⣿⣷⠶⠀⠹⠿⠿⣿⣷⡈⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⢠⣿⣿⣿⣿⣿⣶⣿⣿⣿⣿⣿⣿⠇⠈⠠⠾⠿⠛⠛⣋⡁⣴⣾⣿⣶⣾⣿⣿⣿⣄⠑⠽⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⣸⣿⣿⣿⣿⣿⣯⣉⣉⣉⣉⣩⣤⣶⣶⣄⠰⣶⣿⣿⡿⠃⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠲⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣌⡙⠛⣡⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⠟⣠⣿⡿⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡉⢻⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⠏⣰⣿⡿⢁⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣄⠹⢿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⠏⣰⣿⣿⠃⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⠙⢿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⠏⢰⣿⣿⡿⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠀⠻⣿⣿⣿");
$display("⣿⣿⣿⣿⠟⣰⣿⣿⣿⠇⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆⣀⠙⣿⣿");
$display("⣿⣿⣿⡏⢠⣿⣿⣿⣿⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⣠⣿⠇⣿⣿");
$display("⣿⡿⠛⠁⢾⣿⣿⣿⣿⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⢁⣠⣾⡿⢋⢠⣿⣿");
$display("⣷⡄⢸⣧⣌⠛⢿⣿⣿⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠁⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠛⢩⣍⡙⠛⠛⢋⣉⣤⣴⣿⠟⢛⣩⣴⡿⢸⣿⣿");
$display("⣿⣷⡄⠙⢿⣷⣦⣍⠙⠆⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⠇⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠿⠛⢉⣉⡄⢀⣿⣿⣿⣆⠙⣿⣿⣟⣉⣥⣶⣿⣿⣿⠃⢸⣿⣿");
$display("⣿⣿⣷⡀⣷⣤⣽⣿⣿⣧⠘⣿⣤⣿⣿⣿⣿⣿⣿⡏⢀⣭⣭⣥⣤⣤⣤⣤⣤⣤⣶⣶⣾⣿⣿⣿⣿⠃⣾⡿⠫⡙⠋⠥⠬⠭⡙⢿⣿⣿⣿⣿⡟⣰⣿⣿⣿");
$display("⣿⣿⣿⣧⠘⣿⣿⣿⣿⣿⣧⡘⣿⣿⣿⣿⣿⣿⠏⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⠀⠉⣀⣀⣀⡰⠀⠄⠀⠀⣾⣿⣿⣿⡟⠀⢿⣿⣿⣿");
$display("⣿⣿⣿⣿⣧⠘⢿⣿⣿⣿⣿⣷⣌⡙⠻⠿⠟⢋⣴⣿⠿⠿⠿⠿⠿⠿⣿⣿⣿⣿⣿⣿⣿⣿⠁⠀⡄⢀⠘⠛⠋⠁⣀⣤⣴⡆⣿⣿⣿⡿⠋⣠⣿⣦⡀⠺⣿");
$display("⣿⣿⣿⣿⣿⣷⣌⠹⣿⣿⣿⣿⣿⣿⣷⡶⠞⢉⣥⣶⣶⣶⣶⣶⣶⣶⣶⣬⣉⠙⠻⢿⣿⣿⣧⠀⠀⢚⣀⣴⣶⣿⣿⣿⣿⢃⣿⡿⠋⣠⣾⣿⣿⣿⣿⠆⣹");
$display("⣿⣿⣿⣿⣿⣿⣿⣷⣄⡛⠿⣿⣿⣿⠋⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣌⡙⠋⣴⣿⣿⣿⣿⣿⣿⣿⣿⡏⠘⠋⠤⠿⠿⠿⠿⠟⢛⣁⣴⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣤⣙⠃⢾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⢿⣿⣦⠙⢿⣿⣿⣿⣿⣿⡿⠋⣰⣶⣶⣶⣶⣶⣶⣶⣾⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣬⣙⠛⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣼⣿⣿⣧⠈⢛⣋⣭⣥⣤⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");
$display("⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣦⣭⣍⣉⣉⣉⡛⠛⠛⠛⠛⠛⠛⠛⠉⣉⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿");




  $finish;
end endtask


endmodule
