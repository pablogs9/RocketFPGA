module main(
    //49.152MHz MHz clock
    input OSC,

    //I2C Interface
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
);

localparam BITSIZE = 16;

// Clocking
reg [30:0] divider;
wire mclk_clock;
wire lrc_clock;


// Parallel Data Buses
wire [BITSIZE-1:0]	left1;
wire [BITSIZE-1:0]	right1;
wire [BITSIZE-1:0]	left2;
wire [BITSIZE-1:0]	right2;
wire [BITSIZE-1:0]	left3;
wire [BITSIZE-1:0]	right3;
// I2S Bus
wire serialdatainput;
wire serialdataoutput;

wire mosi_w;
wire sclk_w;
wire cs_w;

assign CS = cs_w;
assign CSMODE = 1'b1;

wire internalout;
SB_LFOSC hfosc (
    .CLKLFPU(1'b1),
    .CLKLFEN(1'b1),
    .CLKLF(internalout)
);

assign IO7 = internalout;
assign IO6 = mosi_w;
assign IO5 = internalout;
assign IO4 = cs_w;


configurator conf (
    .clk(internalout),
    .spi_mosi(mosi_w), 
    .spi_sck(sclk_w),
    .cs(cs_w)
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

always @(posedge OSC) begin
    divider <= divider + 1;
end

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