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

parameter BUFFER_SIZE = 64;

reg [BUFFER_SIZE-1:0] buffer; //63:0

always @(posedge sclk) begin
	if (lrclk) begin
		left_chan <= buffer[BUFFER_SIZE-1:BUFFER_SIZE-1-BITSIZE]; //63:39
		right_chan <= buffer[BUFFER_SIZE-1-BITSIZE:BUFFER_SIZE-1-BITSIZE-BITSIZE]; //38:14
	end else begin
		buffer <= {buffer[BUFFER_SIZE-2:0], sdata};
	end
end

endmodule