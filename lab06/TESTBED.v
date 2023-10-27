/**************************************************************************/
// Copyright (c) 2023, SI2 Lab
// MODULE: TESTBED
// FILE NAME: TESTBED.v
// VERSRION: 1.0
// DATE: July 5, 2023
// AUTHOR: SHAO-HUA LIEN, NYCU IEE
// CODE TYPE: RTL or Behavioral Level (Verilog)
//
/**************************************************************************/

`timescale 1ns/1ps

// PATTERN
`include "PATTERN_IP.v"

// `define RTL

// DESIGN
`ifdef RTL
	`include "SORT_IP_demo.v"
`elsif GATE
	`include "SORT_IP_demo_SYN.v"
`endif


module TESTBED();

// Parameter
parameter IP_WIDTH = 8;

// Connection wires
wire [IP_WIDTH*4-1:0] character_in, character_out;
wire [IP_WIDTH*5-1:0] weight;

// initial begin
//  	`ifdef RTL
//     	$fsdbDumpfile("SORT_IP_demo.fsdb");
// 		$fsdbDumpvars(0,"+mda");
// 	`elsif GATE
// 		$fsdbDumpfile("SORT_IP_demo_SYN.fsdb");
// 		$fsdbDumpvars(0,"+mda");
// 		$sdf_annotate("SORT_IP_demo_SYN.sdf",IP_sort);
// 	`endif
// end

`ifdef RTL
	SORT_IP_demo #(.IP_WIDTH(IP_WIDTH)) IP_sort (
		.IN_character(character_in),
		.IN_weight(weight),
		.OUT_character(character_out)
	);


	PATTERN #(.IP_WIDTH(IP_WIDTH)) I_PATTERN(
		.IN_character(character_in),
		.IN_weight(weight),
		.OUT_character(character_out)
	);

`elsif GATE
    SORT_IP_demo IP_sort  (
        .IN_character(character_in),
		.IN_weight(weight),
		.OUT_character(character_out)
    );

    PATTERN #(.IP_WIDTH(IP_WIDTH)) My_PATTERN (
        .IN_character(character_in),
		.IN_weight(weight),
		.OUT_character(character_out)
    );

`endif

endmodule
