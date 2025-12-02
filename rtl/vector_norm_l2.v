`timescale 1ns / 1ps

module vector_norm_l2 #(parameter WIDTH = 4) (
    input  wire                      clk,
    input  wire                      reset,
    input  wire                      start,
    input  wire [4*WIDTH-1:0]        V_in,
    output reg  [WIDTH-1:0]          norm_out,
    output reg                       done
);

    localparam SUM_BITS = 2*WIDTH + 4;
    localparam STATE_IDLE  = 2'd0;
    localparam STATE_ACCUM = 2'd1;
    localparam STATE_SQRT  = 2'd2;

    reg [1:0] state;
    reg [1:0] idx;
    reg [4:0] sqrt_iter;
    reg [SUM_BITS-1:0] sum_sq;
    reg [SUM_BITS-1:0] rem;
    reg [WIDTH:0] root;
    reg [SUM_BITS-1:0] bit_val;
    reg [WIDTH-1:0] sample;
    reg [2*WIDTH-1:0] product;

    function [WIDTH-1:0] select_sample;
        input [1:0] sel;
        begin
            case (sel)
                2'd0: select_sample = V_in[WIDTH-1:0];
                2'd1: select_sample = V_in[2*WIDTH-1:WIDTH];
                2'd2: select_sample = V_in[3*WIDTH-1:2*WIDTH];
                default: select_sample = V_in[4*WIDTH-1:3*WIDTH];
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (reset) begin
            state    <= STATE_IDLE;
            idx      <= 2'd0;
            sum_sq   <= {SUM_BITS{1'b0}};
            rem      <= {SUM_BITS{1'b0}};
            root     <= {(WIDTH+1){1'b0}};
            bit_val  <= {SUM_BITS{1'b0}};
            sqrt_iter<= 5'd0;
            norm_out <= {WIDTH{1'b0}};
            done     <= 1'b0;
        end else begin
            done <= 1'b0;
            case (state)
                STATE_IDLE: begin
                    if (start) begin
                        state   <= STATE_ACCUM;
                        idx     <= 2'd0;
                        sum_sq  <= {SUM_BITS{1'b0}};
                    end
                end
                STATE_ACCUM: begin
                    sample  = select_sample(idx);
                    product = sample * sample;
                    sum_sq  <= sum_sq + product;
                    if (idx == 2'd3) begin
                        state     <= STATE_SQRT;
                        rem       <= sum_sq + product;
                        root      <= {(WIDTH+1){1'b0}};
                        bit_val   <= {{(SUM_BITS-(2*WIDTH-2)){1'b0}}, 1'b1} << (2*WIDTH - 2);
                        sqrt_iter <= WIDTH[4:0];
                    end else begin
                        idx <= idx + 1'b1;
                    end
                end
                STATE_SQRT: begin
                    if (sqrt_iter != 0) begin
                        if (rem >= (root + bit_val)) begin
                            rem  <= rem - (root + bit_val);
                            root <= (root >> 1) + bit_val;
                        end else begin
                            root <= root >> 1;
                        end
                        bit_val   <= bit_val >> 2;
                        sqrt_iter <= sqrt_iter - 1'b1;
                    end else begin
                        norm_out <= root[WIDTH-1:0];
                        done     <= 1'b1;
                        state    <= STATE_IDLE;
                    end
                end
            endcase
        end
    end

endmodule

