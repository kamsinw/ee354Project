// max_finder.v
// Finds max of 4 signed values

module max_finder #(parameter WIDTH = 16) (
    input  wire signed [WIDTH-1:0] a [0:3],
    output wire signed [WIDTH-1:0] max_val
);

    wire signed [WIDTH-1:0] m0 = (a[0] > a[1]) ? a[0] : a[1];
    wire signed [WIDTH-1:0] m1 = (a[2] > a[3]) ? a[2] : a[3];

    assign max_val = (m0 > m1) ? m0 : m1;

endmodule
