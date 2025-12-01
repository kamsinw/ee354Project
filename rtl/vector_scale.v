`timescale 1ns / 1ps

module vector_scale #(parameter WIDTH = 16) (
    input  wire                      clk,
    input  wire                      reset,
    input  wire                      start,
    input  wire signed [4*WIDTH-1:0] V_in,
    output reg  signed [4*WIDTH-1:0] V_out,
    output reg                       done
);

    wire signed [WIDTH-1:0] max_val;

    max_finder #(WIDTH) MF (
        .clk(clk),
        .reset(reset),
        .a(V_in),
        .max_val(max_val)
    );

    wire signed [WIDTH-1:0] V_in0 = V_in[WIDTH-1:0];
    wire signed [WIDTH-1:0] V_in1 = V_in[2*WIDTH-1:WIDTH];
    wire signed [WIDTH-1:0] V_in2 = V_in[3*WIDTH-1:2*WIDTH];
    wire signed [WIDTH-1:0] V_in3 = V_in[4*WIDTH-1:3*WIDTH];

    wire signed [WIDTH-1:0] scale = max_val;
    
    // NARROW CLOCK DESIGN: Multi-cycle division to break long combinational paths
    // Stage 1: Prepare inputs (combinational, fast)
    wire signed [23:0] V_in0_ext = {{8{V_in0[15]}}, V_in0};
    wire signed [23:0] V_in1_ext = {{8{V_in1[15]}}, V_in1};
    wire signed [23:0] V_in2_ext = {{8{V_in2[15]}}, V_in2};
    wire signed [23:0] V_in3_ext = {{8{V_in3[15]}}, V_in3};
    
    wire signed [23:0] V_in0_shifted = V_in0_ext << 14;
    wire signed [23:0] V_in1_shifted = V_in1_ext << 14;
    wire signed [23:0] V_in2_shifted = V_in2_ext << 14;
    wire signed [23:0] V_in3_shifted = V_in3_ext << 14;
    
    wire signed [23:0] scale_ext = {8'b0, scale};
    
    // NARROW CLOCK DESIGN: Use dedicated multi-cycle divider modules
    // This breaks long combinational paths by doing division over multiple cycles
    wire signed [19:0] div_result0, div_result1, div_result2, div_result3;
    wire div_done0, div_done1, div_done2, div_done3;
    reg div_start;
    
    multi_cycle_divider #(
        .WIDTH_DIVIDEND(24),
        .WIDTH_DIVISOR(24),
        .WIDTH_QUOTIENT(20)
    ) div0 (
        .clk(clk),
        .reset(reset),
        .start(div_start && (scale > 0)),
        .dividend(V_in0_shifted),
        .divisor(scale_ext),
        .quotient(div_result0),
        .done(div_done0)
    );
    
    multi_cycle_divider #(
        .WIDTH_DIVIDEND(24),
        .WIDTH_DIVISOR(24),
        .WIDTH_QUOTIENT(20)
    ) div1 (
        .clk(clk),
        .reset(reset),
        .start(div_start && (scale > 0)),
        .dividend(V_in1_shifted),
        .divisor(scale_ext),
        .quotient(div_result1),
        .done(div_done1)
    );
    
    multi_cycle_divider #(
        .WIDTH_DIVIDEND(24),
        .WIDTH_DIVISOR(24),
        .WIDTH_QUOTIENT(20)
    ) div2 (
        .clk(clk),
        .reset(reset),
        .start(div_start && (scale > 0)),
        .dividend(V_in2_shifted),
        .divisor(scale_ext),
        .quotient(div_result2),
        .done(div_done2)
    );
    
    multi_cycle_divider #(
        .WIDTH_DIVIDEND(24),
        .WIDTH_DIVISOR(24),
        .WIDTH_QUOTIENT(20)
    ) div3 (
        .clk(clk),
        .reset(reset),
        .start(div_start && (scale > 0)),
        .dividend(V_in3_shifted),
        .divisor(scale_ext),
        .quotient(div_result3),
        .done(div_done3)
    );
    
    // Handle scale <= 0 case
    wire signed [19:0] div_result0_final = (scale > 0) ? div_result0 : V_in0_ext[19:0];
    wire signed [19:0] div_result1_final = (scale > 0) ? div_result1 : V_in1_ext[19:0];
    wire signed [19:0] div_result2_final = (scale > 0) ? div_result2 : V_in2_ext[19:0];
    wire signed [19:0] div_result3_final = (scale > 0) ? div_result3 : V_in3_ext[19:0];
    
    // Clamping (combinational, but simple)
    wire signed [15:0] V_out0_final = (div_result0_final[19:15] == 5'b00000 || div_result0_final[19:15] == 5'b11111) ? 
                                      div_result0_final[15:0] : ((div_result0_final[19]) ? 16'sd32768 : 16'sd32767);
    wire signed [15:0] V_out1_final = (div_result1_final[19:15] == 5'b00000 || div_result1_final[19:15] == 5'b11111) ? 
                                      div_result1_final[15:0] : ((div_result1_final[19]) ? 16'sd32768 : 16'sd32767);
    wire signed [15:0] V_out2_final = (div_result2_final[19:15] == 5'b00000 || div_result2_final[19:15] == 5'b11111) ? 
                                      div_result2_final[15:0] : ((div_result2_final[19]) ? 16'sd32768 : 16'sd32767);
    wire signed [15:0] V_out3_final = (div_result3_final[19:15] == 5'b00000 || div_result3_final[19:15] == 5'b11111) ? 
                                      div_result3_final[15:0] : ((div_result3_final[19]) ? 16'sd32768 : 16'sd32767);
    
    // Control logic: wait for all dividers to complete
    reg waiting_for_div;
    
    always @(posedge clk) begin
        if (reset) begin
            div_start <= 1'b0;
            waiting_for_div <= 1'b0;
            V_out <= {(4*WIDTH){1'b0}};
            done <= 1'b0;
        end else if (start) begin
            div_start <= 1'b1;
            if (scale > 0) begin
                waiting_for_div <= 1'b1;
                done <= 1'b0;
            end else begin
                // No division needed, output immediately
                V_out <= {V_out3_final, V_out2_final, V_out1_final, V_out0_final};
                done <= 1'b1;
                waiting_for_div <= 1'b0;
            end
        end else begin
            div_start <= 1'b0;
            if (waiting_for_div) begin
                if (div_done0 && div_done1 && div_done2 && div_done3) begin
                    // All divisions complete
                    V_out <= {V_out3_final, V_out2_final, V_out1_final, V_out0_final};
                    done <= 1'b1;
                    waiting_for_div <= 1'b0;
                end else begin
                    done <= 1'b0;
                end
            end else begin
                done <= 1'b0;
            end
        end
    end

endmodule
