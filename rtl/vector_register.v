// vector_register.v
// 4-element vector storage with write enable

module vector_register #(parameter WIDTH = 16) (
    input clk,
    input we,
    input [1:0] addr,                       // 0..3
    input signed [WIDTH-1:0] din,
    output signed [WIDTH-1:0] v0,
    output signed [WIDTH-1:0] v1,
    output signed [WIDTH-1:0] v2,
    output signed [WIDTH-1:0] v3
);

    reg signed [WIDTH-1:0] data [0:3];

    always @(posedge clk) begin
        if (we)
            data[addr] <= din;
    end

    assign v0 = data[0];
    assign v1 = data[1];
    assign v2 = data[2];
    assign v3 = data[3];

endmodule
