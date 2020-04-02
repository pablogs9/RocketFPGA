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

    output wire TXD,
    input wire RXD,

    output wire CAPACITOR,
    output wire POT_1,
    output wire POT_2,
    input wire DIFF_IN,
);

localparam BITSIZE = 16;

reg [15:0] tones [0:119];
initial $readmemh("cromatic.hex", tones);

// Clocking and reset
reg [30:0] divider;
always @(posedge OSC) begin
    divider <= divider + 1;
end

assign MCLK = divider[1]; //12.288 MHz

configurator #(
    .BITSIZE(BITSIZE),
)conf (
    .clk(divider[6]),
    .spi_mosi(MOSI), 
    .spi_sck(SCLK),
    .cs(CS),
);

// Path
wire signed [BITSIZE-1:0] left2;
wire signed [BITSIZE-1:0] right2;

reg [15:0] freq;
reg [15:0] freq_counter = 0;


wire [15:0] mod;
wire [5:0] adcout;

adc #(
    .OUTSIZE(8),
) ADC1 (
	.pot_1(POT_1),
	.pot_2(POT_2),
	.capacitor(CAPACITOR),
	.osc(OSC),			// 49.152 MHz
	.sense(DIFF_IN),
	.out(adcout)
);

sinegenerator #(
    .BITSIZE(6),
    .PHASESIZE(16),
) S1 (
    .enable(!USER_BUTTON),
	.lrclk(DACLRC),
    .out(mod),
    .freq(adcout),
);

sinegenerator #(
    .BITSIZE(BITSIZE),
    .PHASESIZE(16),
) S2 (
    .enable(!USER_BUTTON),
	.lrclk(DACLRC),
    .out(right2),
    .freq(freq),
);

echo #( 
  .BITSIZE(BITSIZE),
) E1 (
  .enable(1'b1),
  .bclk (BCLK), 
  .lrclk (ADCLRC),
  .left_in (right2>>>1),
  .right_in (right2>>>1),
  .left_out (left2),
  .right_out (left2)
);

i2s_tx #( 
    .BITSIZE(BITSIZE),
) I2STX (
    .sclk (BCLK), 
    .lrclk (DACLRC),
    .sdata (DACDAT),
    .left_chan (right2),
    .right_chan (right2)
);

always @(posedge divider[23]) begin
    freq <= tones[freq_counter];
    freq_counter <= freq_counter + 1;
end

// LED
// assign LED = !USER_BUTTON;

// assign IO7 = divider[16];
// assign IO6 = aux;
// assign IO5 = DACLRC;
// assign IO4 = DACDAT;

endmodule