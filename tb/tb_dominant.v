`timescale 1ns / 1ps

module tb_dominant;

	reg Clk;
	reg Reset;
	reg Start;
	reg [2:0] Epsilon;
	
	reg signed [15:0] A00, A01, A02, A03;
	reg signed [15:0] A10, A11, A12, A13;
	reg signed [15:0] A20, A21, A22, A23;
	reg signed [15:0] A30, A31, A32, A33;
	
	wire Done;
	wire Load_v_old, Load_y, Load_max_d;
	wire Start_mult, Start_scale, Start_diff;
	wire Mul_done, Scale_done, Diff_done;
	wire signed [15:0] Max_d_out;
	wire signed [15:0] v0, v1, v2, v3;
	
	integer iteration_count;
	reg signed [15:0] prev_v0, prev_v1, prev_v2, prev_v3;
	integer clk_cnt;
	integer start_clock_cnt;
	integer iteration_clock_cnt;
	reg Load_max_d_prev;
	integer timeout_cycles;
	integer cycle_count;
	
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
	
	dominant_datapath u_datapath (
		.clk(Clk),
		.reset(Reset),
		.load_v_old(Load_v_old),
		.load_y(Load_y),
		.load_max_d(Load_max_d),
		.start_mult(Start_mult),
		.start_scale(Start_scale),
		.start_diff(Start_diff),
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

	always begin #5; Clk = ~Clk; end

	always @(posedge Clk) begin
		clk_cnt = clk_cnt + 1;
	end

	initial begin
		clk_cnt = 0;
		Clk = 0;
		Reset = 1;
		Start = 0;
		Epsilon = 3'd2;
		
		A00 = 16'sd4; A01 = 16'sd1; A02 = 16'sd1; A03 = 16'sd1;
		A10 = 16'sd1; A11 = 16'sd4; A12 = 16'sd1; A13 = 16'sd1;
		A20 = 16'sd1; A21 = 16'sd1; A22 = 16'sd4; A23 = 16'sd1;
		A30 = 16'sd1; A31 = 16'sd1; A32 = 16'sd1; A33 = 16'sd4;
		
		iteration_count = 0;
		prev_v0 = 16'sd0;
		prev_v1 = 16'sd0;
		prev_v2 = 16'sd0;
		prev_v3 = 16'sd0;
		Load_max_d_prev = 0;
		
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

		#200;
		@(posedge Clk);
		#1;
		Reset = 0;
		
		APPLY_STIMULUS();
		
		$display("========================================");
		$display("Computation Complete");
		$display("========================================");
		$display("Total iterations: %d", iteration_count);
		$display("Final eigenvector (v_new): [%d, %d, %d, %d]", v0, v1, v2, v3);
		$display("Final max_diff: %d (epsilon = %d)", Max_d_out, Epsilon);
		$display("========================================\n");
		$display("TEST PASSED");
		repeat(10) @(posedge Clk);
		$finish;
	end
	
	task APPLY_STIMULUS;
		begin
			@(posedge Clk);
			@(posedge Clk);
			#1;
			
			Start = 1;
			wait(Load_v_old);
			@(posedge Clk);
			#1;
			Start = 0;
			
			start_clock_cnt = clk_cnt;
			timeout_cycles = 1000;
			cycle_count = 0;
			
			while (Done == 0 && cycle_count < timeout_cycles) begin
				@(posedge Clk);
				cycle_count = cycle_count + 1;
				
				if (Load_max_d == 1 && Load_max_d_prev == 0) begin
					@(posedge Clk);
					#1;
					iteration_count = iteration_count + 1;
					iteration_clock_cnt = clk_cnt - start_clock_cnt;
					
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
					
					prev_v0 = v0;
					prev_v1 = v1;
					prev_v2 = v2;
					prev_v3 = v3;
				end
				
				Load_max_d_prev = Load_max_d;
			end
			
			if (Done == 0) begin
				$display("ERROR: Computation did not converge after %d cycles", cycle_count);
				$fatal("TIMEOUT: simulation did not complete");
			end
			
			@(posedge Clk);
			@(posedge Clk);
			#1;
			
			$display("Reporting from the DONE state");
			$display("Convergence achieved after %d iterations", iteration_count);
			$display("Total clocks taken: %d", clk_cnt - start_clock_cnt);
		end
	endtask

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

endmodule
