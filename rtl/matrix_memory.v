// matrix_memory.v
// 4x4 matrix storage with per-cell write

module matrix_memory #(parameter WIDTH = 16) (
    input clk,
    input we,
    input [1:0] row,
    input [1:0] col,
    input signed [WIDTH-1:0] din,
    output signed [WIDTH-1:0] a00,
    output signed [WIDTH-1:0] a01,
    output signed [WIDTH-1:0] a02,
    output signed [WIDTH-1:0] a03,
    output signed [WIDTH-1:0] a10,
    output signed [WIDTH-1:0] a11,
    output signed [WIDTH-1:0] a12,
    output signed [WIDTH-1:0] a13,
    output signed [WIDTH-1:0] a20,
    output signed [WIDTH-1:0] a21,
    output signed [WIDTH-1:0] a22,
    output signed [WIDTH-1:0] a23,
    output signed [WIDTH-1:0] a30,
    output signed [WIDTH-1:0] a31,
    output signed [WIDTH-1:0] a32,
    output signed [WIDTH-1:0] a33
);

    reg signed [WIDTH-1:0] mem [0:3][0:3];

    always @(posedge clk) begin
        if (we)
            mem[row][col] <= din;
    end

    assign a00 = mem[0][0]; assign a01 = mem[0][1];
    assign a02 = mem[0][2]; assign a03 = mem[0][3];
    assign a10 = mem[1][0]; assign a11 = mem[1][1];
    assign a12 = mem[1][2]; assign a13 = mem[1][3];
    assign a20 = mem[2][0]; assign a21 = mem[2][1];
    assign a22 = mem[2][2]; assign a23 = mem[2][3];
    assign a30 = mem[3][0]; assign a31 = mem[3][1];
    assign a32 = mem[3][2]; assign a33 = mem[3][3];

    

endmodule
