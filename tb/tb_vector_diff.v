// tb_vector_diff.v
// Testbench for vector_diff module

`timescale 1ns / 1ps

module tb_vector_diff;

    parameter WIDTH = 16;
    parameter CLK_PERIOD = 10;

    reg clk;
    reg start;
    reg signed [WIDTH-1:0] V_new [0:3];
    reg signed [WIDTH-1:0] V_old [0:3];
    wire signed [WIDTH-1:0] max_diff;
    wire done;

    vector_diff #(.WIDTH(WIDTH)) uut (
        .clk(clk),
        .start(start),
        .V_new(V_new),
        .V_old(V_old),
        .max_diff(max_diff),
        .done(done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        $display("========================================");
        $display("Testing vector_diff");
        $display("========================================");

        start = 0;

        // Test 1: Identical vectors (converged)
        V_new[0] = 16'sd10; V_old[0] = 16'sd10;
        V_new[1] = 16'sd20; V_old[1] = 16'sd20;
        V_new[2] = 16'sd30; V_old[2] = 16'sd30;
        V_new[3] = 16'sd40; V_old[3] = 16'sd40;
        
        $display("Test 1: Identical vectors (converged)");
        $display("  V_new = [%d, %d, %d, %d]", V_new[0], V_new[1], V_new[2], V_new[3]);
        $display("  V_old = [%d, %d, %d, %d]", V_old[0], V_old[1], V_old[2], V_old[3]);
        
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        wait(done == 1);
        #(CLK_PERIOD);
        
        $display("  max_diff = %d (expected: 0)", max_diff);
        if (max_diff == 0) $display("  PASS");
        else $display("  FAIL");

        // Test 2: Small differences
        V_new[0] = 16'sd10; V_old[0] = 16'sd9;
        V_new[1] = 16'sd20; V_old[1] = 16'sd21;
        V_new[2] = 16'sd30; V_old[2] = 16'sd29;
        V_new[3] = 16'sd40; V_old[3] = 16'sd41;
        
        $display("\nTest 2: Small differences");
        $display("  V_new = [%d, %d, %d, %d]", V_new[0], V_new[1], V_new[2], V_new[3]);
        $display("  V_old = [%d, %d, %d, %d]", V_old[0], V_old[1], V_old[2], V_old[3]);
        
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        wait(done == 1);
        #(CLK_PERIOD);
        
        $display("  max_diff = %d (expected: 1)", max_diff);
        if (max_diff == 1) $display("  PASS");
        else $display("  FAIL");

        // Test 3: Larger differences
        V_new[0] = 16'sd10; V_old[0] = 16'sd5;
        V_new[1] = 16'sd20; V_old[1] = 16'sd25;
        V_new[2] = 16'sd30; V_old[2] = 16'sd15;
        V_new[3] = 16'sd40; V_old[3] = 16'sd45;
        
        $display("\nTest 3: Larger differences");
        $display("  V_new = [%d, %d, %d, %d]", V_new[0], V_new[1], V_new[2], V_new[3]);
        $display("  V_old = [%d, %d, %d, %d]", V_old[0], V_old[1], V_old[2], V_old[3]);
        
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        wait(done == 1);
        #(CLK_PERIOD);
        
        // Differences: [5, 5, 15, 5], max = 15
        $display("  max_diff = %d (expected: 15)", max_diff);
        if (max_diff == 15) $display("  PASS");
        else $display("  FAIL");

        // Test 4: Mixed signs
        V_new[0] = 16'sd10; V_old[0] = -16'sd5;
        V_new[1] = -16'sd20; V_old[1] = 16'sd15;
        V_new[2] = 16'sd30; V_old[2] = 16'sd25;
        V_new[3] = -16'sd40; V_old[3] = -16'sd35;
        
        $display("\nTest 4: Mixed signs");
        $display("  V_new = [%d, %d, %d, %d]", V_new[0], V_new[1], V_new[2], V_new[3]);
        $display("  V_old = [%d, %d, %d, %d]", V_old[0], V_old[1], V_old[2], V_old[3]);
        
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        wait(done == 1);
        #(CLK_PERIOD);
        
        // Differences: [15, 35, 5, 5], max = 35
        $display("  max_diff = %d (expected: 35)", max_diff);
        if (max_diff == 35) $display("  PASS");
        else $display("  FAIL");

        $display("========================================\n");
        #(CLK_PERIOD * 5);
        $finish;
    end

endmodule

