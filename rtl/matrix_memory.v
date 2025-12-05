`timescale 1ns / 1ps

module matrix_memory #(
    parameter integer WIDTH = 16
) (
    input  wire                  clk,
    input  wire                  reset,
    input  wire                  we,
    input  wire [1:0]            row,
    input  wire [1:0]            col,
    input  wire signed [WIDTH-1:0] din,
    output wire signed [WIDTH-1:0] a00,
    output wire signed [WIDTH-1:0] a01,
    output wire signed [WIDTH-1:0] a02,
    output wire signed [WIDTH-1:0] a03,
    output wire signed [WIDTH-1:0] a10,
    output wire signed [WIDTH-1:0] a11,
    output wire signed [WIDTH-1:0] a12,
    output wire signed [WIDTH-1:0] a13,
    output wire signed [WIDTH-1:0] a20,
    output wire signed [WIDTH-1:0] a21,
    output wire signed [WIDTH-1:0] a22,
    output wire signed [WIDTH-1:0] a23,
    output wire signed [WIDTH-1:0] a30,
    output wire signed [WIDTH-1:0] a31,
    output wire signed [WIDTH-1:0] a32,
    output wire signed [WIDTH-1:0] a33
);

    reg signed [WIDTH-1:0] mem [0:3][0:3];

    function automatic signed [WIDTH-1:0] cast_val;
        input integer val;
        begin
            cast_val = val;
        end
    endfunction

    integer r_idx;
    integer c_idx;

    always @(posedge clk) begin
        if (reset) begin
            for (r_idx = 0; r_idx < 4; r_idx = r_idx + 1) begin
                for (c_idx = 0; c_idx < 4; c_idx = c_idx + 1) begin
                    mem[r_idx][c_idx] <= (r_idx == c_idx) ? cast_val(4) : cast_val(1);
                end
            end
        end else if (we) begin
            mem[row][col] <= din;
        end
    end

    assign a00 = mem[0][0];
    assign a01 = mem[0][1];
    assign a02 = mem[0][2];
    assign a03 = mem[0][3];

    assign a10 = mem[1][0];
    assign a11 = mem[1][1];
    assign a12 = mem[1][2];
    assign a13 = mem[1][3];

    assign a20 = mem[2][0];
    assign a21 = mem[2][1];
    assign a22 = mem[2][2];
    assign a23 = mem[2][3];

    assign a30 = mem[3][0];
    assign a31 = mem[3][1];
    assign a32 = mem[3][2];
    assign a33 = mem[3][3];

endmodule
