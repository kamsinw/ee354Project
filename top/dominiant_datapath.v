/*
    Data path for 4x4 dominant eigenvector using the power iteration algo.
    Contains all arithmetic modules and storage elements


    The controller(dominant_fsm.v) will drive:
    -load v_old, load_y, load_v_new, load_d
    -row, col counters
    -start_mult,start_scale, start_diff
    -done flags

*/

module dominant_datapath #(
    parameter WIDTH = 8
) (
    input wire clk,
    input wire reset,
    input wire load_v_old,
    input wire load_y,
    input wire load_max_d,
    input wire start_mult, start_scale, start_diff,
    // matrix scalar inputs (top provides 16-bit matrix entries) - we'll take low WIDTH bits
    input signed [15:0] A00, A01, A02, A03,
    input signed [15:0] A10, A11, A12, A13,
    input signed [15:0] A20, A21, A22, A23,
    input signed [15:0] A30, A31, A32, A33,
    // expose scaled vector outputs as 16-bit sign-extended values for top compatibility
    output signed [15:0] v0,
    output signed [15:0] v1,
    output signed [15:0] v2,
    output signed [15:0] v3,
    output signed [15:0] max_d_out
);

    // Build packed A bus from scalar inputs, taking low WIDTH bits of each scalar
    wire signed [16*WIDTH-1:0] A_packed = {
        A33[WIDTH-1:0], A32[WIDTH-1:0], A31[WIDTH-1:0], A30[WIDTH-1:0],
        A23[WIDTH-1:0], A22[WIDTH-1:0], A21[WIDTH-1:0], A20[WIDTH-1:0],
        A13[WIDTH-1:0], A12[WIDTH-1:0], A11[WIDTH-1:0], A10[WIDTH-1:0],
        A03[WIDTH-1:0], A02[WIDTH-1:0], A01[WIDTH-1:0], A00[WIDTH-1:0]
    };

    // Packed vectors for v_old, v_new, y_vec
    wire signed [4*WIDTH-1:0] v_old_packed;
    wire signed [4*WIDTH-1:0] v_new_packed;
    wire signed [4*WIDTH-1:0] y_vec_packed;

    wire mul_done;
    wire scale_done;
    wire diff_done;

    wire signed [WIDTH-1:0] max_d;

    reg signed [4*WIDTH-1:0] y_reg;
    reg signed [WIDTH-1:0] max_d_reg;

    // vector register stores v_new into v_old
    vector_register #(WIDTH) vreg_old(
        .clk(clk),
        .reset(reset),
        .load(load_v_old),
        .in(v_new_packed),
        .out(v_old_packed)
    );

    matrix_vector_mult #(.WIDTH(WIDTH)) matmul (
        .clk(clk),
        .reset(reset),
        .start(start_mult),
        .A(A_packed),
        .V(v_old_packed),
        .Y(y_vec_packed),
        .done(mul_done)
    );

    always @(posedge clk) begin
        if (reset) begin
            y_reg <= {(4*WIDTH){1'b0}};
        end else if (load_y) begin
            y_reg <= y_vec_packed;
        end
    end

    vector_scale #(.WIDTH(WIDTH)) vscale (
        .clk(clk),
        .reset(reset),
        .start(start_scale),
        .V_in(y_reg),
        .V_out(v_new_packed),
        .done(scale_done)
    );

    // Vector difference and max
    vector_diff #(.WIDTH(WIDTH)) vdiff (
        .clk(clk),
        .reset(reset),
        .start(start_diff),
        .V_new(v_new_packed),
        .V_old(v_old_packed),
        .max_diff(max_d),
        .done(diff_done)
    );

    always @(posedge clk) begin
        if (reset) begin
            max_d_reg <= {WIDTH{1'b0}};
        end else if (load_max_d) begin
            max_d_reg <= max_d;
        end
    end

    // expose v_new outputs to module outputs, sign-extended to 16 bits for top
    wire signed [WIDTH-1:0] v_new_0 = v_new_packed[WIDTH-1:0];
    wire signed [WIDTH-1:0] v_new_1 = v_new_packed[2*WIDTH-1:WIDTH];
    wire signed [WIDTH-1:0] v_new_2 = v_new_packed[3*WIDTH-1:2*WIDTH];
    wire signed [WIDTH-1:0] v_new_3 = v_new_packed[4*WIDTH-1:3*WIDTH];

    assign v0 = {{(16-WIDTH){v_new_0[WIDTH-1]}}, v_new_0};
    assign v1 = {{(16-WIDTH){v_new_1[WIDTH-1]}}, v_new_1};
    assign v2 = {{(16-WIDTH){v_new_2[WIDTH-1]}}, v_new_2};
    assign v3 = {{(16-WIDTH){v_new_3[WIDTH-1]}}, v_new_3};

    // sign-extend max_d_reg to 16 bits for FSM input
    assign max_d_out = {{(16-WIDTH){max_d_reg[WIDTH-1]}}, max_d_reg};

endmodule
