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
reg [BITSIZE-1:0] freq = 0;
sinegenerator #(
    .BITSIZE(BITSIZE),
    .PHASESIZE(16),
    .TABLESIZE(12),
) S1 (
    .enable(1'b1),
	.lrclk(DACLRC),
    .out(sineout),
    .freq(freq),
);

wire signed  [BITSIZE-1:0] out;
// lowpassfilter #(
//     .BITSIZE(BITSIZE),
// ) F1 (
//     .clk(DACLRC),
//     .alpha(16),
//     .in(sineout), 
//     .out(out),
// );


// F = 2sin(π*Fc/Fs)
// asin(F/2) = pi*Fc/Fs
// asin(F/2)*Fs/pi = Fc

`define CALCULATE_FREQUENCY(fc) $rtoi(2.0 * $sin(3.1416 * (fc/48000) / (SAMPLING*1000)) )
`define CALCULATE_Q(q) $rtoi(1/q)

parametericfilter #(
    .BITSIZE(BITSIZE),
) F2 (
  .clk(BCLK),
  .sample_clk(DACLRC),
  .in(sineout),
  .out_highpass(),
  .out_lowpass(out),
  .out_bandpass(),
  .out_notch(out),
  .F(18'b000100000000000000),  /* F1: frequency control; fixed point 1.17  ; F = 2sin(π*Fc/Fs).  At a sample rate of 250kHz, F ranges from 0.00050 (10Hz) -> ~0.55 (22kHz) */
  .Q1(`CALCULATE_Q(0.5))  /* Q1: Q control;         fixed point 2.16  ; Q1 = 1/Q        Q1 ranges from 2 (Q=0.5) to 0 (Q = infinity). */
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

always @(posedge divider[20] ) begin
    if (!USER_BUTTON) begin
        freq <= freq + 100;
    end
end

// assign LED = divider[24];

endmodule