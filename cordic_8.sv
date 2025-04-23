// Description: Pipelined CORDIC Rotation Module
// Author: Lawrence Prophete (edited version)

module cordic_8 #(
    parameter int BIT_WIDTH = 8,
    parameter int STG = 8
) (
    input  logic                        clk,
    input  logic signed [BIT_WIDTH-1:0] Xin,
    input  logic signed [BIT_WIDTH-1:0] Yin,
    input  logic signed [31:0]          angle,
    output logic signed [BIT_WIDTH:0]   Xout,
    output logic signed [BIT_WIDTH:0]   Yout
);

    // Atan lookup table (in radians, 32-bit fixed-point)
    logic [31:0] atan_table [0:30];
    initial begin
        atan_table[00] = 32'b00100000000000000000000000000000;
        atan_table[01] = 32'b00010010111001000000010100011101;
        atan_table[02] = 32'b00001001111110110011100001011011;
        atan_table[03] = 32'b00000101000100010001000111010100;
        atan_table[04] = 32'b00000010100010110000110101000011;
        atan_table[05] = 32'b00000001010001011101011111100001;
        atan_table[06] = 32'b00000000101000101111011000011110;
        atan_table[07] = 32'b00000000010100010111110001010101;
    end

    // Pipeline registers
    logic signed [BIT_WIDTH:0] X [0:STG-1];
    logic signed [BIT_WIDTH:0] Y [0:STG-1];
    logic signed [31:0]        Z [0:STG-1];

    wire [1:0] quadrant = angle[31:30];

    // Initial stage (rotation quadrant handling)
    always_ff @(posedge clk) begin
        case (quadrant)
            2'b00, 2'b11: begin
                X[0] <= Xin;
                Y[0] <= Yin;
                Z[0] <= angle;
            end
            2'b01: begin
                X[0] <= -Yin;
                Y[0] <= Xin;
                Z[0] <= angle - 32'sd1073741824; // pi/2 in 2.30 fixed-point
            end
            2'b10: begin
                X[0] <= Yin;
                Y[0] <= -Xin;
                Z[0] <= angle + 32'sd1073741824;
            end
        endcase
    end

    // Pipeline stage generation
    genvar i;
    generate
        for (i = 0; i < STG-1; i = i + 1) begin : stages
            logic signed [BIT_WIDTH:0] X_shr, Y_shr;
            logic Z_sign;

            assign X_shr = X[i] >>> i;
            assign Y_shr = Y[i] >>> i;
            assign Z_sign = Z[i][31];

            always_ff @(posedge clk) begin
                X[i+1] <= Z_sign ? X[i] + Y_shr : X[i] - Y_shr;
                Y[i+1] <= Z_sign ? Y[i] - X_shr : Y[i] + X_shr;
                Z[i+1] <= Z_sign ? Z[i] + atan_table[i] : Z[i] - atan_table[i];
            end
        end
    endgenerate

    // Output
    assign Xout = X[STG-1];
    assign Yout = Y[STG-1];

endmodule
