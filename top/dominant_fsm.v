`timescale 1ns / 1ps

// dominant_fsm.v - Power iteration FSM controller

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

    localparam EDIT_IN      = 8'b0000_0001;
    localparam EDIT_CURR    = 8'b0000_0010;
    localparam EDIT_WRITE   = 8'b0000_0100;
    localparam RUN_IN       = 8'b0000_1000;
    localparam MATH_VEC     = 8'b0001_0000;
    localparam RUN_SCALE    = 8'b0010_0000;
    localparam RUN_CHECK    = 8'b0100_0000;
    localparam RUN_DONE     = 8'b1000_0000;

    reg [7:0] state;
    reg [7:0] state_next;
    reg started_mult, started_scale, started_diff;

    always @(posedge clk) begin
        state_next <= state;
        if (reset) begin
            state       <= EDIT_IN;
            state_next <= EDIT_IN;
            started_mult <= 1'b0;
            started_scale <= 1'b0;
            started_diff <= 1'b0;
            load_v_old  <= 1'b0;
            load_y      <= 1'b0;
            load_max_d  <= 1'b0;
            start_mult  <= 1'b0;
            start_scale <= 1'b0;
            start_diff  <= 1'b0;
            done        <= 1'b0;
        end 
      // State machine logic
      case (state)
            EDIT_IN: begin
                  load_v_old  <= 1'b0;
                  load_y      <= 1'b0;
                  load_max_d  <= 1'b0;
                  start_mult  <= 1'b0;
                  start_scale <= 1'b0;
                  start_diff  <= 1'b0;
                  done        <= 1'b0;
                  if (start) state <= RUN_IN;
            end

            EDIT_CURR: begin
                  state <= EDIT_WRITE;
            end

            EDIT_WRITE: begin
                  state <= EDIT_IN;
            end

            RUN_IN: begin
                  load_v_old  <= 1'b1;
                  load_y      <= 1'b0;
                  load_max_d  <= 1'b0;
                  start_mult  <= 1'b0;
                  start_scale <= 1'b0;
                  start_diff  <= 1'b0;
                  done        <= 1'b0;
                  state       <= MATH_VEC;
            end

            MATH_VEC: begin
                  load_v_old  <= 1'b0;
                  load_y      <= 1'b0;
                  load_max_d  <= 1'b0;
                  if (state_next != MATH_VEC) begin
                      start_mult  <= 1'b1;
                      started_mult <= 1'b1;
                  end else begin
                      start_mult  <= 1'b0;
                  end
                  start_scale <= 1'b0;
                  start_diff  <= 1'b0;
                  done        <= 1'b0;
                  if (mul_done) begin
                      started_mult <= 1'b0;
                      state <= RUN_SCALE;
                  end
            end

            RUN_SCALE: begin
                  load_v_old  <= 1'b0;
                  load_y      <= 1'b1;
                  load_max_d  <= 1'b0;
                  start_mult  <= 1'b0;
                  if (state_next != RUN_SCALE) begin
                      start_scale <= 1'b1;
                      started_scale <= 1'b1;
                  end else begin
                      start_scale <= 1'b0;
                  end
                  start_diff  <= 1'b0;
                  done        <= 1'b0;
                  if (scale_done) begin
                      started_scale <= 1'b0;
                      state <= RUN_CHECK;
                  end
            end

            RUN_CHECK: begin
                  load_v_old  <= 1'b0;
                  load_y      <= 1'b0;
                  load_max_d  <= 1'b0;
                  start_mult  <= 1'b0;
                  start_scale <= 1'b0;
                  if (state_next != RUN_CHECK) begin
                      start_diff  <= 1'b1;
                      started_diff <= 1'b1;
                  end else begin
                      start_diff  <= 1'b0;
                  end
                  done        <= 1'b0;
                  if (diff_done) begin
                      started_diff <= 1'b0;
                      load_max_d  <= 1'b1;
                      if (max_d_in < epsilon) begin
                          state <= RUN_DONE;
                      end else begin
                          load_v_old  <= 1'b1;
                          load_y      <= 1'b0;
                          load_max_d  <= 1'b0;
                          start_mult  <= 1'b0;
                          start_scale <= 1'b0;
                          start_diff  <= 1'b0;
                          done        <= 1'b0;
                          state <= MATH_VEC;
                      end
                  end
            end

            RUN_DONE: begin
                  load_v_old  <= 1'b0;
                  load_y      <= 1'b0;
                  load_max_d  <= 1'b0;
                  start_mult  <= 1'b0;
                  start_scale <= 1'b0;
                  start_diff  <= 1'b0;
                  done        <= 1'b1;
                  if (~start) state <= EDIT_IN;
            end

            default: begin
                  state <= EDIT_IN;
            end
            endcase
      end
    

endmodule
    