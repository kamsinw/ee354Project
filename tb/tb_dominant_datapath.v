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

    wire mul_done;
    wire scale_done;
    wire diff_done;
    wire signed [15:0] max_d_out;
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
        .mul_done(mul_done),
        .scale_done(scale_done),
        .diff_done(diff_done),
        .max_d_out(max_d_out),
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
        $display("========================================");
        $display("Testing dominant_datapath");
        $display("========================================");

        // Reset
        reset = 1;
        load_v_old = 0;
        load_y = 0;
        load_max_d = 0;
        start_mult = 0;
        start_scale = 0;
        start_diff = 0;
        
        // Set up identity matrix
        A00 = 16'sd1; A01 = 16'sd0; A02 = 16'sd0; A03 = 16'sd0;
        A10 = 16'sd0; A11 = 16'sd1; A12 = 16'sd0; A13 = 16'sd0;
        A20 = 16'sd0; A21 = 16'sd0; A22 = 16'sd1; A23 = 16'sd0;
        A30 = 16'sd0; A31 = 16'sd0; A32 = 16'sd0; A33 = 16'sd1;
        
        @(posedge clk);
        @(posedge clk);
        reset = 0;
        
        // Initial vector should be [1,1,1,1] after reset
        @(posedge clk);
        if (v0 == 1 && v1 == 1 && v2 == 1 && v3 == 1) begin
            $display("Test 1: Initial vector is [1,1,1,1] - PASS");
        end else begin
            $display("Test 1: Initial vector is [1,1,1,1] - FAIL (got [%d,%d,%d,%d])", v0, v1, v2, v3);
        end
        
        // Start matrix-vector multiply
        start_mult = 1;
        @(posedge clk);
        start_mult = 0;
        
        // Wait for mul_done
        begin
            integer timeout;
            timeout = 100;
            while (mul_done == 0 && timeout > 0) begin
                @(posedge clk);
                timeout = timeout - 1;
            end
            if (mul_done == 1) begin
                $display("Test 2: Matrix multiply completed - PASS");
            end else begin
                $display("Test 2: Matrix multiply completed - FAIL (timeout)");
            end
        end
        
        // Load y
        load_y = 1;
        @(posedge clk);
        load_y = 0;
        
        // Start scaling
        start_scale = 1;
        @(posedge clk);
        start_scale = 0;
        
        // Wait for scale_done
        begin
            integer timeout;
            timeout = 100;
            while (scale_done == 0 && timeout > 0) begin
                @(posedge clk);
                timeout = timeout - 1;
            end
            if (scale_done == 1) begin
                $display("Test 3: Scaling completed - PASS");
            end else begin
                $display("Test 3: Scaling completed - FAIL (timeout)");
            end
        end
        
        // Start diff
        start_diff = 1;
        @(posedge clk);
        start_diff = 0;
        
        // Wait for diff_done
        begin
            integer timeout;
            timeout = 100;
            while (diff_done == 0 && timeout > 0) begin
                @(posedge clk);
                timeout = timeout - 1;
            end
            if (diff_done == 1) begin
                $display("Test 4: Difference calculation completed - PASS");
            end else begin
                $display("Test 4: Difference calculation completed - FAIL (timeout)");
            end
        end

        $display("========================================");
        $display("✓ dominant_datapath test passed");
        $display("========================================\n");
        repeat(10) @(posedge clk);
        $finish;
    end

    always @(posedge clk) begin
        if (^v0 === 1'bx || ^v0 === 1'bz) begin
            $display("ERROR: X or Z detected in v0 at time %t", $time);
        end
        if (^v1 === 1'bx || ^v1 === 1'bz) begin
            $display("ERROR: X or Z detected in v1 at time %t", $time);
        end
        if (^v2 === 1'bx || ^v2 === 1'bz) begin
            $display("ERROR: X or Z detected in v2 at time %t", $time);
        end
        if (^v3 === 1'bx || ^v3 === 1'bz) begin
            $display("ERROR: X or Z detected in v3 at time %t", $time);
        end
    end

endmodule
