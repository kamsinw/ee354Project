`timescale 1ns / 1ps

// display_controller.v - VGA display controller for dominant eigenvector finder

module display_controller (
    input  wire [9:0] hcount,
    input  wire [9:0] vcount,
    input  wire visible,
    input  wire [1:0] edit_row,
    input  wire [1:0] edit_col,
    input  wire sw0,
    input  wire sw1,
    input  wire [2:0] sw_eps,
    input  wire signed [255:0] matrix_a,
    input  wire signed [63:0] vector_v,
    input  wire [6:0] fsm_state,
    input  wire fsm_done,
    input  wire [7:0] iteration_count,
    input  wire signed [63:0] v_old,
    input  wire signed [63:0] v_new,
    output reg  [3:0] red,
    output reg  [3:0] green,
    output reg  [3:0] blue
);

    // Screen regions
    parameter BANNER_HEIGHT = 30;
    parameter MATRIX_X = 20;
    parameter MATRIX_Y = 50;
    parameter CELL_SIZE = 40;
    parameter VECTOR_X = 300;
    parameter VECTOR_Y = 50;
    parameter GRAPH_X = 200;
    parameter GRAPH_Y = 300;
    parameter GRAPH_WIDTH = 240;
    parameter GRAPH_HEIGHT = 150;
    parameter BAR_WIDTH = 20;
    parameter BAR_SPACING = 10;
    
    wire [9:0] px = hcount;
    wire [9:0] py = vcount;
    
    // Unpack matrix and vectors
    wire signed [15:0] matrix_a_unpack [0:3][0:3];
    assign matrix_a_unpack[0][0] = matrix_a[15:0];
    assign matrix_a_unpack[0][1] = matrix_a[31:16];
    assign matrix_a_unpack[0][2] = matrix_a[47:32];
    assign matrix_a_unpack[0][3] = matrix_a[63:48];
    assign matrix_a_unpack[1][0] = matrix_a[79:64];
    assign matrix_a_unpack[1][1] = matrix_a[95:80];
    assign matrix_a_unpack[1][2] = matrix_a[111:96];
    assign matrix_a_unpack[1][3] = matrix_a[127:112];
    assign matrix_a_unpack[2][0] = matrix_a[143:128];
    assign matrix_a_unpack[2][1] = matrix_a[159:144];
    assign matrix_a_unpack[2][2] = matrix_a[175:160];
    assign matrix_a_unpack[2][3] = matrix_a[191:176];
    assign matrix_a_unpack[3][0] = matrix_a[207:192];
    assign matrix_a_unpack[3][1] = matrix_a[223:208];
    assign matrix_a_unpack[3][2] = matrix_a[239:224];
    assign matrix_a_unpack[3][3] = matrix_a[255:240];
    
    wire signed [15:0] vector_v_unpack [0:3];
    assign vector_v_unpack[0] = vector_v[15:0];
    assign vector_v_unpack[1] = vector_v[31:16];
    assign vector_v_unpack[2] = vector_v[47:32];
    assign vector_v_unpack[3] = vector_v[63:48];
    
    wire signed [15:0] v_old_unpack [0:3];
    assign v_old_unpack[0] = v_old[15:0];
    assign v_old_unpack[1] = v_old[31:16];
    assign v_old_unpack[2] = v_old[47:32];
    assign v_old_unpack[3] = v_old[63:48];
    
    wire signed [15:0] v_new_unpack [0:3];
    assign v_new_unpack[0] = v_new[15:0];
    assign v_new_unpack[1] = v_new[31:16];
    assign v_new_unpack[2] = v_new[47:32];
    assign v_new_unpack[3] = v_new[63:48];
    
    // Region detection
    wire in_banner = (py < BANNER_HEIGHT);
    wire in_matrix = (px >= MATRIX_X) && (px < MATRIX_X + 4*CELL_SIZE) &&
                     (py >= MATRIX_Y) && (py < MATRIX_Y + 4*CELL_SIZE);
    wire in_vector = (px >= VECTOR_X) && (px < VECTOR_X + CELL_SIZE) &&
                     (py >= VECTOR_Y) && (py < VECTOR_Y + 4*CELL_SIZE);
    wire in_graph = (px >= GRAPH_X) && (px < GRAPH_X + GRAPH_WIDTH) &&
                    (py >= GRAPH_Y) && (py < GRAPH_Y + GRAPH_HEIGHT);
    
    // Matrix cell coordinates
    wire [1:0] matrix_row = (py - MATRIX_Y) / CELL_SIZE;
    wire [1:0] matrix_col = (px - MATRIX_X) / CELL_SIZE;
    wire [9:0] matrix_cell_x = px - MATRIX_X - (matrix_col * CELL_SIZE);
    wire [9:0] matrix_cell_y = py - MATRIX_Y - (matrix_row * CELL_SIZE);
    
    // Vector cell coordinates
    wire [1:0] vector_row = (py - VECTOR_Y) / CELL_SIZE;
    wire [9:0] vector_cell_x = px - VECTOR_X;
    wire [9:0] vector_cell_y = py - VECTOR_Y - (vector_row * CELL_SIZE);
    
    // Cursor detection
    wire cursor_matrix = (sw1 == 1'b0) && (matrix_row == edit_row) && (matrix_col == edit_col);
    wire cursor_vector = (sw1 == 1'b1) && (vector_row == edit_row);
    wire cursor_border = (cursor_matrix && (
                          (matrix_cell_x < 2) || (matrix_cell_x >= CELL_SIZE - 2) ||
                          (matrix_cell_y < 2) || (matrix_cell_y >= CELL_SIZE - 2))) ||
                         (cursor_vector && (
                          (vector_cell_x < 2) || (vector_cell_x >= CELL_SIZE - 2) ||
                          (vector_cell_y < 2) || (vector_cell_y >= CELL_SIZE - 2)));
    
    // FSM state decoding
    localparam IDLE     = 7'b0000001;
    localparam LOAD     = 7'b0000010;
    localparam MULT     = 7'b0000100;
    localparam SCALE    = 7'b0001000;
    localparam DIFF     = 7'b0010000;
    localparam CHECK    = 7'b0100000;
    localparam DONE_ST  = 7'b1000000;
    
    wire state_edit = (fsm_state == IDLE) && (sw0 == 1'b0);
    wire state_running = (fsm_state != IDLE) && (fsm_state != DONE_ST);
    wire state_done = fsm_done;
    
    // Bar graph calculations
    // Find maximum absolute value for scaling
    wire [15:0] v_old_abs [0:3];
    wire [15:0] v_new_abs [0:3];
    assign v_old_abs[0] = (v_old_unpack[0] < 0) ? -v_old_unpack[0] : v_old_unpack[0];
    assign v_old_abs[1] = (v_old_unpack[1] < 0) ? -v_old_unpack[1] : v_old_unpack[1];
    assign v_old_abs[2] = (v_old_unpack[2] < 0) ? -v_old_unpack[2] : v_old_unpack[2];
    assign v_old_abs[3] = (v_old_unpack[3] < 0) ? -v_old_unpack[3] : v_old_unpack[3];
    assign v_new_abs[0] = (v_new_unpack[0] < 0) ? -v_new_unpack[0] : v_new_unpack[0];
    assign v_new_abs[1] = (v_new_unpack[1] < 0) ? -v_new_unpack[1] : v_new_unpack[1];
    assign v_new_abs[2] = (v_new_unpack[2] < 0) ? -v_new_unpack[2] : v_new_unpack[2];
    assign v_new_abs[3] = (v_new_unpack[3] < 0) ? -v_new_unpack[3] : v_new_unpack[3];
    
    // Find max of all values for scaling
    wire [15:0] max_old_01 = (v_old_abs[0] > v_old_abs[1]) ? v_old_abs[0] : v_old_abs[1];
    wire [15:0] max_old_23 = (v_old_abs[2] > v_old_abs[3]) ? v_old_abs[2] : v_old_abs[3];
    wire [15:0] max_old = (max_old_01 > max_old_23) ? max_old_01 : max_old_23;
    
    wire [15:0] max_new_01 = (v_new_abs[0] > v_new_abs[1]) ? v_new_abs[0] : v_new_abs[1];
    wire [15:0] max_new_23 = (v_new_abs[2] > v_new_abs[3]) ? v_new_abs[2] : v_new_abs[3];
    wire [15:0] max_new = (max_new_01 > max_new_23) ? max_new_01 : max_new_23;
    
    wire [15:0] max_all = (max_old > max_new) ? max_old : max_new;
    wire [15:0] scale_factor = (max_all > 0) ? max_all : 16'd1;
    
    // Bar heights (scaled to GRAPH_HEIGHT - 20 for labels)
    wire [9:0] bar_max_height = GRAPH_HEIGHT - 20;
    wire [9:0] bar_old_height [0:3];
    wire [9:0] bar_new_height [0:3];
    
    // Simple scaling: multiply by max_height and divide by scale_factor
    // Use right-shift for division (scale_factor >> N to get approximate division)
    wire [5:0] shift_amount;
    assign shift_amount = (scale_factor > 32768) ? 6'd15 :
                         (scale_factor > 16384) ? 6'd14 :
                         (scale_factor > 8192) ? 6'd13 :
                         (scale_factor > 4096) ? 6'd12 :
                         (scale_factor > 2048) ? 6'd11 :
                         (scale_factor > 1024) ? 6'd10 :
                         (scale_factor > 512) ? 6'd9 :
                         (scale_factor > 256) ? 6'd8 :
                         (scale_factor > 128) ? 6'd7 :
                         (scale_factor > 64) ? 6'd6 :
                         (scale_factor > 32) ? 6'd5 :
                         (scale_factor > 16) ? 6'd4 :
                         (scale_factor > 8) ? 6'd3 :
                         (scale_factor > 4) ? 6'd2 :
                         (scale_factor > 2) ? 6'd1 : 6'd0;
    
    assign bar_old_height[0] = (v_old_abs[0] >> shift_amount) > bar_max_height ? bar_max_height : (v_old_abs[0] >> shift_amount);
    assign bar_old_height[1] = (v_old_abs[1] >> shift_amount) > bar_max_height ? bar_max_height : (v_old_abs[1] >> shift_amount);
    assign bar_old_height[2] = (v_old_abs[2] >> shift_amount) > bar_max_height ? bar_max_height : (v_old_abs[2] >> shift_amount);
    assign bar_old_height[3] = (v_old_abs[3] >> shift_amount) > bar_max_height ? bar_max_height : (v_old_abs[3] >> shift_amount);
    
    assign bar_new_height[0] = (v_new_abs[0] >> shift_amount) > bar_max_height ? bar_max_height : (v_new_abs[0] >> shift_amount);
    assign bar_new_height[1] = (v_new_abs[1] >> shift_amount) > bar_max_height ? bar_max_height : (v_new_abs[1] >> shift_amount);
    assign bar_new_height[2] = (v_new_abs[2] >> shift_amount) > bar_max_height ? bar_max_height : (v_new_abs[2] >> shift_amount);
    assign bar_new_height[3] = (v_new_abs[3] >> shift_amount) > bar_max_height ? bar_max_height : (v_new_abs[3] >> shift_amount);
    
    // Bar positions
    wire [9:0] bar_x_old [0:3];
    wire [9:0] bar_x_new [0:3];
    assign bar_x_old[0] = GRAPH_X + 10;
    assign bar_x_old[1] = GRAPH_X + 10 + (BAR_WIDTH + BAR_SPACING);
    assign bar_x_old[2] = GRAPH_X + 10 + 2*(BAR_WIDTH + BAR_SPACING);
    assign bar_x_old[3] = GRAPH_X + 10 + 3*(BAR_WIDTH + BAR_SPACING);
    assign bar_x_new[0] = GRAPH_X + 10 + 4*(BAR_WIDTH + BAR_SPACING);
    assign bar_x_new[1] = GRAPH_X + 10 + 5*(BAR_WIDTH + BAR_SPACING);
    assign bar_x_new[2] = GRAPH_X + 10 + 6*(BAR_WIDTH + BAR_SPACING);
    assign bar_x_new[3] = GRAPH_X + 10 + 7*(BAR_WIDTH + BAR_SPACING);
    
    wire [9:0] bar_bottom = GRAPH_Y + GRAPH_HEIGHT - 20;
    
    // Bar drawing
    wire in_bar_old [0:3];
    wire in_bar_new [0:3];
    assign in_bar_old[0] = (px >= bar_x_old[0]) && (px < bar_x_old[0] + BAR_WIDTH) &&
                           (py >= bar_bottom - bar_old_height[0]) && (py < bar_bottom);
    assign in_bar_old[1] = (px >= bar_x_old[1]) && (px < bar_x_old[1] + BAR_WIDTH) &&
                           (py >= bar_bottom - bar_old_height[1]) && (py < bar_bottom);
    assign in_bar_old[2] = (px >= bar_x_old[2]) && (px < bar_x_old[2] + BAR_WIDTH) &&
                           (py >= bar_bottom - bar_old_height[2]) && (py < bar_bottom);
    assign in_bar_old[3] = (px >= bar_x_old[3]) && (px < bar_x_old[3] + BAR_WIDTH) &&
                           (py >= bar_bottom - bar_old_height[3]) && (py < bar_bottom);
    assign in_bar_new[0] = (px >= bar_x_new[0]) && (px < bar_x_new[0] + BAR_WIDTH) &&
                           (py >= bar_bottom - bar_new_height[0]) && (py < bar_bottom);
    assign in_bar_new[1] = (px >= bar_x_new[1]) && (px < bar_x_new[1] + BAR_WIDTH) &&
                           (py >= bar_bottom - bar_new_height[1]) && (py < bar_bottom);
    assign in_bar_new[2] = (px >= bar_x_new[2]) && (px < bar_x_new[2] + BAR_WIDTH) &&
                           (py >= bar_bottom - bar_new_height[2]) && (py < bar_bottom);
    assign in_bar_new[3] = (px >= bar_x_new[3]) && (px < bar_x_new[3] + BAR_WIDTH) &&
                           (py >= bar_bottom - bar_new_height[3]) && (py < bar_bottom);
    
    wire in_any_bar = in_bar_old[0] || in_bar_old[1] || in_bar_old[2] || in_bar_old[3] ||
                      in_bar_new[0] || in_bar_new[1] || in_bar_new[2] || in_bar_new[3];
    
    // Simple text rendering (8x8 pixel characters)
    // Banner text rendering (simplified - just show state and iteration)
    // We'll use a simple approach: render digits using block_digit_renderer
    
    // Extract digits from iteration_count
    wire [3:0] iter_hundreds = (iteration_count >= 200) ? 4'd2 :
                               (iteration_count >= 100) ? 4'd1 : 4'd0;
    wire [7:0] iter_rem_h = iteration_count - (iter_hundreds * 100);
    wire [3:0] iter_tens = (iter_rem_h >= 90) ? 4'd9 :
                           (iter_rem_h >= 80) ? 4'd8 :
                           (iter_rem_h >= 70) ? 4'd7 :
                           (iter_rem_h >= 60) ? 4'd6 :
                           (iter_rem_h >= 50) ? 4'd5 :
                           (iter_rem_h >= 40) ? 4'd4 :
                           (iter_rem_h >= 30) ? 4'd3 :
                           (iter_rem_h >= 20) ? 4'd2 :
                           (iter_rem_h >= 10) ? 4'd1 : 4'd0;
    wire [3:0] iter_ones = iter_rem_h - (iter_tens * 10);
    
    // Extract epsilon value
    wire [3:0] eps_val = {1'b0, sw_eps};
    
    // Matrix/vector value extraction (for display in cells)
    wire signed [15:0] matrix_val = matrix_a_unpack[matrix_row][matrix_col];
    wire signed [15:0] vector_val = vector_v_unpack[vector_row];
    
    wire [15:0] matrix_abs = (matrix_val < 0) ? -matrix_val : matrix_val;
    wire [15:0] vector_abs = (vector_val < 0) ? -vector_val : vector_val;
    
    // Extract digits (ones only for simplicity in small cells)
    wire [3:0] matrix_ones = matrix_abs[3:0];
    wire [3:0] vector_ones = vector_abs[3:0];
    
    // Simple 8x8 character rendering for banner
    // We'll render a simplified version: just show state name and iteration
    // Position: "EDIT" at (10, 5), "Iter: XX" at (100, 5), "eps = X" at (200, 5)
    
    // Character rendering helper (8x8 grid)
    function [7:0] char_line;
        input [3:0] char_code;
        input [2:0] line;
        begin
            case (char_code)
                4'd0: begin // '0'
                    case (line)
                        3'd0: char_line = 8'b01111110;
                        3'd1: char_line = 8'b11100111;
                        3'd2: char_line = 8'b11101111;
                        3'd3: char_line = 8'b11110111;
                        3'd4: char_line = 8'b11111011;
                        3'd5: char_line = 8'b11111101;
                        3'd6: char_line = 8'b11100111;
                        3'd7: char_line = 8'b01111110;
                        default: char_line = 8'b00000000;
                    endcase
                end
                4'd1: begin // '1'
                    case (line)
                        3'd0: char_line = 8'b00011000;
                        3'd1: char_line = 8'b00111000;
                        3'd2: char_line = 8'b01111000;
                        3'd3: char_line = 8'b00011000;
                        3'd4: char_line = 8'b00011000;
                        3'd5: char_line = 8'b00011000;
                        3'd6: char_line = 8'b00011000;
                        3'd7: char_line = 8'b01111110;
                        default: char_line = 8'b00000000;
                    endcase
                end
                4'd2: begin // '2'
                    case (line)
                        3'd0: char_line = 8'b01111110;
                        3'd1: char_line = 8'b11100111;
                        3'd2: char_line = 8'b00000111;
                        3'd3: char_line = 8'b01111110;
                        3'd4: char_line = 8'b11100000;
                        3'd5: char_line = 8'b11111111;
                        3'd6: char_line = 8'b11111111;
                        3'd7: char_line = 8'b01111110;
                        default: char_line = 8'b00000000;
                    endcase
                end
                4'd3: begin // '3'
                    case (line)
                        3'd0: char_line = 8'b01111110;
                        3'd1: char_line = 8'b11100111;
                        3'd2: char_line = 8'b00000111;
                        3'd3: char_line = 8'b00111110;
                        3'd4: char_line = 8'b00000111;
                        3'd5: char_line = 8'b11100111;
                        3'd6: char_line = 8'b11100111;
                        3'd7: char_line = 8'b01111110;
                        default: char_line = 8'b00000000;
                    endcase
                end
                4'd4: begin // '4'
                    case (line)
                        3'd0: char_line = 8'b11100111;
                        3'd1: char_line = 8'b11100111;
                        3'd2: char_line = 8'b11100111;
                        3'd3: char_line = 8'b11111111;
                        3'd4: char_line = 8'b00000111;
                        3'd5: char_line = 8'b00000111;
                        3'd6: char_line = 8'b00000111;
                        3'd7: char_line = 8'b00000111;
                        default: char_line = 8'b00000000;
                    endcase
                end
                4'd5: begin // '5'
                    case (line)
                        3'd0: char_line = 8'b11111111;
                        3'd1: char_line = 8'b11100000;
                        3'd2: char_line = 8'b11100000;
                        3'd3: char_line = 8'b11111110;
                        3'd4: char_line = 8'b00000111;
                        3'd5: char_line = 8'b11100111;
                        3'd6: char_line = 8'b11100111;
                        3'd7: char_line = 8'b01111110;
                        default: char_line = 8'b00000000;
                    endcase
                end
                4'd6: begin // '6'
                    case (line)
                        3'd0: char_line = 8'b01111110;
                        3'd1: char_line = 8'b11100111;
                        3'd2: char_line = 8'b11100000;
                        3'd3: char_line = 8'b11111110;
                        3'd4: char_line = 8'b11100111;
                        3'd5: char_line = 8'b11100111;
                        3'd6: char_line = 8'b11100111;
                        3'd7: char_line = 8'b01111110;
                        default: char_line = 8'b00000000;
                    endcase
                end
                4'd7: begin // '7'
                    case (line)
                        3'd0: char_line = 8'b11111111;
                        3'd1: char_line = 8'b00000111;
                        3'd2: char_line = 8'b00001110;
                        3'd3: char_line = 8'b00011100;
                        3'd4: char_line = 8'b00111000;
                        3'd5: char_line = 8'b01110000;
                        3'd6: char_line = 8'b11100000;
                        3'd7: char_line = 8'b11100000;
                        default: char_line = 8'b00000000;
                    endcase
                end
                4'd8: begin // '8'
                    case (line)
                        3'd0: char_line = 8'b01111110;
                        3'd1: char_line = 8'b11100111;
                        3'd2: char_line = 8'b11100111;
                        3'd3: char_line = 8'b01111110;
                        3'd4: char_line = 8'b11100111;
                        3'd5: char_line = 8'b11100111;
                        3'd6: char_line = 8'b11100111;
                        3'd7: char_line = 8'b01111110;
                        default: char_line = 8'b00000000;
                    endcase
                end
                4'd9: begin // '9'
                    case (line)
                        3'd0: char_line = 8'b01111110;
                        3'd1: char_line = 8'b11100111;
                        3'd2: char_line = 8'b11100111;
                        3'd3: char_line = 8'b11100111;
                        3'd4: char_line = 8'b01111111;
                        3'd5: char_line = 8'b00000111;
                        3'd6: char_line = 8'b11100111;
                        3'd7: char_line = 8'b01111110;
                        default: char_line = 8'b00000000;
                    endcase
                end
                default: char_line = 8'b00000000;
            endcase
        end
    endfunction
    
    // Render character at position
    function pixel_in_char;
        input [9:0] char_x, char_y;
        input [3:0] char_code;
        input [9:0] px, py;
        reg [2:0] char_line_idx;
        reg [2:0] char_col_idx;
        reg [7:0] char_line_result;
        begin
            if ((px >= char_x) && (px < char_x + 8) && (py >= char_y) && (py < char_y + 8)) begin
                char_line_idx = py - char_y;
                char_col_idx = px - char_x;
                char_line_result = char_line(char_code, char_line_idx);
                pixel_in_char = char_line_result[7 - char_col_idx];
            end else begin
                pixel_in_char = 1'b0;
            end
        end
    endfunction
    
    // Banner rendering
    wire banner_text = pixel_in_char(10, 5, (state_edit ? 4'd4 : (state_running ? 4'd7 : 4'd3)), px, py) || // E/R/D
                      pixel_in_char(18, 5, (state_edit ? 4'd3 : (state_running ? 4'd2 : 4'd0)), px, py) || // D/R/O
                      pixel_in_char(26, 5, (state_edit ? 4'd8 : (state_running ? 4'd0 : 4'd3)), px, py) || // I/U/N
                      pixel_in_char(34, 5, (state_edit ? 4'd9 : (state_running ? 4'd7 : 4'd4)), px, py) || // T/N/E
                      (state_running && pixel_in_char(42, 5, 4'd7, px, py)) || // N
                      (state_running && pixel_in_char(50, 5, 4'd6, px, py)) || // G
                      (state_done && pixel_in_char(42, 5, 4'd3, px, py)) || // D
                      (state_done && pixel_in_char(50, 5, 4'd0, px, py)) || // O
                      (state_done && pixel_in_char(58, 5, 4'd3, px, py)) || // D
                      (state_done && pixel_in_char(66, 5, 4'd4, px, py)) || // E
                      // Iteration count
                      pixel_in_char(100, 5, 4'd8, px, py) || // I
                      pixel_in_char(108, 5, 4'd9, px, py) || // t
                      pixel_in_char(116, 5, 4'd4, px, py) || // e
                      pixel_in_char(124, 5, 4'd7, px, py) || // r
                      pixel_in_char(132, 5, 4'd0, px, py) || // :
                      pixel_in_char(140, 5, iter_tens, px, py) ||
                      pixel_in_char(148, 5, iter_ones, px, py) ||
                      // Epsilon
                      pixel_in_char(200, 5, 4'd4, px, py) || // e
                      pixel_in_char(208, 5, 4'd7, px, py) || // p
                      pixel_in_char(216, 5, 4'd8, px, py) || // s
                      pixel_in_char(224, 5, 4'd0, px, py) || // =
                      pixel_in_char(232, 5, eps_val, px, py);
    
    // Matrix cell borders and labels
    wire matrix_border = in_matrix && (
                         (matrix_cell_x < 1) || (matrix_cell_x >= CELL_SIZE - 1) ||
                         (matrix_cell_y < 1) || (matrix_cell_y >= CELL_SIZE - 1));
    
    // Vector cell borders
    wire vector_border = in_vector && (
                         (vector_cell_x < 1) || (vector_cell_x >= CELL_SIZE - 1) ||
                         (vector_cell_y < 1) || (vector_cell_y >= CELL_SIZE - 1));
    
    // Row/column labels (simple numbers 0-3)
    wire in_matrix_label_row = (px >= MATRIX_X - 15) && (px < MATRIX_X) &&
                                (py >= MATRIX_Y) && (py < MATRIX_Y + 4*CELL_SIZE);
    wire in_matrix_label_col = (px >= MATRIX_X) && (px < MATRIX_X + 4*CELL_SIZE) &&
                               (py >= MATRIX_Y - 15) && (py < MATRIX_Y);
    wire [1:0] label_row_idx = (py - MATRIX_Y) / CELL_SIZE;
    wire [1:0] label_col_idx = (px - MATRIX_X) / CELL_SIZE;
    wire matrix_row_label = in_matrix_label_row && pixel_in_char(MATRIX_X - 12, MATRIX_Y + label_row_idx * CELL_SIZE + 10, {2'b0, label_row_idx}, px, py);
    wire matrix_col_label = in_matrix_label_col && pixel_in_char(MATRIX_X + label_col_idx * CELL_SIZE + 10, MATRIX_Y - 12, {2'b0, label_col_idx}, px, py);
    
    // Cell value rendering (use block_digit_renderer for ones digit)
    wire matrix_digit_pixel, vector_digit_pixel;
    block_digit_renderer #(.DIGIT_WIDTH(20), .DIGIT_HEIGHT(30)) matrix_digit (
        .digit(matrix_ones),
        .px(px),
        .py(py),
        .base_x(MATRIX_X + matrix_col * CELL_SIZE + 10),
        .base_y(MATRIX_Y + matrix_row * CELL_SIZE + 5),
        .pixel_on(matrix_digit_pixel)
    );
    
    block_digit_renderer #(.DIGIT_WIDTH(20), .DIGIT_HEIGHT(30)) vector_digit (
        .digit(vector_ones),
        .px(px),
        .py(py),
        .base_x(VECTOR_X + 10),
        .base_y(VECTOR_Y + vector_row * CELL_SIZE + 5),
        .pixel_on(vector_digit_pixel)
    );
    
    // Negative sign rendering (simple horizontal line)
    wire matrix_neg_sign = in_matrix && (matrix_val < 0) &&
                           (matrix_cell_x >= 5) && (matrix_cell_x < 8) &&
                           (matrix_cell_y >= 15) && (matrix_cell_y < 17);
    wire vector_neg_sign = in_vector && (vector_val < 0) &&
                          (vector_cell_x >= 5) && (vector_cell_x < 8) &&
                          (vector_cell_y >= 15) && (vector_cell_y < 17);
    
    // DONE state message
    wire in_done_msg = (px >= 250) && (px < 400) && (py >= 200) && (py < 250) && state_done;
    wire done_text = in_done_msg && (
                     pixel_in_char(250, 200, 4'd3, px, py) || // D
                     pixel_in_char(258, 200, 4'd0, px, py) || // O
                     pixel_in_char(266, 200, 4'd3, px, py) || // N
                     pixel_in_char(274, 200, 4'd4, px, py) || // E
                     pixel_in_char(290, 200, 4'd0, px, py) || // 0 (dash placeholder)
                     pixel_in_char(298, 200, 4'd4, px, py) || // E
                     pixel_in_char(306, 200, 4'd8, px, py) || // i
                     pixel_in_char(314, 200, 4'd4, px, py) || // e
                     pixel_in_char(322, 200, 4'd6, px, py) || // g
                     pixel_in_char(330, 200, 4'd4, px, py) || // e
                     pixel_in_char(338, 200, 4'd3, px, py) || // n
                     pixel_in_char(346, 200, 4'd7, px, py) || // v
                     pixel_in_char(354, 200, 4'd4, px, py) || // e
                     pixel_in_char(362, 200, 4'd7, px, py)); // r
    
    // Final vector display in DONE state
    wire [3:0] v_new_digit [0:3];
    assign v_new_digit[0] = v_new_unpack[0][3:0];
    assign v_new_digit[1] = v_new_unpack[1][3:0];
    assign v_new_digit[2] = v_new_unpack[2][3:0];
    assign v_new_digit[3] = v_new_unpack[3][3:0];
    
    wire in_final_vec = (px >= 250) && (px < 400) && (py >= 260) && (py < 320) && state_done;
    wire final_vec_text = in_final_vec && (
                          pixel_in_char(250 + 0*16, 260, v_new_digit[0], px, py) ||
                          pixel_in_char(250 + 1*16, 260, v_new_digit[1], px, py) ||
                          pixel_in_char(250 + 2*16, 260, v_new_digit[2], px, py) ||
                          pixel_in_char(250 + 3*16, 260, v_new_digit[3], px, py));
    
    // Main color assignment
    always @(*) begin
        if (!visible) begin
            red = 4'b0000;
            green = 4'b0000;
            blue = 4'b0000;
        end else if (in_banner) begin
            // Banner: white text on black
            if (banner_text) begin
                red = 4'b1111;
                green = 4'b1111;
                blue = 4'b1111;
            end else begin
                red = 4'b0000;
                green = 4'b0000;
                blue = 4'b0000;
            end
        end else if (cursor_border) begin
            // Cursor: yellow/red border
            red = 4'b1111;
            green = 4'b1111;
            blue = 4'b0000;
        end else if (matrix_border || vector_border || matrix_row_label || matrix_col_label) begin
            // Borders and labels: white
            red = 4'b1111;
            green = 4'b1111;
            blue = 4'b1111;
        end else if (in_matrix && (matrix_digit_pixel || matrix_neg_sign)) begin
            // Matrix digits: white
            red = 4'b1111;
            green = 4'b1111;
            blue = 4'b1111;
        end else if (in_vector && (vector_digit_pixel || vector_neg_sign)) begin
            // Vector digits: white
            red = 4'b1111;
            green = 4'b1111;
            blue = 4'b1111;
        end else if (in_any_bar) begin
            // Bar graph: green
            red = 4'b0000;
            green = 4'b1111;
            blue = 4'b0000;
        end else if (done_text || final_vec_text) begin
            // DONE message: white
            red = 4'b1111;
            green = 4'b1111;
            blue = 4'b1111;
        end else begin
            // Background: black
            red = 4'b0000;
            green = 4'b0000;
            blue = 4'b0000;
        end
    end

endmodule
