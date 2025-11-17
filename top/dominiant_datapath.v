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
    input wire load_v_new,
    input wire load_d,
    input wire load_max_y
    input wire load_max_d,


    input wire [1:0] row,
    input wire [1:0] col,

    input wire start_mult, start_scale, start_diff, 
    

    input wire [2:0] epsilon,

    input signed [15:0] A00, A01, A02, A03,
    input signed [15:0] A10, A11, A12, A13,
    input signed [15:0] A20, A21, A22, A23,
    input signed [15:0] A30, A31, A32, A33,

    output signed [63:0] v0,
    output signed [63:0] v1,
    output signed [63:0] v2,
    output signed [63:0] v3
);


wire signed  [15:0] A[0:3][0:3];

assign A[0][0] = A00; assign A[0][1] = A01;
assign A[0][2] = A02; assign A[0][3] = A03;
assign A[1][0] = A10; assign A[1][1] = A11;
assign A[1][2] = A12; assign A[1][3] = A13;
assign A[2][0] = A20; assign A[2][1] = A21;
assign A[2][2] = A22; assign A[2][3] = A23;
assign A[3][0] = A30; assign A[3][1] = A31;
assign A[3][2] = A32; assign A[3][3] = A33;


wire signed [63:0] v_old[0:3];
wire signed [63:0] v_new[0:3];
wire signed [63:0] y_vec[0:3];
wire signed [63:0] d_vec[0:3];

wire signed [63:0] max_y;
wire signed [63:0] max_d;

wire mul_done

vector_register vreg_old(
    .clk(clk)
    .reset(reset)
    .load(load_v_old)
    .in(v_new)
    .out(v_old)

);

matrix_vector_mult matmul (
    .clk(clk)
    .reset(reset)
    .start(start_mult)
    .A(A)
    .V(v_old)
    .Y(y_vec)
    .done(mul_done)
);
wire max_y_done;





