`timescale 1ns / 1ps

module top_eigenvector (

    input  wire        clk,
    input  wire        reset,
    input  wire        sw0,
    input  wire        sw1,
    input  wire [2:0]  sw_eps,
    input  wire        btnl,
    input  wire        btnr,
    input  wire        btnu,
    input  wire        btnd,
    input  wire        btnc,
    output wire [7:0]  led,
    output wire        ca, cb, cc, cd, ce, cf, cg, dp,
    output wire        an0, an1, an2, an3, an4, an5, an6, an7,
    output wire        vga_hsync,
    output wire        vga_vsync,
    output wire [3:0]  vga_red,
    output wire [3:0]  vga_green,
    output wire [3:0]  vga_blue
);

    // CPU_RESET on Nexys A7 is active-low (pressed=0, released=1)
    // Invert to get active-high reset for internal logic
    wire rst_active = ~reset;
    
    // Button debouncing on main clock (clk = 100 MHz)
    // Using longer shift registers for reliable debouncing at higher frequency
    reg [15:0] btnl_sr, btnr_sr, btnu_sr, btnd_sr, btnc_sr;
    reg btnl_stable, btnr_stable, btnu_stable, btnd_stable, btnc_stable;
    reg btnl_d, btnr_d, btnu_d, btnd_d, btnc_d;
    reg btnl_pulse, btnr_pulse, btnu_pulse, btnd_pulse, btnc_pulse;
    
    always @(posedge clk) begin
        if (rst_active) begin
            btnl_sr <= 16'd0;
            btnr_sr <= 16'd0;
            btnu_sr <= 16'd0;
            btnd_sr <= 16'd0;
            btnc_sr <= 16'd0;
            btnl_stable <= 1'b0;
            btnr_stable <= 1'b0;
            btnu_stable <= 1'b0;
            btnd_stable <= 1'b0;
            btnc_stable <= 1'b0;
            btnl_d <= 1'b0;
            btnr_d <= 1'b0;
            btnu_d <= 1'b0;
            btnd_d <= 1'b0;
            btnc_d <= 1'b0;
            btnl_pulse <= 1'b0;
            btnr_pulse <= 1'b0;
            btnu_pulse <= 1'b0;
            btnd_pulse <= 1'b0;
            btnc_pulse <= 1'b0;
        end else begin
            // Shift in new button values
            btnl_sr <= {btnl_sr[14:0], btnl};
            btnr_sr <= {btnr_sr[14:0], btnr};
            btnu_sr <= {btnu_sr[14:0], btnu};
            btnd_sr <= {btnd_sr[14:0], btnd};
            btnc_sr <= {btnc_sr[14:0], btnc};
            
            // Button is stable if all bits in shift register are the same
            btnl_stable <= (btnl_sr == 16'hFFFF) ? 1'b1 : (btnl_sr == 16'h0000) ? 1'b0 : btnl_stable;
            btnr_stable <= (btnr_sr == 16'hFFFF) ? 1'b1 : (btnr_sr == 16'h0000) ? 1'b0 : btnr_stable;
            btnu_stable <= (btnu_sr == 16'hFFFF) ? 1'b1 : (btnu_sr == 16'h0000) ? 1'b0 : btnu_stable;
            btnd_stable <= (btnd_sr == 16'hFFFF) ? 1'b1 : (btnd_sr == 16'h0000) ? 1'b0 : btnd_stable;
            btnc_stable <= (btnc_sr == 16'hFFFF) ? 1'b1 : (btnc_sr == 16'h0000) ? 1'b0 : btnc_stable;
            
            // Delayed versions for edge detection
            btnl_d <= btnl_stable;
            btnr_d <= btnr_stable;
            btnu_d <= btnu_stable;
            btnd_d <= btnd_stable;
            btnc_d <= btnc_stable;
            
            // Rising edge detection
            btnl_pulse <= btnl_stable & ~btnl_d;
            btnr_pulse <= btnr_stable & ~btnr_d;
            btnu_pulse <= btnu_stable & ~btnu_d;
            btnd_pulse <= btnd_stable & ~btnd_d;
            btnc_pulse <= btnc_stable & ~btnc_d;
        end
    end
    
    reg [1:0] edit_row_q;
    reg [1:0] edit_col_q;
    reg [3:0] edit_value_q;
    reg [3:0] matrix_grid_q [0:3][0:3];
    reg [3:0] vector_seed_q [0:3];
    wire [16*4-1:0] matrix_grid_packed;
    wire [4*4-1:0] vector_seed_packed;
    
    // Cell locked state - controls edit mode behavior
    // 0 = unlocked (can navigate), 1 = locked (editing value)
    reg cell_lock_q;
    
    // Next-state logic for edit_row_q and edit_col_q (combinational)
    // MUST be declared as reg since assigned in always block
    reg [1:0] edit_row_d;
    reg [1:0] edit_col_d;
    
    // Next-state logic for matrix_grid_q and vector_seed_q (combinational)
    // MUST be declared as reg arrays since assigned in always block
    reg [3:0] matrix_grid_d [0:3][0:3];
    reg [3:0] vector_seed_d [0:3];
    
    // Next-state logic for edit_value_q (combinational)
    // MUST be declared as reg since assigned in always block
    reg [3:0] edit_value_d;
    
    // SINGLE always @(*) block for next-state computation (edit_row_q/edit_col_q)
    always @(*) begin
        // Default: keep current values
        edit_row_d = edit_row_q;
        edit_col_d = edit_col_q;
        
        // Navigation only works when in edit mode AND cell is NOT locked
        if (~sw0 && ~cell_lock_q) begin
            // Handle row changes
            if (btnu_pulse) begin
                if (edit_row_q > 2'b00)
                    edit_row_d = edit_row_q - 1'b1;
            end else if (btnd_pulse) begin
                if (edit_row_q < 2'b11)
                    edit_row_d = edit_row_q + 1'b1;
            end
            
            // Handle column changes (matrix only)
            if (sw1 == 1'b0) begin  // Matrix mode
                if (btnl_pulse) begin
                    if (edit_col_q > 2'b00)
                        edit_col_d = edit_col_q - 1'b1;
                end else if (btnr_pulse) begin
                    if (edit_col_q < 2'b11)
                        edit_col_d = edit_col_q + 1'b1;
                end
            end
        end
        // When locked or in run mode, keep current values (already set as default)
    end
    
    // SINGLE always @(*) block for next-state computation (matrix_grid_q/vector_seed_q)
    integer i, j;
    always @(*) begin
        // Default: keep all current values
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                matrix_grid_d[i][j] = matrix_grid_q[i][j];
            end
            vector_seed_d[i] = vector_seed_q[i];
        end
        
        if (rst_active) begin
            // Initialize on reset
            matrix_grid_d[0][0] = 4'd4; matrix_grid_d[0][1] = 4'd1; matrix_grid_d[0][2] = 4'd1; matrix_grid_d[0][3] = 4'd1;
            matrix_grid_d[1][0] = 4'd1; matrix_grid_d[1][1] = 4'd4; matrix_grid_d[1][2] = 4'd1; matrix_grid_d[1][3] = 4'd1;
            matrix_grid_d[2][0] = 4'd1; matrix_grid_d[2][1] = 4'd1; matrix_grid_d[2][2] = 4'd4; matrix_grid_d[2][3] = 4'd1;
            matrix_grid_d[3][0] = 4'd1; matrix_grid_d[3][1] = 4'd1; matrix_grid_d[3][2] = 4'd1; matrix_grid_d[3][3] = 4'd4;
            for (i = 0; i < 4; i = i + 1) begin
                vector_seed_d[i] = 4'd1;
            end
        end else if (~sw0 && btnc_pulse && cell_lock_q) begin
            // Edit mode with cell locked: SAVE value and unlock
            if (sw1 == 1'b0) begin
                // Edit matrix
                matrix_grid_d[edit_row_q][edit_col_q] = edit_value_q;
            end else begin
                // Edit vector
                vector_seed_d[edit_row_q] = edit_value_q;
            end
        end
    end
    
    // SINGLE always block for edit_row_q, edit_col_q, and cell_lock_q state update
    // Now on main clock for proper synchronization with VGA
    always @(posedge clk) begin
        if (rst_active) begin
            edit_row_q <= 2'b00;
            edit_col_q <= 2'b00;
            cell_lock_q <= 1'b0;
        end else begin
            edit_row_q <= edit_row_d;
            edit_col_q <= edit_col_d;
            
            // Handle cell_lock_q state transitions with BTNC
            if (~sw0 && btnc_pulse) begin
                // Toggle locked state when BTNC pressed in edit mode
                cell_lock_q <= ~cell_lock_q;
            end else if (sw0) begin
                // Force unlock when entering run mode
                cell_lock_q <= 1'b0;
            end
        end
    end
    
    reg sw0_prev_q, sw1_prev_q;
    reg [1:0] edit_row_prev_q;
    
    always @(posedge clk) begin
        if (rst_active) begin
            sw0_prev_q <= 1'b0;
            sw1_prev_q <= 1'b0;
            edit_row_prev_q <= 2'b00;
        end else begin
            sw0_prev_q <= sw0;
            sw1_prev_q <= sw1;
            edit_row_prev_q <= edit_row_q;
        end
    end
    
    reg cell_lock_prev_q;
    
    always @(posedge clk) begin
        if (rst_active) begin
            cell_lock_prev_q <= 1'b0;
        end else begin
            cell_lock_prev_q <= cell_lock_q;
        end
    end
    
    // SINGLE always @(*) block for edit_value_d computation
    always @(*) begin
        // Default: keep current value
        edit_value_d = edit_value_q;
        
        if (rst_active) begin
            edit_value_d = 4'd0;
        end else if (~sw0) begin
            // When locking onto a cell (transition from unlocked to locked), load current value
            if (~cell_lock_prev_q && cell_lock_q) begin
                if (sw1 == 1'b0) begin
                    edit_value_d = matrix_grid_q[edit_row_q][edit_col_q];
                end else begin
                    edit_value_d = vector_seed_q[edit_row_q];
                end
            end
            // When cell is locked, allow value editing with left/right buttons
            else if (cell_lock_q) begin
                if (btnl_pulse) begin
                    edit_value_d = (edit_value_q == 4'd0) ? 4'd0 : edit_value_q - 4'd1;
                end else if (btnr_pulse) begin
                    edit_value_d = (edit_value_q == 4'd15) ? 4'd15 : edit_value_q + 4'd1;
                end
            end
            // When not locked and navigating, show preview of cell value
            else if ((sw1_prev_q != sw1) || (edit_row_prev_q != edit_row_q)) begin
                if (sw1 == 1'b0) begin
                    edit_value_d = matrix_grid_q[edit_row_q][edit_col_q];
                end else begin
                    edit_value_d = vector_seed_q[edit_row_q];
                end
            end
        end
    end
    
    // SINGLE always @(posedge clk) block for edit_value_q state update
    always @(posedge clk) begin
        edit_value_q <= edit_value_d;
    end
    
    // SINGLE always block for matrix_grid_q and vector_seed_q state update
    // Updates from matrix_grid_d/vector_seed_d (which handles reset, edit mode, etc.)
    integer k, l;
    always @(posedge clk) begin
        // Update all elements from next-state (next-state logic handles reset and edits)
        for (k = 0; k < 4; k = k + 1) begin
            for (l = 0; l < 4; l = l + 1) begin
                matrix_grid_q[k][l] <= matrix_grid_d[k][l];
            end
            vector_seed_q[k] <= vector_seed_d[k];
        end
    end
    
    wire fsm_done;
    wire load_v_old, load_y, load_max_d;
    wire start_mult, start_scale, start_diff;
    wire mul_done, scale_done, diff_done;
    wire [3:0] max_d_out;
    wire [15:0] v_out;
    wire               v_new_valid;
    wire [7:0] fsm_state;
    wire [3:0] v_old0, v_old1, v_old2, v_old3;
    
    // Iteration counter
    reg [7:0] iter_count_q;
    reg [7:0] iter_count_d;
    reg [15:0] debug_display_value_reg;
    
    reg sw0_r;
    wire sw0_edge;
    
    always @(*) begin
        iter_count_d = iter_count_q;
        if (scale_done) begin
            iter_count_d = iter_count_q + 1'b1;
        end
        if (sw0_edge) begin
            iter_count_d = 8'd0;
        end
    end
    
    always @(posedge clk) begin
        if (rst_active) begin
            sw0_r <= 1'b0;
            iter_count_q <= 8'd0;
        end else begin
            sw0_r <= sw0;
            iter_count_q <= iter_count_d;
        end
    end
    
    assign sw0_edge = sw0 & ~sw0_r;
    
    dominant_fsm fsm_inst (
        .clk(clk),
        .reset(rst_active),
        .start(sw0_edge),
        .mul_done(mul_done),
        .scale_done(scale_done),
        .diff_done(diff_done),
        .max_d_in(max_d_out),
        .epsilon(sw_eps),
        .load_v_old(load_v_old),
        .load_y(load_y),
        .load_max_d(load_max_d),
        .start_mult(start_mult),
        .start_scale(start_scale),
        .start_diff(start_diff),
        .done(fsm_done),
        .state_out(fsm_state)
    );
    
    dominant_datapath datapath_inst (
        .clk(clk),
        .reset(rst_active),
        .load_v_old(load_v_old),
        .load_y(load_y),
        .load_max_d(load_max_d),
        .start_mult(start_mult),
        .start_scale(start_scale),
        .start_diff(start_diff),
        .v_init(vector_seed_packed),
        .A00(matrix_grid_q[0][0]),
        .A01(matrix_grid_q[0][1]),
        .A02(matrix_grid_q[0][2]),
        .A03(matrix_grid_q[0][3]),
        .A10(matrix_grid_q[1][0]),
        .A11(matrix_grid_q[1][1]),
        .A12(matrix_grid_q[1][2]),
        .A13(matrix_grid_q[1][3]),
        .A20(matrix_grid_q[2][0]),
        .A21(matrix_grid_q[2][1]),
        .A22(matrix_grid_q[2][2]),
        .A23(matrix_grid_q[2][3]),
        .A30(matrix_grid_q[3][0]),
        .A31(matrix_grid_q[3][1]),
        .A32(matrix_grid_q[3][2]),
        .A33(matrix_grid_q[3][3]),
        .mul_done(mul_done),
        .scale_done(scale_done),
        .diff_done(diff_done),
        .max_d_out(max_d_out),
        .v0(v_out[3:0]),
        .v1(v_out[7:4]),
        .v2(v_out[11:8]),
        .v3(v_out[15:12]),
        .v_old0(v_old0),
        .v_old1(v_old1),
        .v_old2(v_old2),
        .v_old3(v_old3),
        .v_new_valid_out(v_new_valid)
    );
    
    // LED layout: [0]=lock, [1]=button pulse, [2]=mode, [3]=new vector valid, [5:4]=row, [7:6]=col
    wire any_button_pulse = btnl_pulse | btnr_pulse | btnu_pulse | btnd_pulse | btnc_pulse;
    
    assign led[0] = cell_lock_q;  // Shows locked/unlocked state
    assign led[1] = any_button_pulse;
    assign led[2] = sw0;
    assign led[3] = v_new_valid;
    assign led[5:4] = edit_row_q;
    assign led[7:6] = edit_col_q;
    
    // ========================================================================
    // DEBUG: SEVEN SEGMENT DISPLAY
    // ========================================================================
    // Display useful debug information based on mode:
    // - Edit mode (sw0=0): Show current edit value (with sign handling)
    // - Run mode (sw0=1): Show iteration count
    
    reg [15:0] ssd_display_value;
    reg [15:0] ssd_display_value_reg;
    wire [7:0] ssd_anode;
    wire [6:0] ssd_segments;
    
    // Select what to display based on mode
    always @(*) begin
        if (sw0 == 1'b0) begin
            // Edit mode: zero-extend nibble value
            ssd_display_value = {12'd0, edit_value_q};
        end else begin
            // Run mode: Display iteration count
            ssd_display_value = {8'd0, iter_count_q};
        end
    end
    
    // Instantiate 7-segment display counter (8 digits: left=debug, right=status)
    ssd_counter ssd_debug (
        .clk(clk),
        .displayNumberLow(ssd_display_value_reg),
        .displayNumberHigh(debug_display_value_reg),
        .anode(ssd_anode),
        .ssdOut(ssd_segments)
    );
    
    // Map to individual segment outputs (ssd_segments is already active-low)
    assign {ca, cb, cc, cd, ce, cf, cg} = ssd_segments;
    
    // Decimal point: active-low (0=on, 1=off)
    // In edit mode: on for negative (dark), off for positive (lit)
    // In run mode: always off (lit)
    assign dp = (sw0 == 1'b0) ? ~cell_lock_q : 1'b1;
    
    // Map anode bus to physical pins
    assign {an7, an6, an5, an4, an3, an2, an1, an0} = ssd_anode;

    always @(posedge clk) begin
        if (rst_active) begin
            ssd_display_value_reg <= 16'd0;
        end else begin
            ssd_display_value_reg <= ssd_display_value;
        end
    end

    wire [3:0] v0_debug = v_out[3:0];
    wire [15:0] v0_zero_ext = {12'd0, v0_debug};

    always @(posedge clk) begin
        if (rst_active) begin
            debug_display_value_reg <= 16'd0;
        end else if (v_new_valid) begin
            debug_display_value_reg <= v0_zero_ext;
        end
    end
    
    assign matrix_grid_packed = {matrix_grid_q[3][3], matrix_grid_q[3][2], matrix_grid_q[3][1], matrix_grid_q[3][0],
                              matrix_grid_q[2][3], matrix_grid_q[2][2], matrix_grid_q[2][1], matrix_grid_q[2][0],
                              matrix_grid_q[1][3], matrix_grid_q[1][2], matrix_grid_q[1][1], matrix_grid_q[1][0],
                              matrix_grid_q[0][3], matrix_grid_q[0][2], matrix_grid_q[0][1], matrix_grid_q[0][0]};

    assign vector_seed_packed = {vector_seed_q[3], vector_seed_q[2], vector_seed_q[1], vector_seed_q[0]};

    wire [15:0] v_old_packed = {v_old3, v_old2, v_old1, v_old0};
    wire [15:0] v_new_packed = v_out;
    
    vga_top vga_display (
        .clk_100mhz(clk),
        .reset(rst_active),
        .edit_row(edit_row_q),
        .edit_col(edit_col_q),
        .cell_locked(cell_lock_q),
        .sw0(sw0),
        .sw1(sw1),
        .sw_eps(sw_eps),
        .matrix_a(matrix_grid_packed),
        .vector_v(vector_seed_packed),
        .fsm_state(fsm_state),
        .fsm_done(fsm_done),
        .iteration_count(iter_count_q),
        .v_old(v_old_packed),
        .v_new(v_new_packed),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_red(vga_red),
        .vga_green(vga_green),
        .vga_blue(vga_blue)
    );
    
endmodule
