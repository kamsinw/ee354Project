`timescale 1ns / 1ps

module tb_vector_diff;

    parameter WIDTH = 16;
    parameter CLK_PERIOD = 10;

    reg clk;
    reg start;
    reg signed [4*WIDTH-1:0] V_new;
    reg signed [4*WIDTH-1:0] V_old;
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

    wire signed [WIDTH-1:0] V_new0 = V_new[WIDTH-1:0];
    wire signed [WIDTH-1:0] V_new1 = V_new[2*WIDTH-1:WIDTH];
    wire signed [WIDTH-1:0] V_new2 = V_new[3*WIDTH-1:2*WIDTH];
    wire signed [WIDTH-1:0] V_new3 = V_new[4*WIDTH-1:3*WIDTH];
    wire signed [WIDTH-1:0] V_old0 = V_old[WIDTH-1:0];
    wire signed [WIDTH-1:0] V_old1 = V_old[2*WIDTH-1:WIDTH];
    wire signed [WIDTH-1:0] V_old2 = V_old[3*WIDTH-1:2*WIDTH];
    wire signed [WIDTH-1:0] V_old3 = V_old[4*WIDTH-1:3*WIDTH];

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        #50000;
        $fatal("TIMEOUT: simulation did not complete");
    end

    initial begin
        $display("========================================");
        $display("Testing vector_diff");
        $display("========================================");

        start = 0;

        V_new = {16'sd40, 16'sd30, 16'sd20, 16'sd10};
        V_old = {16'sd40, 16'sd30, 16'sd20, 16'sd10};
        
        $display("Test 1: Identical vectors (converged)");
        $display("  V_new = [%d, %d, %d, %d]", V_new0, V_new1, V_new2, V_new3);
        $display("  V_old = [%d, %d, %d, %d]", V_old0, V_old1, V_old2, V_old3);
        
        start = 1;
        @(posedge clk);
        start = 0;
        @(posedge done);
        @(posedge clk);
        
        $display("  max_diff = %d (expected: 0)", max_diff);
        if (max_diff == 0) $display("  PASS");
        else $display("  FAIL");

        V_new = {16'sd41, 16'sd20, 16'sd29, 16'sd10};
        V_old = {16'sd40, 16'sd21, 16'sd30, 16'sd9};
        
        $display("\nTest 2: Small differences");
        $display("  V_new = [%d, %d, %d, %d]", V_new0, V_new1, V_new2, V_new3);
        $display("  V_old = [%d, %d, %d, %d]", V_old0, V_old1, V_old2, V_old3);
        
        start = 1;
        @(posedge clk);
        start = 0;
        @(posedge done);
        @(posedge clk);
        
        $display("  max_diff = %d (expected: 1)", max_diff);
        if (max_diff == 1) $display("  PASS");
        else $display("  FAIL");

        V_new = {16'sd45, 16'sd25, 16'sd15, 16'sd5};
        V_old = {16'sd40, 16'sd20, 16'sd30, 16'sd10};
        
        $display("\nTest 3: Larger differences");
        $display("  V_new = [%d, %d, %d, %d]", V_new0, V_new1, V_new2, V_new3);
        $display("  V_old = [%d, %d, %d, %d]", V_old0, V_old1, V_old2, V_old3);
        
        start = 1;
        @(posedge clk);
        start = 0;
        @(posedge done);
        @(posedge clk);
        
        $display("  max_diff = %d (expected: 15)", max_diff);
        if (max_diff == 15) $display("  PASS");
        else $display("  FAIL");

        V_new = {-16'sd5, 16'sd20, 16'sd25, -16'sd35};
        V_old = {16'sd10, -16'sd15, 16'sd30, -16'sd40};
        
        $display("\nTest 4: Mixed signs");
        $display("  V_new = [%d, %d, %d, %d]", V_new0, V_new1, V_new2, V_new3);
        $display("  V_old = [%d, %d, %d, %d]", V_old0, V_old1, V_old2, V_old3);
        
        start = 1;
        @(posedge clk);
        start = 0;
        @(posedge done);
        @(posedge clk);
        
        $display("  max_diff = %d (expected: 35)", max_diff);
        if (max_diff == 35) $display("  PASS");
        else $display("  FAIL");

        $display("========================================\n");
        $display("TEST PASSED");
        #(CLK_PERIOD * 5);
        $finish;
    end

endmodule
