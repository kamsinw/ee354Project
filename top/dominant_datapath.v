`timescale 1ns / 1ps

module dominant_datapath #(
    parameter integer Y_WIDTH   = 12,
    parameter integer SCALE_OUT = 4
) (
    input  wire        clk,
    input  wire        reset,
    input  wire        load_v_old,
    input  wire        load_y,
    input  wire        load_max_d,
    input  wire        start_mult,
    input  wire        start_scale,
    input  wire        start_diff,
    input  wire [4*4-1:0] v_init,
    input  wire [3:0] A00, A01, A02, A03,
    input  wire [3:0] A10, A11, A12, A13,
    input  wire [3:0] A20, A21, A22, A23,
    input  wire [3:0] A30, A31, A32, A33,
    output wire        mul_done,
    output wire        scale_done,
    output wire        diff_done,
    output wire [3:0]  max_d_out,
    output wire [3:0]  v0,
    output wire [3:0]  v1,
    output wire [3:0]  v2,
    output wire [3:0]  v3,
    output wire [3:0]  v_old0,
    output wire [3:0]  v_old1,
    output wire [3:0]  v_old2,
    output wire [3:0]  v_old3,
    output wire        v_new_valid_out,
    output wire [4*Y_WIDTH-1:0] y_out,
    output wire [Y_WIDTH-1:0]   norm_out,
    output wire [4*SCALE_OUT-1:0] v_new_out
);
    

    wire [16*4-1:0] A;
    assign A = {A33, A32, A31, A30, A23, A22, A21, A20, A13, A12, A11, A10, A03, A02, A01, A00};

    wire [4*4-1:0]   v_old;
    wire [4*SCALE_OUT-1:0]   v_new_internal;
    wire [4*Y_WIDTH-1:0] y_vec;
    reg  [4*Y_WIDTH-1:0] y_reg;
    reg first_iter;
    
    wire [4*4-1:0] init_vec = v_init;
    wire [4*4-1:0] v_old_in = first_iter ? init_vec : v_new_reg;
    
    wire [3:0] max_diff_raw;
    reg [3:0] max_d_reg;
    
    always @(posedge clk) begin
        if (reset) begin
            first_iter <= 1'b1;
            y_reg <= {(4*Y_WIDTH){1'b0}};
            max_d_reg <= 4'd0;
        end else begin
            if (load_v_old) begin
                first_iter <= 1'b0;
            end
            if (load_y) begin
                y_reg <= y_vec;
            end
            if (load_max_d) begin
                max_d_reg <= max_diff_raw;
            end
        end
    end

    assign max_d_out = max_d_reg;

    vector_register vreg_old (
        .clk(clk),
        .reset(reset),
        .load(load_v_old),
        .in(v_old_in),
        .out(v_old)
    );

    matrix_vector_mult #(.OUT_WIDTH(Y_WIDTH)) matmul (
        .clk(clk),
        .reset(reset),
        .start(start_mult),
        .A(A),
        .V(v_old),
        .Y(y_vec),
        .done(mul_done)
    );

    wire [Y_WIDTH-1:0] norm_value;
    wire norm_done;
    reg  norm_start;
    reg  scale_div_start;
    reg [1:0] scale_state;
    reg scale_done_reg;
    localparam SCALE_IDLE = 2'd0;
    localparam SCALE_NORM = 2'd1;
    localparam SCALE_DIV  = 2'd2;

    vector_norm_l2 #(.WIDTH(Y_WIDTH)) vnorm (
        .clk(clk),
        .reset(reset),
        .start(norm_start),
        .V_in(y_reg),
        .norm_out(norm_value),
        .done(norm_done)
    );

    wire scale_div_done;
    reg [4*SCALE_OUT-1:0] v_new_reg;
    reg v_new_valid;

    vector_scale #(.IN_WIDTH(Y_WIDTH), .OUT_WIDTH(SCALE_OUT), .NORM_WIDTH(Y_WIDTH)) vscale (
        .clk(clk),
        .reset(reset),
        .start(scale_div_start),
        .V_in(y_reg),
        .norm_value(norm_value),
        .V_out(v_new_internal),
        .done(scale_div_done)
    );

    assign scale_done = scale_done_reg;

    always @(posedge clk) begin
        if (reset) begin
            scale_state     <= SCALE_IDLE;
            norm_start      <= 1'b0;
            scale_div_start <= 1'b0;
            scale_done_reg  <= 1'b0;
            v_new_reg       <= {(4*SCALE_OUT){1'b0}};
            v_new_valid     <= 1'b0;
        end else begin
            norm_start      <= 1'b0;
            scale_div_start <= 1'b0;
            scale_done_reg  <= 1'b0;
            case (scale_state)
                SCALE_IDLE: begin
                    if (start_scale) begin
                        norm_start  <= 1'b1;
                        v_new_valid <= 1'b0;
                        scale_state <= SCALE_NORM;
                    end
                end
                SCALE_NORM: begin
                    if (norm_done) begin
                        scale_div_start <= 1'b1;
                        scale_state     <= SCALE_DIV;
                    end
                end
                SCALE_DIV: begin
                    if (scale_div_done) begin
                        v_new_reg      <= v_new_internal;
                        v_new_valid    <= 1'b1;
                        scale_done_reg <= 1'b1;
                        scale_state    <= SCALE_IDLE;
                    end
                end
            endcase
        end
    end

    vector_diff #(.WIDTH(4)) vdiff (
        .clk(clk),
        .reset(reset),
        .start(start_diff),
        .V_new(v_new_reg),
        .V_old(v_old),
        .max_diff(max_diff_raw),
        .done(diff_done)
    );

    assign v0 = v_new_reg[3:0];
    assign v1 = v_new_reg[7:4];
    assign v2 = v_new_reg[11:8];
    assign v3 = v_new_reg[15:12];
    assign v_new_valid_out = v_new_valid;
    assign y_out   = y_reg;
    assign norm_out = norm_value;
    assign v_new_out = v_new_reg;
    
    assign v_old0 = v_old[3:0];
    assign v_old1 = v_old[7:4];
    assign v_old2 = v_old[11:8];
    assign v_old3 = v_old[15:12];

endmodule
