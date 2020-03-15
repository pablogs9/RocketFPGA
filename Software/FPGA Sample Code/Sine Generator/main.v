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

reg	[BITSIZE-1:0] quartertable [0:((1<<TABLE)-1)];
initial	$readmemh("testtable.hex", quartertable);

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

reg [PHASE-1:0]	phase;
reg [TABLE-1:0] index;
reg [BITSIZE-1:0] val;
reg [BITSIZE-1:0] sine_out;


// reg [PHASE-1:0] step;
// initial step = 1365; // Start at 1 kHz

// always @(posedge divider[23]) begin
// 	step <= step + 137; // Increase 100 Hz at led rate
// end

always @(posedge DACLRC) begin
	phase <= phase + 1365;
end

always @(posedge DACLRC) begin
    if (phase[PHASE-2])
        index <= ~phase[PHASE-3:PHASE-TABLE-2];
    else
        index <= phase[PHASE-3:PHASE-TABLE-2];

    val <=  quartertable[index];

    if (phase[PHASE-1]) begin
        sine_out <= -val;
        end
    else begin
        sine_out <= val;
    end
end

assign right2 = sine_out;
assign left2 = sine_out;

// div 1 = 12.288 MHz
assign MCLK = divider[1];

// LED
assign LED = divider[23];


endmodule