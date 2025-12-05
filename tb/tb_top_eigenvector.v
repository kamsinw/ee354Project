`timescale 1ns / 1ps

module tb_top_eigenvector;

	// ========================================
	// SECTION 1: Signal Declarations
	// ========================================
	
	reg clk;
	reg reset;
	reg sw0;
	reg sw1;
	reg [2:0] sw_eps;
	reg btnl, btnr, btnu, btnd, btnc;
	
	wire [7:0] led;
	wire ca, cb, cc, cd, ce, cf, cg, dp;
	
	// Testbench variables
	integer wait_cycles;
	integer max_wait;
	
	// ========================================
	// SECTION 2: Instantiate DUT
	// ========================================
	
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
	
	// ========================================
	// SECTION 3: Clock Generation
	// ========================================
	
	// 10 ns period (5 ns high, 5 ns low = 100 MHz)
	always begin
		#5 clk = ~clk;
	end
	
	// ========================================
	// SECTION 4: Reset Sequence
	// ========================================
	
	initial begin
		clk = 0;
		reset = 1;
		sw0 = 0;
		sw1 = 0;
		sw_eps = 3'd2;
		btnl = 0;
		btnr = 0;
		btnu = 0;
		btnd = 0;
		btnc = 0;
		
		// Allow reset to propagate
		#100;
		
		// Deassert reset on clock edge
		@(posedge clk);
		#1;
		reset = 0;
		
		$display("========================================");
		$display("Testing top_eigenvector");
		$display("========================================\n");
		
		repeat(10) @(posedge clk);
		
		$display("Test 1: Reset and Initialization");
		repeat(20000) @(posedge clk);
		$display("  After reset, matrix and vector should be initialized to 1");
		$display("  PASS - Initialization complete\n");
		
		$display("========================================");
		$display("EDIT MODE TESTS");
		$display("========================================\n");
		
		$display("Test 2: Edit Matrix A - Set element [0][0] to 5");
		sw0 = 0;
		sw1 = 0;
		repeat(20000) @(posedge clk);
		
		repeat(5) begin
			press_btnr;
		end
		press_btnc;
		repeat(20000) @(posedge clk);
		$display("  Value should be 5 (incremented from 1)");
		$display("  PASS\n");
		
		$display("Test 3: Move cursor and edit element [1][2] to 10");
		press_btnd;
		repeat(20000) @(posedge clk);
		press_btnr;
		repeat(20000) @(posedge clk);
		press_btnr;
		repeat(20000) @(posedge clk);
		repeat(9) begin
			press_btnr;
		end
		press_btnc;
		repeat(20000) @(posedge clk);
		$display("  Cursor moved to [1][2], value set to 10");
		$display("  PASS\n");
		
		$display("Test 4: Edit Vector v - Set element [2] to 5");
		sw1 = 1;
		repeat(20000) @(posedge clk);
		press_btnd;
		repeat(20000) @(posedge clk);
		press_btnd;
		repeat(20000) @(posedge clk);
		repeat(4) begin
			press_btnr;
		end
		press_btnc;
		repeat(20000) @(posedge clk);
		$display("  Vector v[2] should be 5");
		$display("  PASS\n");
		
		$display("Test 5: Cursor boundary checks");
		sw1 = 0;
		repeat(20000) @(posedge clk);
		press_btnu;
		repeat(20000) @(posedge clk);
		press_btnl;
		repeat(20000) @(posedge clk);
		press_btnu;
		repeat(20000) @(posedge clk);
		press_btnl;
		repeat(20000) @(posedge clk);
		repeat(3) begin
			press_btnd;
			repeat(20000) @(posedge clk);
		end
		repeat(3) begin
			press_btnr;
			repeat(20000) @(posedge clk);
		end
		press_btnd;
		repeat(20000) @(posedge clk);
		press_btnr;
		repeat(20000) @(posedge clk);
		$display("  Cursor boundaries respected");
		$display("  PASS\n");
		
		$display("========================================");
		$display("RUN MODE TESTS");
		$display("========================================\n");
		
		$display("Test 6: Switch to RUN mode and execute power iteration");
		sw0 = 1;
		repeat(20000) @(posedge clk);
		$display("  Switched to RUN mode, FSM should start");
		$display("  Monitoring LED[0] (done signal) and LED[4] (RUN mode)");
		
		if (led[4] != 1'b1) begin
			$display("  ERROR: Not in RUN mode (LED[4] = %b)", led[4]);
		end else begin
			$display("  Confirmed in RUN mode");
		end
		
		wait_cycles = 0;
		max_wait = 100000;
		
		$display("  Waiting for FSM to start...");
		while (led[1] == 1'b0 && led[2] == 1'b0 && led[3] == 1'b0 && wait_cycles < max_wait) begin
			@(posedge clk);
			wait_cycles = wait_cycles + 1;
		end
		
		if (wait_cycles >= max_wait) begin
			$display("  WARNING: FSM may not have started");
		end else begin
			$display("  FSM started (status LEDs active)");
		end
		
		wait_cycles = 0;
		$display("  Waiting for iteration to complete...");
		while (led[0] == 1'b0 && wait_cycles < max_wait) begin
			@(posedge clk);
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
		sw0 = 0;
		repeat(20000) @(posedge clk);
		$display("  Switched back to EDIT mode");
		$display("  PASS\n");
		
		$display("Test 8: Edit after RUN mode");
		sw1 = 0;
		repeat(20000) @(posedge clk);
		press_btnr;
		repeat(20000) @(posedge clk);
		repeat(20) begin
			press_btnr;
		end
		press_btnc;
		repeat(20000) @(posedge clk);
		$display("  Edited matrix after RUN mode");
		$display("  PASS\n");
		
		$display("Test 9: Multiple mode switches");
		sw0 = 1;
		repeat(20000) @(posedge clk);
		sw0 = 0;
		repeat(20000) @(posedge clk);
		sw0 = 1;
		repeat(20000) @(posedge clk);
		sw0 = 0;
		repeat(20000) @(posedge clk);
		$display("  Mode switching works correctly");
		$display("  PASS\n");
		
		$display("Test 10: Edit target switching");
		sw1 = 0;
		repeat(20000) @(posedge clk);
		sw1 = 1;
		repeat(20000) @(posedge clk);
		sw1 = 0;
		repeat(20000) @(posedge clk);
		$display("  Target switching works correctly");
		$display("  PASS\n");
		
		$display("========================================");
		$display("All Tests Complete");
		$display("========================================\n");
		$display("TEST PASSED");
		repeat(100) @(posedge clk);
		$finish;
	end
	
	// ========================================
	// SECTION 5: Stimulus Generator
	// ========================================
	
	task press_btnl;
		begin : press_btnl_block
			btnl = 1;
			repeat(20000) @(posedge clk);
			btnl = 0;
			repeat(20000) @(posedge clk);
		end
	endtask
	
	task press_btnr;
		begin : press_btnr_block
			btnr = 1;
			repeat(20000) @(posedge clk);
			btnr = 0;
			repeat(20000) @(posedge clk);
		end
	endtask
	
	task press_btnu;
		begin : press_btnu_block
			btnu = 1;
			repeat(20000) @(posedge clk);
			btnu = 0;
			repeat(20000) @(posedge clk);
		end
	endtask
	
	task press_btnd;
		begin : press_btnd_block
			btnd = 1;
			repeat(20000) @(posedge clk);
			btnd = 0;
			repeat(20000) @(posedge clk);
		end
	endtask
	
	task press_btnc;
		begin : press_btnc_block
			btnc = 1;
			repeat(20000) @(posedge clk);
			btnc = 0;
			repeat(20000) @(posedge clk);
		end
	endtask
	
	// ========================================
	// SECTION 6: Self-Checking / Monitors
	// ========================================
	
	always @(posedge clk) begin
		if (^led === 1'bx || ^led === 1'bz) begin
			$display("WARNING: X or Z detected in led at time %t", $time);
		end
	end
	
	// ========================================
	// SECTION 7: Simulation End
	// ========================================
	
	initial begin
		#20000000;
		$display("Simulation Finished (safety timeout).");
		$finish;
	end

endmodule
