`timescale 1ns/1ps

module tb_cordic();

    parameter int BIT_WIDTH = 8;
    parameter int STG = 8;

    logic clk;
    logic signed [BIT_WIDTH-1:0] Xin, Yin;
    logic signed [31:0] angle;
    logic signed [BIT_WIDTH:0] Xout, Yout;

    // Instantiate DUT
    cordic #(
        .BIT_WIDTH(BIT_WIDTH),
        .STG(STG)
    ) dut (
        .clk(clk),
        .Xin(Xin),
        .Yin(Yin),
        .angle(angle),
        .Xout(Xout),
        .Yout(Yout)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Init
        clk = 0;
        Xin = 0;
        Yin = 0;
        angle = 0;

        #10;
        
        // Rotate vector (1,0) by 45 degrees => π/4 = ~0.785 rad
        // In 2.30 fixed-point: π/4 ≈ 0x0C90FDB
        Xin = 8'sd64;        // Q1.7 format for 0.5
        Yin = 8'sd0;
        angle = 32'sd210828714; // π/4 in 2.30 fixed-point

        // Wait for pipeline latency
        #(STG * 10);

        $display("Xout: %d, Yout: %d", Xout, Yout);
        $finish;
    end

endmodule
