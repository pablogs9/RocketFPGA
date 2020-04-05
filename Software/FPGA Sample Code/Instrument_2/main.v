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


wire signed [BITSIZE-1:0] out_echo;

echo #( 
  .BITSIZE(BITSIZE),
  .LENGHT(1),
) E1 (
  .enable(!USER_BUTTON),
  .bclk (BCLK), 
  .lrclk (ADCLRC), 
  .offset(1),
  .in (mic),
  .out (out_echo),
);

wire signed [BITSIZE-1:0] out_mixer;

mixer2 #(
    .BITSIZE(BITSIZE),
) MIX1 (
    .in1(out_echo),
    .n1(16'b0100100000000000),
    .in2(mic),
    .n2(16'b0100100000000000),
    .out(out_mixer),
);

i2s_tx #( 
    .BITSIZE(BITSIZE),
) I2STX (
    .sclk (BCLK), 
    .lrclk (DACLRC),
    .sdata (DACDAT),
    .left_chan (out_mixer),
    .right_chan (out_mixer)
);

endmodule