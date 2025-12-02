`timescale 1ns / 1ps

// abs_diff.v - Simplified combinational version

module abs_diff #(parameter WIDTH = 4) (
    input  wire [4*WIDTH-1:0] a,
    input  wire [4*WIDTH-1:0] b,
    output wire [4*WIDTH-1:0] diff
);

    wire [WIDTH-1:0] a0 = a[WIDTH-1:0];
    wire [WIDTH-1:0] a1 = a[2*WIDTH-1:WIDTH];
    wire [WIDTH-1:0] a2 = a[3*WIDTH-1:2*WIDTH];
    wire [WIDTH-1:0] a3 = a[4*WIDTH-1:3*WIDTH];

    wire [WIDTH-1:0] b0 = b[WIDTH-1:0];
    wire [WIDTH-1:0] b1 = b[2*WIDTH-1:WIDTH];
    wire [WIDTH-1:0] b2 = b[3*WIDTH-1:2*WIDTH];
    wire [WIDTH-1:0] b3 = b[4*WIDTH-1:3*WIDTH];

    wire [WIDTH-1:0] diff0 = (a0 >= b0) ? (a0 - b0) : (b0 - a0);
    wire [WIDTH-1:0] diff1 = (a1 >= b1) ? (a1 - b1) : (b1 - a1);
    wire [WIDTH-1:0] diff2 = (a2 >= b2) ? (a2 - b2) : (b2 - a2);
    wire [WIDTH-1:0] diff3 = (a3 >= b3) ? (a3 - b3) : (b3 - a3);

    assign diff = {diff3, diff2, diff1, diff0};

endmodule
