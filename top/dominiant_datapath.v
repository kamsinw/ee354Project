/*
    Data path for 4x4 dominant eigenvector using the power iteration algo.
    Contains all arithmetic modules and storage elements


    The controller(dominant_fsm.v) will drive:
    -load v_old, load_y, load_v_new, load_d
    -row, col counters
    -start_mult,start_scale, start_diff
    -done flags

*/

module dominant_datapath( 
    input wire clk,
    input wire reset,
    input wire load_v_old,
    input wire load_y,
    input wire load_max_d,
    input wire start_mult, start_scale, start_diff,
    input signed [15:0] A00, A01, A02, A03,
    input signed [15:0] A10, A11, A12, A13,
    input signed [15:0] A20, A21, A22, A23,
    input signed [15:0] A30, A31, A32, A33,// each element in matrix
    output signed [15:0] v0,
    output signed [15:0] v1,
    output signed [15:0] v2,
    output signed [15:0] v3
);

wire signed  [15:0] A[0:3][0:3];

assign A[0][0] = A00; assign A[0][1] = A01;
assign A[0][2] = A02; assign A[0][3] = A03;
assign A[1][0] = A10; assign A[1][1] = A11;
assign A[1][2] = A12; assign A[1][3] = A13;
assign A[2][0] = A20; assign A[2][1] = A21;
assign A[2][2] = A22; assign A[2][3] = A23;
assign A[3][0] = A30; assign A[3][1] = A31;
assign A[3][2] = A32; assign A[3][3] = A33;// fold into 2d array

// v_old: registered previous-iteration eigenvector (stored from last v_new)
// v_new: newly computed, normalized eigenvector (output of scalar vector_scale)
wire signed [15:0] v_old[0:3];
wire signed [15:0] v_new[0:3];
wire signed [15:0] y_vec[0:3];

wire mul_done;
wire scale_done;
wire diff_done;// done signals

wire signed [15:0] max_d;

reg signed [15:0] y_reg[0:3];
reg signed [15:0] max_d_reg;

vector_register vreg_old(
    .clk(clk),
    .reset(reset),
    .load(load_v_old),
    .in(v_new),
    .out(v_old)
);


matrix_vector_mult matmul (
    .clk(clk),
    .start(start_mult),
    .A(A),
    .V(v_old),
    .Y(y_vec),
    .done(mul_done)
);

always @(posedge clk) begin
    if (load_y) begin
        y_reg[0] <= y_vec[0];
        y_reg[1] <= y_vec[1];
        y_reg[2] <= y_vec[2];
        y_reg[3] <= y_vec[3];
    end
end

vector_scale vscale (
    .clk(clk),
    .start(start_scale),
    .V_in(y_reg),
    .V_out(v_new),
    .done(scale_done)
);

// Vector difference: compute max |v_new - v_old| using array-style ports
vector_diff vdiff (
    .clk(clk),
    .start(start_diff),
    .V_new(v_new),
    .V_old(v_old),
    .max_diff(max_d),
    .done(diff_done)
);

always @(posedge clk) begin
    // capture max_d into an internal register when controller requests it
    if (reset) begin
        max_d_reg <= 0;
    end else if (load_max_d) begin
        max_d_reg <= max_d;
    end
end

// expose v_new outputs to module outputs
assign v0 = v_new[0];
assign v1 = v_new[1];
assign v2 = v_new[2];
assign v3 = v_new[3];
endmodule
