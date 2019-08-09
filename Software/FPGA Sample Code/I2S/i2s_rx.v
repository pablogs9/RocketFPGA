module i2s_rx #(
	parameter BITSIZE = 24
)(
	input bclk,
	input wire rst,
	input wire lrclk,
	input wire sdata,

	output reg [BITSIZE-1:0] left_chan,
	output reg [BITSIZE-1:0] right_chan
);

reg [BITSIZE-1:0]	left;
reg [BITSIZE-1:0]	right;
reg			        lrclk_r;
wire			    lrclk_nedge;

assign lrclk_nedge = !lrclk & lrclk_r;

always @(posedge bclk) begin
	lrclk_r <= lrclk;
end

always @(posedge bclk) begin
	if (lrclk_r)
		right <= {right[BITSIZE-2:0], sdata};
	else
		left <= {left[BITSIZE-2:0], sdata};
end

always @(posedge bclk) begin
	if (rst) begin
		left_chan <= 0;
		right_chan <= 0;
	end else if (lrclk_nedge) begin
		left_chan <= left;
		right_chan <= {right[BITSIZE-2:0], sdata};
	end
end

endmodule