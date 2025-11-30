`timescale 1ns / 1ps

module tb_dominant;

    parameter CLK_PERIOD = 10;
    
    reg clk;
    reg reset;
    reg start;
    reg [2:0] epsilon;
    
    wire done;
    wire load_v_old, load_y, load_max_d;
    wire start_mult, start_scale, start_diff;
    
    wire mul_done, scale_done, diff_done;
    wire signed [15:0] max_d_out;
    wire signed [15:0] v0, v1, v2, v3;
    
    reg signed [15:0] A00, A01, A02, A03;
    reg signed [15:0] A10, A11, A12, A13;
    reg signed [15:0] A20, A21, A22, A23;
    reg signed [15:0] A30, A31, A32, A33;
    
    integer iteration_count;
    reg signed [15:0] prev_v0, prev_v1, prev_v2, prev_v3;
    
    dominant_fsm u_fsm (
        .clk(clk),
        .reset(reset),
        .start(start),
        .mul_done(mul_done),
        .scale_done(scale_done),
        .diff_done(diff_done),
        .max_d_in(max_d_out),
        .epsilon(epsilon),
        .load_v_old(load_v_old),
        .load_y(load_y),
        .load_max_d(load_max_d),
        .start_mult(start_mult),
        .start_scale(start_scale),
        .start_diff(start_diff),
        .done(done)
    );
    
    dominant_datapath u_datapath (
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
        reset = 1;
        start = 0;
        epsilon = 3'd2;
        
        A00 = 16'sd4; A01 = 16'sd1; A02 = 16'sd1; A03 = 16'sd1;
        A10 = 16'sd1; A11 = 16'sd4; A12 = 16'sd1; A13 = 16'sd1;
        A20 = 16'sd1; A21 = 16'sd1; A22 = 16'sd4; A23 = 16'sd1;
        A30 = 16'sd1; A31 = 16'sd1; A32 = 16'sd1; A33 = 16'sd4;
        
        iteration_count = 0;
        prev_v0 = 16'sd0;
        prev_v1 = 16'sd0;
        prev_v2 = 16'sd0;
        prev_v3 = 16'sd0;
        
        $display("========================================");
        $display("Starting Power Iteration Test");
        $display("========================================");
        $display("Matrix A:");
        $display("  [%d, %d, %d, %d]", A00, A01, A02, A03);
        $display("  [%d, %d, %d, %d]", A10, A11, A12, A13);
        $display("  [%d, %d, %d, %d]", A20, A21, A22, A23);
        $display("  [%d, %d, %d, %d]", A30, A31, A32, A33);
        $display("Epsilon threshold: %d", epsilon);
        $display("Initial vector: [1, 1, 1, 1]");
        $display("========================================\n");
        
        // Reset sequence: assert reset for 2 clock cycles, then deassert (match cocotb pattern)
        @(posedge clk);
        @(posedge clk);
        reset = 0;
        
        // Pulse start signal HIGH for exactly one clock cycle
        start = 1;
        @(posedge clk);
        start = 0;
        
        // Wait for convergence (done signal) - use timeout loop like cocotb
        begin
            integer timeout_cycles;
            integer cycle_count;
            reg load_max_d_prev;
            
            timeout_cycles = 1000;  // Reasonable limit
            cycle_count = 0;
            load_max_d_prev = 0;
            
            // Wait for done signal with timeout, monitoring iterations
            while (done == 0 && cycle_count < timeout_cycles) begin
                @(posedge clk);
                cycle_count = cycle_count + 1;
                
                // Monitor iterations by detecting posedge of load_max_d
                if (load_max_d == 1 && load_max_d_prev == 0) begin
                    // New iteration completed
                    @(posedge clk);  // Wait one cycle for max_d_out register to update
                    iteration_count = iteration_count + 1;
                    
                    // Print iteration results
                    // Note: y (intermediate matrix-vector product) is not accessible from testbench
                    // v_old is the previous iteration's v_new (or initial vector for first iteration)
                    $display("Iteration %0d:", iteration_count);
                    if (iteration_count == 1) begin
                        $display("  v_old: [1, 1, 1, 1] (initial vector)");
                    end else begin
                        $display("  v_old: [%d, %d, %d, %d]", prev_v0, prev_v1, prev_v2, prev_v3);
                    end
                    $display("  y: [not accessible from testbench]");
                    $display("  v_new: [%d, %d, %d, %d]", v0, v1, v2, v3);
                    $display("  max_diff: %d", max_d_out);
                    $display("");
                    
                    // Update previous values for next iteration (store current v_new as v_old)
                    prev_v0 = v0;
                    prev_v1 = v1;
                    prev_v2 = v2;
                    prev_v3 = v3;
                end
                
                load_max_d_prev = load_max_d;
            end
            
            if (done == 0) begin
                $display("ERROR: Computation did not converge after %d cycles", cycle_count);
                $fatal("TIMEOUT: simulation did not complete");
            end
        end
        
        // Only read vectors AFTER done is high
        @(posedge clk);  // Wait one cycle to ensure values are stable
        
        $display("========================================");
        $display("Computation Complete");
        $display("========================================");
        $display("Total iterations: %d", iteration_count);
        $display("Final eigenvector (v_new): [%d, %d, %d, %d]", v0, v1, v2, v3);
        $display("Final max_diff: %d (epsilon = %d)", max_d_out, epsilon);
        $display("========================================\n");
        $display("TEST PASSED");
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
