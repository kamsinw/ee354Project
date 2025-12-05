`timescale 1ns / 1ps

module dominant_fsm (
    input  wire       clk,
    input  wire       reset,
    input  wire       start,
    input  wire       mul_done,
    input  wire       scale_done,
    input  wire       diff_done,
    input  wire [3:0] max_d_in,
    input  wire [2:0] epsilon,
    output reg        load_v_old,
    output reg        load_y,
    output reg        load_max_d,
    output reg        start_mult,
    output reg        start_scale,
    output reg        start_diff,
    output reg        done,
    output wire [7:0] state_out
);

    localparam [7:0] IDLE     = 8'b0000_0001;
    localparam [7:0] LOAD     = 8'b0000_0010;
    localparam [7:0] MULT     = 8'b0000_0100;
    localparam [7:0] WAIT_MAX = 8'b0000_1000;
    localparam [7:0] SCALE    = 8'b0001_0000;
    localparam [7:0] DIFF     = 8'b0010_0000;
    localparam [7:0] CHECK    = 8'b0100_0000;
    localparam [7:0] DONE_ST  = 8'b1000_0000;

    localparam [3:0] MIN_ITER = 4'd3;

    reg [7:0] state_q;
    reg [7:0] state_n;

    reg [1:0] wait_max_q;
    reg [1:0] wait_max_n;

    reg [3:0] iter_q;
    reg [3:0] iter_n;

    reg       mult_busy_q;
    reg       mult_busy_n;

    reg       scale_busy_q;
    reg       scale_busy_n;

    reg       diff_busy_q;
    reg       diff_busy_n;

    reg       start_prev_q;

    wire [3:0] eps_thresh = {1'b0, epsilon};
    wire       start_pulse = start & ~start_prev_q;
    wire       iter_ok = (iter_q >= MIN_ITER);
    wire       eps_ok = (max_d_in <= eps_thresh);

    assign state_out = state_q;

    always @(*) begin
        state_n     = state_q;
        wait_max_n  = wait_max_q;
        iter_n      = iter_q;
        mult_busy_n = mult_busy_q;
        scale_busy_n = scale_busy_q;
        diff_busy_n = diff_busy_q;

        load_v_old  = 1'b0;
        load_y      = 1'b0;
        load_max_d  = 1'b0;
        start_mult  = 1'b0;
        start_scale = 1'b0;
        start_diff  = 1'b0;
        done        = 1'b0;

        case (state_q)
            IDLE: begin
                iter_n       = 4'd0;
                wait_max_n   = 2'd0;
                mult_busy_n  = 1'b0;
                scale_busy_n = 1'b0;
                diff_busy_n  = 1'b0;
                if (start_pulse) begin
                    state_n = LOAD;
                end
            end

            LOAD: begin
                load_v_old = 1'b1;
                state_n    = MULT;
            end

            MULT: begin
                if (!mult_busy_q) begin
                    start_mult  = 1'b1;
                    mult_busy_n = 1'b1;
                end
                if (mul_done) begin
                    load_y      = 1'b1;
                    wait_max_n  = 2'd2;
                    mult_busy_n = 1'b0;
                    state_n     = WAIT_MAX;
                end
            end

            WAIT_MAX: begin
                if (wait_max_q != 0) begin
                    wait_max_n = wait_max_q - 1'b1;
                end else begin
                    state_n = SCALE;
                end
            end

            SCALE: begin
                if (!scale_busy_q) begin
                    start_scale  = 1'b1;
                    scale_busy_n = 1'b1;
                end
                if (scale_done) begin
                    scale_busy_n = 1'b0;
                    state_n      = DIFF;
                end
            end

            DIFF: begin
                if (!diff_busy_q) begin
                    start_diff  = 1'b1;
                    diff_busy_n = 1'b1;
                end
                if (diff_done) begin
                    diff_busy_n = 1'b0;
                    load_max_d  = 1'b1;
                    if (iter_q != 4'hF) begin
                        iter_n = iter_q + 1'b1;
                    end
                    state_n = CHECK;
                end
            end

            CHECK: begin
                if (!iter_ok) begin
                    state_n = LOAD;
                end else if (eps_ok) begin
                    state_n = DONE_ST;
                end else begin
                    state_n = LOAD;
                end
            end

            DONE_ST: begin
                done = 1'b1;
                if (start_pulse) begin
                    state_n = LOAD;
                    iter_n  = 4'd0;
                end
            end

            default: begin
                state_n = IDLE;
            end
        endcase
    end

    always @(posedge clk) begin
        if (reset) begin
            state_q      <= IDLE;
            wait_max_q   <= 2'd0;
            iter_q       <= 4'd0;
            mult_busy_q  <= 1'b0;
            scale_busy_q <= 1'b0;
            diff_busy_q  <= 1'b0;
            start_prev_q <= 1'b0;
        end else begin
            state_q      <= state_n;
            wait_max_q   <= wait_max_n;
            iter_q       <= iter_n;
            mult_busy_q  <= mult_busy_n;
            scale_busy_q <= scale_busy_n;
            diff_busy_q  <= diff_busy_n;
            start_prev_q <= start;
        end
    end

endmodule
