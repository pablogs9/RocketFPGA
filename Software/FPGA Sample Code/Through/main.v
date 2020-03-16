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
localparam PHASE = 16;
localparam TABLE = 9;

wire [7:0] IO;

assign IO7 = DACDAT;
assign IO6 = ADCLRC;
assign IO5 = BCLK;
assign IO4 = ADCDAT;

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
wire [BITSIZE-1:0] left2;
wire [BITSIZE-1:0] right2;

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

assign right2 = right1;
assign left2 = left1;


// div 1 = 12.288 MHz
assign MCLK = divider[1];

// LED
assign LED = divider[23];


endmodule