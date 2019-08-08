module main(
    //49.152MHz MHz clock
    input OSC,

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

i2s_rx #( 
  .BITSIZE(BITSIZE),
) I2SRX (
  .bclk (MCLK), 
  .rst (RESET), 
  .lrclk (ADCLRC),
  .sdata (ADCDAT),
  .left_chan (left1),
  .right_chan (right1)
);

echo E1 (
  .bclk (MCLK), 
  .lrclk (ADCLRC),
  .right_in (right1),
  .right_out (right2)
);


i2s_tx #( 
  .BITSIZE(BITSIZE),
) I2STX (
  .bclk (MCLK), 
  .rst (RESET), 
  .lrclk (DACLRC),
  .sdata (DACDAT),
  .left_chan (left1),
  .right_chan (right2)
);

always @(posedge OSC) begin
    divider <= divider + 1;
end

assign serialdatainput = ADCDAT;
assign LED = divider[24];
assign mclk_clock = divider[1];
assign lrc_clock = divider[7];
assign MCLK = divider[1];
assign BCLK = divider[1];
assign ADCLRC = divider[7];
assign DACLRC = divider[7];


endmodule