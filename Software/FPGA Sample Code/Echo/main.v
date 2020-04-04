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

    output wire PRE_RESET,
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
)conf (
    .clk(divider[6]),
    .spi_mosi(MOSI), 
    .spi_sck(SCLK),
    .cs(CS),
    .prereset(PRE_RESET),
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
  .lrclk (ADCLRC),
  .sdata (ADCDAT),
  .left_chan (left1),
  .right_chan (right1)
);

echo #( 
  .BITSIZE(BITSIZE),
) E1 (
  .enable(!USER_BUTTON),
  .bclk (BCLK), 
  .lrclk (ADCLRC),
  .left_in (left1),
  .right_in (right1),
  .left_out (left2),
  .right_out (right2)
);

i2s_tx #( 
  .BITSIZE(BITSIZE),
) I2STX (
    .sclk (BCLK), 
    .lrclk (DACLRC),
    .sdata (DACDAT),
    .left_chan (left2),
    .right_chan (right2)
);

// LED
assign LED = !USER_BUTTON;

// assign IO7 = divider[16];
// assign IO6 = aux;
// assign IO5 = DACLRC;
// assign IO4 = DACDAT;

endmodule