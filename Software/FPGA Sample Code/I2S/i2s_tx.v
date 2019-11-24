module i2s_tx (
	input wire mclk,
	input wire bclk,
	input wire confdone,
	input wire lrclk,
	output reg sdata,

	input wire [BITSIZE-1:0] left_chan,
	input wire [BITSIZE-1:0] right_chan
);
parameter BITSIZE = 16;

reg [5:0]				bit_cnt = 0;
reg [BITSIZE-1:0]		left;
reg [BITSIZE-1:0]		right;

reg			        lrclk_r;
wire			    lrclk_nedge;

wire data;

always @(negedge lrclk) begin
	left <= left_chan;
	right <= right_chan;
end

always @(posedge bclk) begin
	sdata <= lrclk ? right[BITSIZE - (bit_cnt - BITSIZE/2)] : left[BITSIZE - bit_cnt];
	bit_cnt <= bit_cnt + 1;
end

endmodule