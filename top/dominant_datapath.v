// dominant_datapath.v - Power iteration datapath

module dominant_datapath (
    input  wire        clk,
    input  wire        reset,
    input  wire        load_v_old,
    input  wire        load_y,
    input  wire        load_max_d,
    input  wire        start_mult,
    input  wire        start_scale,
    input  wire        start_diff,
    input  wire signed [15:0] A00, A01, A02, A03,
    input  wire signed [15:0] A10, A11, A12, A13,
    input  wire signed [15:0] A20, A21, A22, A23,
    input  wire signed [15:0] A30, A31, A32, A33,
    output wire        mul_done,
    output wire        scale_done,
    output wire        diff_done,
    output wire signed [15:0] max_d_out,
    output wire signed [15:0] v0,
    output wire signed [15:0] v1,
    output wire signed [15:0] v2,
    output wire signed [15:0] v3
);

    wire signed [15:0] A [0:3][0:3];
    assign A[0][0] = A00; assign A[0][1] = A01; assign A[0][2] = A02; assign A[0][3] = A03;
    assign A[1][0] = A10; assign A[1][1] = A11; assign A[1][2] = A12; assign A[1][3] = A13;
    assign A[2][0] = A20; assign A[2][1] = A21; assign A[2][2] = A22; assign A[2][3] = A23;
    assign A[3][0] = A30; assign A[3][1] = A31; assign A[3][2] = A32; assign A[3][3] = A33;

    wire signed [15:0] v_old [0:3];
    wire signed [15:0] v_new [0:3];
    wire signed [15:0] y_vec [0:3];
    reg signed [15:0] y_reg [0:3];
    reg first_iter;
    
    wire signed [15:0] init_vec [0:3];
    assign init_vec[0] = 16'sd1;
    assign init_vec[1] = 16'sd1;
    assign init_vec[2] = 16'sd1;
    assign init_vec[3] = 16'sd1;
    
    wire signed [15:0] v_old_in [0:3];
    assign v_old_in[0] = first_iter ? init_vec[0] : v_new[0];
    assign v_old_in[1] = first_iter ? init_vec[1] : v_new[1];
    assign v_old_in[2] = first_iter ? init_vec[2] : v_new[2];
    assign v_old_in[3] = first_iter ? init_vec[3] : v_new[3];
    
    always @(posedge clk) begin
        if (reset) begin
            first_iter <= 1'b1;
        end else if (load_v_old) begin
            first_iter <= 1'b0;
        end
    end

    vector_register vreg_old (
        .clk(clk),
        .reset(reset),
        .load(load_v_old),
        .in(v_old_in),
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
        if (reset) begin
            y_reg[0] <= 0;
            y_reg[1] <= 0;
            y_reg[2] <= 0;
            y_reg[3] <= 0;
        end else if (load_y) begin
            y_reg[0] <= y_vec[0];
            y_reg[1] <= y_vec[1];
            y_reg[2] <= y_vec[2];
            y_reg[3] <= y_vec[3];
        end
    end

    vector_scale #(.WIDTH(16)) vscale (
        .clk(clk),
        .start(start_scale),
        .V_in(y_reg),
        .V_out(v_new),
        .done(scale_done)
    );

    vector_diff vdiff (
        .clk(clk),
        .start(start_diff),
        .V_new(v_new),
        .V_old(v_old),
        .max_diff(max_d_out),
        .done(diff_done)
    );

    assign v0 = v_new[0];
    assign v1 = v_new[1];
    assign v2 = v_new[2];
    assign v3 = v_new[3];

endmodule

