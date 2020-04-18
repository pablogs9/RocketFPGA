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
localparam SAMPLING = 96;

reg [15:0] tones [0:139];
// python3 ../Utils/scale_generator.py 48000 16 > cromatic_48k_16bits.hex

if (SAMPLING == 48) begin
    initial $readmemh("cromatic_48k_16bits.hex", tones);
end else if (SAMPLING == 96) begin
    initial $readmemh("cromatic_96k_16bits.hex", tones);
end


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

// Path
wire [BITSIZE-1:0] out;

localparam PHASE_SIZE = 16;
`define CALCULATE_PHASE_FROM_FREQ(f) $rtoi(f * $pow(2,PHASE_SIZE) / (SAMPLING * 1000.0))

reg [PHASE_SIZE-1:0] freq = 0;
reg [PHASE_SIZE-1:0] freq_counter = 0;

sinegenerator #(
    .BITSIZE(BITSIZE),
    .PHASESIZE(PHASE_SIZE),
    .TABLESIZE(12),
) S1 (
    .enable(1'b1),
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

always @(posedge divider[23]) begin
    if (!USER_BUTTON) begin
        freq <= tones[freq_counter];
        freq_counter <= freq_counter + 1;
    end
end


endmodule