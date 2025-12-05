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
    output wire [Y_WIDTH-1:0]       max_out,
    output wire [4*SCALE_OUT-1:0]   v_new_out
);

    localparam integer LANE_WIDTH   = 4;
    localparam integer VEC_WIDTH = 4 * LANE_WIDTH;
    localparam integer MAT_WIDTH = 16 * LANE_WIDTH;
    localparam integer MAX_WIDTH = Y_WIDTH;

    wire [MAT_WIDTH-1:0] mat_bus = {
        A33, A32, A31, A30,
        A23, A22, A21, A20,
        A13, A12, A11, A10,
        A03, A02, A01, A00
    };

    reg  first_iter_q;
    reg  first_iter_n;
    reg  [4*Y_WIDTH-1:0] y_q;
    reg  [4*Y_WIDTH-1:0] y_n;
    reg  [3:0]           max_diff_q;
    reg  [3:0]           max_diff_n;

    reg  [1:0]           scale_state_q;
    reg  [1:0]           scale_state_n;
    reg                  max_start_q;
    reg                  max_start_n;
    reg                  scale_start_q;
    reg                  scale_start_n;
    reg                  scale_done_q;
    reg                  scale_done_n;
    reg  [4*SCALE_OUT-1:0] v_new_q;
    reg  [4*SCALE_OUT-1:0] v_new_n;
    reg                  v_new_valid_q;
    reg                  v_new_valid_n;

    localparam [1:0] SCALE_IDLE = 2'd0;
    localparam [1:0] SCALE_MAX  = 2'd1;
    localparam [1:0] SCALE_DIV  = 2'd2;

    wire [VEC_WIDTH-1:0] v_old_bus;
    wire [VEC_WIDTH-1:0] seed_vec = v_init;
    wire [VEC_WIDTH-1:0] feedback_vec = v_new_q[VEC_WIDTH-1:0];
    wire [VEC_WIDTH-1:0] v_reg_in = first_iter_q ? seed_vec : feedback_vec;

    vector_register vreg_old (
        .clk    (clk),
        .reset  (reset),
        .load   (load_v_old),
        .vec_in (v_reg_in),
        .vec_out(v_old_bus)
    );

    wire [4*Y_WIDTH-1:0] y_calc;

    matrix_vector_mult #(.OUT_WIDTH(Y_WIDTH)) matmul (
        .clk  (clk),
        .reset(reset),
        .start(start_mult),
        .A    (mat_bus),
        .V    (v_old_bus),
        .Y    (y_calc),
        .done (mul_done)
    );

    wire [MAX_WIDTH-1:0] max_val;
    wire                 max_done;

    vector_max #(.WIDTH(Y_WIDTH)) vmax (
        .clk     (clk),
        .reset   (reset),
        .start   (max_start_q),
        .V_in    (y_q),
        .max_out (max_val),
        .done    (max_done)
    );

    wire [4*SCALE_OUT-1:0] scaled_vec;
    wire                   scale_div_done;

    vector_scale #(
        .IN_WIDTH  (Y_WIDTH),
        .OUT_WIDTH (SCALE_OUT)
    ) vscale (
        .clk       (clk),
        .reset     (reset),
        .start     (scale_start_q),
        .V_in      (y_q),
        .V_out     (scaled_vec),
        .done      (scale_div_done)
    );

    wire [3:0] max_diff_raw;

    vector_diff #(.WIDTH(LANE_WIDTH)) vdiff (
        .clk     (clk),
        .reset   (reset),
        .start   (start_diff),
        .vec_new (v_new_q[VEC_WIDTH-1:0]),
        .vec_old (v_old_bus),
        .max_diff(max_diff_raw),
        .done    (diff_done)
    );

    always @(*) begin
        first_iter_n = first_iter_q;
        y_n          = y_q;
        max_diff_n   = max_diff_q;

        if (load_v_old) begin
            first_iter_n = 1'b0;
        end

        if (load_y) begin
            y_n = y_calc;
        end

        if (load_max_d) begin
            max_diff_n = max_diff_raw;
        end
    end

    always @(*) begin
        scale_state_n = scale_state_q;
        max_start_n   = 1'b0;
        scale_start_n = 1'b0;
        scale_done_n  = 1'b0;
        v_new_n       = v_new_q;
        v_new_valid_n = v_new_valid_q;

        case (scale_state_q)
            SCALE_IDLE: begin
                v_new_valid_n = 1'b0;
                if (start_scale) begin
                    max_start_n   = 1'b1;
                    scale_state_n = SCALE_MAX;
                end
            end

            SCALE_MAX: begin
                if (max_done) begin
                    scale_start_n = 1'b1;
                    scale_state_n = SCALE_DIV;
                end
            end

            SCALE_DIV: begin
                if (scale_div_done) begin
                    v_new_n       = scaled_vec;
                    v_new_valid_n = 1'b1;
                    scale_done_n  = 1'b1;
                    scale_state_n = SCALE_IDLE;
                end
            end

            default: begin
                scale_state_n = SCALE_IDLE;
            end
        endcase
    end

    always @(posedge clk) begin
        if (reset) begin
            first_iter_q  <= 1'b1;
            y_q           <= {(4*Y_WIDTH){1'b0}};
            max_diff_q    <= 4'd0;
            scale_state_q <= SCALE_IDLE;
            max_start_q   <= 1'b0;
            scale_start_q <= 1'b0;
            scale_done_q  <= 1'b0;
            v_new_q       <= {(4*SCALE_OUT){1'b0}};
            v_new_valid_q <= 1'b0;
        end else begin
            first_iter_q  <= first_iter_n;
            y_q           <= y_n;
            max_diff_q    <= max_diff_n;
            scale_state_q <= scale_state_n;
            max_start_q   <= max_start_n;
            scale_start_q <= scale_start_n;
            scale_done_q  <= scale_done_n;
            v_new_q       <= v_new_n;
            v_new_valid_q <= v_new_valid_n;
        end
    end

    assign scale_done      = scale_done_q;
    assign max_d_out       = max_diff_q;
    assign v_new_valid_out = v_new_valid_q;
    assign y_out           = y_q;
    assign max_out         = max_val;
    assign v_new_out       = v_new_q;
    assign {v3, v2, v1, v0} = v_new_q[VEC_WIDTH-1:0];
    assign {v_old3, v_old2, v_old1, v_old0} = v_old_bus;

endmodule
