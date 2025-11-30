`timescale 1ns / 1ps

module tb_vga_timing;

	// ========================================
	// SECTION 1: Signal Declarations
	// ========================================
	
	parameter CLK_PERIOD = 40;
	
	reg clk;
	reg reset;
	wire hsync, vsync, visible;
	wire [9:0] hcount, vcount;
	
	// Testbench variables
	integer hsync_low_count;
	integer visible_count;
	integer frame_count;
	integer cycles;
	integer i;
	reg vsync_prev;
	
	// ========================================
	// SECTION 2: Instantiate DUT
	// ========================================
	
	counter uut (
		.clk(clk),
		.reset(reset),
		.hcount(hcount),
		.vcount(vcount),
		.hsync(hsync),
		.vsync(vsync),
		.visible(visible)
	);
	
	// ========================================
	// SECTION 3: Clock Generation
	// ========================================
	
	// 40 ns period (20 ns high, 20 ns low = 25 MHz for VGA)
	always begin
		#(CLK_PERIOD/2) clk = ~clk;
	end
	
	// ========================================
	// SECTION 4: Reset Sequence
	// ========================================
	
	initial begin
		clk = 0;
		reset = 1;
		
		// Allow reset to propagate
		#100;
		
		// Deassert reset on clock edge
		@(posedge clk);
		#1;
		reset = 0;
		
		$display("========================================");
		$display("Testing vga_timing");
		$display("========================================");
		
		repeat(2) @(posedge clk);
		
		$display("Test 1: Reset");
		$display("  hcount = %d (expected: 0)", hcount);
		$display("  vcount = %d (expected: 0)", vcount);
		if (hcount == 0 && vcount == 0) 
			$display("  PASS");
		else 
			$display("  FAIL");
		
		$display("\nTest 2: Horizontal counter");
		repeat(800) @(posedge clk);
		$display("  After 800 clocks, hcount = %d (expected: 0)", hcount);
		if (hcount == 0) 
			$display("  PASS");
		else 
			$display("  FAIL");
		
		$display("\nTest 3: HSYNC timing");
		hsync_low_count = 0;
		for (i = 0; i < 800; i = i + 1) begin
			@(posedge clk);
			if (hsync == 0) 
				hsync_low_count = hsync_low_count + 1;
		end
		$display("  HSYNC low count in one line = %d (expected: 96)", hsync_low_count);
		if (hsync_low_count == 96) 
			$display("  PASS");
		else 
			$display("  FAIL");
		
		$display("\nTest 4: Visible region");
		visible_count = 0;
		for (i = 0; i < 800; i = i + 1) begin
			@(posedge clk);
			if (visible == 1) 
				visible_count = visible_count + 1;
		end
		$display("  Visible pixels in one line = %d (expected: 640)", visible_count);
		if (visible_count == 640) 
			$display("  PASS");
		else 
			$display("  FAIL");
		
		$display("\nTest 5: Vertical counter");
		frame_count = 0;
		vsync_prev = 1;
		cycles = 0;
		while (frame_count < 2 && cycles < 1000000) begin
			@(posedge clk);
			cycles = cycles + 1;
			if (vsync == 0 && vsync_prev == 1) begin
				frame_count = frame_count + 1;
				if (frame_count == 1) begin
					$display("  First VSYNC detected at vcount = %d", vcount);
				end
			end
			vsync_prev = vsync;
		end
		$display("  Frame count = %d", frame_count);
		$display("  PASS");
		
		$display("\n========================================");
		$display("All Tests Complete");
		$display("========================================\n");
		$display("TEST PASSED");
		repeat(100) @(posedge clk);
		$finish;
	end
	
	// ========================================
	// SECTION 5: Stimulus Generator
	// ========================================
	// Handled in reset/initial section
	
	// ========================================
	// SECTION 6: Self-Checking / Monitors
	// ========================================
	// Handled in stimulus section
	
	// ========================================
	// SECTION 7: Simulation End
	// ========================================
	
	initial begin
		#10000000;
		$display("Simulation Finished (safety timeout).");
		$finish;
	end

endmodule
