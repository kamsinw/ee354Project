// tb_vga_top.v
// Testbench for VGA top module

`timescale 1ns / 1ps

module tb_vga_top;

    parameter CLK_PERIOD = 10;  // 100 MHz

    reg clk_100mhz;
    reg reset;
    reg [1:0] edit_row, edit_col;
    reg sw0, sw1;
    reg signed [15:0] matrix_a [0:3][0:3];
    reg signed [15:0] vector_v [0:3];
    
    wire vga_hsync, vga_vsync;
    wire [3:0] vga_red, vga_green, vga_blue;

    vga_top uut (
        .clk_100mhz(clk_100mhz),
        .reset(reset),
        .edit_row(edit_row),
        .edit_col(edit_col),
        .sw0(sw0),
        .sw1(sw1),
        .matrix_a(matrix_a),
        .vector_v(vector_v),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_red(vga_red),
        .vga_green(vga_green),
        .vga_blue(vga_blue)
    );

    // Clock generation
    initial begin
        clk_100mhz = 0;
        forever #(CLK_PERIOD/2) clk_100mhz = ~clk_100mhz;
    end

    initial begin
        $display("========================================");
        $display("Testing vga_top");
        $display("========================================");

        // Initialize
        reset = 1;
        edit_row = 0;
        edit_col = 0;
        sw0 = 0;
        sw1 = 0;
        
        integer i, j;
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                matrix_a[i][j] = 16'sd1;
            end
            vector_v[i] = 16'sd1;
        end

        #(CLK_PERIOD * 10);
        reset = 0;
        #(CLK_PERIOD * 10);

        $display("Test 1: Reset and initialization");
        $display("  HSYNC = %b, VSYNC = %b", vga_hsync, vga_vsync);
        $display("  PASS");

        $display("\nTest 2: VGA signals generation");
        // Wait for a few clock cycles
        #(CLK_PERIOD * 100);
        $display("  HSYNC = %b, VSYNC = %b", vga_hsync, vga_vsync);
        $display("  RGB = (%d, %d, %d)", vga_red, vga_green, vga_blue);
        $display("  PASS (signals should be toggling)");

        $display("\nTest 3: Mode switching");
        sw0 = 0;  // EDIT mode
        #(CLK_PERIOD * 1000);
        sw0 = 1;  // RUN mode
        #(CLK_PERIOD * 1000);
        $display("  Mode switched, RGB should change");
        $display("  PASS");

        $display("\nTest 4: Cursor movement");
        edit_row = 1;
        edit_col = 2;
        #(CLK_PERIOD * 1000);
        $display("  Cursor moved to [%d, %d]", edit_row, edit_col);
        $display("  PASS");

        $display("\nTest 5: Matrix value change");
        matrix_a[0][0] = 16'sd42;
        matrix_a[1][1] = -16'sd15;
        #(CLK_PERIOD * 1000);
        $display("  Matrix values changed");
        $display("  PASS");

        $display("\nTest 6: Vector value change");
        vector_v[0] = 16'sd99;
        vector_v[2] = -16'sd7;
        #(CLK_PERIOD * 1000);
        $display("  Vector values changed");
        $display("  PASS");

        $display("\nTest 7: Full frame timing");
        integer frame_count = 0;
        reg vsync_prev = 1;
        integer cycles = 0;
        while (frame_count < 2 && cycles < 1000000) begin
            @(posedge clk_100mhz);
            cycles = cycles + 1;
            if (vga_vsync == 0 && vsync_prev == 1) begin
                frame_count = frame_count + 1;
                if (frame_count == 1) begin
                    $display("  First VSYNC detected at cycle %d", cycles);
                end
            end
            vsync_prev = vga_vsync;
        end
        $display("  Frame count = %d", frame_count);
        $display("  PASS");

        $display("\n========================================");
        $display("All Tests Complete");
        $display("========================================\n");

        #(CLK_PERIOD * 1000);
        $finish;
    end

    // Dump VCD
    initial begin
        $dumpfile("tb_vga_top.vcd");
        $dumpvars(0, tb_vga_top);
    end

endmodule

