`timescale 1ns / 1ps

// display_controller.v - VGA display renderer
// Layout:
//   TOP-LEFT:     Editable Vector v (vertical with brackets) - what you edit with sw1=1
//   TOP-RIGHT:    Bar chart (v_old bars | v_new bars) - shows computation progress
//   BOTTOM-LEFT:  Matrix A (4x4 with brackets) - what you edit with sw1=0
//   BOTTOM-RIGHT: Vector v_new (horizontal) + iteration counter

module display_controller (
    input  wire clk,
    input  wire bright,
    input  wire [9:0] hCount,
    input  wire [9:0] vCount,
    input  wire [1:0] edit_row,
    input  wire [1:0] edit_col,
    input  wire cell_locked,
    input  wire sw0,
    input  wire sw1,
    input  wire [2:0] sw_eps,
    input  wire [63:0] matrix_a,
    input  wire [15:0] vector_v,   // Editable initial vector
    input  wire [7:0] fsm_state,
    input  wire fsm_done,
    input  wire [7:0] iteration_count,
    input  wire [15:0] v_old,      // Previous iteration (for chart)
    input  wire [15:0] v_new,      // Current iteration result (for chart)
    output reg  [11:0] rgb
);

    // ========================================================================
    // HELPER FUNCTIONS
    // ========================================================================

    // Convert unsigned 16-bit value to 5-digit BCD (20 bits, [19:16]=ten-thousands)
    function [19:0] bin16_to_bcd;
        input [15:0] value;
        integer idx;
        reg [35:0] shift_reg;
        begin
            shift_reg = 36'd0;
            shift_reg[15:0] = value;
            for (idx = 0; idx < 16; idx = idx + 1) begin
                if (shift_reg[19:16] >= 5) shift_reg[19:16] = shift_reg[19:16] + 3;
                if (shift_reg[23:20] >= 5) shift_reg[23:20] = shift_reg[23:20] + 3;
                if (shift_reg[27:24] >= 5) shift_reg[27:24] = shift_reg[27:24] + 3;
                if (shift_reg[31:28] >= 5) shift_reg[31:28] = shift_reg[31:28] + 3;
                if (shift_reg[35:32] >= 5) shift_reg[35:32] = shift_reg[35:32] + 3;
                shift_reg = shift_reg << 1;
            end
            bin16_to_bcd = shift_reg[35:16];
        end
    endfunction

    // 5x7 font pattern for digits 0-9
    function font_bit;
        input [3:0] digit;
        input [2:0] x;
        input [2:0] y;
        reg [4:0] row_bits;
        begin
            row_bits = 5'b00000;
            case (digit)
                4'd0: case (y)
                    0: row_bits = 5'b01110;
                    1: row_bits = 5'b10001;
                    2: row_bits = 5'b10011;
                    3: row_bits = 5'b10101;
                    4: row_bits = 5'b11001;
                    5: row_bits = 5'b10001;
                    6: row_bits = 5'b01110;
                endcase
                4'd1: case (y)
                    0: row_bits = 5'b00100;
                    1: row_bits = 5'b01100;
                    2: row_bits = 5'b00100;
                    3: row_bits = 5'b00100;
                    4: row_bits = 5'b00100;
                    5: row_bits = 5'b00100;
                    6: row_bits = 5'b01110;
                endcase
                4'd2: case (y)
                    0: row_bits = 5'b01110;
                    1: row_bits = 5'b10001;
                    2: row_bits = 5'b00001;
                    3: row_bits = 5'b00110;
                    4: row_bits = 5'b01000;
                    5: row_bits = 5'b10000;
                    6: row_bits = 5'b11111;
                endcase
                4'd3: case (y)
                    0: row_bits = 5'b11110;
                    1: row_bits = 5'b00001;
                    2: row_bits = 5'b00001;
                    3: row_bits = 5'b01110;
                    4: row_bits = 5'b00001;
                    5: row_bits = 5'b00001;
                    6: row_bits = 5'b11110;
                endcase
                4'd4: case (y)
                    0: row_bits = 5'b00010;
                    1: row_bits = 5'b00110;
                    2: row_bits = 5'b01010;
                    3: row_bits = 5'b10010;
                    4: row_bits = 5'b11111;
                    5: row_bits = 5'b00010;
                    6: row_bits = 5'b00010;
                endcase
                4'd5: case (y)
                    0: row_bits = 5'b11111;
                    1: row_bits = 5'b10000;
                    2: row_bits = 5'b11110;
                    3: row_bits = 5'b00001;
                    4: row_bits = 5'b00001;
                    5: row_bits = 5'b10001;
                    6: row_bits = 5'b01110;
                endcase
                4'd6: case (y)
                    0: row_bits = 5'b01110;
                    1: row_bits = 5'b10000;
                    2: row_bits = 5'b11110;
                    3: row_bits = 5'b10001;
                    4: row_bits = 5'b10001;
                    5: row_bits = 5'b10001;
                    6: row_bits = 5'b01110;
                endcase
                4'd7: case (y)
                    0: row_bits = 5'b11111;
                    1: row_bits = 5'b00001;
                    2: row_bits = 5'b00010;
                    3: row_bits = 5'b00100;
                    4: row_bits = 5'b01000;
                    5: row_bits = 5'b10000;
                    6: row_bits = 5'b10000;
                endcase
                4'd8: case (y)
                    0: row_bits = 5'b01110;
                    1: row_bits = 5'b10001;
                    2: row_bits = 5'b10001;
                    3: row_bits = 5'b01110;
                    4: row_bits = 5'b10001;
                    5: row_bits = 5'b10001;
                    6: row_bits = 5'b01110;
                endcase
                4'd9: case (y)
                    0: row_bits = 5'b01110;
                    1: row_bits = 5'b10001;
                    2: row_bits = 5'b10001;
                    3: row_bits = 5'b01111;
                    4: row_bits = 5'b00001;
                    5: row_bits = 5'b00001;
                    6: row_bits = 5'b01110;
                endcase
                default: row_bits = 5'b00000;
            endcase
            if ((x < FONT_BASE_W) && (y < FONT_BASE_H))
                font_bit = row_bits[FONT_BASE_W-1 - x];
            else
                font_bit = 1'b0;
        end
    endfunction

    // Render scaled font pixel
    function digit_bitmap_pixel;
        input [3:0] digit;
        input [9:0] local_x;
        input [9:0] local_y;
        input [1:0] scale_shift; // 0=original size, 1=double, etc.
        reg [2:0] glyph_x;
        reg [2:0] glyph_y;
        begin
            if ((local_x < (FONT_BASE_W << scale_shift)) &&
                (local_y < (FONT_BASE_H << scale_shift))) begin
                glyph_x = local_x >> scale_shift;
                glyph_y = local_y >> scale_shift;
                digit_bitmap_pixel = font_bit(digit, glyph_x, glyph_y);
            end else begin
                digit_bitmap_pixel = 1'b0;
            end
        end
    endfunction

    // COLORS
    // ========================================================================
    parameter BLACK   = 12'b0000_0000_0000;
    parameter WHITE   = 12'b1111_1111_1111;
    parameter YELLOW  = 12'b1111_1111_0000;
    parameter CYAN    = 12'b0000_1111_1111;
    parameter GREEN   = 12'b0000_1111_0000;
    parameter RED     = 12'b1111_0000_0000;
    parameter MAGENTA = 12'b1111_0000_1111;
    parameter GRAY    = 12'b0100_0100_0100;
    parameter BLUE    = 12'b0011_0011_1111;
    parameter ORANGE  = 12'b1111_1000_0000;

    // Small digit rendering parameters (5x7 font scaled as needed)
    localparam integer FONT_BASE_W = 5;
    localparam integer FONT_BASE_H = 7;
    localparam integer DIGIT_COUNT = 5;  // Show up to 5 decimal digits (covers 16-bit range)

    // ========================================================================
    // SCREEN LAYOUT CONSTANTS - Visible area: 640 x 480 pixels
    // ========================================================================
    
    // ---- EDITABLE VECTOR V REGION (top-left) ----
    // This is the vector you edit when sw1=1
    parameter VEC_V_X0 = 20;
    parameter VEC_V_X1 = 120;
    parameter VEC_V_Y0 = 30;
    parameter VEC_V_Y1 = 220;
    parameter VEC_V_CELL_H = 45;
    
    // ---- CHART REGION (top-right) ----
    parameter CHART_X0 = 160;
    parameter CHART_X1 = 620;
    parameter CHART_Y0 = 30;
    parameter CHART_Y1 = 220;
    parameter BAR_WIDTH = 45;
    parameter BAR_SPACING = 10;
    parameter BAR_MAX_HEIGHT = 160;
    
    // ---- MATRIX REGION (bottom-left) - LARGER to fit 4x4 ----
    parameter MATRIX_X0 = 10;
    parameter MATRIX_X1 = 190;   // Wider!
    parameter MATRIX_Y0 = 250;
    parameter MATRIX_Y1 = 470;
    parameter MATRIX_CELL_SIZE = 42;  // Slightly smaller cells
    
    // ---- VEC_NEW REGION (bottom-right) ----
    parameter VEC_NEW_X0 = 220;
    parameter VEC_NEW_X1 = 540;
    parameter VEC_NEW_Y0 = 320;
    parameter VEC_NEW_Y1 = 390;
    parameter VEC_NEW_CELL_W = 75;
    
    // ---- ITER DISPLAY ----
    parameter ITER_X0 = 560;
    parameter ITER_Y0 = 340;

    // ========================================================================
    // VISIBLE PIXEL COORDINATES
    // ========================================================================
    wire [9:0] px = hCount - 10'd144;
    wire [9:0] py = vCount - 10'd35;
    
    // ========================================================================
    // UNPACK INPUT DATA
    // ========================================================================
    // Matrix A (4x4) - editable with sw1=0
    wire [3:0] A [0:3][0:3];
    assign A[0][0] = matrix_a[3:0];
    assign A[0][1] = matrix_a[7:4];
    assign A[0][2] = matrix_a[11:8];
    assign A[0][3] = matrix_a[15:12];
    assign A[1][0] = matrix_a[19:16];
    assign A[1][1] = matrix_a[23:20];
    assign A[1][2] = matrix_a[27:24];
    assign A[1][3] = matrix_a[31:28];
    assign A[2][0] = matrix_a[35:32];
    assign A[2][1] = matrix_a[39:36];
    assign A[2][2] = matrix_a[43:40];
    assign A[2][3] = matrix_a[47:44];
    assign A[3][0] = matrix_a[51:48];
    assign A[3][1] = matrix_a[55:52];
    assign A[3][2] = matrix_a[59:56];
    assign A[3][3] = matrix_a[63:60];
    
    // Vector v (editable initial vector) - editable with sw1=1
    wire [3:0] v [0:3];
    assign v[0] = vector_v[3:0];
    assign v[1] = vector_v[7:4];
    assign v[2] = vector_v[11:8];
    assign v[3] = vector_v[15:12];
    
    // v_old (previous iteration - for bar chart)
    wire [3:0] vo [0:3];
    assign vo[0] = v_old[3:0];
    assign vo[1] = v_old[7:4];
    assign vo[2] = v_old[11:8];
    assign vo[3] = v_old[15:12];
    
    // v_new (current iteration result - for bar chart and display)
    wire [3:0] vn [0:3];
    assign vn[0] = v_new[3:0];
    assign vn[1] = v_new[7:4];
    assign vn[2] = v_new[11:8];
    assign vn[3] = v_new[15:12];
    
    // FSM state
    localparam IDLE = 7'b0000001;
    // Edit mode: sw0=0 means we're in edit mode
    wire state_edit = (sw0 == 1'b0);

    // Precomputed decimal digits for matrix and vectors (tens/ones only)
    reg [3:0] mat_digit_tens [0:3][0:3];
    reg [3:0] mat_digit_ones [0:3][0:3];

    reg [3:0] vec_digit_tens [0:3];
    reg [3:0] vec_digit_ones [0:3];

    reg [3:0] vnew_digit_tens [0:3];
    reg [3:0] vnew_digit_ones [0:3];

    integer mi, mj;

    always @(*) begin
        for (mi = 0; mi < 4; mi = mi + 1) begin
            vec_digit_tens[mi] = v[mi] / 10;
            vec_digit_ones[mi] = v[mi] % 10;
        end

        for (mi = 0; mi < 4; mi = mi + 1) begin
            vnew_digit_tens[mi] = vn[mi] / 10;
            vnew_digit_ones[mi] = vn[mi] % 10;
        end

        for (mi = 0; mi < 4; mi = mi + 1) begin
            for (mj = 0; mj < 4; mj = mj + 1) begin
                mat_digit_tens[mi][mj] = A[mi][mj] / 10;
                mat_digit_ones[mi][mj] = A[mi][mj] % 10;
            end
        end
    end

    function [3:0] get_vec_digit;
        input [1:0] row;
        input [1:0] slot;
        begin
            case (slot)
                2'd0: get_vec_digit = vec_digit_tens[row];
                2'd1: get_vec_digit = vec_digit_ones[row];
                default: get_vec_digit = 4'd0;
            endcase
        end
    endfunction

    function [3:0] get_vnew_digit;
        input [1:0] row;
        input [1:0] slot;
        begin
            case (slot)
                2'd0: get_vnew_digit = vnew_digit_tens[row];
                2'd1: get_vnew_digit = vnew_digit_ones[row];
                default: get_vnew_digit = 4'd0;
            endcase
        end
    endfunction

    function [3:0] get_mat_digit;
        input [1:0] row;
        input [1:0] col;
        input [1:0] slot;
        begin
            case (slot)
                2'd0: get_mat_digit = mat_digit_tens[row][col];
                2'd1: get_mat_digit = mat_digit_ones[row][col];
                default: get_mat_digit = 4'd0;
            endcase
        end
    endfunction

    // ========================================================================
    // REGION DETECTION
    // ========================================================================
    wire in_vec_v_region = (px >= VEC_V_X0) && (px < VEC_V_X1) &&
                           (py >= VEC_V_Y0) && (py < VEC_V_Y1);
    
    wire in_chart_region = (px >= CHART_X0) && (px < CHART_X1) &&
                           (py >= CHART_Y0) && (py < CHART_Y1);
    
    wire in_matrix_region = (px >= MATRIX_X0) && (px < MATRIX_X1) &&
                            (py >= MATRIX_Y0) && (py < MATRIX_Y1);
    
    wire in_vec_new_region = (px >= VEC_NEW_X0) && (px < VEC_NEW_X1) &&
                             (py >= VEC_NEW_Y0) && (py < VEC_NEW_Y1);
    
    wire in_iter_region = (px >= ITER_X0) && (px < ITER_X0 + 70) &&
                          (py >= ITER_Y0) && (py < ITER_Y0 + 30);
    
    // ========================================================================
    // EDITABLE VECTOR V REGION - Shows vector_v (what you edit with sw1=1)
    // ========================================================================
    wire [9:0] vec_v_local_x = px - VEC_V_X0;
    wire [9:0] vec_v_local_y = py - VEC_V_Y0;
    wire [1:0] vec_v_idx = vec_v_local_y / VEC_V_CELL_H;
    wire [9:0] vec_v_cell_y = vec_v_local_y - (vec_v_idx * VEC_V_CELL_H);
    wire vec_v_valid_idx = (vec_v_idx < 4) && (vec_v_local_y < 4 * VEC_V_CELL_H);
    
    // Brackets for vector v
    wire [9:0] vec_v_width = VEC_V_X1 - VEC_V_X0;
    wire [9:0] vec_v_height = 4 * VEC_V_CELL_H;
    wire vec_v_left_bracket = in_vec_v_region && (vec_v_local_x < 8) && vec_v_valid_idx &&
                              ((vec_v_local_y < 4) || (vec_v_local_y >= vec_v_height - 4) || (vec_v_local_x < 3));
    wire vec_v_right_bracket = in_vec_v_region && (vec_v_local_x >= vec_v_width - 8) && vec_v_valid_idx &&
                               ((vec_v_local_y < 4) || (vec_v_local_y >= vec_v_height - 4) || (vec_v_local_x >= vec_v_width - 3));
    
    // Get vector v value for current row (this is what you EDIT)
    // Current editable vector element (unsigned values only)
    
    // Multi-digit rendering for editable vector (5 decimal digits)
    localparam integer VEC_DIGIT_SCALE   = 1; // 2x scale
    localparam integer VEC_DIGIT_WIDTH   = FONT_BASE_W << VEC_DIGIT_SCALE;  // 10
    localparam integer VEC_DIGIT_HEIGHT  = FONT_BASE_H << VEC_DIGIT_SCALE;  // 14
    localparam integer VEC_DIGIT_SPACING = 3;
    localparam integer VEC_DIGIT_X_START = 18;
    localparam integer VEC_DIGIT_Y_OFF   = 10;
    
    wire vec_digit_band = in_vec_v_region && vec_v_valid_idx &&
                          (vec_v_cell_y >= VEC_DIGIT_Y_OFF) && (vec_v_cell_y < VEC_DIGIT_Y_OFF + VEC_DIGIT_HEIGHT);
    wire [9:0] vec_digit_local_y = vec_v_cell_y - VEC_DIGIT_Y_OFF;
    
    wire vec_digit0_pix = vec_digit_band &&
                      (vec_v_local_x >= VEC_DIGIT_X_START) &&
                      (vec_v_local_x < VEC_DIGIT_X_START + VEC_DIGIT_WIDTH) &&
                      digit_bitmap_pixel(get_vec_digit(vec_v_idx, 2'd0),
                                         vec_v_local_x - VEC_DIGIT_X_START,
                                         vec_digit_local_y,
                                         VEC_DIGIT_SCALE);
    wire vec_digit1_pix = vec_digit_band &&
                      (vec_v_local_x >= VEC_DIGIT_X_START + (VEC_DIGIT_WIDTH + VEC_DIGIT_SPACING)) &&
                      (vec_v_local_x < VEC_DIGIT_X_START + (VEC_DIGIT_WIDTH + VEC_DIGIT_SPACING) + VEC_DIGIT_WIDTH) &&
                      digit_bitmap_pixel(get_vec_digit(vec_v_idx, 2'd1),
                                         vec_v_local_x - (VEC_DIGIT_X_START + (VEC_DIGIT_WIDTH + VEC_DIGIT_SPACING)),
                                         vec_digit_local_y,
                                         VEC_DIGIT_SCALE);
    
    wire vec_digits_on = vec_digit0_pix | vec_digit1_pix;
    
    // Cursor for vector v (only in edit mode when sw1=1)
    wire vec_v_cursor = state_edit && (sw1 == 1'b1) && (vec_v_idx == edit_row) && vec_v_valid_idx;
    wire vec_v_cursor_border = vec_v_cursor && in_vec_v_region &&
                               ((vec_v_cell_y < 5) || (vec_v_cell_y >= VEC_V_CELL_H - 5) ||
                                (vec_v_local_x < 13) || (vec_v_local_x >= vec_v_width - 13));

    // ========================================================================
    // CHART REGION - Bar charts for v_old and v_new (computation progress)
    // ========================================================================
    wire [9:0] chart_local_x = px - CHART_X0;
    wire [9:0] chart_local_y = py - CHART_Y0;
    wire [9:0] chart_width = CHART_X1 - CHART_X0;
    wire [9:0] chart_height = CHART_Y1 - CHART_Y0;
    wire [9:0] bar_bottom = chart_height - 15;
    
    // Split chart: left half = v_old bars, right half = v_new bars
    wire [9:0] half_width = chart_width / 2;
    wire in_left_chart = in_chart_region && (chart_local_x < half_width);
    wire in_right_chart = in_chart_region && (chart_local_x >= half_width);
    
    // Bar positions
    wire [9:0] left_bar_base_x = 25;
    wire [9:0] right_bar_base_x = half_width + 25;
    
    wire [9:0] left_bar_offset = chart_local_x - left_bar_base_x;
    wire [9:0] right_bar_offset = chart_local_x - right_bar_base_x;
    wire [2:0] left_bar_idx = left_bar_offset / (BAR_WIDTH + BAR_SPACING);
    wire [2:0] right_bar_idx = right_bar_offset / (BAR_WIDTH + BAR_SPACING);
    wire [9:0] left_bar_local_x = left_bar_offset - (left_bar_idx * (BAR_WIDTH + BAR_SPACING));
    wire [9:0] right_bar_local_x = right_bar_offset - (right_bar_idx * (BAR_WIDTH + BAR_SPACING));
    
    // Scale bars directly from 4-bit unsigned magnitudes
    localparam integer BAR_SCALE = 10;
    wire [9:0] vo_bar_h [0:3];
    wire [9:0] vn_bar_h [0:3];
    wire [9:0] vo_scaled [0:3];
    wire [9:0] vn_scaled [0:3];
    assign vo_scaled[0] = vo[0] * BAR_SCALE;
    assign vo_scaled[1] = vo[1] * BAR_SCALE;
    assign vo_scaled[2] = vo[2] * BAR_SCALE;
    assign vo_scaled[3] = vo[3] * BAR_SCALE;
    assign vn_scaled[0] = vn[0] * BAR_SCALE;
    assign vn_scaled[1] = vn[1] * BAR_SCALE;
    assign vn_scaled[2] = vn[2] * BAR_SCALE;
    assign vn_scaled[3] = vn[3] * BAR_SCALE;
    assign vo_bar_h[0] = (vo_scaled[0] > BAR_MAX_HEIGHT) ? BAR_MAX_HEIGHT : vo_scaled[0];
    assign vo_bar_h[1] = (vo_scaled[1] > BAR_MAX_HEIGHT) ? BAR_MAX_HEIGHT : vo_scaled[1];
    assign vo_bar_h[2] = (vo_scaled[2] > BAR_MAX_HEIGHT) ? BAR_MAX_HEIGHT : vo_scaled[2];
    assign vo_bar_h[3] = (vo_scaled[3] > BAR_MAX_HEIGHT) ? BAR_MAX_HEIGHT : vo_scaled[3];
    assign vn_bar_h[0] = (vn_scaled[0] > BAR_MAX_HEIGHT) ? BAR_MAX_HEIGHT : vn_scaled[0];
    assign vn_bar_h[1] = (vn_scaled[1] > BAR_MAX_HEIGHT) ? BAR_MAX_HEIGHT : vn_scaled[1];
    assign vn_bar_h[2] = (vn_scaled[2] > BAR_MAX_HEIGHT) ? BAR_MAX_HEIGHT : vn_scaled[2];
    assign vn_bar_h[3] = (vn_scaled[3] > BAR_MAX_HEIGHT) ? BAR_MAX_HEIGHT : vn_scaled[3];
    
    // Check if pixel is in a v_old bar
    reg in_vo_bar;
    always @(*) begin
        in_vo_bar = 1'b0;
        if (in_left_chart && (left_bar_local_x < BAR_WIDTH) && (left_bar_idx < 4)) begin
            case (left_bar_idx[1:0])
                2'd0: in_vo_bar = (chart_local_y >= bar_bottom - vo_bar_h[0]) && (chart_local_y < bar_bottom);
                2'd1: in_vo_bar = (chart_local_y >= bar_bottom - vo_bar_h[1]) && (chart_local_y < bar_bottom);
                2'd2: in_vo_bar = (chart_local_y >= bar_bottom - vo_bar_h[2]) && (chart_local_y < bar_bottom);
                2'd3: in_vo_bar = (chart_local_y >= bar_bottom - vo_bar_h[3]) && (chart_local_y < bar_bottom);
                    endcase
                end
    end
    
    // Check if pixel is in a v_new bar
    reg in_vn_bar;
    always @(*) begin
        in_vn_bar = 1'b0;
        if (in_right_chart && (right_bar_local_x < BAR_WIDTH) && (right_bar_idx < 4)) begin
            case (right_bar_idx[1:0])
                2'd0: in_vn_bar = (chart_local_y >= bar_bottom - vn_bar_h[0]) && (chart_local_y < bar_bottom);
                2'd1: in_vn_bar = (chart_local_y >= bar_bottom - vn_bar_h[1]) && (chart_local_y < bar_bottom);
                2'd2: in_vn_bar = (chart_local_y >= bar_bottom - vn_bar_h[2]) && (chart_local_y < bar_bottom);
                2'd3: in_vn_bar = (chart_local_y >= bar_bottom - vn_bar_h[3]) && (chart_local_y < bar_bottom);
                    endcase
                end
    end
    
    // Chart structure
    wire chart_border = in_chart_region && 
                        ((chart_local_x < 2) || (chart_local_x >= chart_width - 2) ||
                         (chart_local_y < 2) || (chart_local_y >= chart_height - 2));
    wire chart_divider = in_chart_region && (chart_local_x >= half_width - 1) && (chart_local_x < half_width + 1);
    wire chart_baseline = in_chart_region && (chart_local_y >= bar_bottom) && (chart_local_y < bar_bottom + 2);

    // ========================================================================
    // MATRIX REGION - 4x4 matrix with brackets (edit with sw1=0)
    // ========================================================================
    wire [9:0] mat_local_x = px - MATRIX_X0;
    wire [9:0] mat_local_y = py - MATRIX_Y0;
    wire [9:0] mat_width = MATRIX_X1 - MATRIX_X0;
    wire [9:0] mat_height = MATRIX_Y1 - MATRIX_Y0;
    
    // Matrix grid area (inside brackets)
    parameter MAT_BRACKET_W = 10;
    wire [9:0] mat_grid_x0 = MAT_BRACKET_W;
    wire [9:0] mat_grid_y0 = 20;
    wire [9:0] mat_grid_w = 4 * MATRIX_CELL_SIZE;
    wire [9:0] mat_grid_h = 4 * MATRIX_CELL_SIZE;
    
    wire in_mat_grid = in_matrix_region && 
                       (mat_local_x >= mat_grid_x0) && (mat_local_x < mat_grid_x0 + mat_grid_w) &&
                       (mat_local_y >= mat_grid_y0) && (mat_local_y < mat_grid_y0 + mat_grid_h);
    
    // Matrix cell position
    wire [9:0] mat_grid_rel_x = mat_local_x - mat_grid_x0;
    wire [9:0] mat_grid_rel_y = mat_local_y - mat_grid_y0;
    wire [1:0] mat_row = mat_grid_rel_y / MATRIX_CELL_SIZE;
    wire [1:0] mat_col = mat_grid_rel_x / MATRIX_CELL_SIZE;
    wire [9:0] mat_cell_x = mat_grid_rel_x - (mat_col * MATRIX_CELL_SIZE);
    wire [9:0] mat_cell_y = mat_grid_rel_y - (mat_row * MATRIX_CELL_SIZE);
    
    // Matrix brackets
    wire mat_left_bracket = in_matrix_region && (mat_local_x < MAT_BRACKET_W) &&
                            (mat_local_y >= mat_grid_y0) && (mat_local_y < mat_grid_y0 + mat_grid_h) &&
                            ((mat_local_y < mat_grid_y0 + 4) || 
                             (mat_local_y >= mat_grid_y0 + mat_grid_h - 4) || 
                             (mat_local_x < 3));
    wire mat_right_bracket = in_matrix_region && (mat_local_x >= mat_grid_x0 + mat_grid_w) &&
                             (mat_local_y >= mat_grid_y0) && (mat_local_y < mat_grid_y0 + mat_grid_h) &&
                             ((mat_local_y < mat_grid_y0 + 4) || 
                              (mat_local_y >= mat_grid_y0 + mat_grid_h - 4) || 
                              (mat_local_x >= mat_grid_x0 + mat_grid_w + MAT_BRACKET_W - 3));
    
    localparam integer MAT_DIGIT_SCALE   = 0; // base size
    localparam integer MAT_DIGIT_WIDTH   = FONT_BASE_W << MAT_DIGIT_SCALE;  // 5
    localparam integer MAT_DIGIT_HEIGHT  = FONT_BASE_H << MAT_DIGIT_SCALE;  // 7
    localparam integer MAT_DIGIT_SPACING = 1;
    localparam integer MAT_DIGIT_X_START = 4;
    localparam integer MAT_DIGIT_Y_OFF   = 10;
    
    wire mat_digit_band = in_mat_grid &&
                          (mat_cell_y >= MAT_DIGIT_Y_OFF) && (mat_cell_y < MAT_DIGIT_Y_OFF + MAT_DIGIT_HEIGHT);
    wire [9:0] mat_digit_local_y = mat_cell_y - MAT_DIGIT_Y_OFF;
    
    wire mat_digit0_pix = mat_digit_band &&
                      (mat_cell_x >= MAT_DIGIT_X_START) &&
                      (mat_cell_x < MAT_DIGIT_X_START + MAT_DIGIT_WIDTH) &&
                      digit_bitmap_pixel(get_mat_digit(mat_row, mat_col, 2'd0),
                                         mat_cell_x - MAT_DIGIT_X_START,
                                         mat_digit_local_y,
                                         MAT_DIGIT_SCALE);
    wire mat_digit1_pix = mat_digit_band &&
                      (mat_cell_x >= MAT_DIGIT_X_START + (MAT_DIGIT_WIDTH + MAT_DIGIT_SPACING)) &&
                      (mat_cell_x < MAT_DIGIT_X_START + (MAT_DIGIT_WIDTH + MAT_DIGIT_SPACING) + MAT_DIGIT_WIDTH) &&
                      digit_bitmap_pixel(get_mat_digit(mat_row, mat_col, 2'd1),
                                         mat_cell_x - (MAT_DIGIT_X_START + (MAT_DIGIT_WIDTH + MAT_DIGIT_SPACING)),
                                         mat_digit_local_y,
                                         MAT_DIGIT_SCALE);
    
    wire mat_digits_on = mat_digit0_pix | mat_digit1_pix;
    
    // Matrix cell border
    wire mat_cell_border = in_mat_grid && 
                           ((mat_cell_x < 1) || (mat_cell_x >= MATRIX_CELL_SIZE - 1) ||
                            (mat_cell_y < 1) || (mat_cell_y >= MATRIX_CELL_SIZE - 1));
    
    // Matrix cursor (only in edit mode, sw1=0 means editing matrix)
    wire mat_cursor = state_edit && (sw1 == 1'b0) && in_mat_grid &&
                      (mat_row == edit_row) && (mat_col == edit_col);
    wire mat_cursor_border = mat_cursor &&
                             ((mat_cell_x < 5) || (mat_cell_x >= MATRIX_CELL_SIZE - 5) ||
                              (mat_cell_y < 5) || (mat_cell_y >= MATRIX_CELL_SIZE - 5));

    // ========================================================================
    // VEC_NEW REGION - Horizontal vector showing computation result
    // ========================================================================
    wire [9:0] vnew_local_x = px - VEC_NEW_X0;
    wire [9:0] vnew_local_y = py - VEC_NEW_Y0;
    wire [9:0] vnew_width = VEC_NEW_X1 - VEC_NEW_X0;
    wire [9:0] vnew_height = VEC_NEW_Y1 - VEC_NEW_Y0;
    
    // v_new element position
    wire [9:0] vnew_grid_x0 = 15;
    wire [2:0] vnew_idx = (vnew_local_x - vnew_grid_x0) / VEC_NEW_CELL_W;
    wire [9:0] vnew_cell_x = (vnew_local_x - vnew_grid_x0) - (vnew_idx * VEC_NEW_CELL_W);
    wire vnew_valid = (vnew_local_x >= vnew_grid_x0) && (vnew_idx < 4);
    
    // v_new brackets
    wire vnew_left_bracket = in_vec_new_region && (vnew_local_x < 12) &&
                             ((vnew_local_y < 5) || (vnew_local_y >= vnew_height - 5) || (vnew_local_x < 3));
    wire vnew_right_bracket = in_vec_new_region && (vnew_local_x >= vnew_width - 12) &&
                              ((vnew_local_y < 5) || (vnew_local_y >= vnew_height - 5) || (vnew_local_x >= vnew_width - 3));
    
    // Get v_new value (unsigned)
    
    localparam integer VNEW_DIGIT_SCALE   = 1;
    localparam integer VNEW_DIGIT_WIDTH   = FONT_BASE_W << VNEW_DIGIT_SCALE;
    localparam integer VNEW_DIGIT_HEIGHT  = FONT_BASE_H << VNEW_DIGIT_SCALE;
    localparam integer VNEW_DIGIT_SPACING = 3;
    localparam integer VNEW_DIGIT_X_START = 18;
    localparam integer VNEW_DIGIT_Y_OFF   = 18;
    
    wire vnew_digit_band = in_vec_new_region && vnew_valid &&
                           (vnew_local_y >= VNEW_DIGIT_Y_OFF) && (vnew_local_y < VNEW_DIGIT_Y_OFF + VNEW_DIGIT_HEIGHT);
    wire [9:0] vnew_digit_local_y = vnew_local_y - VNEW_DIGIT_Y_OFF;
    
    wire vnew_digit0_pix = vnew_digit_band &&
                       (vnew_cell_x >= VNEW_DIGIT_X_START) &&
                       (vnew_cell_x < VNEW_DIGIT_X_START + VNEW_DIGIT_WIDTH) &&
                       digit_bitmap_pixel(get_vnew_digit(vnew_idx[1:0], 2'd0),
                                          vnew_cell_x - VNEW_DIGIT_X_START,
                                          vnew_digit_local_y,
                                          VNEW_DIGIT_SCALE);
    wire vnew_digit1_pix = vnew_digit_band &&
                       (vnew_cell_x >= VNEW_DIGIT_X_START + (VNEW_DIGIT_WIDTH + VNEW_DIGIT_SPACING)) &&
                       (vnew_cell_x < VNEW_DIGIT_X_START + (VNEW_DIGIT_WIDTH + VNEW_DIGIT_SPACING) + VNEW_DIGIT_WIDTH) &&
                       digit_bitmap_pixel(get_vnew_digit(vnew_idx[1:0], 2'd1),
                                          vnew_cell_x - (VNEW_DIGIT_X_START + (VNEW_DIGIT_WIDTH + VNEW_DIGIT_SPACING)),
                                          vnew_digit_local_y,
                                          VNEW_DIGIT_SCALE);
    
    wire vnew_digits_on = vnew_digit0_pix | vnew_digit1_pix;
    
    // v_new border
    wire vnew_border = in_vec_new_region &&
                       ((vnew_local_x < 2) || (vnew_local_x >= vnew_width - 2) ||
                        (vnew_local_y < 2) || (vnew_local_y >= vnew_height - 2));
    
    // ========================================================================
    // ITERATION COUNTER DISPLAY
    // ========================================================================
    wire [3:0] iter_tens = iteration_count / 10;
    wire [3:0] iter_ones = iteration_count % 10;
    
    wire [9:0] iter_local_x = px - ITER_X0;
    wire [9:0] iter_local_y = py - ITER_Y0;
    
    wire in_iter_tens = in_iter_region && (iter_local_x >= 5) && (iter_local_x < 30);
    wire in_iter_ones = in_iter_region && (iter_local_x >= 35) && (iter_local_x < 60);
    
    wire [9:0] iter_dig_x = in_iter_tens ? (iter_local_x - 5) : (iter_local_x - 35);
    wire [9:0] iter_dig_y = iter_local_y - 5;
    wire in_iter_digit_area = (in_iter_tens || in_iter_ones) && (iter_dig_y < 22);
    
    // 7-segment for iteration
    wire iter_seg_a = in_iter_digit_area && (iter_dig_y < 3) && (iter_dig_x >= 3) && (iter_dig_x < 20);
    wire iter_seg_b = in_iter_digit_area && (iter_dig_x >= 20) && (iter_dig_y >= 1) && (iter_dig_y < 10);
    wire iter_seg_c = in_iter_digit_area && (iter_dig_x >= 20) && (iter_dig_y >= 12) && (iter_dig_y < 21);
    wire iter_seg_d = in_iter_digit_area && (iter_dig_y >= 19) && (iter_dig_x >= 3) && (iter_dig_x < 20);
    wire iter_seg_e = in_iter_digit_area && (iter_dig_x < 3) && (iter_dig_y >= 12) && (iter_dig_y < 21);
    wire iter_seg_f = in_iter_digit_area && (iter_dig_x < 3) && (iter_dig_y >= 1) && (iter_dig_y < 10);
    wire iter_seg_g = in_iter_digit_area && (iter_dig_y >= 9) && (iter_dig_y < 13) && (iter_dig_x >= 3) && (iter_dig_x < 20);
    
    wire [3:0] iter_curr_digit = in_iter_tens ? iter_tens : iter_ones;
    reg [6:0] iter_seg_en;
    always @(*) begin
        case (iter_curr_digit)
            4'd0: iter_seg_en = 7'b1111110;
            4'd1: iter_seg_en = 7'b0110000;
            4'd2: iter_seg_en = 7'b1101101;
            4'd3: iter_seg_en = 7'b1111001;
            4'd4: iter_seg_en = 7'b0110011;
            4'd5: iter_seg_en = 7'b1011011;
            4'd6: iter_seg_en = 7'b1011111;
            4'd7: iter_seg_en = 7'b1110000;
            4'd8: iter_seg_en = 7'b1111111;
            4'd9: iter_seg_en = 7'b1111011;
            default: iter_seg_en = 7'b0000000;
        endcase
    end
    
    wire iter_digit_pixel = (iter_seg_en[6] && iter_seg_a) || (iter_seg_en[5] && iter_seg_b) ||
                            (iter_seg_en[4] && iter_seg_c) || (iter_seg_en[3] && iter_seg_d) ||
                            (iter_seg_en[2] && iter_seg_e) || (iter_seg_en[1] && iter_seg_f) ||
                            (iter_seg_en[0] && iter_seg_g);

    // ========================================================================
    // LABELS
    // ========================================================================
    // "v" label for editable vector
    wire in_v_label = (px >= VEC_V_X0 + 35) && (px < VEC_V_X0 + 65) &&
                      (py >= VEC_V_Y0 - 18) && (py < VEC_V_Y0 - 5);
    
    // "A" label for matrix
    wire in_A_label = (px >= MATRIX_X0 + 80) && (px < MATRIX_X0 + 110) &&
                      (py >= MATRIX_Y0 - 18) && (py < MATRIX_Y0 - 5);
    
    // "v_old" and "v_new" chart labels
    wire in_vo_label = (px >= CHART_X0 + 70) && (px < CHART_X0 + 150) &&
                       (py >= CHART_Y0 - 18) && (py < CHART_Y0 - 5);
    wire in_vn_chart_label = (px >= CHART_X0 + half_width + 70) && (px < CHART_X0 + half_width + 150) &&
                             (py >= CHART_Y0 - 18) && (py < CHART_Y0 - 5);
    
    // "result" label for v_new
    wire in_result_label = (px >= VEC_NEW_X0 + 100) && (px < VEC_NEW_X0 + 200) &&
                           (py >= VEC_NEW_Y0 - 18) && (py < VEC_NEW_Y0 - 5);
    
    // "iter" label
    wire in_iter_label = (px >= ITER_X0) && (px < ITER_X0 + 50) &&
                         (py >= ITER_Y0 - 18) && (py < ITER_Y0 - 5);
    
    // ========================================================================
    // MODE INDICATOR
    // ========================================================================
    wire in_mode_area = (px >= 550) && (px < 630) && (py >= 5) && (py < 22);
    
    // Debug: Show edit position indicators (orange bars on left/top)
    wire edit_pos_indicator = state_edit && (
        // Show row indicator on the left
        ((px >= 2) && (px < 6) && (py >= 240 + edit_row * 10) && (py < 248 + edit_row * 10)) ||
        // Show col indicator on the top (only when editing matrix)
        ((sw1 == 1'b0) && (px >= 200 + edit_col * 10) && (px < 208 + edit_col * 10) && (py >= 240) && (py < 244))
    );
    
    // ========================================================================
    // DEBUG DISPLAY - Shows switch states and edit position
    // ========================================================================
    // Big visual indicators for switch states (top of screen)
    wire sw0_indicator = (px >= 10) && (px < 60) && (py >= 5) && (py < 20);
    wire sw1_indicator = (px >= 70) && (px < 120) && (py >= 5) && (py < 20);
    
    // Show edit_row as vertical bars (left side)
    wire row0_bar = (px >= 3) && (px < 8) && (py >= 60) && (py < 80) && (edit_row == 2'd0);
    wire row1_bar = (px >= 3) && (px < 8) && (py >= 90) && (py < 110) && (edit_row == 2'd1);
    wire row2_bar = (px >= 3) && (px < 8) && (py >= 120) && (py < 140) && (edit_row == 2'd2);
    wire row3_bar = (px >= 3) && (px < 8) && (py >= 150) && (py < 170) && (edit_row == 2'd3);
    wire row_indicator = row0_bar || row1_bar || row2_bar || row3_bar;
    
    // Show edit_col as horizontal bars (top)
    wire col0_bar = (px >= 200) && (px < 220) && (py >= 235) && (py < 240) && (edit_col == 2'd0);
    wire col1_bar = (px >= 230) && (px < 250) && (py >= 235) && (py < 240) && (edit_col == 2'd1);
    wire col2_bar = (px >= 260) && (px < 280) && (py >= 235) && (py < 240) && (edit_col == 2'd2);
    wire col3_bar = (px >= 290) && (px < 310) && (py >= 235) && (py < 240) && (edit_col == 2'd3);
    wire col_indicator = col0_bar || col1_bar || col2_bar || col3_bar;
    
    // Full cell highlight for cursor (VERY OBVIOUS)
    wire vec_v_cursor_fill = vec_v_cursor && in_vec_v_region;
    wire mat_cursor_fill = mat_cursor && in_mat_grid;
    
    // ========================================================================
    // BLINKING CURSOR - for debugging VGA updates
    // ========================================================================
    // Create a blink signal that toggles at ~2 Hz (visible to human eye)
    // At 25 MHz clock, divide by 2^24 gives ~1.5 Hz
    reg [24:0] blink_counter;
    wire cursor_blink;
    wire fast_blink;
    
    always @(posedge clk) begin
        blink_counter <= blink_counter + 1'b1;
    end
    
    assign cursor_blink = blink_counter[24];  // ~1.5 Hz blink rate
    assign fast_blink = blink_counter[23];    // ~3 Hz blink rate (faster, more obvious)
    
    // Fixed position blink indicator (top-right corner) - PROVES VGA is updating!
    wire blink_indicator = (px >= 630) && (px < 638) && (py >= 2) && (py < 10);
    
    // DEBUG: Always-on cursor test (should always show in matrix [0][0])
    wire test_cursor_pos = (px >= MATRIX_X0 + 5) && (px < MATRIX_X0 + 15) &&
                           (py >= MATRIX_Y0 + 5) && (py < MATRIX_Y0 + 15);
    
    // DEBUG: Show edit_row/edit_col values as colored bars
    wire edit_row_debug = (py >= 430) && (py < 440) && (px >= 10 + edit_row * 20) && (px < 18 + edit_row * 20);
    wire edit_col_debug = (py >= 450) && (py < 460) && (px >= 10 + edit_col * 20) && (px < 18 + edit_col * 20);
    
    // ========================================================================
    // RGB OUTPUT - REGISTERED
    // ========================================================================
    always @(posedge clk) begin
        if (~bright) begin
            rgb <= BLACK;
        end
        // BLINK INDICATOR (top-right corner) - ALWAYS VISIBLE, proves VGA updates!
        else if (blink_indicator && fast_blink) begin
            rgb <= RED;  // Blinks red at ~3 Hz - if this doesn't blink, VGA not updating!
        end
        // DEBUG: Test cursor at fixed position (should always show small blue square in matrix [0][0])
        else if (test_cursor_pos) begin
            rgb <= BLUE;  // Static blue square - proves cursor rendering works
        end
        // DEBUG: Visual display of edit_row value (colored bars at bottom)
        else if (edit_row_debug) begin
            rgb <= CYAN;  // Shows which row is selected (0-3)
        end
        // DEBUG: Visual display of edit_col value (colored bars at bottom)
        else if (edit_col_debug) begin
            rgb <= MAGENTA;  // Shows which column is selected (0-3)
        end
        // DEBUG: Switch state indicators (top of screen)
        else if (sw0_indicator) begin
            rgb <= sw0 ? GREEN : RED;  // Green if ON, Red if OFF
        end
        else if (sw1_indicator) begin
            rgb <= sw1 ? CYAN : MAGENTA;  // Cyan if ON, Magenta if OFF
        end
        // DEBUG: Row indicator (left side - shows which row is selected)
        else if (row_indicator) begin
            rgb <= YELLOW;
        end
        // DEBUG: Col indicator (top - shows which column is selected)
        else if (col_indicator) begin
            rgb <= YELLOW;
        end
        // CURSOR: Different appearance based on locked state
        // When LOCKED (editing): Solid green fill (no blink) - cell is being edited
        else if ((vec_v_cursor_fill || mat_cursor_fill) && cell_locked) begin
            rgb <= GREEN;  // Solid green = locked/editing mode
        end
        // When UNLOCKED (navigating): Blinking yellow (shows you can move)
        else if ((vec_v_cursor_fill || mat_cursor_fill) && cursor_blink) begin
            rgb <= YELLOW;  // Blinks yellow = unlocked/navigation mode
        end
        // Cursor border - color indicates locked state
        else if (vec_v_cursor_border || mat_cursor_border) begin
            rgb <= cell_locked ? GREEN : ORANGE;  // Green border when locked, orange when unlocked
        end
        // Debug: edit position indicators
        else if (edit_pos_indicator) begin
            rgb <= ORANGE;
        end
        // Bar chart bars
        else if (in_vo_bar) begin
            rgb <= CYAN;
        end
        else if (in_vn_bar) begin
            rgb <= GREEN;
        end
        // Chart structure
        else if (chart_border || chart_divider || chart_baseline) begin
            rgb <= GRAY;
        end
        // Brackets
        else if (vec_v_left_bracket || vec_v_right_bracket) begin
            rgb <= WHITE;
        end
        else if (mat_left_bracket || mat_right_bracket) begin
            rgb <= WHITE;
        end
        else if (vnew_left_bracket || vnew_right_bracket) begin
            rgb <= WHITE;
        end
        // Matrix cell borders
        else if (mat_cell_border) begin
            rgb <= GRAY;
        end
        // v_new border
        else if (vnew_border) begin
            rgb <= GRAY;
        end
        // Digits - editable vector v (color indicates sign)
        else if (vec_digits_on) begin
            rgb <= CYAN;
        end
        // Digits - matrix (WHITE)
        else if (mat_digits_on) begin
            rgb <= WHITE;
        end
        // Digits - result v_new (GREEN)
        else if (vnew_digits_on) begin
            rgb <= GREEN;
        end
        // Digits - iteration counter (MAGENTA)
        else if (iter_digit_pixel) begin
            rgb <= MAGENTA;
        end
        // Labels
        else if (in_v_label || in_A_label || in_vo_label || in_vn_chart_label || 
                 in_result_label || in_iter_label) begin
            rgb <= GRAY;
        end
        // Mode indicator
        else if (in_mode_area) begin
            rgb <= state_edit ? ORANGE : (fsm_done ? GREEN : RED);
        end
        // Background
        else begin
            rgb <= BLACK;
        end
    end

endmodule
