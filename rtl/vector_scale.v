// vector_scale.v
// Normalizes vector by shifting based on max magnitude

module vector_scale #(parameter WIDTH = 16) (
    input clk,
    input start,
    input signed [WIDTH-1:0] v0_in,
    input signed [WIDTH-1:0] v1_in,
    input signed [WIDTH-1:0] v2_in,
    input signed [WIDTH-1:0] v3_in,
    output reg signed [WIDTH-1:0] v0_out,
    output reg signed [WIDTH-1:0] v1_out,
    output reg signed [WIDTH-1:0] v2_out,
    output reg signed [WIDTH-1:0] v3_out,
    output reg done
);

    wire signed [WIDTH-1:0] max_val;

    max_finder #(WIDTH) MF (
        v0_in, v1_in, v2_in, v3_in,
        max_val
    );

    always @(posedge clk) begin
        if (start) begin
            // Right shift by 1 to keep values bounded
            v0_out <= v0_in >>> 1;
            v1_out <= v1_in >>> 1;
            v2_out <= v2_in >>> 1;
            v3_out <= v3_in >>> 1;
            done   <= 1;
        end
    end

endmodule
