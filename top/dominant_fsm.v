`timescale 1ns / 1ps

module dominant_fsm (
    input  wire        clk,
    input  wire        reset,
    input  wire        start,
    
    input  wire        mul_done,
    input  wire        scale_done,
    input  wire        diff_done,
    input  wire signed [15:0] max_d_in,
    input  wire [2:0] epsilon,
    output reg         load_v_old,
    output reg         load_y,
    output reg         load_max_d,
    output reg         start_mult,
    output reg         start_scale,
    output reg         start_diff,
    output reg         done,
    output wire [6:0]  state_out
);

    localparam IDLE     = 7'b0000001;
    localparam LOAD     = 7'b0000010;
    localparam MULT     = 7'b0000100;
    localparam SCALE    = 7'b0001000;
    localparam DIFF     = 7'b0010000;
    localparam CHECK    = 7'b0100000;
    localparam DONE_ST  = 7'b1000000;

    reg [6:0] state;
    reg start_mult_reg, start_scale_reg, start_diff_reg;
    
    wire [15:0] eps16 = {13'b0, epsilon};
    
    assign state_out = state;

    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            load_v_old <= 1'b0;
            load_y <= 1'b0;
            load_max_d <= 1'b0;
            start_mult <= 1'b0;
            start_scale <= 1'b0;
            start_diff <= 1'b0;
            done <= 1'b0;
            start_mult_reg <= 1'b0;
            start_scale_reg <= 1'b0;
            start_diff_reg <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    load_v_old <= 1'b0;
                    load_y <= 1'b0;
                    load_max_d <= 1'b0;
                    start_mult <= 1'b0;
                    start_scale <= 1'b0;
                    start_diff <= 1'b0;
                    done <= 1'b0;
                    start_mult_reg <= 1'b0;
                    start_scale_reg <= 1'b0;
                    start_diff_reg <= 1'b0;
                    if (start) begin
                        state <= LOAD;
                    end
                end

                LOAD: begin
                    load_v_old <= 1'b1;
                    load_y <= 1'b0;
                    load_max_d <= 1'b0;
                    start_mult <= 1'b0;
                    start_scale <= 1'b0;
                    start_diff <= 1'b0;
                    done <= 1'b0;
                    start_mult_reg <= 1'b0;
                    start_scale_reg <= 1'b0;
                    start_diff_reg <= 1'b0;
                    state <= MULT;
                end

                MULT: begin
                    load_v_old <= 1'b0;
                    load_y <= 1'b0;
                    load_max_d <= 1'b0;
                    start_scale <= 1'b0;
                    start_diff <= 1'b0;
                    done <= 1'b0;
                    if (!start_mult_reg) begin
                        start_mult <= 1'b1;
                        start_mult_reg <= 1'b1;
                    end else begin
                        start_mult <= 1'b0;
                    end
                    if (mul_done) begin
                        start_mult_reg <= 1'b0;
                        load_y <= 1'b1;
                        state <= SCALE;
                    end
                end

                SCALE: begin
                    load_v_old <= 1'b0;
                    load_y <= 1'b0;
                    load_max_d <= 1'b0;
                    start_mult <= 1'b0;
                    start_diff <= 1'b0;
                    done <= 1'b0;
                    if (!start_scale_reg) begin
                        start_scale <= 1'b1;
                        start_scale_reg <= 1'b1;
                    end else begin
                        start_scale <= 1'b0;
                    end
                    if (scale_done) begin
                        start_scale_reg <= 1'b0;
                        state <= DIFF;
                    end
                end

                DIFF: begin
                    load_v_old <= 1'b0;
                    load_y <= 1'b0;
                    load_max_d <= 1'b0;
                    start_mult <= 1'b0;
                    start_scale <= 1'b0;
                    done <= 1'b0;
                    if (!start_diff_reg) begin
                        start_diff <= 1'b1;
                        start_diff_reg <= 1'b1;
                    end else begin
                        start_diff <= 1'b0;
                    end
                    if (diff_done) begin
                        start_diff_reg <= 1'b0;
                        load_max_d <= 1'b1;
                        state <= CHECK;
                    end
                end

                CHECK: begin
                    load_v_old <= 1'b0;
                    load_y <= 1'b0;
                    load_max_d <= 1'b0;
                    start_mult <= 1'b0;
                    start_scale <= 1'b0;
                    start_diff <= 1'b0;
                    done <= 1'b0;
                    if (max_d_in <= eps16) begin
                        state <= DONE_ST;
                    end else begin
                        state <= LOAD;
                    end
                end

                DONE_ST: begin
                    load_v_old <= 1'b0;
                    load_y <= 1'b0;
                    load_max_d <= 1'b0;
                    start_mult <= 1'b0;
                    start_scale <= 1'b0;
                    start_diff <= 1'b0;
                    done <= 1'b1;
                end

                default: begin
                    state <= IDLE;
                    load_v_old <= 1'b0;
                    load_y <= 1'b0;
                    load_max_d <= 1'b0;
                    start_mult <= 1'b0;
                    start_scale <= 1'b0;
                    start_diff <= 1'b0;
                    done <= 1'b0;
                end
            endcase
        end
    end

endmodule
