
module i2s_rx #(
	parameter AUDIO_DW		= 32
)(
	input				sclk,
	input				rst,

	input				lrclk,
	input				sdata,

	// Parallel datastreams
	output reg [AUDIO_DW-1:0]	left_chan,
	output reg [AUDIO_DW-1:0]	right_chan
);

reg [AUDIO_DW-1:0]	left;
reg [AUDIO_DW-1:0]	right;
reg			lrclk_r;
wire			lrclk_nedge;

assign lrclk_nedge = !lrclk & lrclk_r;

always @(posedge sclk)
	lrclk_r <= lrclk;

// sdata msb is valid one clock cycle after lrclk switches
always @(posedge sclk)
	if (lrclk_r)
		right <= {right[AUDIO_DW-2:0], sdata};
	else
		left <= {left[AUDIO_DW-2:0], sdata};

always @(posedge sclk)
	if (rst) begin
		left_chan <= 0;
		right_chan <= 0;
	end else if (lrclk_nedge) begin
		left_chan <= left;
		right_chan <= {right[AUDIO_DW-2:0], sdata};
	end

endmodule