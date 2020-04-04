module main(
    //49.152MHz MHz clock
    input OSC,

    //SPI Interface
    output wire SCLK,
    output wire MOSI,
    output wire CS,

    output wire IO7,
    output wire IO6,
    output wire IO5,
    output wire IO4,


    //I2S Interface
    output wire MCLK,
    input wire BCLK,
    input wire ADCLRC,
    input wire DACLRC,
    input wire ADCDAT,
    output wire DACDAT,

    output wire LED,
    input wire RESET,
    input wire USER_BUTTON,

    input wire PRE_RESET,
    input wire RXD,

    output wire CAPACITOR,
    output wire POT_1,
    output wire POT_2,
    input wire DIFF_IN,
);

localparam BITSIZE = 16;

// Clocking and reset
reg [30:0] divider;
always @(posedge OSC) begin
    divider <= divider + 1;
end

assign MCLK = divider[1]; //12.288 MHz

configurator #(
    .BITSIZE(BITSIZE),
    .LINE_NOMIC(1'b0),
    .ENABLE_MICBOOST(1'b1),
)conf (
    .clk(divider[6]),
    .spi_mosi(MOSI), 
    .spi_sck(SCLK),
    .cs(CS),
    .prereset(PRE_RESET),
);

wire signed [BITSIZE-1:0] mic;

i2s_rx #( 
  .BITSIZE(BITSIZE),
) I2SRX (
  .sclk (BCLK), 
  .lrclk (ADCLRC),
  .sdata (ADCDAT),
  .left_chan (mic),
);

wire signed [BITSIZE-1:0] sine1;

sinegenerator #(
    .BITSIZE(BITSIZE),
    .PHASESIZE(16),
) S1 (
    .enable(1'b1),
	.lrclk(DACLRC),
    .out(sine1),
    .freq(21), // 11 - 220 Hz
);

wire signed [BITSIZE-1:0] sine2;

sinegenerator #(
    .BITSIZE(BITSIZE),
    .PHASESIZE(16),
) S2 (
    .enable(1'b1),
	.lrclk(DACLRC),
    .out(sine2),
    .freq(2403), // 1760 Hz
);

wire signed [BITSIZE-1:0] out_mult;

multiplier #(
    .BITSIZE(BITSIZE),
) M1 (
	.lrclk(DACLRC),
	.bclk(BCLK),
	.in1((2**BITSIZE/2) + sine1 >>> 2),
	.in2(sine2 >>> 1),
    .out(out_mult),
);

wire signed [BITSIZE-1:0] out_mult2;

multiplier #(
    .BITSIZE(BITSIZE),
) M2 (
	.lrclk(DACLRC),
	.bclk(BCLK),
	.in1((sine1 >>> 4)),
	.in2(mic >>> 2),
    .out(out_mult2),
);

wire signed [BITSIZE-1:0] out_echo;

echo #( 
  .BITSIZE(BITSIZE),
) E1 (
  .enable(!USER_BUTTON),
  .bclk (BCLK), 
  .lrclk (ADCLRC),
  .in (mic),
  .out (out_echo),
);

i2s_tx #( 
    .BITSIZE(BITSIZE),
) I2STX (
    .sclk (BCLK), 
    .lrclk (DACLRC),
    .sdata (DACDAT),
    .left_chan (out_echo),
    .right_chan (out_echo)
);

endmodule