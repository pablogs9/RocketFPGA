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
    input wire TXD,
    input wire RXD,

    output wire CAPACITOR,
    output wire POT_1,
    output wire POT_2,
    input wire DIFF_IN,
);

localparam BITSIZE = 16;
localparam SAMPLING = 48;


// Clocking and reset
reg [30:0] divider;
always @(posedge OSC) begin
    divider <= divider + 1;
end

assign MCLK = divider[1]; //12.288 MHz

configurator #(
    .BITSIZE(BITSIZE),
    .SAMPLING(SAMPLING),
)conf (
    .clk(divider[6]),
    .spi_mosi(MOSI), 
    .spi_sck(SCLK),
    .cs(CS),
    .prereset(PRE_RESET),
);


localparam PHASE_SIZE = 16;
`define CALCULATE_PHASE_FROM_FREQ(f) $rtoi(f * $pow(2,PHASE_SIZE) / (SAMPLING * 1000.0))

wire signed  [BITSIZE-1:0] sineout;
sinegenerator #(
    .BITSIZE(BITSIZE),
    .PHASESIZE(PHASE_SIZE),
    .TABLESIZE(12),
) S1 (
    .enable(1'b1),
	.lrclk(DACLRC),
    .out(sineout),
    .freq((divider[24]) ? `CALCULATE_PHASE_FROM_FREQ(100.0) : `CALCULATE_PHASE_FROM_FREQ(200.0)),
);

wire signed [BITSIZE-1:0] envelope;
envelope_generator #(
    .SAMPLE_CLK_FREQ(48000),
    .ACCUMULATOR_BITS(26),
) ENV1 (
    .clk(DACLRC),
    .gate(divider[23]),
    .a(4'b0001),
    .d(4'b1000),
    .s(4'b0000),
    .r(4'b0000),
    .amplitude(envelope),
);

wire signed [BITSIZE-1:0] out;
multiplier #(
    .BITSIZE(BITSIZE),
) M1 (
    .clk(OSC),
	.in1({envelope}),
	.in2(sineout),
    .out(out),
);

i2s_tx #( 
    .BITSIZE(BITSIZE),
) I2STX (
    .sclk (BCLK), 
    .lrclk (DACLRC),
    .sdata (DACDAT),
    .left_chan (out),
    .right_chan (out)
);

// assign LED = divider[24];

endmodule