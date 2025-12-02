`timescale 1ns / 1ps

module dominant_datapath #(
    parameter integer Y_WIDTH   = 12,
    parameter integer SCALE_OUT = 4
) (
    input  wire                     clk,
    input  wire                     reset,
    input  wire                     load_v_old,
    input  wire                     load_y,
    input  wire                     load_max_d,
    input  wire                     start_mult,
    input  wire                     start_scale,
    input  wire                     start_diff,
    input  wire [4*4-1:0]           v_init,
    input  wire [3:0]               A00, A01, A02, A03,
    input  wire [3:0]               A10, A11, A12, A13,
    input  wire [3:0]               A20, A21, A22, A23,
    input  wire [3:0]               A30, A31, A32, A33,
    output wire                     mul_done,
    output wire                     scale_done,
    output wire                     diff_done,
    output wire [3:0]               max_d_out,
    output wire [3:0]               v0,
    output wire [3:0]               v1,
    output wire [3:0]               v2,
    output wire [3:0]               v3,
    output wire [3:0]               v_old0,
    output wire [3:0]               v_old1,
    output wire [3:0]               v_old2,
    output wire [3:0]               v_old3,
    output wire                     v_new_valid_out,
    output wire [4*Y_WIDTH-1:0]     y_out,
    output wire [Y_WIDTH+1:0]       norm_out,
    output wire [4*SCALE_OUT-1:0]   v_new_out
);

    localparam integer LANE_WIDTH   = 4;
    localparam integer VECTOR_WIDTH = 4 * LANE_WIDTH;
    localparam integer MATRIX_WIDTH = 16 * LANE_WIDTH;
    localparam integer NORM_WIDTH   = Y_WIDTH + 2;

    wire [MATRIX_WIDTH-1:0] matrix_bus = {
        A33, A32, A31, A30,
        A23, A22, A21, A20,
        A13, A12, A11, A10,
        A03, A02, A01, A00
    };

    reg  first_iter_q;
    reg  first_iter_d;
    reg  [4*Y_WIDTH-1:0] y_q;
    reg  [4*Y_WIDTH-1:0] y_d;
    reg  [3:0]           max_diff_q;
    reg  [3:0]           max_diff_d;

    reg  [1:0]           scale_state_q;
    reg  [1:0]           scale_state_d;
    reg                  norm_start_q;
    reg                  norm_start_d;
    reg                  scale_start_q;
    reg                  scale_start_d;
    reg                  scale_done_q;
    reg                  scale_done_d;
    reg  [4*SCALE_OUT-1:0] v_new_q;
    reg  [4*SCALE_OUT-1:0] v_new_d;
    reg                  v_new_valid_q;
    reg                  v_new_valid_d;

    localparam [1:0] SCALE_IDLE = 2'd0;
    localparam [1:0] SCALE_NORM = 2'd1;
    localparam [1:0] SCALE_DIV  = 2'd2;

    wire [VECTOR_WIDTH-1:0] v_old_bus;
    wire [VECTOR_WIDTH-1:0] seed_vector     = v_init;
    wire [VECTOR_WIDTH-1:0] feedback_vector = v_new_q[VECTOR_WIDTH-1:0];
    wire [VECTOR_WIDTH-1:0] v_reg_input     = first_iter_q ? seed_vector : feedback_vector;
    // bug:fix(kamsi) vector_register assumes 4-bit lanes; SCALE_OUT != 4 breaks this mux

    vector_register vreg_old (
        .clk    (clk),
        .reset  (reset),
        .load   (load_v_old),
        .vec_in (v_reg_input),
        .vec_out(v_old_bus)
    );

    wire [4*Y_WIDTH-1:0] y_calc;

    matrix_vector_mult #(.OUT_WIDTH(Y_WIDTH)) matmul (
        .clk  (clk),
        .reset(reset),
        .start(start_mult),
        .A    (matrix_bus),
        .V    (v_old_bus),
        .Y    (y_calc),
        .done (mul_done)
    );

    wire [NORM_WIDTH-1:0] norm_value;
    wire                  norm_done;

    vector_norm_l2 #(
        .WIDTH(Y_WIDTH),
        .NORM_WIDTH(NORM_WIDTH)
    ) vnorm (
        .clk     (clk),
        .reset   (reset),
        .start   (norm_start_q),
        .V_in    (y_q),
        .norm_out(norm_value),
        .done    (norm_done)
    );

    wire [4*SCALE_OUT-1:0] scaled_vector;
    wire                   scale_div_done;

    vector_scale #(
        .IN_WIDTH  (Y_WIDTH),
        .OUT_WIDTH (SCALE_OUT),
        .NORM_WIDTH(NORM_WIDTH)
    ) vscale (
        .clk       (clk),
        .reset     (reset),
        .start     (scale_start_q),
        .V_in      (y_q),
        .norm_value(norm_value),
        .V_out     (scaled_vector),
        .done      (scale_div_done)
    );

    wire [3:0] max_diff_raw;

    vector_diff #(.WIDTH(LANE_WIDTH)) vdiff (
        .clk     (clk),
        .reset   (reset),
        .start   (start_diff),
        .vec_new (v_new_q[VECTOR_WIDTH-1:0]),
        .vec_old (v_old_bus),
        .max_diff(max_diff_raw),
        .done    (diff_done)
    );

    always @(*) begin
        first_iter_d = first_iter_q;
        y_d          = y_q;
        max_diff_d   = max_diff_q;

        if (load_v_old) begin
            first_iter_d = 1'b0;
        end

        if (load_y) begin
            y_d = y_calc;
        end

        if (load_max_d) begin
            max_diff_d = max_diff_raw;
        end
    end

    always @(*) begin
        scale_state_d = scale_state_q;
        norm_start_d  = 1'b0;
        scale_start_d = 1'b0;
        scale_done_d  = 1'b0;
        v_new_d       = v_new_q;
        v_new_valid_d = v_new_valid_q;

        case (scale_state_q)
            SCALE_IDLE: begin
                v_new_valid_d = 1'b0;
                if (start_scale) begin
                    norm_start_d  = 1'b1;
                    scale_state_d = SCALE_NORM;
                end
            end

            SCALE_NORM: begin
                if (norm_done) begin
                    scale_start_d = 1'b1;
                    scale_state_d = SCALE_DIV;
                end
            end

            SCALE_DIV: begin
                if (scale_div_done) begin
                    v_new_d       = scaled_vector;
                    v_new_valid_d = 1'b1;
                    scale_done_d  = 1'b1;
                    scale_state_d = SCALE_IDLE;
                end
            end

            default: begin
                scale_state_d = SCALE_IDLE;
            end
        endcase
    end

    always @(posedge clk) begin
        if (reset) begin
            first_iter_q  <= 1'b1;
            y_q           <= {(4*Y_WIDTH){1'b0}};
            max_diff_q    <= 4'd0;
            scale_state_q <= SCALE_IDLE;
            norm_start_q  <= 1'b0;
            scale_start_q <= 1'b0;
            scale_done_q  <= 1'b0;
            v_new_q       <= {(4*SCALE_OUT){1'b0}};
            v_new_valid_q <= 1'b0;
        end else begin
            first_iter_q  <= first_iter_d;
            y_q           <= y_d;
            max_diff_q    <= max_diff_d;
            scale_state_q <= scale_state_d;
            norm_start_q  <= norm_start_d;
            scale_start_q <= scale_start_d;
            scale_done_q  <= scale_done_d;
            v_new_q       <= v_new_d;
            v_new_valid_q <= v_new_valid_d;
        end
    end

    assign scale_done      = scale_done_q;
    assign max_d_out       = max_diff_q;
    assign v_new_valid_out = v_new_valid_q;
    assign y_out           = y_q;
    assign norm_out        = norm_value;
    assign v_new_out       = v_new_q;
    assign {v3, v2, v1, v0} = v_new_q[VECTOR_WIDTH-1:0];
    assign {v_old3, v_old2, v_old1, v_old0} = v_old_bus;

endmodule
