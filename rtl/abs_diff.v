`timescale 1ns / 1ps

module abs_diff #(parameter WIDTH = 16) (
    input  wire signed [4*WIDTH-1:0] a,
    input  wire signed [4*WIDTH-1:0] b,
    output wire [4*WIDTH-1:0] diff
);

    wire signed [WIDTH-1:0] a0 = a[WIDTH-1:0];
    wire signed [WIDTH-1:0] a1 = a[2*WIDTH-1:WIDTH];
    wire signed [WIDTH-1:0] a2 = a[3*WIDTH-1:2*WIDTH];
    wire signed [WIDTH-1:0] a3 = a[4*WIDTH-1:3*WIDTH];

    wire signed [WIDTH-1:0] b0 = b[WIDTH-1:0];
    wire signed [WIDTH-1:0] b1 = b[2*WIDTH-1:WIDTH];
    wire signed [WIDTH-1:0] b2 = b[3*WIDTH-1:2*WIDTH];
    wire signed [WIDTH-1:0] b3 = b[4*WIDTH-1:3*WIDTH];

    wire signed [WIDTH-1:0] d0 = a0 - b0;
    wire signed [WIDTH-1:0] d1 = a1 - b1;
    wire signed [WIDTH-1:0] d2 = a2 - b2;
    wire signed [WIDTH-1:0] d3 = a3 - b3;

    wire signed [WIDTH:0] d0_17 = {d0[15], d0};
    wire signed [WIDTH:0] d1_17 = {d1[15], d1};
    wire signed [WIDTH:0] d2_17 = {d2[15], d2};
    wire signed [WIDTH:0] d3_17 = {d3[15], d3};

    wire signed [WIDTH:0] abs_d0_17 = (d0_17 < 0) ? (-d0_17) : d0_17;
    wire signed [WIDTH:0] abs_d1_17 = (d1_17 < 0) ? (-d1_17) : d1_17;
    wire signed [WIDTH:0] abs_d2_17 = (d2_17 < 0) ? (-d2_17) : d2_17;
    wire signed [WIDTH:0] abs_d3_17 = (d3_17 < 0) ? (-d3_17) : d3_17;

    wire [WIDTH-1:0] diff0 = abs_d0_17[WIDTH-1:0];
    wire [WIDTH-1:0] diff1 = abs_d1_17[WIDTH-1:0];
    wire [WIDTH-1:0] diff2 = abs_d2_17[WIDTH-1:0];
    wire [WIDTH-1:0] diff3 = abs_d3_17[WIDTH-1:0];

    assign diff = {diff3, diff2, diff1, diff0};

endmodule
