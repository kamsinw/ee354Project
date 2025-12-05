`timescale 1ns / 1ps

module vector_scale #(
    parameter integer IN_WIDTH   = 12,
    parameter integer OUT_WIDTH  = 4,
    parameter integer MAX_WIDTH  = 12
) (
    input  wire                   clk,
    input  wire                   reset,
    input  wire                   start,
    input  wire [4*IN_WIDTH-1:0]  V_in,
    input  wire [MAX_WIDTH-1:0]   max_value,  // Not used
    output reg  [4*OUT_WIDTH-1:0] V_out,
    output reg                    done
);

    // ========================================================================
    // SHIFT-BASED NORMALIZATION (NO LOOKUP TABLE, NO DIVISION)
    // ========================================================================
    // Algorithm:
    // 1. Find max of inputs
    // 2. Determine position of MSB in max (priority encoder)
    // 3. Calculate: scale_factor = 15 << (11 - msb_position)
    // 4. For each input: output = (input × scale_factor) >> 11
    // 5. Clamp to [0, 15]
    //
    // This approximates: output = (input × 15) / max
    // By using: output = (input × 15 × 2^(11-msb)) >> 11
    //                  ≈ (input × 15) / 2^msb
    //                  ≈ (input × 15) / max  (since max ≈ 2^msb)
    // ========================================================================

    localparam integer LANE_COUNT = 4;
    
    // State machine
    localparam [1:0] IDLE    = 2'd0;
    localparam [1:0] COMPUTE = 2'd1;
    
    reg [1:0] state_q, state_d;
    reg [4*OUT_WIDTH-1:0] v_out_d;
    reg done_d;
    
    // ========================================================================
    // STEP 1: EXTRACT INPUT LANES
    // ========================================================================
    wire [IN_WIDTH-1:0] lane_0 = V_in[0*IN_WIDTH +: IN_WIDTH];
    wire [IN_WIDTH-1:0] lane_1 = V_in[1*IN_WIDTH +: IN_WIDTH];
    wire [IN_WIDTH-1:0] lane_2 = V_in[2*IN_WIDTH +: IN_WIDTH];
    wire [IN_WIDTH-1:0] lane_3 = V_in[3*IN_WIDTH +: IN_WIDTH];
    
    // ========================================================================
    // STEP 2: FIND MAXIMUM ELEMENT
    // ========================================================================
    wire [IN_WIDTH-1:0] max_01 = (lane_0 > lane_1) ? lane_0 : lane_1;
    wire [IN_WIDTH-1:0] max_23 = (lane_2 > lane_3) ? lane_2 : lane_3;
    wire [IN_WIDTH-1:0] max_all = (max_01 > max_23) ? max_01 : max_23;
    
    // ========================================================================
    // STEP 3: FIND MSB POSITION (PRIORITY ENCODER)
    // ========================================================================
    // Returns position of highest set bit (0-11)
    
    reg [3:0] msb_pos;
    
    always @(*) begin
        if (max_all[11]) msb_pos = 4'd11;
        else if (max_all[10]) msb_pos = 4'd10;
        else if (max_all[9])  msb_pos = 4'd9;
        else if (max_all[8])  msb_pos = 4'd8;
        else if (max_all[7])  msb_pos = 4'd7;
        else if (max_all[6])  msb_pos = 4'd6;
        else if (max_all[5])  msb_pos = 4'd5;
        else if (max_all[4])  msb_pos = 4'd4;
        else if (max_all[3])  msb_pos = 4'd3;
        else if (max_all[2])  msb_pos = 4'd2;
        else if (max_all[1])  msb_pos = 4'd1;
        else msb_pos = 4'd0;
    end
    
    // ========================================================================
    // STEP 4: CALCULATE SCALE FACTOR
    // ========================================================================
    // scale_factor = 15 << (11 - msb_pos)
    // This ensures max element will scale close to 15
    
    wire [3:0] shift_amt = (max_all == 0) ? 4'd0 : (4'd11 - msb_pos);
    wire [14:0] scale_factor = 15'd15 << shift_amt;  // Up to 15 << 11 = 30720
    
    // ========================================================================
    // STEP 5: MULTIPLY EACH LANE BY SCALE FACTOR
    // ========================================================================
    // product = input × scale_factor (max: 4095 × 30720 = 125,829,120 = 27 bits)
    
    wire [26:0] product_0 = lane_0 * scale_factor;
    wire [26:0] product_1 = lane_1 * scale_factor;
    wire [26:0] product_2 = lane_2 * scale_factor;
    wire [26:0] product_3 = lane_3 * scale_factor;
    
    // ========================================================================
    // STEP 6: SHIFT RIGHT AND CLAMP
    // ========================================================================
    // output = product >> 11 (removes the 2^11 scaling factor)
    
    wire [15:0] result_0 = product_0[26:11];
    wire [15:0] result_1 = product_1[26:11];
    wire [15:0] result_2 = product_2[26:11];
    wire [15:0] result_3 = product_3[26:11];
    
    // Clamp to [0, 15]
    wire [OUT_WIDTH-1:0] scaled_0 = (max_all == 0) ? 4'd0 :
                                     (result_0 > 16'd15) ? 4'd15 : result_0[3:0];
    
    wire [OUT_WIDTH-1:0] scaled_1 = (max_all == 0) ? 4'd0 :
                                     (result_1 > 16'd15) ? 4'd15 : result_1[3:0];
    
    wire [OUT_WIDTH-1:0] scaled_2 = (max_all == 0) ? 4'd0 :
                                     (result_2 > 16'd15) ? 4'd15 : result_2[3:0];
    
    wire [OUT_WIDTH-1:0] scaled_3 = (max_all == 0) ? 4'd0 :
                                     (result_3 > 16'd15) ? 4'd15 : result_3[3:0];
    
    wire [4*OUT_WIDTH-1:0] scaled_vector = {scaled_3, scaled_2, scaled_1, scaled_0};
    
    // ========================================================================
    // CONTROL FSM (SINGLE-CYCLE OPERATION)
    // ========================================================================
    always @(*) begin
        state_d = state_q;
        v_out_d = V_out;
        done_d  = 1'b0;
        
        case (state_q)
            IDLE: begin
                if (start) begin
                    state_d = COMPUTE;
                end
            end
            
            COMPUTE: begin
                // All computation is combinational
                v_out_d = scaled_vector;
                done_d  = 1'b1;
                state_d = IDLE;
            end
            
            default: begin
                state_d = IDLE;
            end
        endcase
    end
    
    // ========================================================================
    // STATE REGISTERS
    // ========================================================================
    always @(posedge clk) begin
        if (reset) begin
            state_q <= IDLE;
            V_out   <= {(4*OUT_WIDTH){1'b0}};
            done    <= 1'b0;
        end else begin
            state_q <= state_d;
            V_out   <= v_out_d;
            done    <= done_d;
        end
    end

endmodule
