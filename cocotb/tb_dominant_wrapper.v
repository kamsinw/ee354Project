`timescale 1ns / 1ps

module tb_dominant_wrapper;

    parameter CLK_PERIOD = 10;
    
    reg clk;
    reg reset;
    reg start;
    reg [2:0] epsilon;
    
    wire done;
    wire load_v_old, load_y, load_max_d;
    wire start_mult, start_scale, start_diff;
    
    wire mul_done, scale_done, diff_done;
    wire [3:0] max_d_out;
    wire [3:0] v0, v1, v2, v3;
    
    reg [3:0] A00, A01, A02, A03;
    reg [3:0] A10, A11, A12, A13;
    reg [3:0] A20, A21, A22, A23;
    reg [3:0] A30, A31, A32, A33;
    reg [4*4-1:0] v_init;
    
    dominant_fsm u_fsm (
        .clk(clk),
        .reset(reset),
        .start(start),
        .mul_done(mul_done),
        .scale_done(scale_done),
        .diff_done(diff_done),
        .max_d_in(max_d_out),
        .epsilon(epsilon),
        .load_v_old(load_v_old),
        .load_y(load_y),
        .load_max_d(load_max_d),
        .start_mult(start_mult),
        .start_scale(start_scale),
        .start_diff(start_diff),
        .done(done)
    );
    
    dominant_datapath u_datapath (
        .clk(clk),
        .reset(reset),
        .load_v_old(load_v_old),
        .load_y(load_y),
        .load_max_d(load_max_d),
        .start_mult(start_mult),
        .start_scale(start_scale),
        .start_diff(start_diff),
        .v_init(v_init),
        .A00(A00), .A01(A01), .A02(A02), .A03(A03),
        .A10(A10), .A11(A11), .A12(A12), .A13(A13),
        .A20(A20), .A21(A21), .A22(A22), .A23(A23),
        .A30(A30), .A31(A31), .A32(A32), .A33(A33),
        .mul_done(mul_done),
        .scale_done(scale_done),
        .diff_done(diff_done),
        .max_d_out(max_d_out),
        .v0(v0),
        .v1(v1),
        .v2(v2),
        .v3(v3)
    );

    initial begin
        v_init = {16'sd1, 16'sd1, 16'sd1, 16'sd1};
    end

endmodule

