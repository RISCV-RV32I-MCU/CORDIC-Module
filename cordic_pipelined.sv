module cordic_pipelined #(
    parameter int BIT_WIDTH = 16,
    parameter int STAGES = 16
)(
    input  logic                        clk,
    input  logic signed [BIT_WIDTH-1:0] Xin,
    input  logic signed [BIT_WIDTH-1:0] Yin,
    input  logic signed [BIT_WIDTH-1:0] Zin,
    output logic signed [BIT_WIDTH-1:0] Xout,
    output logic signed [BIT_WIDTH-1:0] Yout
);

    logic signed [BIT_WIDTH-1:0] x     [0:STAGES];
    logic signed [BIT_WIDTH-1:0] y     [0:STAGES];
    logic signed [BIT_WIDTH-1:0] z     [0:STAGES];

    logic signed [BIT_WIDTH-1:0] atan_table [0:STAGES-1] = '{
        16'sd25735, 16'sd15192, 16'sd8027, 16'sd4074,
        16'sd2045, 16'sd1023, 16'sd511,  16'sd256,
        16'sd128,  16'sd64,   16'sd32,   16'sd16,
        16'sd8,    16'sd4,    16'sd2,    16'sd1
    };

    // Input to stage 0
    always_ff @(posedge clk) begin
        x[0] <= Xin;
        y[0] <= Yin;
        z[0] <= Zin;
    end

    genvar i;
    generate
        for (i = 0; i < STAGES; i++) begin : cordic_stage
            always_ff @(posedge clk) begin
                if (z[i] >= 0) begin
                    x[i+1] <= x[i] - (y[i] >>> i);
                    y[i+1] <= y[i] + (x[i] >>> i);
                    z[i+1] <= z[i] - atan_table[i];
                end else begin
                    x[i+1] <= x[i] + (y[i] >>> i);
                    y[i+1] <= y[i] - (x[i] >>> i);
                    z[i+1] <= z[i] + atan_table[i];
                end
            end
        end
    endgenerate

    // Output from last stage
    assign Xout = x[STAGES];
    assign Yout = y[STAGES];

endmodule
