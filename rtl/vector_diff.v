`timescale 1ns / 1ps

module vector_diff #(parameter WIDTH = 16) (
    input  wire                      clk,
    input  wire                      reset,
    input  wire                      start,
    input  wire signed [4*WIDTH-1:0] V_new,
    input  wire signed [4*WIDTH-1:0] V_old,
    output reg  signed [WIDTH-1:0]   max_diff,
    output reg                       done
);

    // Stage 0: Register inputs to reduce routing delays
    reg signed [4*WIDTH-1:0] V_new_reg, V_old_reg;
    reg start_stage0;
    
    always @(posedge clk) begin
        if (reset) begin
            V_new_reg <= {4*WIDTH{1'b0}};
            V_old_reg <= {4*WIDTH{1'b0}};
            start_stage0 <= 1'b0;
        end else begin
            V_new_reg <= V_new;
            V_old_reg <= V_old;
            start_stage0 <= start;
        end
    end

    // Stage 1: Compute absolute differences (combinational)
    wire signed [4*WIDTH-1:0] d_in;
    abs_diff #(WIDTH) AD (
        .a(V_new_reg),
        .b(V_old_reg),
        .diff(d_in)
    );

    // Stage 2: Register the differences
    reg signed [4*WIDTH-1:0] d_reg;
    reg start_stage1;
    
    always @(posedge clk) begin
        if (reset) begin
            d_reg <= {4*WIDTH{1'b0}};
            start_stage1 <= 1'b0;
        end else begin
            d_reg <= d_in;
            start_stage1 <= start_stage0;
        end
    end

    // Stage 3-4: Find maximum (pipelined internally in max_finder)
    wire signed [WIDTH-1:0] maxv;
    max_finder #(WIDTH) MF (
        .clk(clk),
        .reset(reset),
        .a(d_reg),
        .max_val(maxv)
    );

    // Track start signal through max_finder pipeline (2 stages)
    reg start_stage2, start_stage3;
    
    always @(posedge clk) begin
        if (reset) begin
            start_stage2 <= 1'b0;
            start_stage3 <= 1'b0;
        end else begin
            start_stage2 <= start_stage1;
            start_stage3 <= start_stage2;
        end
    end

    // Final output (maxv is already registered from max_finder)
    reg done_reg;
    
    always @(posedge clk) begin
        if (reset) begin
            max_diff <= {WIDTH{1'b0}};
            done <= 1'b0;
            done_reg <= 1'b0;
        end else if (start_stage3) begin
            max_diff <= maxv;
            done_reg <= 1'b1;
            done <= 1'b1;
        end else begin
            done <= done_reg;
        end
    end

endmodule
