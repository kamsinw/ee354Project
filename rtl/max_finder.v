`timescale 1ns / 1ps

// max_finder.v - Pipelined comparison tree

module max_finder #(parameter WIDTH = 16) (
    input  wire                      clk,
    input  wire                      reset,
    input  wire signed [4*WIDTH-1:0] a,
    output reg  signed [WIDTH-1:0]   max_val
);

    wire signed [WIDTH-1:0] a0 = a[WIDTH-1:0];
    wire signed [WIDTH-1:0] a1 = a[2*WIDTH-1:WIDTH];
    wire signed [WIDTH-1:0] a2 = a[3*WIDTH-1:2*WIDTH];
    wire signed [WIDTH-1:0] a3 = a[4*WIDTH-1:3*WIDTH];

    // Stage 1: First level comparisons (combinational)
    wire signed [WIDTH-1:0] m0 = (a0 > a1) ? a0 : a1;
    wire signed [WIDTH-1:0] m1 = (a2 > a3) ? a2 : a3;

    // Stage 2: Register intermediate results
    reg signed [WIDTH-1:0] m0_reg, m1_reg;
    
    always @(posedge clk) begin
        if (reset) begin
            m0_reg <= {WIDTH{1'b0}};
            m1_reg <= {WIDTH{1'b0}};
        end else begin
            m0_reg <= m0;
            m1_reg <= m1;
        end
    end
    
    // Stage 3: Final comparison and register output
    always @(posedge clk) begin
        if (reset)
            max_val <= {WIDTH{1'b0}};
        else
            max_val <= (m0_reg > m1_reg) ? m0_reg : m1_reg;
    end

endmodule
