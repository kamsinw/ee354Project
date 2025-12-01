`timescale 1ns / 1ps

// Multi-cycle divider using Restoring Division (Shift-Subtract) algorithm
// Classic pen-and-paper long division: 1 bit per cycle
// Divides dividend by divisor over WIDTH_QUOTIENT cycles
module multi_cycle_divider #(
    parameter WIDTH_DIVIDEND = 24,
    parameter WIDTH_DIVISOR = 24,
    parameter WIDTH_QUOTIENT = 20
) (
    input  wire                      clk,
    input  wire                      reset,
    input  wire                      start,
    input  wire signed [WIDTH_DIVIDEND-1:0] dividend,
    input  wire signed [WIDTH_DIVISOR-1:0] divisor,
    output reg  signed [WIDTH_QUOTIENT-1:0] quotient,
    output reg                       done
);

    localparam IDLE = 2'b00;
    localparam DIVIDING = 2'b01;
    localparam DONE_ST = 2'b10;
    
    reg [1:0] state;
    
    // Working registers (unsigned for division)
    reg [WIDTH_DIVIDEND-1:0] dividend_abs;
    reg [WIDTH_DIVISOR-1:0] divisor_abs;
    reg [WIDTH_QUOTIENT-1:0] quotient_reg;
    reg [WIDTH_DIVISOR:0] remainder;  // One extra bit for sign detection
    reg [$clog2(WIDTH_QUOTIENT+1):0] bit_count;
    
    // Sign flags
    reg dividend_sign, divisor_sign;
    
    // Shift register for dividend bits (we process MSB to LSB)
    // For WIDTH_QUOTIENT bits, we use the upper WIDTH_QUOTIENT bits of dividend
    reg [WIDTH_DIVIDEND-1:0] dividend_shift_reg;
    
    // Combinational: compute next remainder after shift and subtract
    // Bring in next bit from dividend (MSB of remaining dividend)
    wire [WIDTH_DIVISOR:0] remainder_shifted = {remainder[WIDTH_DIVISOR-1:0], 
                                                dividend_shift_reg[WIDTH_DIVIDEND-1]};
    wire [WIDTH_DIVISOR:0] remainder_after_sub = remainder_shifted - {1'b0, divisor_abs};
    
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            dividend_abs <= {WIDTH_DIVIDEND{1'b0}};
            divisor_abs <= {WIDTH_DIVISOR{1'b0}};
            dividend_shift_reg <= {WIDTH_DIVIDEND{1'b0}};
            quotient_reg <= {WIDTH_QUOTIENT{1'b0}};
            remainder <= {(WIDTH_DIVISOR+1){1'b0}};
            bit_count <= 0;
            dividend_sign <= 1'b0;
            divisor_sign <= 1'b0;
            quotient <= {WIDTH_QUOTIENT{1'b0}};
            done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        if (divisor == 0) begin
                            // Division by zero: return zero
                            quotient <= {WIDTH_QUOTIENT{1'b0}};
                            state <= DONE_ST;
                        end else begin
                            // Store signs and convert to absolute values (unsigned)
                            dividend_sign <= dividend[WIDTH_DIVIDEND-1];
                            divisor_sign <= divisor[WIDTH_DIVISOR-1];
                            dividend_abs <= (dividend[WIDTH_DIVIDEND-1]) ? -dividend : dividend;
                            divisor_abs <= (divisor[WIDTH_DIVISOR-1]) ? -divisor : divisor;
                            
                            // Initialize: remainder = 0, quotient = 0
                            // Load dividend into shift register (left-aligned for upper bits)
                            dividend_shift_reg <= dividend_abs;
                            quotient_reg <= {WIDTH_QUOTIENT{1'b0}};
                            remainder <= {(WIDTH_DIVISOR+1){1'b0}};
                            bit_count <= WIDTH_QUOTIENT - 1;  // Process MSB to LSB
                            state <= DIVIDING;
                        end
                    end
                end
                
                DIVIDING: begin
                    // Restoring Division Algorithm:
                    // 1. Shift remainder left, bring in next bit from dividend
                    // 2. Subtract divisor
                    // 3. If result >= 0: keep it, set quotient bit to 1
                    // 4. If result < 0: restore old remainder, set quotient bit to 0
                    
                    if (remainder_after_sub[WIDTH_DIVISOR] == 1'b0) begin
                        // Subtraction successful (result >= 0)
                        remainder <= remainder_after_sub;
                        quotient_reg <= {quotient_reg[WIDTH_QUOTIENT-2:0], 1'b1};
                    end else begin
                        // Subtraction failed (result < 0), restore
                        remainder <= remainder_shifted;
                        quotient_reg <= {quotient_reg[WIDTH_QUOTIENT-2:0], 1'b0};
                    end
                    
                    // Shift dividend left to bring in next bit for next iteration
                    dividend_shift_reg <= {dividend_shift_reg[WIDTH_DIVIDEND-2:0], 1'b0};
                    
                    if (bit_count == 0) begin
                        // All bits processed, apply sign correction
                        if (dividend_sign ^ divisor_sign) begin
                            quotient <= -quotient_reg;
                        end else begin
                            quotient <= quotient_reg;
                        end
                        state <= DONE_ST;
                    end else begin
                        bit_count <= bit_count - 1;
                    end
                end
                
                DONE_ST: begin
                    done <= 1'b1;
                    state <= IDLE;
                end
                
                default: begin
                    state <= IDLE;
                    done <= 1'b0;
                end
            endcase
        end
    end

endmodule
