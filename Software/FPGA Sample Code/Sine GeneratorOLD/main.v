module main(
    //49.152MHz MHz clock
    input OSC,

    //SPI Interface
    output wire SCLK,
    output wire MOSI,
    output wire MISO,
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

// Clocking
reg [30:0] divider;

always @(posedge OSC) begin
    divider <= divider + 1;
    if (divider[17]) begin
        internal_reset <= 1'b1;
    end
end

wire LFOSC_internal;
SB_LFOSC lfosc (
    .CLKLFPU(1'b1),
    .CLKLFEN(1'b1),
    .CLKLF(LFOSC_internal)
);

wire HFOSC_internal;
reg [30:0] divider_internal;
always @(posedge HFOSC_internal) begin
    divider_internal <= divider_internal + 1;
end
SB_HFOSC #( 
   .CLKHF_DIV("0b01"), // 48 MHz /8 = 6 MHz
 ) hfosc (
    .CLKHFPU(1'b1),
    .CLKHFEN(1'b1),
    .CLKHF(HFOSC_internal)
);

wire mosi_w;
wire miso_w;
wire sclk_w;

// Debug
wire [7:0] IO;
assign IO7 = sclk_w;
assign IO6 = IO[6];
assign IO5 = IO[5];
assign IO4 = IO[4];
assign MOSI = mosi_w;
assign MISO = miso_w;

configurator conf (
    .clk(HFOSC_internal), //6 MHz / 2 = 3 MHz
    .spi_mosi(mosi_w), 
    .spi_miso(miso_w), 
    .spi_sck(sclk_w),
    .cs(cs_w),
    .IO(IO),
);

// i2s_rx #( 
//   .BITSIZE(BITSIZE),
// ) I2SRX (
//   .bclk (MCLK), 
//   .rst (RESET), 
//   .lrclk (ADCLRC),
//   .sdata (ADCDAT),
//   .left_chan (left1),
//   .right_chan (right1)
// );




i2s_tx #( 
  .BITSIZE(BITSIZE),
) I2STX (
  .bclk (MCLK), 
  .rst (RESET), 
  .lrclk (DACLRC),
  .sdata (DACDAT),
  .left_chan (left2),
  .right_chan (right2)
);



wire [BITSIZE-1:0]	auxreg;

always @(posedge lrc_clock) begin
    left2 <= auxreg;
    right2 <= auxreg;
    auxreg <= auxreg + 1;
end

assign serialdatainput = ADCDAT;
assign LED = divider[23];
assign mclk_clock = divider[1];
assign lrc_clock = divider[7];
assign MCLK = divider[1];
assign BCLK = divider[1];
assign ADCLRC = divider[7];
assign DACLRC = divider[7];


endmodule