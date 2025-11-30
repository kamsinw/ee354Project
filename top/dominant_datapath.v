`timescale 1ns / 1ps

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

    wire signed [16*16-1:0] A;
    assign A = {A33, A32, A31, A30, A23, A22, A21, A20, A13, A12, A11, A10, A03, A02, A01, A00};

    wire signed [4*16-1:0] v_old;
    wire signed [4*16-1:0] v_new;
    wire signed [4*16-1:0] y_vec;
    reg signed [4*16-1:0] y_reg;
    reg first_iter;
    
    wire signed [4*16-1:0] init_vec = {16'sd1, 16'sd1, 16'sd1, 16'sd1};
    wire signed [4*16-1:0] v_old_in = first_iter ? init_vec : v_new;
    
    always @(posedge clk) begin
        if (reset) begin
            first_iter <= 1'b1;
            y_reg <= 64'd0;
        end else begin
            if (load_v_old) begin
                first_iter <= 1'b0;
            end
            if (load_y) begin
                y_reg <= y_vec;
            end
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
        .reset(reset),
        .start(start_mult),
        .A(A),
        .V(v_old),
        .Y(y_vec),
        .done(mul_done)
    );

    vector_scale #(.WIDTH(16)) vscale (
        .clk(clk),
        .reset(reset),
        .start(start_scale),
        .V_in(y_reg),
        .V_out(v_new),
        .done(scale_done)
    );

    vector_diff vdiff (
        .clk(clk),
        .reset(reset),
        .start(start_diff),
        .V_new(v_new),
        .V_old(v_old),
        .max_diff(max_d_out),
        .done(diff_done)
    );

    assign v0 = v_new[15:0];
    assign v1 = v_new[31:16];
    assign v2 = v_new[47:32];
    assign v3 = v_new[63:48];

endmodule
