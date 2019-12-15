module main(
    //49.152MHz MHz clock
    input OSC,

    //SPI Interface
    output wire SCLK,
    output wire MOSI,
    output wire CS,
    output wire CSMODE,

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

    output wire TXD,
    input wire RXD
);

localparam BITSIZE = 24;
wire [7:0] IO;

parameter	PW =18, // Number of bits in the input phase
			OW =24; // Number of output bits
reg	[(OW-1):0]		quartertable	[0:((1<<(PW-2))-1)];
initial	$readmemh("quarterwav.hex", quartertable);


// Clocking and reset
reg [30:0] divider;
reg reset = 1;
always @(posedge OSC) begin
    divider <= divider + 1;
    if (divider > 500) begin
        reset <= 0;
    end
end

// Internal clocking
wire HFOSC_internal;
reg [30:0] divider_internal;
always @(posedge HFOSC_internal) begin
    divider_internal <= divider_internal + 1;
end
SB_HFOSC #( 
   .CLKHF_DIV("0b11"), // 48 MHz /8 = 6 MHz
 ) hfosc (
    .CLKHFPU(1'b1),
    .CLKHFEN(1'b1),
    .CLKHF(HFOSC_internal)
);
wire LFOSC_internal;
SB_LFOSC lfosc (
    .CLKLFPU(1'b1),
    .CLKLFEN(1'b1),
    .CLKLF(LFOSC_internal)
);


// Codec  configuration interface
assign SCLK = sclk_w;
assign MOSI = mosi_w;
assign CS = cs_w;
assign CSMODE = 1'b1;

wire sclk_w;
wire mosi_w;
wire cs_w;
wire confdone;
configurator conf (
    .clk(divider_internal[3]),
    .spi_mosi(mosi_w), 
    .spi_sck(sclk_w),
    .cs(cs_w),
    .reset(reset),
    .done(confdone),
);

// Path
wire [BITSIZE-1:0] left1;
wire [BITSIZE-1:0] right1;
reg [BITSIZE-1:0] left2;
reg [BITSIZE-1:0] right2;

i2s_rx #( 
  .BITSIZE(BITSIZE),
) I2SRX (
  .sclk (BCLK), 
  .rst (!confdone), 
  .lrclk (ADCLRC),
  .sdata (ADCDAT),
  .left_chan (left1),
  .right_chan (right1)
);

i2s_tx #( 
  .BITSIZE(BITSIZE),
) I2STX (
    .sclk (BCLK), 
    .rst (!confdone), 
    .lrclk (DACLRC),
    .sdata (DACDAT),
    .left_chan (left2),
    .right_chan (right2)
);

// NCO
// Debug NC0
assign IO7 = DACDAT;
assign IO6 = DACLRC;
assign IO5 = BCLK;
assign IO4 = 1;

reg [BITSIZE-1:0]	phase;

always @(posedge DACLRC) begin
	// Allow for an D/A running at a lower speed from your FPGA
	phase <= phase + 174763;
end

always @(posedge DACLRC) begin
    // left2 <= {(WORD-BITSIZE){1'b0}};
    // right2 <= {(WORD-BITSIZE){1'b0}};
    left2 <= phase;
    right2 <= phase;
end

// MCLK = 49.152 MHz
// div 0 = 24.576 MHz
// div 1 = 12.288 MHz
// div 2 = 6.114 MHz
// div 3 = 3.072 MHz
// div 4 = 1.536 MHz
// div 5 = 768 kHz
// div 6 = 384 kHz
// div 7 = 192 kHz
// div 8 = 96 kHz
// div 9 = 48 kHz
// div 10 = 24 kHz
assign MCLK = divider[1];

// LED
assign LED = divider[23];


endmodule