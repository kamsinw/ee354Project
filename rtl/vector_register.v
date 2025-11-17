// -------------------------------------------------------------
// vector_register.v
// A 4-element vector register, WIDTH bits per element.
// Takes vector bus in[0:3] and outputs vector bus out[0:3].
// Synchronous reset, synchronous load.
// -------------------------------------------------------------

module vector_register #(parameter WIDTH = 64) (
    input  wire clk,
    input  wire reset,
    input  wire load,

    input  wire signed [WIDTH-1:0] in  [0:3],
    output reg  signed [WIDTH-1:0] out [0:3]
);

    integer i;

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 4; i = i + 1)
                out[i] <= 0;
        end
        else if (load) begin
            for (i = 0; i < 4; i = i + 1)
                out[i] <= in[i];
        end
    end

endmodule
