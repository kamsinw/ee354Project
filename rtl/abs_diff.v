`timescale 1ns / 1ps

// abs_diff.v - Simplified combinational version

module abs_diff #(parameter WIDTH = 16) (
    input  wire signed [4*WIDTH-1:0] a,
    input  wire signed [4*WIDTH-1:0] b,
    output wire signed [4*WIDTH-1:0] diff
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

    // Simple absolute value - let synthesizer optimize
    wire signed [WIDTH-1:0] diff0 = (d0 < 0) ? -d0 : d0;
    wire signed [WIDTH-1:0] diff1 = (d1 < 0) ? -d1 : d1;
    wire signed [WIDTH-1:0] diff2 = (d2 < 0) ? -d2 : d2;
    wire signed [WIDTH-1:0] diff3 = (d3 < 0) ? -d3 : d3;

    assign diff = {diff3, diff2, diff1, diff0};

endmodule
