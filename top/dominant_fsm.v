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
    output wire [7:0]  state_out
);

    localparam IDLE     = 8'b00000001;
    localparam LOAD     = 8'b00000010;
    localparam MULT     = 8'b00000100;
    localparam WAIT_MAX = 8'b00001000;  // Wait for max_finder pipeline
    localparam SCALE    = 8'b00010000;
    localparam DIFF     = 8'b00100000;
    localparam CHECK    = 8'b01000000;
    localparam DONE_ST  = 8'b10000000;

    reg [7:0] state;
    reg start_mult_reg, start_scale_reg, start_diff_reg;
    reg [1:0] wait_max_count;
    
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
            wait_max_count <= 2'd0;
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
                        wait_max_count <= 2'd2;
                        state <= WAIT_MAX;
                    end
                end

                WAIT_MAX: begin
                    // Wait 2 cycles for max_finder pipeline to settle
                    load_v_old <= 1'b0;
                    load_y <= 1'b0;
                    load_max_d <= 1'b0;
                    start_mult <= 1'b0;
                    start_scale <= 1'b0;
                    start_diff <= 1'b0;
                    done <= 1'b0;
                    if (wait_max_count != 0) begin
                        wait_max_count <= wait_max_count - 1'b1;
                        state <= WAIT_MAX;
                    end else begin
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
