`timescale 1ns / 1ps

module dominant_datapath #(
    parameter integer WIDTH = 8
) (
    input  wire                     clk,
    input  wire                     reset,
    input  wire                     load_v_old,
    input  wire                     load_y,
    input  wire                     load_max_d,
    input  wire                     start_mult,
    input  wire                     start_scale,
    input  wire                     start_diff,
    input  wire signed [15:0]       A00, A01, A02, A03,
    input  wire signed [15:0]       A10, A11, A12, A13,
    input  wire signed [15:0]       A20, A21, A22, A23,
    input  wire signed [15:0]       A30, A31, A32, A33,
    output wire signed [15:0]       v0,
    output wire signed [15:0]       v1,
    output wire signed [15:0]       v2,
    output wire signed [15:0]       v3,
    output wire signed [15:0]       max_d_out
);

    wire signed [16*WIDTH-1:0] matrix_bus = {
        A33[WIDTH-1:0], A32[WIDTH-1:0], A31[WIDTH-1:0], A30[WIDTH-1:0],
        A23[WIDTH-1:0], A22[WIDTH-1:0], A21[WIDTH-1:0], A20[WIDTH-1:0],
        A13[WIDTH-1:0], A12[WIDTH-1:0], A11[WIDTH-1:0], A10[WIDTH-1:0],
        A03[WIDTH-1:0], A02[WIDTH-1:0], A01[WIDTH-1:0], A00[WIDTH-1:0]
    };

    wire signed [4*WIDTH-1:0] v_old_packed;
    wire signed [4*WIDTH-1:0] v_new_packed;
    wire signed [4*WIDTH-1:0] y_vec_packed;

    wire                      mul_done;
    wire                      scale_done;
    wire                      diff_done;
    wire signed [WIDTH-1:0]   max_diff_wire;

    reg  signed [4*WIDTH-1:0] y_reg;
    reg  signed [WIDTH-1:0]   max_diff_reg;

    vector_register #(.ELEM_WIDTH(WIDTH)) vreg_old (
        .clk    (clk),
        .reset  (reset),
        .load   (load_v_old),
        .vec_in (v_new_packed),
        .vec_out(v_old_packed)
    );

    matrix_vector_mult #(.OUT_WIDTH(WIDTH)) matmul (
        .clk  (clk),
        .reset(reset),
        .start(start_mult),
        .A    (matrix_bus),
        .V    (v_old_packed),
        .Y    (y_vec_packed),
        .done (mul_done)
    );

    always @(posedge clk) begin
        if (reset) begin
            y_reg <= {(4*WIDTH){1'b0}};
        end else if (load_y) begin
            y_reg <= y_vec_packed;
        end
    end

    // bug:fix(ollie) Legacy variant lacks norm input; keep unused with caution
    vector_scale #(.IN_WIDTH(WIDTH)) vscale (
        .clk  (clk),
        .reset(reset),
        .start(start_scale),
        .V_in (y_reg),
        .V_out(v_new_packed),
        .done (scale_done)
    );

    vector_diff #(.WIDTH(WIDTH)) vdiff (
        .clk     (clk),
        .reset   (reset),
        .start   (start_diff),
        .vec_new (v_new_packed),
        .vec_old (v_old_packed),
        .max_diff(max_diff_wire),
        .done    (diff_done)
    );

    always @(posedge clk) begin
        if (reset) begin
            max_diff_reg <= {WIDTH{1'b0}};
        end else if (load_max_d) begin
            max_diff_reg <= max_diff_wire;
        end
    end

    wire signed [WIDTH-1:0] v_lane0 = v_new_packed[WIDTH-1:0];
    wire signed [WIDTH-1:0] v_lane1 = v_new_packed[2*WIDTH-1:WIDTH];
    wire signed [WIDTH-1:0] v_lane2 = v_new_packed[3*WIDTH-1:2*WIDTH];
    wire signed [WIDTH-1:0] v_lane3 = v_new_packed[4*WIDTH-1:3*WIDTH];

    assign v0 = {{(16-WIDTH){v_lane0[WIDTH-1]}}, v_lane0};
    assign v1 = {{(16-WIDTH){v_lane1[WIDTH-1]}}, v_lane1};
    assign v2 = {{(16-WIDTH){v_lane2[WIDTH-1]}}, v_lane2};
    assign v3 = {{(16-WIDTH){v_lane3[WIDTH-1]}}, v_lane3};
    assign max_d_out = {{(16-WIDTH){max_diff_reg[WIDTH-1]}}, max_diff_reg};

endmodule
