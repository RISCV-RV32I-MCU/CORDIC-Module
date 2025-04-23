`timescale 1ns/1ps

module cordic_tb;

  // Parameters
  parameter int BIT_WIDTH = 8;
  parameter int STG = 16;

  // Clock and reset
  logic clk;
  logic signed [BIT_WIDTH-1:0] Xin, Yin;
  logic signed [31:0] angle;
  logic signed [BIT_WIDTH:0] Xout, Yout;

  // Instantiate the DUT
  cordic #(
    .BIT_WIDTH(BIT_WIDTH),
    .ITERATIONS(STG)
  ) dut (
    .clk(clk),
    .Xin(Xin),
    .Yin(Yin),
    .angle(angle),
    .Xout(Xout),
    .Yout(Yout)
  );

  // Clock generation
  always #5 clk = ~clk;  // 100MHz

  // Initial block
  initial begin
    $display("CORDIC Testbench Starting...");
    clk = 0;
    
    // Wait for global reset
    #10;

    // Test case: rotate (0.5, 0.0) by 45 degrees
    // In Q1.7, 0.5 = 64
    Xin = 64;
    Yin = 0;
    // 45 deg = pi/4 ≈ 0.785 rad
    // 0.785 * 2^30 = 843314857 (fixed-point 2.30)
    angle = 32'sd843314857;

    // Wait for pipeline to process (STG cycles)
    repeat(STG + 2) @(posedge clk);

    $display("Input:  Xin = %0d, Yin = %0d", Xin, Yin);
    $display("Angle (rad, fixed-point): %0d", angle);
    $display("Output: Xout = %0d, Yout = %0d", Xout, Yout);
    $display("Expected approx: Xout ≈ 45, Yout ≈ 45");

    $finish;
  end

endmodule
