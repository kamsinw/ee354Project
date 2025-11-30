`timescale 1ns / 1ps

module tb_dominant_datapath;

    parameter CLK_PERIOD = 10;

    reg clk;
    reg reset;
    reg load_v_old;
    reg load_y;
    reg load_max_d;
    reg start_mult;
    reg start_scale;
    reg start_diff;
    
    reg signed [15:0] A00, A01, A02, A03;
    reg signed [15:0] A10, A11, A12, A13;
    reg signed [15:0] A20, A21, A22, A23;
    reg signed [15:0] A30, A31, A32, A33;

    wire signed [15:0] v0, v1, v2, v3;

    dominant_datapath uut (
        .clk(clk),
        .reset(reset),
        .load_v_old(load_v_old),
        .load_y(load_y),
        .load_max_d(load_max_d),
        .start_mult(start_mult),
        .start_scale(start_scale),
        .start_diff(start_diff),
        .A00(A00), .A01(A01), .A02(A02), .A03(A03),
        .A10(A10), .A11(A11), .A12(A12), .A13(A13),
        .A20(A20), .A21(A21), .A22(A22), .A23(A23),
        .A30(A30), .A31(A31), .A32(A32), .A33(A33),
        .v0(v0),
        .v1(v1),
        .v2(v2),
        .v3(v3)
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
        $display("========================================");
        $display("Testing dominant_datapath");
        $display("========================================");

        reset = 1;
        load_v_old = 0;
        load_y = 0;
        load_max_d = 0;
        start_mult = 0;
        start_scale = 0;
        start_diff = 0;

        A00 = 4; A01 = 1; A02 = 1; A03 = 1;
        A10 = 1; A11 = 4; A12 = 1; A13 = 1;
        A20 = 1; A21 = 1; A22 = 4; A23 = 1;
        A30 = 1; A31 = 1; A32 = 1; A33 = 4;

        repeat(5) @(posedge clk);
        reset = 0;
        repeat(2) @(posedge clk);

        $display("Test 1: Reset");
        $display("  v = [%d, %d, %d, %d]", v0, v1, v2, v3);

        $display("\nTest 2: One iteration cycle");

        load_v_old = 1;
        @(posedge clk);
        load_v_old = 0;
        @(posedge clk);

        start_mult = 1;
        @(posedge clk);
        start_mult = 0;
        repeat(4) @(posedge clk);

        $display("  After matrix multiply (4 cycles)");

        load_y = 1;
        start_scale = 1;
        @(posedge clk);
        load_y = 0;
        start_scale = 0;
        repeat(2) @(posedge clk);

        $display("  After scaling");
        $display("  v = [%d, %d, %d, %d]", v0, v1, v2, v3);

        start_diff = 1;
        @(posedge clk);
        start_diff = 0;
        repeat(2) @(posedge clk);

        $display("  After diff");

        load_max_d = 1;
        @(posedge clk);
        load_max_d = 0;
        @(posedge clk);

        $display("\nTest 3: Multiple iterations");
        $display("Iteration 1: v = [%d, %d, %d, %d]", v0, v1, v2, v3);

        integer i;
        for (i = 0; i < 5; i = i + 1) begin
            load_v_old = 1;
            @(posedge clk);
            load_v_old = 0;
            @(posedge clk);

            start_mult = 1;
            @(posedge clk);
            start_mult = 0;
            repeat(4) @(posedge clk);

            load_y = 1;
            start_scale = 1;
            @(posedge clk);
            load_y = 0;
            start_scale = 0;
            repeat(2) @(posedge clk);

            start_diff = 1;
            @(posedge clk);
            start_diff = 0;
            repeat(2) @(posedge clk);

            load_max_d = 1;
            @(posedge clk);
            load_max_d = 0;
            @(posedge clk);

            $display("Iteration %0d: v = [%d, %d, %d, %d]", i+2, v0, v1, v2, v3);
        end

        $display("========================================\n");
        $display("TEST PASSED");
        repeat(10) @(posedge clk);
        $finish;
    end

    always @(posedge clk) begin
        if (^v0 === 1'bx || ^v0 === 1'bz) begin
            $display("ERROR: X or Z in v0 at time %t", $time);
        end
        if (^v1 === 1'bx || ^v1 === 1'bz) begin
            $display("ERROR: X or Z in v1 at time %t", $time);
        end
        if (^v2 === 1'bx || ^v2 === 1'bz) begin
            $display("ERROR: X or Z in v2 at time %t", $time);
        end
        if (^v3 === 1'bx || ^v3 === 1'bz) begin
            $display("ERROR: X or Z in v3 at time %t", $time);
        end
    end

endmodule
