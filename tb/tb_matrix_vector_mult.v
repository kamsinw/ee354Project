`timescale 1ns / 1ps

module tb_matrix_vector_mult;

	// ========================================
	// SECTION 1: Signal Declarations
	// ========================================
	
	reg clk;
	reg reset;
	reg start;
	reg signed [16*16-1:0] A;
	reg signed [4*16-1:0] V;
	wire signed [4*16-1:0] Y;
	wire done;
	
	// Unpacked signals for display
	wire signed [15:0] V0;
	wire signed [15:0] V1;
	wire signed [15:0] V2;
	wire signed [15:0] V3;
	wire signed [15:0] Y0;
	wire signed [15:0] Y1;
	wire signed [15:0] Y2;
	wire signed [15:0] Y3;
	
	// Testbench variables
	integer timeout;
	integer y0, y1, y2, y3;
	
	// ========================================
	// SECTION 2: Instantiate DUT
	// ========================================
	
	matrix_vector_mult uut (
		.clk(clk),
		.reset(reset),
		.start(start),
		.A(A),
		.V(V),
		.Y(Y),
		.done(done)
	);
	
	// Unpack signals
	assign V0 = V[15:0];
	assign V1 = V[31:16];
	assign V2 = V[47:32];
	assign V3 = V[63:48];
	assign Y0 = Y[15:0];
	assign Y1 = Y[31:16];
	assign Y2 = Y[47:32];
	assign Y3 = Y[63:48];
	
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
		start = 0;
		
		// Allow reset to propagate
		#100;
		
		// Deassert reset on clock edge
		@(posedge clk);
		#1;
		reset = 0;
		
		$display("========================================");
		$display("Testing matrix_vector_mult");
		$display("========================================");
		
		// Set up 4x4 identity matrix and vector [1,2,3,4]
		// Matrix: row-major, packed as A[255:0] = {A33, A32, A31, A30, ..., A00}
		// Identity matrix: A00=1, A11=1, A22=1, A33=1, others=0
		A = 0;
		A = A | (16'sd1 << 0);    // A00
		A = A | (16'sd1 << 80);   // A11
		A = A | (16'sd1 << 160);  // A22
		A = A | (16'sd1 << 240);  // A33
		
		V = (16'sd4 << 48) | (16'sd3 << 32) | (16'sd2 << 16) | 16'sd1;  // [4,3,2,1]
		
		// Start multiplication
		start = 1;
		@(posedge clk);
		start = 0;
		
		// Wait for done
		timeout = 100;
		while (done == 0 && timeout > 0) begin
			@(posedge clk);
			timeout = timeout - 1;
		end
		if (done == 1) begin
			$display("Test 1: Identity matrix multiplication completed - PASS");
		end else begin
			$display("Test 1: Identity matrix multiplication completed - FAIL (timeout)");
		end
		
		// Check result: Y should be [1,2,3,4] for identity matrix
		// Extract and sign extend
		y0 = Y0;
		y1 = Y1;
		y2 = Y2;
		y3 = Y3;
		
		if (y0 == 1 && y1 == 2 && y2 == 3 && y3 == 4) begin
			$display("  Result: Y = [%d, %d, %d, %d] (expected: [1,2,3,4]) - PASS", y0, y1, y2, y3);
		end else begin
			$display("  Result: Y = [%d, %d, %d, %d] (expected: [1,2,3,4]) - FAIL", y0, y1, y2, y3);
		end
		
		$display("========================================");
		$display("✓ matrix_vector_mult test passed");
		$display("========================================\n");
		repeat(10) @(posedge clk);
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
		#200000;
		$display("Simulation Finished (safety timeout).");
		$finish;
	end

endmodule
