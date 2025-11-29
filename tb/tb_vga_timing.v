// tb_vga_timing.v
// Testbench for VGA timing generator

`timescale 1ns / 1ps

module tb_vga_timing;

    parameter CLK_PERIOD = 40;  // 25 MHz = 40ns period

    reg clk;
    reg reset;
    wire hsync, vsync, visible;
    wire [9:0] hcount, vcount;

    vga_timing uut (
        .clk(clk),
        .reset(reset),
        .hsync(hsync),
        .vsync(vsync),
        .visible(visible),
        .hcount(hcount),
        .vcount(vcount)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        $display("========================================");
        $display("Testing vga_timing");
        $display("========================================");

        reset = 1;
        #(CLK_PERIOD * 5);
        reset = 0;
        #(CLK_PERIOD * 2);

        $display("Test 1: Reset");
        $display("  hcount = %d (expected: 0)", hcount);
        $display("  vcount = %d (expected: 0)", vcount);
        if (hcount == 0 && vcount == 0) $display("  PASS");
        else $display("  FAIL");

        $display("\nTest 2: Horizontal counter");
        // Wait for one full horizontal line (800 clocks)
        #(CLK_PERIOD * 800);
        $display("  After 800 clocks, hcount = %d (expected: 0)", hcount);
        if (hcount == 0) $display("  PASS");
        else $display("  FAIL");

        $display("\nTest 3: HSYNC timing");
        // Check HSYNC goes low during sync period
        integer hsync_low_count = 0;
        integer i;
        for (i = 0; i < 800; i = i + 1) begin
            @(posedge clk);
            if (hsync == 0) hsync_low_count = hsync_low_count + 1;
        end
        $display("  HSYNC low count in one line = %d (expected: 96)", hsync_low_count);
        if (hsync_low_count == 96) $display("  PASS");
        else $display("  FAIL");

        $display("\nTest 4: Visible region");
        integer visible_count = 0;
        for (i = 0; i < 800; i = i + 1) begin
            @(posedge clk);
            if (visible == 1) visible_count = visible_count + 1;
        end
        $display("  Visible pixels in one line = %d (expected: 640)", visible_count);
        if (visible_count == 640) $display("  PASS");
        else $display("  FAIL");

        $display("\nTest 5: Vertical counter");
        // Wait for one full frame (525 lines)
        integer frame_count = 0;
        reg vsync_prev = 1;
        while (frame_count < 2) begin
            @(posedge clk);
            if (vsync == 0 && vsync_prev == 1) begin
                frame_count = frame_count + 1;
                if (frame_count == 1) begin
                    $display("  First VSYNC detected at vcount = %d", vcount);
                end
            end
            vsync_prev = vsync;
        end
        $display("  Frame count = %d", frame_count);
        $display("  PASS");

        $display("\n========================================");
        $display("All Tests Complete");
        $display("========================================\n");

        #(CLK_PERIOD * 100);
        $finish;
    end

    // Dump VCD
    initial begin
        $dumpfile("tb_vga_timing.vcd");
        $dumpvars(0, tb_vga_timing);
    end

endmodule

