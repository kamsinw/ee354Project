`timescale 1ns / 1ps

module vector_diff #(parameter WIDTH = 16) (
    input  wire                      clk,
    input  wire                      reset,
    input  wire                      start,
    input  wire signed [4*WIDTH-1:0] V_new,
    input  wire signed [4*WIDTH-1:0] V_old,
    output reg  [WIDTH-1:0]          max_diff,
    output reg                       done
);

    wire [4*WIDTH-1:0] d_in;
    abs_diff #(WIDTH) AD (
        .a(V_new),
        .b(V_old),
        .diff(d_in)
    );

    wire [WIDTH-1:0] maxv;
    max_finder #(WIDTH) MF (
        .a(d_in),
        .max_val(maxv)
    );

    reg done_reg;
    
    always @(posedge clk) begin
        if (reset) begin
            max_diff <= {WIDTH{1'b0}};
            done <= 1'b0;
            done_reg <= 1'b0;
        end else if (start) begin
            max_diff <= maxv;
            done_reg <= 1'b1;
            done <= 1'b1;
        end else if (done_reg) begin
            done <= 1'b0;
            done_reg <= 1'b0;
        end else begin
            done <= 1'b0;
        end
    end

endmodule
