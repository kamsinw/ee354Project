// max_finder.v - Converted array ports to packed buses

module max_finder #(parameter WIDTH = 16) (
    input  wire signed [4*WIDTH-1:0] a,
    output wire signed [WIDTH-1:0] max_val
);

    wire signed [WIDTH-1:0] a0 = a[WIDTH-1:0];
    wire signed [WIDTH-1:0] a1 = a[2*WIDTH-1:WIDTH];
    wire signed [WIDTH-1:0] a2 = a[3*WIDTH-1:2*WIDTH];
    wire signed [WIDTH-1:0] a3 = a[4*WIDTH-1:3*WIDTH];

    wire signed [WIDTH-1:0] abs_a0 = (a0 < 0) ? -a0 : a0;
    wire signed [WIDTH-1:0] abs_a1 = (a1 < 0) ? -a1 : a1;
    wire signed [WIDTH-1:0] abs_a2 = (a2 < 0) ? -a2 : a2;
    wire signed [WIDTH-1:0] abs_a3 = (a3 < 0) ? -a3 : a3;

    wire signed [WIDTH-1:0] m0 = (abs_a0 > abs_a1) ? abs_a0 : abs_a1;
    wire signed [WIDTH-1:0] m1 = (abs_a2 > abs_a3) ? abs_a2 : abs_a3;

    assign max_val = (m0 > m1) ? m0 : m1;

endmodule
