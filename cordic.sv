// Desription: Cordic Module 


module cordic #(
    parameter int BIT_WIDTH = 8,
    parameter int ITERATIONS = 8 //Bit width of vectrs X and Y 
) (
    input  logic                  clk,
    input  logic signed [BIT_WIDTH-1:0] Xin,
    input  logic signed [BIT_WIDTH-1:0] Yin,
    input  logic signed [31:0]        angle,
    output logic signed [BIT_WIDTH:0]  Xout,
    output logic signed [BIT_WIDTH:0]  Yout
);
    // Module implementation 
    logic [31:0] atan_table [0:30]; // Table of atan values
    assign atan_table[00] = 32'b00100000000000000000000000000000; // 45.000 degrees -> atan(2^0)
    assign atan_table[01] = 32'b00010010111001000000010100011101; // 26.565 degrees -> atan(2^-1)
    assign atan_table[02] = 32'b00001001111110110011100001011011; // 14.036 degrees -> atan(2^-2)
    assign atan_table[03] = 32'b00000101000100010001000111010100; // atan(2^-3)
    assign atan_table[04] = 32'b00000010100010110000110101000011;
    assign atan_table[05] = 32'b00000001010001011101011111100001;
    assign atan_table[06] = 32'b00000000101000101111011000011110;
    assign atan_table[07] = 32'b00000000010100010111110001010101;
    assign atan_table[08] = 32'b00000000001010001011111001010011;
    assign atan_table[09] = 32'b00000000000101000101111100101110;
    assign atan_table[10] = 32'b00000000000010100010111110011000;
    assign atan_table[11] = 32'b00000000000001010001011111001100;
    assign atan_table[12] = 32'b00000000000000101000101111100110;
    assign atan_table[13] = 32'b00000000000000010100010111110011;
    assign atan_table[14] = 32'b00000000000000001010001011111001;
    assign atan_table[15] = 32'b00000000000000000101000101111101;
    assign atan_table[16] = 32'b00000000000000000010100010111110;
    assign atan_table[17] = 32'b00000000000000000001010001011111;
    assign atan_table[18] = 32'b00000000000000000000101000101111;
    assign atan_table[19] = 32'b00000000000000000000010100011000;
    assign atan_table[20] = 32'b00000000000000000000001010001100;
    assign atan_table[21] = 32'b00000000000000000000000101000110;
    assign atan_table[22] = 32'b00000000000000000000000010100011;
    assign atan_table[23] = 32'b00000000000000000000000001010001;
    assign atan_table[24] = 32'b00000000000000000000000000101000;
    assign atan_table[25] = 32'b00000000000000000000000000010100;
    assign atan_table[26] = 32'b00000000000000000000000000001010;
    assign atan_table[27] = 32'b00000000000000000000000000000101;
    assign atan_table[28] = 32'b00000000000000000000000000000010;
    assign atan_table[29] = 32'b00000000000000000000000000000001;
    assign atan_table[30] = 32'b00000000000000000000000000000000;  
    // REGISTERS
    //stage outputs
   reg signed [BIT_WIDTH :0] X [0:STG-1];
   reg signed [BIT_WIDTH :0] Y [0:STG-1];
   reg signed [31:0] Z [0:STG-1]; // 32bit
   wire                 [1:0] quadrant;
   assign   quadrant = angle[31:30];
   
   always @(posedge clock)
   begin // make sure the rotation angle is in the -pi/2 to pi/2 range.  If not then pre-rotate
      case (quadrant)
         2'b00,
         2'b11:   // no pre-rotation needed for these quadrants
         begin    // X[n], Y[n] is 1 bit larger than Xin, Yin, but Verilog handles the assignments properly
            X[0] <= Xin;
            Y[0] <= Yin;
            Z[0] <= angle;
         end
         
         2'b01:
         begin
            X[0] <= -Yin;
            Y[0] <= Xin;
            Z[0] <= {2'b00,angle[29:0]}; // subtract pi/2 from angle for this quadrant
         end
         
         2'b10:
         begin
            X[0] <= Yin;
            Y[0] <= -Xin;
            Z[0] <= {2'b11,angle[29:0]}; // add pi/2 to angle for this quadrant
         end
         
      endcase
   end
   
   //------------------------------------------------------------------------------
   //                           generate stages 1 to STG-1
   //------------------------------------------------------------------------------
   genvar i;

   generate
   for (i=0; i < (STG-1); i=i+1)
   begin: XYZ
      logiv                   Z_sign;
      logic signed  [c_parameter :0] X_shr, Y_shr; 
   
      assign X_shr = X[i] >>> i; // signed shift right
      assign Y_shr = Y[i] >>> i;
   
      //the sign of the current rotation angle
      assign Z_sign = Z[i][31]; // Z_sign = 1 if Z[i] < 0
   
      always @(posedge clk)
      begin
         // add/subtract shifted data
         X[i+1] <= Z_sign ? X[i] + Y_shr         : X[i] - Y_shr;
         Y[i+1] <= Z_sign ? Y[i] - X_shr         : Y[i] + X_shr;
         Z[i+1] <= Z_sign ? Z[i] + atan_table[i] : Z[i] - atan_table[i];
      end
   end
   endgenerate
   
   
   //------------------------------------------------------------------------------
   //                                 output
   //------------------------------------------------------------------------------
   assign Xout = X[STG-1];
   assign Yout = Y[STG-1];

endmodule
