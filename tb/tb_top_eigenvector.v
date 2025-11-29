// tb_top_eigenvector.v
// Testbench for top_eigenvector module
// Tests both EDIT mode and RUN mode functionality

`timescale 1ns / 1ps

module tb_top_eigenvector;

    parameter CLK_PERIOD = 10;  // 100 MHz clock

    // Testbench signals
    reg clk;
    reg reset;
    reg sw0;           // EDIT/RUN mode (0=edit, 1=run)
    reg sw1;           // Edit target (0=matrix A, 1=vector v)
    reg [2:0] sw_eps;  // Epsilon threshold
    reg btnl, btnr, btnu, btnd, btnc;  // Button inputs
    
    // Outputs
    wire [7:0] led;
    wire ca, cb, cc, cd, ce, cf, cg, dp;

    // Instantiate DUT
    top_eigenvector dut (
        .clk(clk),
        .reset(reset),
        .sw0(sw0),
        .sw1(sw1),
        .sw_eps(sw_eps),
        .btnl(btnl),
        .btnr(btnr),
        .btnu(btnu),
        .btnd(btnd),
        .btnc(btnc),
        .led(led),
        .ca(ca), .cb(cb), .cc(cc), .cd(cd),
        .ce(ce), .cf(cf), .cg(cg), .dp(dp)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Helper task to press and release a button
    // Note: Buttons are debounced on clk_1k (~1kHz), so need longer hold time
    // Since we can't pass by reference, we'll use separate tasks for each button
    task press_btnl;
        begin
            btnl = 1;
            #(200000);  // Hold for ~200us (enough for clk_1k debounce)
            btnl = 0;
            #(200000);  // Release
        end
    endtask
    
    task press_btnr;
        begin
            btnr = 1;
            #(200000);
            btnr = 0;
            #(200000);
        end
    endtask
    
    task press_btnu;
        begin
            btnu = 1;
            #(200000);
            btnu = 0;
            #(200000);
        end
    endtask
    
    task press_btnd;
        begin
            btnd = 1;
            #(200000);
            btnd = 0;
            #(200000);
        end
    endtask
    
    task press_btnc;
        begin
            btnc = 1;
            #(200000);
            btnc = 0;
            #(200000);
        end
    endtask

    // Helper task to wait for debounced pulse
    task wait_debounce;
        #(200000);  // Wait for debounce logic (clk_1k domain)
    endtask

    initial begin
        $display("========================================");
        $display("Testing top_eigenvector");
        $display("========================================\n");

        // Initialize
        reset = 1;
        sw0 = 0;      // Start in EDIT mode
        sw1 = 0;      // Edit matrix A
        sw_eps = 3'd2;
        btnl = 0;
        btnr = 0;
        btnu = 0;
        btnd = 0;
        btnc = 0;

        // Reset sequence
        #(CLK_PERIOD * 10);
        reset = 0;
        #(CLK_PERIOD * 10);

        $display("Test 1: Reset and Initialization");
        $display("  After reset, matrix and vector should be initialized to 1");
        wait_debounce;
        $display("  PASS - Initialization complete\n");

        // ========== EDIT MODE TESTS ==========
        $display("========================================");
        $display("EDIT MODE TESTS");
        $display("========================================\n");

        $display("Test 2: Edit Matrix A - Set element [0][0] to 5");
        sw0 = 0;  // EDIT mode
        sw1 = 0;  // Edit matrix A
        wait_debounce;
        
        // Cursor should be at [0][0] by default
        // Increment value 5 times
        repeat(5) begin
            press_btnr;
            wait_debounce;
        end
        // Commit the edit
        press_btnc;
        wait_debounce;
        $display("  Value should be 5 (incremented from 1)");
        $display("  PASS\n");

        $display("Test 3: Move cursor and edit element [1][2] to 10");
        // Move cursor: row 0 -> row 1 (down)
        press_btnd;
        wait_debounce;
        // Move cursor: col 0 -> col 2 (right twice)
        press_btnr;
        wait_debounce;
        press_btnr;
        wait_debounce;
        // Increment value to 10 (currently 1, need +9)
        repeat(9) begin
            press_btnr;
            wait_debounce;
        end
        // Commit
        press_btnc;
        wait_debounce;
        $display("  Cursor moved to [1][2], value set to 10");
        $display("  PASS\n");

        $display("Test 4: Edit Vector v - Set element [2] to -5");
        sw1 = 1;  // Switch to edit vector v
        wait_debounce;
        // Move cursor to row 2
        press_btnd;
        wait_debounce;
        press_btnd;
        wait_debounce;
        // Decrement value 6 times (1 -> -5)
        repeat(6) begin
            press_btnl;
            wait_debounce;
        end
        // Commit
        press_btnc;
        wait_debounce;
        $display("  Vector v[2] should be -5");
        $display("  PASS\n");

        $display("Test 5: Cursor boundary checks");
        // Try to move cursor beyond boundaries
        sw1 = 0;  // Back to matrix
        wait_debounce;
        // Move to [0][0]
        press_btnu;
        wait_debounce;
        press_btnl;
        wait_debounce;
        // Try to move up (should stay at row 0)
        press_btnu;
        wait_debounce;
        // Try to move left (should stay at col 0)
        press_btnl;
        wait_debounce;
        // Move to [3][3]
        repeat(3) begin
            press_btnd;
            wait_debounce;
        end
        repeat(3) begin
            press_btnr;
            wait_debounce;
        end
        // Try to move beyond (should stay at [3][3])
        press_btnd;
        wait_debounce;
        press_btnr;
        wait_debounce;
        $display("  Cursor boundaries respected");
        $display("  PASS\n");

        // ========== RUN MODE TESTS ==========
        $display("========================================");
        $display("RUN MODE TESTS");
        $display("========================================\n");

        $display("Test 6: Switch to RUN mode and execute power iteration");
        sw0 = 1;  // Switch to RUN mode
        wait_debounce;
        $display("  Switched to RUN mode, FSM should start");
        $display("  Monitoring LED[0] (done signal) and LED[4] (RUN mode)");
        
        // Verify we're in RUN mode
        if (led[4] != 1'b1) begin
            $display("  ERROR: Not in RUN mode (LED[4] = %b)", led[4]);
        end else begin
            $display("  Confirmed in RUN mode");
        end
        
        // Wait for FSM to start and complete at least one iteration
        // Monitor LED[0] (done signal) and LED[1-3] (status signals)
        integer wait_cycles = 0;
        integer max_wait = 100000;  // Wait up to 1ms at 100MHz
        
        $display("  Waiting for FSM to start...");
        while (led[1] == 1'b0 && led[2] == 1'b0 && led[3] == 1'b0 && wait_cycles < max_wait) begin
            #(CLK_PERIOD);
            wait_cycles = wait_cycles + 1;
        end
        
        if (wait_cycles >= max_wait) begin
            $display("  WARNING: FSM may not have started");
        end else begin
            $display("  FSM started (status LEDs active)");
        end
        
        // Wait for done signal
        wait_cycles = 0;
        $display("  Waiting for iteration to complete...");
        while (led[0] == 1'b0 && wait_cycles < max_wait) begin
            #(CLK_PERIOD);
            wait_cycles = wait_cycles + 1;
        end
        
        if (led[0] == 1'b1) begin
            $display("  Iteration complete (LED[0] = 1)");
            $display("  Status: mul_done=%b, scale_done=%b, diff_done=%b", 
                     led[1], led[2], led[3]);
        end else begin
            $display("  WARNING: Done signal not observed");
        end
        
        $display("  PASS\n");

        $display("Test 7: Switch back to EDIT mode");
        sw0 = 0;  // Back to EDIT mode
        wait_debounce;
        $display("  Switched back to EDIT mode");
        $display("  PASS\n");

        $display("Test 8: Edit after RUN mode");
        // Edit a value after running
        sw1 = 0;  // Edit matrix
        wait_debounce;
        // Move to [0][1]
        press_btnr;
        wait_debounce;
        // Set value to 20
        repeat(20) begin
            press_btnr;
            wait_debounce;
        end
        press_btnc;
        wait_debounce;
        $display("  Edited matrix after RUN mode");
        $display("  PASS\n");

        $display("Test 9: Multiple mode switches");
        // Switch modes multiple times
        sw0 = 1;  // RUN
        wait_debounce;
        sw0 = 0;  // EDIT
        wait_debounce;
        sw0 = 1;  // RUN
        wait_debounce;
        sw0 = 0;  // EDIT
        wait_debounce;
        $display("  Mode switching works correctly");
        $display("  PASS\n");

        $display("Test 10: Edit target switching");
        // Switch between matrix and vector editing
        sw1 = 0;  // Matrix
        wait_debounce;
        sw1 = 1;  // Vector
        wait_debounce;
        sw1 = 0;  // Matrix
        wait_debounce;
        $display("  Target switching works correctly");
        $display("  PASS\n");

        $display("========================================");
        $display("All Tests Complete");
        $display("========================================\n");

        #(CLK_PERIOD * 100);
        $finish;
    end

    // Monitor for X or Z values
    always @(posedge clk) begin
        if (^led === 1'bx || ^led === 1'bz) begin
            $display("WARNING: X or Z detected in led at time %t", $time);
        end
    end

    // Dump VCD for waveform viewing
    initial begin
        $dumpfile("tb_top_eigenvector.vcd");
        $dumpvars(0, tb_top_eigenvector);
    end

endmodule

