
module i2s_tx #(
	parameter BITSIZE	= 32
)(
	input			sclk,
	input			rst,
	input		lrclk,
	output reg		sdata,
	input [BITSIZE-1:0]	left_chan,
	input [BITSIZE-1:0]	right_chan
);

reg [BITSIZE-1:0]		bit_cnt;
reg [BITSIZE-1:0]		left;
reg [BITSIZE-1:0]		right;
reg [BITSIZE-1:0]		prescaler = BITSIZE;

always @(negedge sclk)
	if (rst)
		bit_cnt <= 1;
	else if (bit_cnt >= prescaler)
		bit_cnt <= 1;
	else
		bit_cnt <= bit_cnt + 1;

// Sample channels on the transfer of the last bit of the right channel
always @(negedge sclk)
	if (bit_cnt == prescaler && lrclk) begin
		left <= left_chan;
		right <= right_chan;
	end

// left/right "clock" generation - 0 = left, 1 = right
// always @(negedge sclk)
// 	if (rst)
// 		lrclk <= 1;
// 	else if (bit_cnt == prescaler)
// 		lrclk <= ~lrclk;

always @(negedge sclk)
	sdata <= lrclk ? right[BITSIZE - bit_cnt] : left[BITSIZE - bit_cnt];

endmodule