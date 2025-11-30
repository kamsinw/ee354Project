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
    output reg         done
);

    localparam IDLE     = 7'b0000001;
    localparam MULT     = 7'b0000010;
    localparam SCALE    = 7'b0000100;
    localparam DIFF     = 7'b0001000;
    localparam CHECK    = 7'b0010000;
    localparam LOAD     = 7'b0100000;
    localparam DONE_ST  = 7'b1000000;

    reg [6:0] state;
    reg [6:0] next_state;
    
    wire [15:0] eps16 = {13'b0, epsilon};

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start) next_state = MULT;
            end
            MULT: begin
                if (mul_done) next_state = SCALE;
            end
            SCALE: begin
                if (scale_done) next_state = DIFF;
            end
            DIFF: begin
                if (diff_done) next_state = CHECK;
            end
            CHECK: begin
                if (max_d_in <= eps16) next_state = DONE_ST;
                else next_state = LOAD;
            end
            LOAD: begin
                next_state = MULT;
            end
            DONE_ST: begin
                next_state = DONE_ST;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

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
        end else begin
            state <= next_state;
            
            start_mult <= (next_state == MULT);
            start_scale <= (next_state == SCALE);
            start_diff <= (next_state == DIFF);
            load_v_old <= (next_state == LOAD);
            done <= (next_state == DONE_ST);
            
            if (next_state == SCALE) begin
                load_y <= 1'b1;
            end else begin
                load_y <= 1'b0;
            end
            
            if (next_state == CHECK) begin
                load_max_d <= 1'b1;
            end else begin
                load_max_d <= 1'b0;
            end
        end
    end

endmodule
