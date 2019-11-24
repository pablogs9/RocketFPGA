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
    output wire BCLK,
    output wire ADCLRC,
    output wire DACLRC,
    input wire ADCDAT,
    output wire DACDAT,

    output wire LED,
    input wire RESET,

    output wire TXD,
    input wire RXD
);

localparam BITSIZE = 16;

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

wire [7:0] IO;
// Debug SPI
// assign IO7 = sclk_w;
// assign IO6 = mosi_w;
// assign IO5 = cs_w;
// assign IO4 = confdone;

// Debug I2S
assign IO7 = ADCDAT;
assign IO6 = ADCLRC;
assign IO5 = BCLK;
assign IO4 = DACDAT;


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
wire [BITSIZE-1:0] left2;
wire [BITSIZE-1:0] right2;

i2s_rx #( 
  .BITSIZE(BITSIZE),
) I2SRX (
  .sclk (BCLK), 
  .rst (!confdone), 
  .lrclk (ADCLRC),
  .sdata (ADCDAT),
  .left_chan (left2),
  .right_chan (right2)
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

reg [BITSIZE-1:0] auxreg = 0;

// reg [20:0]	inc = 150000;
// reg [50:0]	phase;
// The initial value is usually irrelevant
// always @(posedge divider[13]) begin
//     inc <= inc + 300;
// end

// always @(posedge OSC)
// 	// Allow for an D/A running at a lower speed from your FPGA
// 	if (lrc_clock)
// 		phase <= phase + inc;

// always @(posedge lrc_clock) begin
//     auxreg <= phase[50:34];
//     left2 <= auxreg;
//     right2 <= auxreg;
// end

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
assign BCLK = divider[4];

// LRCLK
assign lrc_clock = divider[9];
assign ADCLRC = divider[9];
assign DACLRC = divider[9];


// LED
assign LED = divider[23];


endmodule