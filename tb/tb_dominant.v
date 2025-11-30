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
    integer i;
    integer timeout_counter;
    real prev_ratio;
    real curr_ratio;
    real diff_ratio;
    
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
        #10000000;
        $display("\n*** GLOBAL TIMEOUT: simulation did not complete ***");
        $display("Time: %t", $time);
        $display("Current state signals: mul_done=%b, scale_done=%b, diff_done=%b, done=%b", 
                 mul_done, scale_done, diff_done, done);
        $display("Control signals: load_v_old=%b, load_y=%b, load_max_d=%b",
                 load_v_old, load_y, load_max_d);
        $display("Start signals: start_mult=%b, start_scale=%b, start_diff=%b",
                 start_mult, start_scale, start_diff);
        $display("Current vector: [%d, %d, %d, %d]", v0, v1, v2, v3);
        $display("Current max_diff: %d", max_d_out);
        $display("Iteration count: %d", iteration_count);
        $fatal("TIMEOUT: simulation did not complete");
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
        
        // Ensure proper reset sequence - wait for clock edges
        @(posedge clk);
        repeat(5) @(posedge clk);
        reset = 0;
        @(posedge clk);
        repeat(2) @(posedge clk);
        
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
        
        // Assert start signal and ensure it's seen
        start = 1;
        @(posedge clk);
        start = 0;
        @(posedge clk);  // Extra cycle to ensure start is processed
        
        iteration_count = 0;
        timeout_counter = 0;
        
        // Wait for FSM done signal with enhanced debugging
        // Use same timeout as cocotb test (1000 cycles) but allow more for safety
        while (!done && timeout_counter < 5000) begin
            @(posedge clk);
            timeout_counter = timeout_counter + 1;
            
            // Enhanced monitoring - show FSM control signals
            if (timeout_counter % 50 == 0 || timeout_counter < 20) begin
                $display("Cycle %6d: v=[%6d,%6d,%6d,%6d] max_diff=%6d done=%b",
                         timeout_counter, v0, v1, v2, v3, max_d_out, done);
                $display("  Control: load_v_old=%b load_y=%b load_max_d=%b",
                         load_v_old, load_y, load_max_d);
                $display("  Start: start_mult=%b start_scale=%b start_diff=%b",
                         start_mult, start_scale, start_diff);
                $display("  Done:  mul_done=%b scale_done=%b diff_done=%b",
                         mul_done, scale_done, diff_done);
            end
            
            // Detect if we're stuck (same values for many cycles)
            if (timeout_counter > 100 && timeout_counter % 100 == 0) begin
                $display("WARNING: Still waiting after %d cycles", timeout_counter);
            end
        end
        
        if (done) begin
            $display("\n*** CONVERGED: FSM done signal asserted ***");
            $display("Total cycles: %d", timeout_counter);
            $display("Final eigenvector: [%d, %d, %d, %d]", v0, v1, v2, v3);
            $display("Final max_diff: %d (epsilon = %d)", max_d_out, epsilon);
        end else begin
            $display("\n*** TIMEOUT: FSM done signal not asserted after %d cycles ***", timeout_counter);
            $display("Current signals: mul_done=%b, scale_done=%b, diff_done=%b, done=%b",
                     mul_done, scale_done, diff_done, done);
            $display("Control signals: load_v_old=%b, load_y=%b, load_max_d=%b",
                     load_v_old, load_y, load_max_d);
            $display("Start signals: start_mult=%b, start_scale=%b, start_diff=%b",
                     start_mult, start_scale, start_diff);
            $display("Current vector: [%d, %d, %d, %d]", v0, v1, v2, v3);
            $display("Current max_diff: %d", max_d_out);
            $fatal("Test failed: timeout waiting for done signal");
        end
        
        $display("\n========================================");
        $display("Test Complete");
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
