`timescale 1ns / 1ps

// block_digit_renderer.v - 7-segment block digit using rectangles only

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

    wire in_bounds = (local_x >= 0) && (local_x < DIGIT_WIDTH) && 
                     (local_y >= 0) && (local_y < DIGIT_HEIGHT);

    wire segment_a = in_bounds && (local_y >= 0) && (local_y < SEGMENT_THICKNESS) &&
                     (local_x >= SEGMENT_THICKNESS) && (local_x < (DIGIT_WIDTH - SEGMENT_THICKNESS));

    wire segment_b = in_bounds && (local_x >= (DIGIT_WIDTH - SEGMENT_THICKNESS)) && (local_x < DIGIT_WIDTH) &&
                     (local_y >= SEGMENT_THICKNESS) && (local_y < (DIGIT_HEIGHT/2 - SEGMENT_THICKNESS/2));

    wire segment_c = in_bounds && (local_x >= (DIGIT_WIDTH - SEGMENT_THICKNESS)) && (local_x < DIGIT_WIDTH) &&
                     (local_y >= (DIGIT_HEIGHT/2 + SEGMENT_THICKNESS/2)) && (local_y < (DIGIT_HEIGHT - SEGMENT_THICKNESS));

    wire segment_d = in_bounds && (local_y >= (DIGIT_HEIGHT - SEGMENT_THICKNESS)) && (local_y < DIGIT_HEIGHT) &&
                     (local_x >= SEGMENT_THICKNESS) && (local_x < (DIGIT_WIDTH - SEGMENT_THICKNESS));

    wire segment_e = in_bounds && (local_x >= 0) && (local_x < SEGMENT_THICKNESS) &&
                     (local_y >= (DIGIT_HEIGHT/2 + SEGMENT_THICKNESS/2)) && (local_y < (DIGIT_HEIGHT - SEGMENT_THICKNESS));

    wire segment_f = in_bounds && (local_x >= 0) && (local_x < SEGMENT_THICKNESS) &&
                     (local_y >= SEGMENT_THICKNESS) && (local_y < (DIGIT_HEIGHT/2 - SEGMENT_THICKNESS/2));

    wire segment_g = in_bounds && (local_y >= (DIGIT_HEIGHT/2 - SEGMENT_THICKNESS/2)) && (local_y < (DIGIT_HEIGHT/2 + SEGMENT_THICKNESS/2)) &&
                     (local_x >= SEGMENT_THICKNESS) && (local_x < (DIGIT_WIDTH - SEGMENT_THICKNESS));

    wire [6:0] segments;
    assign segments[6] = (digit == 4'd0) || (digit == 4'd2) || (digit == 4'd3) || (digit == 4'd5) || 
                         (digit == 4'd6) || (digit == 4'd7) || (digit == 4'd8) || (digit == 4'd9);
    assign segments[5] = (digit == 4'd0) || (digit == 4'd1) || (digit == 4'd2) || (digit == 4'd3) || 
                         (digit == 4'd4) || (digit == 4'd7) || (digit == 4'd8) || (digit == 4'd9);
    assign segments[4] = (digit == 4'd0) || (digit == 4'd1) || (digit == 4'd3) || (digit == 4'd4) || 
                         (digit == 4'd5) || (digit == 4'd6) || (digit == 4'd7) || (digit == 4'd8) || (digit == 4'd9);
    assign segments[3] = (digit == 4'd0) || (digit == 4'd2) || (digit == 4'd3) || (digit == 4'd5) || 
                         (digit == 4'd6) || (digit == 4'd8) || (digit == 4'd9);
    assign segments[2] = (digit == 4'd0) || (digit == 4'd2) || (digit == 4'd6) || (digit == 4'd8);
    assign segments[1] = (digit == 4'd0) || (digit == 4'd4) || (digit == 4'd5) || (digit == 4'd6) || 
                         (digit == 4'd8) || (digit == 4'd9);
    assign segments[0] = (digit == 4'd2) || (digit == 4'd3) || (digit == 4'd4) || (digit == 4'd5) || 
                         (digit == 4'd6) || (digit == 4'd8) || (digit == 4'd9);

    assign pixel_on = (segments[6] && segment_a) ||
                      (segments[5] && segment_b) ||
                      (segments[4] && segment_c) ||
                      (segments[3] && segment_d) ||
                      (segments[2] && segment_e) ||
                      (segments[1] && segment_f) ||
                      (segments[0] && segment_g);

endmodule

