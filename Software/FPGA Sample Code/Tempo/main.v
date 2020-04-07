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

wire quarter_output;
reg quarter_reg;

wire quarter2_output;
reg quarter2_reg;

always @(posedge OSC ) begin
    quarter_reg <= quarter_output;
    quarter2_reg <= quarter2_output;
end

wire tempo_clock;

tempo #(
	.BPM(180),
	.GENERATE_CLOCK(1),
) T1 (
    .whole(),
    .half(),
    .quarter(quarter_output),
    .eighth(),
    .sixteenth(),
    .thirtysecond(),
    .sixtyfourth(),
    .clock_out(tempo_clock),
);

tempo #(
	.BPM(60),
	.GENERATE_CLOCK(0),
) T2 (
    .clock_in(tempo_clock),
    .whole(),
    .half(),
    .quarter(quarter2_output),
    .eighth(),
    .sixteenth(),
    .thirtysecond(),
    .sixtyfourth(),
);

assign IO7 = quarter_reg;
assign IO6 = quarter2_reg;

endmodule