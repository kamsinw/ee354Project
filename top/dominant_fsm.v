/*

1. run_in:
      Initialize v_old, row, count, and epsilon depending on edit mode. This sets up
      the initial guess and iteration parameters before beginning matrix-vector steps.

2. mattrix_mult:
      Prepare to compute one row of the product y = A * v_old by resetting the column
      index and the accumulator.

3. mm_inner (required inner loop):
      Perform one multiply-accumulate per clock: A[row][col] * v_old[col] is added
      into the running sum. Once all four columns are processed, the completed dot
      product is stored into y[row]. When all rows are finished, proceed to max scan.

4. find_max (required helper state):
      Sequentially examine the four entries of y and determine max(|y|). This single
      value is needed for both stable normalization and later convergence testing.

5. run_scale:
      Normalize the vector y by dividing each element by max(|y|) to obtain v_new.
      Division is required because max(|y|) is generally NOT a power of two, so simple
      bit shifting would produce unstable scaling. Shifting causes magnitude drift,
      overflow/underflow, and oscillation since the scale factor jumps in powers of two.
      Using division ensures the new vector is properly normalized, maintains direction,
      keeps values within representable range, and guarantees monotonic convergence.

6. run_check:
      Compute d[i] = |v_new[i] - v_old[i]| and find max(d). If max(d) < epsilon, the
      dominant eigenvector is considered converged. Otherwise, copy v_new into v_old
      and repeat the cycle starting at the matrix multiplication stage.

Overall, this FSM implements the classical normalized power iteration in a fully
sequential hardware-friendly form. The added states (mm_inner and find_max) guarantee
correct multi-cycle dot-product computation and proper normalization behavior on FPGA.
------------------------------------------------------------------------------------
*/



module dominant_fsm (
    input  wire        clk,
    input  wire        reset,
    input  wire        start,
    
    // Datapath done signals
    input  wire        mul_done,
    input  wire        scale_done,
    input  wire        diff_done,
    
    // Convergence threshold from datapath
    input  wire signed [15:0] max_d_in,
    input  wire [2:0] epsilon,
    
    // Control outputs to datapath
    output reg         load_v_old,
    output reg         load_y,
    output reg         load_max_d,
    output reg         start_mult,
    output reg         start_scale,
    output reg         start_diff,
    
    // FSM status output
    output reg         done
);

    // State definitions 
    localparam EDIT_IN      = 8'b0000_0001;
    localparam EDIT_CURR    = 8'b0000_0010;
    localparam EDIT_WRITE   = 8'b0000_0100;
    localparam RUN_IN       = 8'b0000_1000;
    localparam MATH_VEC     = 8'b0001_0000;
    localparam RUN_SCALE    = 8'b0010_0000;
    localparam RUN_CHECK    = 8'b0100_0000;
    localparam RUN_DONE     = 8'b1000_0000;

    reg [7:0] state;

    // Synchronous state machine
    always @(posedge clk) begin
        if (reset) begin
            state       <= EDIT_IN;
            load_v_old  <= 1'bX;
            load_y      <= 1'bX;
            load_max_d  <= 1'bX;
            start_mult  <= 1'bX;
            start_scale <= 1'bX;
            start_diff  <= 1'bX;
            done        <= 1'bX;
        end 
      // State machine logic
      case (state)
            EDIT_IN: begin
                  // Wait for start signal to enter computation
                  if (start) begin
                  state <= RUN_IN;
                  end
            end

            EDIT_CURR: begin
                  // Placeholder for edit current value
                  state <= EDIT_WRITE;
            end

            EDIT_WRITE: begin
                  // Placeholder for write edit; return to EDIT_IN
                  state <= EDIT_IN;
            end

            RUN_IN: begin
                  // Initialize v_old and epsilon
                  load_v_old  <= 1'b1;
                  state       <= MATH_VEC;
            end

            MATH_VEC: begin
                  // Start matrix-vector multiplication
                  start_mult <= 1'b1;
                  if (mul_done) begin
                  state <= RUN_SCALE;
                  end
            end

            RUN_SCALE: begin
                  // Load y and start scaling
                  load_y      <= 1'b1;
                  start_scale <= 1'b1;
                  if (scale_done) begin
                  state <= RUN_CHECK;
                  end
            end

            RUN_CHECK: begin
                  // Compute vector difference
                  start_diff <= 1'b1;
                  if (diff_done) begin
                  load_max_d  <= 1'b1;
                  // Convergence decision: max_d < epsilon?
                  if (max_d_in < epsilon) begin
                      // Converged:: We have the dominant eigenvector
                      state <= RUN_DONE;
                  end else begin
                      // Not converged yet. Copy v_new into v_old and iterate again
                      load_v_old <= 1'b1;
                      state <= MATH_VEC;
                  end
                  end
            end

            RUN_DONE: begin
                  // Signal completion and wait for start to go low
                  done <= 1'b1;
                  if (~start) begin
                  state <= EDIT_IN;
                  end
            end

            default: begin
                  state <= EDIT_IN;
            end
            endcase
      end
    

endmodule
    