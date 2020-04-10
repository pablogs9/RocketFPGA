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

reg [15:0] tones [0:139];
initial $readmemh("../WaveformGenerators/cromatic_48k_16bits.hex", tones);

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

wire [BITSIZE-1:0] out;
reg [BITSIZE-1:0] freq = 425;
reg enable = 1;

sinegenerator #(
    .BITSIZE(BITSIZE),
    .PHASESIZE(16),
) S1 (
    .enable(enable),
	  .lrclk(DACLRC),
    .out(out),
    .freq(freq),
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



wire [7:0] data;

uart_rx UARTRX (
    .rstn (1'b1), 
    .rx (RXD),
    .data (data),
);

always @(posedge OSC) begin
    if (data == "A")
      freq <= tones[63];
    else if (data == "S")
      freq <= tones[64];
    else if (data == "D")
      freq <= tones[65];
    else if (data == "F")
      freq <= tones[66];
    else if (data == "G")
      freq <= tones[67];
    else if (data == "H")
      freq <= tones[68];
    else if (data == "J")
      freq <= tones[69];
    else if (data == "K")
      freq <= tones[70];

    else if (data == "Q")
      freq <= tones[71];
    else if (data == "W")
      freq <= tones[72];
    else if (data == "E")
      freq <= tones[73];
    else if (data == "R")
      freq <= tones[74];
    else if (data == "T")
      freq <= tones[75];
    else if (data == "Y")
      freq <= tones[76];
    else if (data == "U")
      freq <= tones[77];
    else if (data == "I")
      freq <= tones[78];

    
    else if (data == "Z")
      freq <= tones[55];
    else if (data == "X")
      freq <= tones[56];
    else if (data == "C")
      freq <= tones[57];
    else if (data == "V")
      freq <= tones[58];
    else if (data == "B")
      freq <= tones[59];
    else if (data == "N")
      freq <= tones[60];
    else if (data == "M")
      freq <= tones[61];
    else if (data == ",")
      freq <= tones[62];

    else
      freq <= 0;
end

assign enable = (freq != 0) ? 1 : 0;

endmodule