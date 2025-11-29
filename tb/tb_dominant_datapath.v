// tb_dominant_datapath.v
// Testbench for dominant_datapath module (using existing dominiant_datapath.v)

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

    // Note: Using the existing dominiant_datapath.v
    // This testbench tests the existing datapath module
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

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        $display("========================================");
        $display("Testing dominant_datapath");
        $display("========================================");

        // Initialize
        reset = 1;
        load_v_old = 0;
        load_y = 0;
        load_max_d = 0;
        start_mult = 0;
        start_scale = 0;
        start_diff = 0;

        // Test matrix
        A00 = 4; A01 = 1; A02 = 1; A03 = 1;
        A10 = 1; A11 = 4; A12 = 1; A13 = 1;
        A20 = 1; A21 = 1; A22 = 4; A23 = 1;
        A30 = 1; A31 = 1; A32 = 1; A33 = 4;

        #(CLK_PERIOD * 2);
        reset = 0;
        #(CLK_PERIOD * 2);

        $display("Test 1: Reset");
        $display("  v = [%d, %d, %d, %d]", v0, v1, v2, v3);

        // Test one iteration
        $display("\nTest 2: One iteration cycle");

        // Step 1: Load initial vector (v_old gets initialized)
        load_v_old = 1;
        #(CLK_PERIOD);
        load_v_old = 0;
        #(CLK_PERIOD);

        // Step 2: Matrix multiply (takes 4 cycles)
        start_mult = 1;
        #(CLK_PERIOD);
        start_mult = 0;
        #(CLK_PERIOD * 4);  // Wait for 4 cycles

        $display("  After matrix multiply (4 cycles)");

        // Step 3: Load y and scale
        load_y = 1;
        start_scale = 1;
        #(CLK_PERIOD);
        load_y = 0;
        start_scale = 0;
        #(CLK_PERIOD * 2);  // Wait for scaling

        $display("  After scaling");
        $display("  v = [%d, %d, %d, %d]", v0, v1, v2, v3);

        // Step 4: Compute difference
        start_diff = 1;
        #(CLK_PERIOD);
        start_diff = 0;
        #(CLK_PERIOD * 2);  // Wait for diff

        $display("  After diff");

        // Step 5: Load max_d
        load_max_d = 1;
        #(CLK_PERIOD);
        load_max_d = 0;
        #(CLK_PERIOD);

        $display("\nTest 3: Multiple iterations");
        $display("Iteration 1: v = [%d, %d, %d, %d]", v0, v1, v2, v3);

        // Run a few more iterations
        integer i;
        for (i = 0; i < 5; i = i + 1) begin
            // Load v_old for next iteration
            load_v_old = 1;
            #(CLK_PERIOD);
            load_v_old = 0;
            #(CLK_PERIOD);

            // Matrix multiply (4 cycles)
            start_mult = 1;
            #(CLK_PERIOD);
            start_mult = 0;
            #(CLK_PERIOD * 4);

            // Scale
            load_y = 1;
            start_scale = 1;
            #(CLK_PERIOD);
            load_y = 0;
            start_scale = 0;
            #(CLK_PERIOD * 2);

            // Diff
            start_diff = 1;
            #(CLK_PERIOD);
            start_diff = 0;
            #(CLK_PERIOD * 2);

            load_max_d = 1;
            #(CLK_PERIOD);
            load_max_d = 0;
            #(CLK_PERIOD);

            $display("Iteration %0d: v = [%d, %d, %d, %d]", i+2, v0, v1, v2, v3);
        end

        $display("========================================\n");
        #(CLK_PERIOD * 10);
        $finish;
    end

    // Monitor for X or Z
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

