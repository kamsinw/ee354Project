`timescale 1ns / 1ps

module max_finder #(parameter WIDTH = 16) (
    input  wire [4*WIDTH-1:0] a,
    output wire [WIDTH-1:0] max_val
);

    wire [WIDTH-1:0] a0 = a[WIDTH-1:0];
    wire [WIDTH-1:0] a1 = a[2*WIDTH-1:WIDTH];
    wire [WIDTH-1:0] a2 = a[3*WIDTH-1:2*WIDTH];
    wire [WIDTH-1:0] a3 = a[4*WIDTH-1:3*WIDTH];

    wire [WIDTH-1:0] m0 = (a0 > a1) ? a0 : a1;
    wire [WIDTH-1:0] m1 = (a2 > a3) ? a2 : a3;

    assign max_val = (m0 > m1) ? m0 : m1;

endmodule
