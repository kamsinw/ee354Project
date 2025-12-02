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

    reg [4*WIDTH-1:0] new_vec_q;
    reg [4*WIDTH-1:0] old_vec_q;
    reg [4*WIDTH-1:0] diff_q;

    reg [4*WIDTH-1:0] new_vec_d;
    reg [4*WIDTH-1:0] old_vec_d;
    reg [4*WIDTH-1:0] diff_d;

    reg [PIPE_CYCLES-1:0] start_pipe_q;
    reg [PIPE_CYCLES-1:0] start_pipe_d;

    reg                   done_flag_q;
    reg                   done_flag_d;

    reg [WIDTH-1:0] max_diff_d;
    reg             done_d;

    wire [4*WIDTH-1:0] diff_lane;
    wire [WIDTH-1:0]   max_lane;

    always @(*) begin
        new_vec_d     = vec_new;
        old_vec_d     = vec_old;
        diff_d        = diff_lane;
        start_pipe_d  = {start_pipe_q[PIPE_CYCLES-2:0], start};
        done_d        = 1'b0;
        done_flag_d   = done_flag_q;
        max_diff_d    = max_diff;

        if (start) begin
            done_flag_d = 1'b0;
        end

        if (start_pipe_q[PIPE_CYCLES-1]) begin
            max_diff_d  = max_lane;
            done_flag_d = 1'b1;
            done_d      = 1'b1;
        end else if (!start && done_flag_q) begin
            done_d = 1'b1;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            new_vec_q    <= {4*WIDTH{1'b0}};
            old_vec_q    <= {4*WIDTH{1'b0}};
            diff_q       <= {4*WIDTH{1'b0}};
            start_pipe_q <= {PIPE_CYCLES{1'b0}};
            max_diff     <= {WIDTH{1'b0}};
            done         <= 1'b0;
            done_flag_q  <= 1'b0;
        end else begin
            new_vec_q    <= new_vec_d;
            old_vec_q    <= old_vec_d;
            diff_q       <= diff_d;
            start_pipe_q <= start_pipe_d;
            max_diff     <= max_diff_d;
            done         <= done_d;
            done_flag_q  <= done_flag_d;
        end
    end

    abs_diff #(.WIDTH(WIDTH)) diff_unit (
        .vec_new (new_vec_q),
        .vec_old (old_vec_q),
        .vec_diff(diff_lane)
    );

    max_finder #(.WIDTH(WIDTH)) max_unit (
        .clk        (clk),
        .reset      (reset),
        .lane_values(diff_q),
        .max_value  (max_lane)
    );

endmodule
