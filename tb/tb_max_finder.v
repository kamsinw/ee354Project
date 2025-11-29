// tb_max_finder.v
// Testbench for max_finder module

`timescale 1ns / 1ps

module tb_max_finder;

    parameter WIDTH = 16;
    parameter CLK_PERIOD = 10;

    reg signed [WIDTH-1:0] a [0:3];
    wire signed [WIDTH-1:0] max_val;

    max_finder #(.WIDTH(WIDTH)) uut (
        .a(a),
        .max_val(max_val)
    );

    initial begin
        $display("========================================");
        $display("Testing max_finder");
        $display("========================================");

        // Test 1: All positive values
        a[0] = 16'sd10;
        a[1] = 16'sd5;
        a[2] = 16'sd15;
        a[3] = 16'sd8;
        #1;
        $display("Test 1: [%d, %d, %d, %d] -> max = %d (expected: 15)", 
                 a[0], a[1], a[2], a[3], max_val);
        if (max_val == 15) $display("  PASS");
        else $display("  FAIL");

        // Test 2: Mixed positive and negative
        a[0] = 16'sd10;
        a[1] = -16'sd20;
        a[2] = 16'sd5;
        a[3] = -16'sd15;
        #1;
        $display("Test 2: [%d, %d, %d, %d] -> max = %d (expected: 20)", 
                 a[0], a[1], a[2], a[3], max_val);
        if (max_val == 20) $display("  PASS");
        else $display("  FAIL");

        // Test 3: All negative
        a[0] = -16'sd10;
        a[1] = -16'sd5;
        a[2] = -16'sd15;
        a[3] = -16'sd8;
        #1;
        $display("Test 3: [%d, %d, %d, %d] -> max = %d (expected: 15)", 
                 a[0], a[1], a[2], a[3], max_val);
        if (max_val == 15) $display("  PASS");
        else $display("  FAIL");

        // Test 4: Edge case - zeros
        a[0] = 16'sd0;
        a[1] = 16'sd0;
        a[2] = 16'sd0;
        a[3] = 16'sd0;
        #1;
        $display("Test 4: [%d, %d, %d, %d] -> max = %d (expected: 0)", 
                 a[0], a[1], a[2], a[3], max_val);
        if (max_val == 0) $display("  PASS");
        else $display("  FAIL");

        $display("========================================\n");
        #10;
        $finish;
    end

endmodule

