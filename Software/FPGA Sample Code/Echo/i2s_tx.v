module i2s_tx (
	input wire bclk,
	input wire rst,
	input wire lrclk,
	output reg sdata,

	input wire [BITSIZE-1:0] left_chan,
	input wire [BITSIZE-1:0] right_chan
);
parameter BITSIZE = 24;

reg [5:0]		bit_cnt;
reg [BITSIZE-1:0]		left;
reg [BITSIZE-1:0]		right;

reg			        lrclk_r;
wire			    lrclk_nedge;

wire data;

assign lrclk_nedge = !lrclk & lrclk_r;

always @(posedge lrclk_nedge) begin
	left <= left_chan;
	right <= right_chan;
	// bit_cnt <= 1;
end

always @(negedge bclk) begin
	lrclk_r <= lrclk;
	bit_cnt <= bit_cnt + 1;
end

always @(negedge bclk) begin
	sdata <= lrclk ? right[BITSIZE - (bit_cnt - 32)] : left[BITSIZE - bit_cnt];
end

endmodule