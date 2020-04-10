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

wire signed  [BITSIZE-1:0] sineout;

localparam PHASE_SIZE = 16;

`define CALCULATE_PHASE_FROM_FREQ(f) $rtoi(f * $pow(2,PHASE_SIZE) / (SAMPLING * 1000.0))

sinegenerator #(
    .BITSIZE(BITSIZE),
    .PHASESIZE(PHASE_SIZE),
    .TABLESIZE(12),
) S1 (
    .enable(1'b1),
	.lrclk(DACLRC),
    .out(sineout),
    .freq(`CALCULATE_PHASE_FROM_FREQ(100.0)),
);

wire quarter_output;

tempo #(
	.BPM(120),
	.GENERATE_CLOCK(1),
) T1 (
    .quarter(quarter_output),
);

wire [7:0] envelope;

envelope_generator #(
    .SAMPLE_CLK_FREQ(48000),
    .ACCUMULATOR_BITS(26),
) ENV1 (
    .clk(DACLRC),
    .gate(quarter_output),
    .a(4'b1000),
    .d(4'b1001),
    .s(4'b1000),
    .r(4'b1001),
    .amplitude(envelope),
    .rst(1'b1)
);

wire signed [BITSIZE-1:0] out;
reg [5:0] cola;
assign cola = {6{envelope[0]}};

multiplier #(
    .BITSIZE(BITSIZE),
) M1 (
	.in1({2'b00, envelope, 6'b000000}),
	.in2(sineout),
    .out(out),
);

wire signed [BITSIZE-1:0] outfiltered;

lowpassfilter #(
  .DATA_BITS(BITSIZE),
) LPF1 (
  .clk(BCLK),
  .s_alpha(2), 
  .din(out), 
  .dout(outfiltered),
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

assign LED = quarter_output;

endmodule