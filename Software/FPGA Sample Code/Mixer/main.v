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

localparam BITSIZE = 24;

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
wire [BITSIZE-1:0] sine1;
wire [BITSIZE-1:0] sine2;
wire [BITSIZE-1:0] n1;
wire [BITSIZE-1:0] n2;
wire [BITSIZE-1:0] out;

reg counter = 0;
always @(posedge divider[23]) begin
    if (counter) begin
        n1 <= 24'b001000000000000000000000;
        n2 <= 24'b000100000000000000000000;
    end else begin
        n1 <= 24'b000100000000000000000000;
        n2 <= 24'b001000000000000000000000;
    end
    counter <= !counter;
end

sinegenerator #(
    .BITSIZE(BITSIZE),
    .PHASESIZE(16),
) S1 (
    .enable(1'b1),
	.lrclk(DACLRC),
    .out(sine1),
    .freq(601),
);

sinegenerator #(
    .BITSIZE(BITSIZE),
    .PHASESIZE(16),
) S2 (
    .enable(1'b1),
	.lrclk(DACLRC),
    .out(sine2),
    .freq(7629),
);

mixer #(
    .BITSIZE(BITSIZE),
) M1 (
	.lrclk(DACLRC),
	.bclk(BCLK),
	.in1(sine1),
	.in2(sine2),
	.n1(n1),
	.n2(n2),
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

endmodule