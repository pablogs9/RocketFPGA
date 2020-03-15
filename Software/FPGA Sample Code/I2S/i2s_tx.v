
module i2s_tx #(
	parameter BITSIZE	= 16
)(
	input			sclk,
	input			rst,
	input			lrclk,
	output reg		sdata,
	input [BITSIZE-1:0]	left_chan,
	input [BITSIZE-1:0]	right_chan
);
parameter WORD	= 32;

reg [BITSIZE-1:0]		bit_cnt;
reg [(2*WORD)-1:0]		data_word;
reg [BITSIZE-1:0]		prescaler = BITSIZE;

reg last_lrclk = 0;
reg buf_lrclk = 0;
wire lrclk_posedge = !last_lrclk && buf_lrclk;

always @(negedge sclk) begin
	buf_lrclk <= lrclk;
	last_lrclk <= buf_lrclk;
end

always @(posedge sclk)
	if (lrclk_posedge) 
		bit_cnt <= 2;
	else
		bit_cnt <= bit_cnt + 1;

always @(negedge sclk)
	if (!last_lrclk && lrclk) begin
		data_word <= {right_chan,{(WORD-BITSIZE){1'b0}},left_chan,{(WORD-BITSIZE){1'b0}}};
	end

always @(negedge sclk)
	if (rst) 
		sdata <= 0;
	else
		sdata <= data_word[(2*WORD)-bit_cnt];

endmodule