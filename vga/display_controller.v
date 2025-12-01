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
    input  wire signed [255:0] matrix_a,
    input  wire signed [63:0] vector_v,   // Editable initial vector
    input  wire [7:0] fsm_state,
    input  wire fsm_done,
    input  wire [7:0] iteration_count,
    input  wire signed [63:0] v_old,      // Previous iteration (for chart)
    input  wire signed [63:0] v_new,      // Current iteration result (for chart)
    output reg  [11:0] rgb
);

    // ========================================================================
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
    wire signed [15:0] A [0:3][0:3];
    assign A[0][0] = matrix_a[15:0];
    assign A[0][1] = matrix_a[31:16];
    assign A[0][2] = matrix_a[47:32];
    assign A[0][3] = matrix_a[63:48];
    assign A[1][0] = matrix_a[79:64];
    assign A[1][1] = matrix_a[95:80];
    assign A[1][2] = matrix_a[111:96];
    assign A[1][3] = matrix_a[127:112];
    assign A[2][0] = matrix_a[143:128];
    assign A[2][1] = matrix_a[159:144];
    assign A[2][2] = matrix_a[175:160];
    assign A[2][3] = matrix_a[191:176];
    assign A[3][0] = matrix_a[207:192];
    assign A[3][1] = matrix_a[223:208];
    assign A[3][2] = matrix_a[239:224];
    assign A[3][3] = matrix_a[255:240];
    
    // Vector v (editable initial vector) - editable with sw1=1
    wire signed [15:0] v [0:3];
    assign v[0] = vector_v[15:0];
    assign v[1] = vector_v[31:16];
    assign v[2] = vector_v[47:32];
    assign v[3] = vector_v[63:48];
    
    // v_old (previous iteration - for bar chart)
    wire signed [15:0] vo [0:3];
    assign vo[0] = v_old[15:0];
    assign vo[1] = v_old[31:16];
    assign vo[2] = v_old[47:32];
    assign vo[3] = v_old[63:48];
    
    // v_new (current iteration result - for bar chart and display)
    wire signed [15:0] vn [0:3];
    assign vn[0] = v_new[15:0];
    assign vn[1] = v_new[31:16];
    assign vn[2] = v_new[47:32];
    assign vn[3] = v_new[63:48];
    
    // FSM state
    localparam IDLE = 7'b0000001;
    // Edit mode: sw0=0 means we're in edit mode
    wire state_edit = (sw0 == 1'b0);

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
    reg signed [15:0] vec_v_val;
    always @(*) begin
        case (vec_v_idx)
            2'd0: vec_v_val = v[0];
            2'd1: vec_v_val = v[1];
            2'd2: vec_v_val = v[2];
            2'd3: vec_v_val = v[3];
        endcase
    end
    
    wire vec_v_is_neg = vec_v_val[15];
    wire [15:0] vec_v_abs = vec_v_is_neg ? -vec_v_val : vec_v_val;
    wire [3:0] vec_v_digit = vec_v_abs % 10;
    
    // Digit rendering for vector v
    wire [9:0] vv_dig_x = vec_v_local_x - 30;
    wire [9:0] vv_dig_y = vec_v_cell_y - 8;
    wire in_vv_digit_area = in_vec_v_region && vec_v_valid_idx &&
                            (vec_v_local_x >= 30) && (vec_v_local_x < 70) &&
                            (vec_v_cell_y >= 8) && (vec_v_cell_y < 38);
    
    // 7-segment for vector v
    wire vv_seg_a = in_vv_digit_area && (vv_dig_y < 4) && (vv_dig_x >= 4) && (vv_dig_x < 32);
    wire vv_seg_b = in_vv_digit_area && (vv_dig_x >= 32) && (vv_dig_y >= 2) && (vv_dig_y < 14);
    wire vv_seg_c = in_vv_digit_area && (vv_dig_x >= 32) && (vv_dig_y >= 17) && (vv_dig_y < 28);
    wire vv_seg_d = in_vv_digit_area && (vv_dig_y >= 26) && (vv_dig_x >= 4) && (vv_dig_x < 32);
    wire vv_seg_e = in_vv_digit_area && (vv_dig_x < 4) && (vv_dig_y >= 17) && (vv_dig_y < 28);
    wire vv_seg_f = in_vv_digit_area && (vv_dig_x < 4) && (vv_dig_y >= 2) && (vv_dig_y < 14);
    wire vv_seg_g = in_vv_digit_area && (vv_dig_y >= 13) && (vv_dig_y < 18) && (vv_dig_x >= 4) && (vv_dig_x < 32);
    
    reg [6:0] vv_seg_en;
    always @(*) begin
        case (vec_v_digit)
            4'd0: vv_seg_en = 7'b1111110;
            4'd1: vv_seg_en = 7'b0110000;
            4'd2: vv_seg_en = 7'b1101101;
            4'd3: vv_seg_en = 7'b1111001;
            4'd4: vv_seg_en = 7'b0110011;
            4'd5: vv_seg_en = 7'b1011011;
            4'd6: vv_seg_en = 7'b1011111;
            4'd7: vv_seg_en = 7'b1110000;
            4'd8: vv_seg_en = 7'b1111111;
            4'd9: vv_seg_en = 7'b1111011;
            default: vv_seg_en = 7'b0000000;
        endcase
    end
    
    wire vv_digit_pixel = (vv_seg_en[6] && vv_seg_a) || (vv_seg_en[5] && vv_seg_b) ||
                          (vv_seg_en[4] && vv_seg_c) || (vv_seg_en[3] && vv_seg_d) ||
                          (vv_seg_en[2] && vv_seg_e) || (vv_seg_en[1] && vv_seg_f) ||
                          (vv_seg_en[0] && vv_seg_g);
    
    wire vv_neg_sign = in_vv_digit_area && vec_v_is_neg && 
                       (vv_dig_x >= 0) && (vv_dig_x < 10) && (vv_dig_y >= 12) && (vv_dig_y < 17);
    
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
    
    // Get bar heights (absolute values, scaled)
    wire [15:0] vo_abs [0:3];
    wire [15:0] vn_abs [0:3];
    assign vo_abs[0] = vo[0][15] ? -vo[0] : vo[0];
    assign vo_abs[1] = vo[1][15] ? -vo[1] : vo[1];
    assign vo_abs[2] = vo[2][15] ? -vo[2] : vo[2];
    assign vo_abs[3] = vo[3][15] ? -vo[3] : vo[3];
    assign vn_abs[0] = vn[0][15] ? -vn[0] : vn[0];
    assign vn_abs[1] = vn[1][15] ? -vn[1] : vn[1];
    assign vn_abs[2] = vn[2][15] ? -vn[2] : vn[2];
    assign vn_abs[3] = vn[3][15] ? -vn[3] : vn[3];
    
    // Scale bars (divide by 2, max BAR_MAX_HEIGHT)
    wire [9:0] vo_bar_h [0:3];
    wire [9:0] vn_bar_h [0:3];
    assign vo_bar_h[0] = (vo_abs[0] > 320) ? BAR_MAX_HEIGHT : vo_abs[0][8:1];
    assign vo_bar_h[1] = (vo_abs[1] > 320) ? BAR_MAX_HEIGHT : vo_abs[1][8:1];
    assign vo_bar_h[2] = (vo_abs[2] > 320) ? BAR_MAX_HEIGHT : vo_abs[2][8:1];
    assign vo_bar_h[3] = (vo_abs[3] > 320) ? BAR_MAX_HEIGHT : vo_abs[3][8:1];
    assign vn_bar_h[0] = (vn_abs[0] > 320) ? BAR_MAX_HEIGHT : vn_abs[0][8:1];
    assign vn_bar_h[1] = (vn_abs[1] > 320) ? BAR_MAX_HEIGHT : vn_abs[1][8:1];
    assign vn_bar_h[2] = (vn_abs[2] > 320) ? BAR_MAX_HEIGHT : vn_abs[2][8:1];
    assign vn_bar_h[3] = (vn_abs[3] > 320) ? BAR_MAX_HEIGHT : vn_abs[3][8:1];
    
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
    
    // Get matrix value
    reg signed [15:0] mat_val;
    always @(*) begin
        case ({mat_row, mat_col})
            4'b0000: mat_val = A[0][0];
            4'b0001: mat_val = A[0][1];
            4'b0010: mat_val = A[0][2];
            4'b0011: mat_val = A[0][3];
            4'b0100: mat_val = A[1][0];
            4'b0101: mat_val = A[1][1];
            4'b0110: mat_val = A[1][2];
            4'b0111: mat_val = A[1][3];
            4'b1000: mat_val = A[2][0];
            4'b1001: mat_val = A[2][1];
            4'b1010: mat_val = A[2][2];
            4'b1011: mat_val = A[2][3];
            4'b1100: mat_val = A[3][0];
            4'b1101: mat_val = A[3][1];
            4'b1110: mat_val = A[3][2];
            4'b1111: mat_val = A[3][3];
                    endcase
                end
    
    wire mat_is_neg = mat_val[15];
    wire [15:0] mat_abs = mat_is_neg ? -mat_val : mat_val;
    wire [3:0] mat_digit = mat_abs % 10;
    
    // Matrix digit area (centered in cell)
    wire [9:0] mat_dig_x = mat_cell_x - 10;
    wire [9:0] mat_dig_y = mat_cell_y - 8;
    wire in_mat_digit_area = in_mat_grid && (mat_cell_x >= 10) && (mat_cell_x < 35) &&
                             (mat_cell_y >= 8) && (mat_cell_y < 35);
    
    // 7-segment for matrix
    wire mat_seg_a = in_mat_digit_area && (mat_dig_y < 3) && (mat_dig_x >= 3) && (mat_dig_x < 20);
    wire mat_seg_b = in_mat_digit_area && (mat_dig_x >= 20) && (mat_dig_y >= 2) && (mat_dig_y < 12);
    wire mat_seg_c = in_mat_digit_area && (mat_dig_x >= 20) && (mat_dig_y >= 15) && (mat_dig_y < 25);
    wire mat_seg_d = in_mat_digit_area && (mat_dig_y >= 24) && (mat_dig_x >= 3) && (mat_dig_x < 20);
    wire mat_seg_e = in_mat_digit_area && (mat_dig_x < 3) && (mat_dig_y >= 15) && (mat_dig_y < 25);
    wire mat_seg_f = in_mat_digit_area && (mat_dig_x < 3) && (mat_dig_y >= 2) && (mat_dig_y < 12);
    wire mat_seg_g = in_mat_digit_area && (mat_dig_y >= 12) && (mat_dig_y < 15) && (mat_dig_x >= 3) && (mat_dig_x < 20);
    
    reg [6:0] mat_seg_en;
    always @(*) begin
        case (mat_digit)
            4'd0: mat_seg_en = 7'b1111110;
            4'd1: mat_seg_en = 7'b0110000;
            4'd2: mat_seg_en = 7'b1101101;
            4'd3: mat_seg_en = 7'b1111001;
            4'd4: mat_seg_en = 7'b0110011;
            4'd5: mat_seg_en = 7'b1011011;
            4'd6: mat_seg_en = 7'b1011111;
            4'd7: mat_seg_en = 7'b1110000;
            4'd8: mat_seg_en = 7'b1111111;
            4'd9: mat_seg_en = 7'b1111011;
            default: mat_seg_en = 7'b0000000;
                    endcase
                end
    
    wire mat_digit_pixel = (mat_seg_en[6] && mat_seg_a) || (mat_seg_en[5] && mat_seg_b) ||
                           (mat_seg_en[4] && mat_seg_c) || (mat_seg_en[3] && mat_seg_d) ||
                           (mat_seg_en[2] && mat_seg_e) || (mat_seg_en[1] && mat_seg_f) ||
                           (mat_seg_en[0] && mat_seg_g);
    
    wire mat_neg_sign = in_mat_digit_area && mat_is_neg &&
                        (mat_dig_x >= 0) && (mat_dig_x < 6) && (mat_dig_y >= 11) && (mat_dig_y < 15);
    
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
    
    // Get v_new value
    reg signed [15:0] vnew_val;
    always @(*) begin
        case (vnew_idx[1:0])
            2'd0: vnew_val = vn[0];
            2'd1: vnew_val = vn[1];
            2'd2: vnew_val = vn[2];
            2'd3: vnew_val = vn[3];
                    endcase
                end
    
    wire vnew_is_neg = vnew_val[15];
    wire [15:0] vnew_abs_val = vnew_is_neg ? -vnew_val : vnew_val;
    wire [3:0] vnew_digit = vnew_abs_val % 10;
    
    // v_new digit area
    wire [9:0] vnew_dig_x = vnew_cell_x - 15;
    wire [9:0] vnew_dig_y = vnew_local_y - 20;
    wire in_vnew_digit_area = in_vec_new_region && vnew_valid &&
                              (vnew_cell_x >= 15) && (vnew_cell_x < 55) &&
                              (vnew_local_y >= 20) && (vnew_local_y < 55);
    
    // 7-segment for v_new
    wire vnew_seg_a = in_vnew_digit_area && (vnew_dig_y < 4) && (vnew_dig_x >= 4) && (vnew_dig_x < 32);
    wire vnew_seg_b = in_vnew_digit_area && (vnew_dig_x >= 32) && (vnew_dig_y >= 2) && (vnew_dig_y < 16);
    wire vnew_seg_c = in_vnew_digit_area && (vnew_dig_x >= 32) && (vnew_dig_y >= 19) && (vnew_dig_y < 33);
    wire vnew_seg_d = in_vnew_digit_area && (vnew_dig_y >= 31) && (vnew_dig_x >= 4) && (vnew_dig_x < 32);
    wire vnew_seg_e = in_vnew_digit_area && (vnew_dig_x < 4) && (vnew_dig_y >= 19) && (vnew_dig_y < 33);
    wire vnew_seg_f = in_vnew_digit_area && (vnew_dig_x < 4) && (vnew_dig_y >= 2) && (vnew_dig_y < 16);
    wire vnew_seg_g = in_vnew_digit_area && (vnew_dig_y >= 15) && (vnew_dig_y < 20) && (vnew_dig_x >= 4) && (vnew_dig_x < 32);
    
    reg [6:0] vnew_seg_en;
    always @(*) begin
        case (vnew_digit)
            4'd0: vnew_seg_en = 7'b1111110;
            4'd1: vnew_seg_en = 7'b0110000;
            4'd2: vnew_seg_en = 7'b1101101;
            4'd3: vnew_seg_en = 7'b1111001;
            4'd4: vnew_seg_en = 7'b0110011;
            4'd5: vnew_seg_en = 7'b1011011;
            4'd6: vnew_seg_en = 7'b1011111;
            4'd7: vnew_seg_en = 7'b1110000;
            4'd8: vnew_seg_en = 7'b1111111;
            4'd9: vnew_seg_en = 7'b1111011;
            default: vnew_seg_en = 7'b0000000;
                    endcase
                end
    
    wire vnew_digit_pixel = (vnew_seg_en[6] && vnew_seg_a) || (vnew_seg_en[5] && vnew_seg_b) ||
                            (vnew_seg_en[4] && vnew_seg_c) || (vnew_seg_en[3] && vnew_seg_d) ||
                            (vnew_seg_en[2] && vnew_seg_e) || (vnew_seg_en[1] && vnew_seg_f) ||
                            (vnew_seg_en[0] && vnew_seg_g);
    
    wire vnew_neg_sign = in_vnew_digit_area && vnew_is_neg &&
                         (vnew_dig_x >= 0) && (vnew_dig_x < 10) && (vnew_dig_y >= 14) && (vnew_dig_y < 19);
    
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
        // Digits - editable vector v (CYAN)
        else if (vv_digit_pixel || vv_neg_sign) begin
            rgb <= CYAN;
        end
        // Digits - matrix (WHITE)
        else if (mat_digit_pixel || mat_neg_sign) begin
            rgb <= WHITE;
        end
        // Digits - result v_new (GREEN)
        else if (vnew_digit_pixel || vnew_neg_sign) begin
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
