`timescale 1ns / 1ps

module vector_diff #(
    parameter integer WIDTH = 4
) (
    input  wire                   clk,
    input  wire                   reset,
    input  wire                   start,
    input  wire [4*WIDTH-1:0]     vec_new,
    input  wire [4*WIDTH-1:0]     vec_old,
    output reg  [WIDTH-1:0]       max_diff,
    output reg                    done
);

    localparam integer PIPE_CYCLES = 4;

    reg [4*WIDTH-1:0] vec_new_q;
    reg [4*WIDTH-1:0] vec_old_q;
    reg [4*WIDTH-1:0] diff_q;

    reg [4*WIDTH-1:0] vec_new_n;
    reg [4*WIDTH-1:0] vec_old_n;
    reg [4*WIDTH-1:0] diff_n;

    reg [PIPE_CYCLES-1:0] start_pipe_q;
    reg [PIPE_CYCLES-1:0] start_pipe_n;

    reg                   done_flag_q;
    reg                   done_flag_n;

    reg [WIDTH-1:0] max_diff_n;
    reg             done_n;

    wire [4*WIDTH-1:0] diff_vec;
    wire [WIDTH-1:0]   max_val;

    always @(*) begin
        vec_new_n = vec_new;
        vec_old_n = vec_old;
        diff_n = diff_vec;
        start_pipe_n = {start_pipe_q[PIPE_CYCLES-2:0], start};
        done_n = 1'b0;
        done_flag_n = done_flag_q;
        max_diff_n = max_diff;

        if (start) begin
            done_flag_n = 1'b0;
        end

        if (start_pipe_q[PIPE_CYCLES-1]) begin
            max_diff_n = max_val;
            done_flag_n = 1'b1;
            done_n = 1'b1;
        end else if (!start && done_flag_q) begin
            done_n = 1'b1;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            vec_new_q <= {4*WIDTH{1'b0}};
            vec_old_q <= {4*WIDTH{1'b0}};
            diff_q <= {4*WIDTH{1'b0}};
            start_pipe_q <= {PIPE_CYCLES{1'b0}};
            max_diff <= {WIDTH{1'b0}};
            done <= 1'b0;
            done_flag_q <= 1'b0;
        end else begin
            vec_new_q <= vec_new_n;
            vec_old_q <= vec_old_n;
            diff_q <= diff_n;
            start_pipe_q <= start_pipe_n;
            max_diff <= max_diff_n;
            done <= done_n;
            done_flag_q <= done_flag_n;
        end
    end

    abs_diff #(.WIDTH(WIDTH)) diff_unit (
        .vec_new (vec_new_q),
        .vec_old (vec_old_q),
        .vec_diff(diff_vec)
    );

    max_finder #(.WIDTH(WIDTH)) max_unit (
        .clk        (clk),
        .reset      (reset),
        .lane_values(diff_q),
        .max_value  (max_val)
    );

endmodule
