module CHIP(
    //Input Port
    clk,
    rst_n,
    in_valid,
    in_valid2,
    mode,
    matrix,
    matrix_idx,
    matrix_size,

    //Output Port
    out_valid,
    out_value
);


input           clk, rst_n, in_valid, in_valid2;
input           mode;
input   [ 7:0]  matrix;
input   [ 3:0]  matrix_idx;
input   [ 1:0]  matrix_size;
output          out_valid;
output          out_value;

wire C_clk;
wire C_rst_n;
wire C_in_valid;
wire C_in_valid2;
wire C_mode;
wire [7:0] C_matrix;
wire [3:0] C_matrix_idx;
wire [1:0] C_matrix_size;
wire C_out_valid;
wire C_out_value;

//TA has already defined for you
// CLKBUFX20 buf0(.A(C_clk),.Y(BUF_CLK));
//LBP module
CAD CORE(
    .clk(C_clk),
    .rst_n(C_rst_n),
    .in_valid(C_in_valid),
    .in_valid2(C_in_valid2),
    .mode(C_mode),
    .matrix(C_matrix),
    .matrix_size(C_matrix_size),
    .matrix_idx(C_matrix_idx),
    .out_valid(C_out_valid),
    .out_value(C_out_value)
    );

// CLKBUFX20 buf0(.A(C_clk),.Y(BUF_CLK));

// Inputs
// N
XMD I_RST_N             ( .O(C_rst_n),          .I(rst_n),              .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD I_CLK               ( .O(C_clk),            .I(clk),                .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD I_IN_VALID          ( .O(C_in_valid),       .I(in_valid),           .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD I_IN_VALID2         ( .O(C_in_valid2),      .I(in_valid2),          .PU(1'b0), .PD(1'b0), .SMT(1'b0));

//  E
XMD I_MATRIX_IDX0       ( .O(C_matrix_idx[0]),  .I(matrix_idx[0]),      .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD I_MATRIX_IDX1       ( .O(C_matrix_idx[1]),  .I(matrix_idx[1]),      .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD I_MATRIX_IDX2       ( .O(C_matrix_idx[2]),  .I(matrix_idx[2]),      .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD I_MATRIX_IDX3       ( .O(C_matrix_idx[3]),  .I(matrix_idx[3]),      .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD I_MODE              ( .O(C_mode),  .I(mode),      .PU(1'b0), .PD(1'b0), .SMT(1'b0));

// S
XMD I_MATRIX_3          ( .O(C_matrix[3]),  .I(matrix[3]),      .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD I_MATRIX_4          ( .O(C_matrix[4]),  .I(matrix[4]),      .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD I_MATRIX_5          ( .O(C_matrix[5]),  .I(matrix[5]),      .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD I_MATRIX_6          ( .O(C_matrix[6]),  .I(matrix[6]),      .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD I_MATRIX_7          ( .O(C_matrix[7]),  .I(matrix[7]),      .PU(1'b0), .PD(1'b0), .SMT(1'b0));

// W
XMD I_MATRIX_SIZE0      ( .O(C_matrix_size[0]),  .I(matrix_size[0]),       .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD I_MATRIX_SIZE1      ( .O(C_matrix_size[1]),  .I(matrix_size[1]),       .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD I_MATRIX_0          ( .O(C_matrix[0]),       .I(matrix[0]),      .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD I_MATRIX_1          ( .O(C_matrix[1]),       .I(matrix[1]),      .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD I_MATRIX_2          ( .O(C_matrix[2]),       .I(matrix[2]),      .PU(1'b0), .PD(1'b0), .SMT(1'b0));

// Outputs
// N
YA2GSD O_VALID          ( .I(C_out_valid),.O(out_valid), .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b0), .SR(1'b0));
YA2GSD O_VALUE          ( .I(C_out_value),.O(out_value), .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b0), .SR(1'b0));


//I/O power 3.3V pads x? (DVDD + DGND)
// N
VCC3IOD VDDP0 ();
GNDIOD  GNDP0 ();
VCC3IOD VDDP1 ();
GNDIOD  GNDP1 ();

// W
VCC3IOD VDDP2 ();
GNDIOD  GNDP2 ();
VCC3IOD VDDP3 ();
GNDIOD  GNDP3 ();

//Core poweri 1.8V pads x? (VDD + GND)
// W
GNDKD GNDC0 ();

// E
VCCKD VDDC0 ();
VCCKD VDDC1 ();
VCCKD VDDC2 ();
VCCKD VDDC3 ();
GNDKD GNDC6 ();

// S
GNDKD GNDC1 ();
GNDKD GNDC2 ();
GNDKD GNDC3 ();
GNDKD GNDC4 ();
GNDKD GNDC5 ();

endmodule
