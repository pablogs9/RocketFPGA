module i2s_rx #(
	parameter BITSIZE		= 24
)(
	input				sclk,
	input				rst,
	input				lrclk,
	input				sdata,
	output reg [BITSIZE-1:0]	left_chan,
	output reg [BITSIZE-1:0]	right_chan
);

parameter WORD	= 32;

reg [WORD-1:0]	left;
reg [WORD-1:0]	right;
reg					lrclk_r;
wire				lrclk_nedge;

assign lrclk_nedge = !lrclk & lrclk_r;

always @(posedge sclk)
	lrclk_r <= lrclk;

always @(posedge sclk)
	if (lrclk_r)
		right <= {right[WORD-2:0], sdata};
	else
		left <= {left[WORD-2:0], sdata};

always @(posedge sclk)
	if (rst) begin
		left_chan <= 0;
		right_chan <= 0;
	end else if (lrclk_nedge) begin
		left_chan <= left[WORD-1:WORD-1-BITSIZE];
		right_chan <= right[WORD-1:WORD-1-BITSIZE];
		// right_chan <= {right[WORD-2:0], sdata};
	end

endmodule