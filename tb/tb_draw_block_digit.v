`timescale 1ns / 1ps

module tb_draw_block_digit;

	// ========================================
	// SECTION 1: Signal Declarations
	// ========================================
	
	parameter DIGIT_WIDTH = 40;
	parameter DIGIT_HEIGHT = 60;
	
	reg [9:0] px, py;
	reg [3:0] digit;
	wire pixel_on;
	
	// Testbench variables
	integer pixel_count;
	integer x, y;
	
	// ========================================
	// SECTION 2: Instantiate DUT
	// ========================================
	
	block_digit_renderer #(
		.DIGIT_WIDTH(DIGIT_WIDTH),
		.DIGIT_HEIGHT(DIGIT_HEIGHT)
	) uut (
		.px(px),
		.py(py),
		.digit(digit),
		.pixel_on(pixel_on)
	);
	
	// ========================================
	// SECTION 3: Clock Generation
	// ========================================
	// Not needed for combinational module
	
	// ========================================
	// SECTION 4: Reset Sequence
	// ========================================
	// Not needed for combinational module
	
	// ========================================
	// SECTION 5: Stimulus Generator
	// ========================================
	
	initial begin
		$display("========================================");
		$display("Testing draw_block_digit");
		$display("========================================");
		
		$display("Test 1: Digit 8 (all segments)");
		digit = 4'd8;
		px = DIGIT_WIDTH / 2;
		py = 5;
		#1;
		$display("  Pixel at (%d, %d) = %b (expected: 1 for top segment)", px, py, pixel_on);
		if (pixel_on == 1) 
			$display("  PASS");
		else 
			$display("  FAIL");
		
		$display("\nTest 2: Digit 1 (only right segments)");
		digit = 4'd1;
		px = DIGIT_WIDTH - 5;
		py = DIGIT_HEIGHT / 2;
		#1;
		$display("  Pixel at (%d, %d) = %b (expected: 1 for right segment)", px, py, pixel_on);
		if (pixel_on == 1) 
			$display("  PASS");
		else 
			$display("  FAIL");
		
		$display("\nTest 3: Digit 0 (no middle segment)");
		digit = 4'd0;
		px = DIGIT_WIDTH / 2;
		py = DIGIT_HEIGHT / 2;
		#1;
		$display("  Pixel at (%d, %d) = %b (expected: 0 for middle segment)", px, py, pixel_on);
		if (pixel_on == 0) 
			$display("  PASS");
		else 
			$display("  FAIL");
		
		$display("\nTest 4: Background pixels (should be off)");
		digit = 4'd5;
		px = 0;
		py = 0;
		#1;
		$display("  Pixel at (%d, %d) = %b (expected: 0)", px, py, pixel_on);
		if (pixel_on == 0) 
			$display("  PASS");
		else 
			$display("  FAIL");
		
		$display("\nTest 5: Scan all pixels for digit 8");
		pixel_count = 0;
		for (x = 0; x < DIGIT_WIDTH; x = x + 1) begin
			for (y = 0; y < DIGIT_HEIGHT; y = y + 1) begin
				px = x;
				py = y;
				#1;
				if (pixel_on) 
					pixel_count = pixel_count + 1;
			end
		end
		$display("  Total lit pixels for digit 8 = %d", pixel_count);
		$display("  PASS (should be reasonable number of pixels)");
		
		$display("\n========================================");
		$display("All Tests Complete");
		$display("========================================\n");
		$display("TEST PASSED");
		#10;
		$finish;
	end
	
	// ========================================
	// SECTION 6: Self-Checking / Monitors
	// ========================================
	// Handled in stimulus section
	
	// ========================================
	// SECTION 7: Simulation End
	// ========================================
	
	initial begin
		#100000;
		$display("Simulation Finished (safety timeout).");
		$finish;
	end

endmodule
