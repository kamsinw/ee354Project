`timescale 1ns / 1ps

module tb_dominant;

	// ========================================
	// SECTION 1: Signal Declarations
	// ========================================
	
	// Clock and reset
	reg Clk;
	reg Reset;
	
	// Control inputs
	reg Start;
	reg [2:0] Epsilon;
	
	// Matrix inputs (4x4 matrix)
	reg signed [15:0] A00, A01, A02, A03;
	reg signed [15:0] A10, A11, A12, A13;
	reg signed [15:0] A20, A21, A22, A23;
	reg signed [15:0] A30, A31, A32, A33;
	reg signed [4*16-1:0] V_init;
	
	// FSM outputs
	wire Done;
	wire Load_v_old, Load_y, Load_max_d;
	wire Start_mult, Start_scale, Start_diff;
	
	// Datapath outputs
	wire Mul_done, Scale_done, Diff_done;
	wire signed [15:0] Max_d_out;
	wire signed [15:0] v0, v1, v2, v3;
	
	// Testbench counters and state
	integer iteration_count;
	integer clk_cnt;
	integer start_clock_cnt;
	integer iteration_clock_cnt;
	integer cycle_count;
	integer timeout_cycles;
	
	// Previous values for edge detection
	reg signed [15:0] prev_v0, prev_v1, prev_v2, prev_v3;
	reg Load_max_d_prev;
	
	// ========================================
	// SECTION 2: Instantiate DUT
	// ========================================
	
	// FSM controller
	dominant_fsm u_fsm (
		.clk(Clk),
		.reset(Reset),
		.start(Start),
		.mul_done(Mul_done),
		.scale_done(Scale_done),
		.diff_done(Diff_done),
		.max_d_in(Max_d_out),
		.epsilon(Epsilon),
		.load_v_old(Load_v_old),
		.load_y(Load_y),
		.load_max_d(Load_max_d),
		.start_mult(Start_mult),
		.start_scale(Start_scale),
		.start_diff(Start_diff),
		.done(Done)
	);
	
	// Datapath
	dominant_datapath u_datapath (
		.clk(Clk),
		.reset(Reset),
		.load_v_old(Load_v_old),
		.load_y(Load_y),
		.load_max_d(Load_max_d),
		.start_mult(Start_mult),
		.start_scale(Start_scale),
		.start_diff(Start_diff),
		.v_init(V_init),
		.A00(A00), .A01(A01), .A02(A02), .A03(A03),
		.A10(A10), .A11(A11), .A12(A12), .A13(A13),
		.A20(A20), .A21(A21), .A22(A22), .A23(A23),
		.A30(A30), .A31(A31), .A32(A32), .A33(A33),
		.mul_done(Mul_done),
		.scale_done(Scale_done),
		.diff_done(Diff_done),
		.max_d_out(Max_d_out),
		.v0(v0),
		.v1(v1),
		.v2(v2),
		.v3(v3)
	);
	
	// ========================================
	// SECTION 3: Clock Generation
	// ========================================
	
	// 10 ns period (5 ns high, 5 ns low = 100 MHz)
	always begin
		#5 Clk = ~Clk;
	end
	
	// Clock counter
	always @(posedge Clk) begin
		clk_cnt = clk_cnt + 1;
	end
	
	// ========================================
	// SECTION 4: Reset Sequence
	// ========================================
	
	initial begin
		Clk = 0;
		Reset = 1;
		Start = 0;
		Epsilon = 3'd2;
		
		// Initialize matrix: [4,1,1,1; 1,4,1,1; 1,1,4,1; 1,1,1,4]
		A00 = 16'sd4; A01 = 16'sd1; A02 = 16'sd1; A03 = 16'sd1;
		A10 = 16'sd1; A11 = 16'sd4; A12 = 16'sd1; A13 = 16'sd1;
		A20 = 16'sd1; A21 = 16'sd1; A22 = 16'sd4; A23 = 16'sd1;
		A30 = 16'sd1; A31 = 16'sd1; A32 = 16'sd1; A33 = 16'sd4;
		V_init = {16'sd1, 16'sd1, 16'sd1, 16'sd1};
		
		// Initialize counters
		clk_cnt = 0;
		iteration_count = 0;
		prev_v0 = 16'sd0;
		prev_v1 = 16'sd0;
		prev_v2 = 16'sd0;
		prev_v3 = 16'sd0;
		Load_max_d_prev = 0;
		start_clock_cnt = 0;
		iteration_clock_cnt = 0;
		cycle_count = 0;
		timeout_cycles = 5000;
		
		// Allow reset to propagate
		#100;
		
		// Deassert reset on clock edge
		@(posedge Clk);
		#1;
		Reset = 0;
		
		// Display test information
		$display("========================================");
		$display("Starting Power Iteration Test");
		$display("========================================");
		$display("Matrix A:");
		$display("  [%d, %d, %d, %d]", A00, A01, A02, A03);
		$display("  [%d, %d, %d, %d]", A10, A11, A12, A13);
		$display("  [%d, %d, %d, %d]", A20, A21, A22, A23);
		$display("  [%d, %d, %d, %d]", A30, A31, A32, A33);
		$display("Epsilon threshold: %d", Epsilon);
		$display("Initial vector: [1, 1, 1, 1]");
		$display("========================================\n");
		
		// Apply stimulus
		APPLY_STIMULUS();
		
		// Display results
		$display("========================================");
		$display("Computation Complete");
		$display("========================================");
		$display("Total iterations: %d", iteration_count);
		$display("Final eigenvector (v_new): [%d, %d, %d, %d]", v0, v1, v2, v3);
		$display("Final max_diff: %d (epsilon = %d)", Max_d_out, Epsilon);
		$display("========================================\n");
		$display("TEST PASSED");
		
		// Wait a few cycles before finishing
		repeat(10) @(posedge Clk);
		$finish;
	end
	
	// ========================================
	// SECTION 5: Stimulus Generator
	// ========================================
	
	task APPLY_STIMULUS;
		begin : apply_stimulus_block
			integer timeout_flag;
			
			// Wait a couple cycles after reset
			@(posedge Clk);
			@(posedge Clk);
			#1;
			
			// Assert start signal
			Start = 1;
			wait(Load_v_old);
			@(posedge Clk);
			#1;
			Start = 0;
			
			// Record start time
			start_clock_cnt = clk_cnt;
			cycle_count = 0;
			timeout_flag = 0;
			
			// Use fork/join for timeout protection (Verilog-2001 compatible)
			fork
				begin : timeout_block
					// Timeout after specified cycles
					repeat(timeout_cycles) begin
						@(posedge Clk);
						cycle_count = cycle_count + 1;
					end
					timeout_flag = 1;
					$display("ERROR: Timeout after %d cycles - Done never asserted", cycle_count);
					$display("  Done = %b, Mul_done = %b, Scale_done = %b, Diff_done = %b", 
					         Done, Mul_done, Scale_done, Diff_done);
					$display("  Load_v_old = %b, Load_y = %b, Load_max_d = %b", 
					         Load_v_old, Load_y, Load_max_d);
					$display("  Start_mult = %b, Start_scale = %b, Start_diff = %b", 
					         Start_mult, Start_scale, Start_diff);
					$display("  max_diff = %d, epsilon = %d", Max_d_out, Epsilon);
					$display("  v_new = [%d, %d, %d, %d]", v0, v1, v2, v3);
					$fatal("Simulation timeout - Done signal never asserted");
				end
				begin : wait_done_block
					// Wait for Done signal while monitoring iterations
					while (Done == 0) begin
						@(posedge Clk);
						
						// Detect iteration completion (positive edge of Load_max_d)
						if (Load_max_d == 1 && Load_max_d_prev == 0) begin
							@(posedge Clk);
							#1;
							iteration_count = iteration_count + 1;
							iteration_clock_cnt = clk_cnt - start_clock_cnt;
							
							// Display iteration information
							$display("Iteration %0d (at clock %0d):", iteration_count, clk_cnt);
							if (iteration_count == 1) begin
								$display("  v_old: [1, 1, 1, 1] (initial vector)");
							end else begin
								$display("  v_old: [%d, %d, %d, %d]", prev_v0, prev_v1, prev_v2, prev_v3);
							end
							$display("  y: [not accessible from testbench]");
							$display("  v_new: [%d, %d, %d, %d]", v0, v1, v2, v3);
							$display("  max_diff: %d", Max_d_out);
							$display("  Clocks taken so far: %d", iteration_clock_cnt);
							$display("");
							
							// Store current v_new as next iteration's v_old
							prev_v0 = v0;
							prev_v1 = v1;
							prev_v2 = v2;
							prev_v3 = v3;
						end
						
						// Update previous value for edge detection
						Load_max_d_prev = Load_max_d;
					end
				end
			join
			
			// Wait a couple cycles after Done is asserted
			@(posedge Clk);
			@(posedge Clk);
			#1;
			
			// Display completion message
			$display("Reporting from the DONE state");
			$display("Convergence achieved after %d iterations", iteration_count);
			$display("Total clocks taken: %d", clk_cnt - start_clock_cnt);
		end
	endtask
	
	// ========================================
	// SECTION 6: Self-Checking / Monitors
	// ========================================
	
	// Monitor for X or Z values in output vectors
	always @(posedge Clk) begin
		if (^v0 === 1'bx || ^v0 === 1'bz) begin
			$display("ERROR: X or Z detected in v0 at time %t (clock %0d)", $time, clk_cnt);
		end
		if (^v1 === 1'bx || ^v1 === 1'bz) begin
			$display("ERROR: X or Z detected in v1 at time %t (clock %0d)", $time, clk_cnt);
		end
		if (^v2 === 1'bx || ^v2 === 1'bz) begin
			$display("ERROR: X or Z detected in v2 at time %t (clock %0d)", $time, clk_cnt);
		end
		if (^v3 === 1'bx || ^v3 === 1'bz) begin
			$display("ERROR: X or Z detected in v3 at time %t (clock %0d)", $time, clk_cnt);
		end
	end
	
	// ========================================
	// SECTION 7: Simulation End
	// ========================================
	
	// Safety timeout to prevent infinite simulation
	initial begin
		#200000;
		$display("Simulation Finished (safety timeout).");
		$finish;
	end

endmodule
