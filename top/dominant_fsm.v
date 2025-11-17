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



module dominant_fsm #(

)(
    input wire clk,
    input wire start,
     input wire reset,

);

    