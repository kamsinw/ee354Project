// max_finder.v
// Finds max of 4 signed values

module max_finder #(parameter WIDTH = 64) (
    input signed [WIDTH-1:0] a0,
    input signed [WIDTH-1:0] a1,
    input signed [WIDTH-1:0] a2,
    input signed [WIDTH-1:0] a3,
    output signed [WIDTH-1:0] max_val
);

    wire signed [WIDTH-1:0] m0 = (a0 > a1) ? a0 : a1;
    wire signed [WIDTH-1:0] m1 = (a2 > a3) ? a2 : a3;

    assign max_val = (m0 > m1) ? m0 : m1;

endmodule
