// abs_diff.v
// Returns |a - b|

module abs_diff #(parameter WIDTH = 16) (
    input  signed [WIDTH-1:0] a,
    input  signed [WIDTH-1:0] b,
    output signed [WIDTH-1:0] diff
);

    wire signed [WIDTH-1:0] d = a - b;

    assign diff = (d < 0) ? -d : d;

endmodule
