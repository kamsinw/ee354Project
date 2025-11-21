// abs_diff.v
// Returns |a - b|

module abs_diff #(parameter WIDTH = 16) (
    input  wire signed [WIDTH-1:0] a [0:3],
    input  wire signed [WIDTH-1:0] b [0:3],
    output wire signed [WIDTH-1:0] diff [0:3]
);

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : GEN_ABS
            wire signed [WIDTH-1:0] d = a[i] - b[i];
            assign diff[i] = (d < 0) ? -d : d;
        end
    endgenerate

endmodule
