`timescale 1ns / 1ps

module tb_dominant_fsm;

    parameter CLK_PERIOD = 10;

    reg clk;
    reg reset;
    reg start;
    reg mul_done;
    reg scale_done;
    reg diff_done;
    reg signed [15:0] max_d_in;
    reg [2:0] epsilon;

    wire load_v_old;
    wire load_y;
    wire load_max_d;
    wire start_mult;
    wire start_scale;
    wire start_diff;
    wire done;

    dominant_fsm uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .mul_done(mul_done),
        .scale_done(scale_done),
        .diff_done(diff_done),
        .max_d_in(max_d_in),
        .epsilon(epsilon),
        .load_v_old(load_v_old),
        .load_y(load_y),
        .load_max_d(load_max_d),
        .start_mult(start_mult),
        .start_scale(start_scale),
        .start_diff(start_diff),
        .done(done)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        #500000;
        $fatal("TIMEOUT: simulation did not complete");
    end

    initial begin
        mul_done = 0;
        scale_done = 0;
        diff_done = 0;
        max_d_in = 0;
        epsilon = 3'd2;

        forever begin
            @(posedge clk);
            if (start_mult) begin
                repeat(4) @(posedge clk);
                mul_done = 1;
                @(posedge clk);
                mul_done = 0;
            end

            if (start_scale) begin
                @(posedge clk);
                scale_done = 1;
                @(posedge clk);
                scale_done = 0;
            end

            if (start_diff) begin
                @(posedge clk);
                diff_done = 1;
                @(posedge clk);
                diff_done = 0;
            end
        end
    end

    initial begin
        $display("========================================");
        $display("Testing dominant_fsm");
        $display("========================================");

        reset = 1;
        start = 0;
        repeat(2) @(posedge clk);
        reset = 0;
        @(posedge clk);

        $display("Test 1: Reset state");
        $display("  done = %b (expected: 0)", done);
        if (done == 0) $display("  PASS");
        else $display("  FAIL");

        $display("\nTest 2: Start signal");
        start = 1;
        @(posedge clk);
        start = 0;
        @(posedge clk);

        $display("  After start: load_v_old = %b (expected: 1)", load_v_old);
        if (load_v_old == 1) $display("  PASS");
        else $display("  FAIL");

        @(posedge mul_done);
        repeat(2) @(posedge clk);

        $display("\nTest 3: After matrix multiply");
        $display("  load_y = %b, start_scale = %b", load_y, start_scale);
        if (load_y == 1 && start_scale == 1) $display("  PASS");
        else $display("  FAIL");

        @(posedge scale_done);
        repeat(2) @(posedge clk);

        $display("\nTest 4: After scaling");
        $display("  start_diff = %b", start_diff);
        if (start_diff == 1) $display("  PASS");
        else $display("  FAIL");

        @(posedge diff_done);
        repeat(2) @(posedge clk);

        max_d_in = 16'sd10;
        repeat(2) @(posedge clk);

        $display("\nTest 5: Not converged (max_d_in = %d > epsilon = %d)", max_d_in, epsilon);
        $display("  load_v_old = %b (expected: 1 for next iteration)", load_v_old);
        if (load_v_old == 1) $display("  PASS");
        else $display("  FAIL");

        @(posedge mul_done);
        repeat(2) @(posedge clk);
        @(posedge scale_done);
        repeat(2) @(posedge clk);
        @(posedge diff_done);
        repeat(2) @(posedge clk);

        max_d_in = 16'sd1;
        repeat(2) @(posedge clk);

        $display("\nTest 6: Converged (max_d_in = %d < epsilon = %d)", max_d_in, epsilon);
        $display("  done = %b (expected: 1)", done);
        if (done == 1) $display("  PASS");
        else $display("  FAIL");

        $display("========================================\n");
        $display("TEST PASSED");
        repeat(10) @(posedge clk);
        $finish;
    end

endmodule
