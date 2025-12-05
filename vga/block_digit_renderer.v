`timescale 1ns / 1ps

module block_digit_renderer (
    input  wire [3:0] digit,
    input  wire [9:0] px,
    input  wire [9:0] py,
    input  wire [9:0] base_x,
    input  wire [9:0] base_y,
    output wire pixel_on
);

    parameter DIGIT_WIDTH = 50;
    parameter DIGIT_HEIGHT = 70;
    parameter SEGMENT_THICKNESS = 8;

    wire [9:0] local_x = px - base_x;
    wire [9:0] local_y = py - base_y;

    /* verilator lint_off UNSIGNED */
    wire in_bounds = (local_x >= 0) && (local_x < DIGIT_WIDTH) &&
                     (local_y >= 0) && (local_y < DIGIT_HEIGHT);

    wire seg_a = in_bounds && (local_y >= 0) && (local_y < SEGMENT_THICKNESS) &&
                 (local_x >= SEGMENT_THICKNESS) && (local_x < (DIGIT_WIDTH - SEGMENT_THICKNESS));

    wire seg_b = in_bounds && (local_x >= (DIGIT_WIDTH - SEGMENT_THICKNESS)) && (local_x < DIGIT_WIDTH) &&
                 (local_y >= SEGMENT_THICKNESS) && (local_y < (DIGIT_HEIGHT/2 - SEGMENT_THICKNESS/2));

    wire seg_c = in_bounds && (local_x >= (DIGIT_WIDTH - SEGMENT_THICKNESS)) && (local_x < DIGIT_WIDTH) &&
                 (local_y >= (DIGIT_HEIGHT/2 + SEGMENT_THICKNESS/2)) && (local_y < (DIGIT_HEIGHT - SEGMENT_THICKNESS));

    wire seg_d = in_bounds && (local_y >= (DIGIT_HEIGHT - SEGMENT_THICKNESS)) && (local_y < DIGIT_HEIGHT) &&
                 (local_x >= SEGMENT_THICKNESS) && (local_x < (DIGIT_WIDTH - SEGMENT_THICKNESS));

    wire seg_e = in_bounds && (local_x >= 0) && (local_x < SEGMENT_THICKNESS) &&
                 (local_y >= (DIGIT_HEIGHT/2 + SEGMENT_THICKNESS/2)) && (local_y < (DIGIT_HEIGHT - SEGMENT_THICKNESS));

    wire seg_f = in_bounds && (local_x >= 0) && (local_x < SEGMENT_THICKNESS) &&
                 (local_y >= SEGMENT_THICKNESS) && (local_y < (DIGIT_HEIGHT/2 - SEGMENT_THICKNESS/2));
    /* verilator lint_on UNSIGNED */

    wire seg_g = in_bounds && (local_y >= (DIGIT_HEIGHT/2 - SEGMENT_THICKNESS/2)) && (local_y < (DIGIT_HEIGHT/2 + SEGMENT_THICKNESS/2)) &&
                 (local_x >= SEGMENT_THICKNESS) && (local_x < (DIGIT_WIDTH - SEGMENT_THICKNESS));

    wire [6:0] segs;
    assign segs[6] = (digit == 4'd0) || (digit == 4'd2) || (digit == 4'd3) || (digit == 4'd5) ||
                     (digit == 4'd6) || (digit == 4'd7) || (digit == 4'd8) || (digit == 4'd9);
    assign segs[5] = (digit == 4'd0) || (digit == 4'd1) || (digit == 4'd2) || (digit == 4'd3) ||
                     (digit == 4'd4) || (digit == 4'd7) || (digit == 4'd8) || (digit == 4'd9);
    assign segs[4] = (digit == 4'd0) || (digit == 4'd1) || (digit == 4'd3) || (digit == 4'd4) ||
                     (digit == 4'd5) || (digit == 4'd6) || (digit == 4'd7) || (digit == 4'd8) || (digit == 4'd9);
    assign segs[3] = (digit == 4'd0) || (digit == 4'd2) || (digit == 4'd3) || (digit == 4'd5) ||
                     (digit == 4'd6) || (digit == 4'd8) || (digit == 4'd9);
    assign segs[2] = (digit == 4'd0) || (digit == 4'd2) || (digit == 4'd6) || (digit == 4'd8);
    assign segs[1] = (digit == 4'd0) || (digit == 4'd4) || (digit == 4'd5) || (digit == 4'd6) ||
                     (digit == 4'd8) || (digit == 4'd9);
    assign segs[0] = (digit == 4'd2) || (digit == 4'd3) || (digit == 4'd4) || (digit == 4'd5) ||
                     (digit == 4'd6) || (digit == 4'd8) || (digit == 4'd9);

    assign pixel_on = (segs[6] && seg_a) ||
                      (segs[5] && seg_b) ||
                      (segs[4] && seg_c) ||
                      (segs[3] && seg_d) ||
                      (segs[2] && seg_e) ||
                      (segs[1] && seg_f) ||
                      (segs[0] && seg_g);

endmodule
