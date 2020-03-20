
module i2s_tx #(
	parameter BITSIZE	= 24
)(
	input			sclk,
	input			rst,
	input			lrclk,
	output reg		sdata,
	input [BITSIZE-1:0]	left_chan,
	input [BITSIZE-1:0]	right_chan
);

parameter BUFFER_SIZE = 64;

reg [BUFFER_SIZE-1:0] buffer;
reg [6:0] counter;
always @(posedge sclk) begin
	if (lrclk) begin
		buffer <= {left_chan, right_chan, {BUFFER_SIZE-(2*BITSIZE){1'b0}}};
		counter = 0;
	end else begin
		counter <= counter + 1;
	end
end

always @(negedge sclk) begin
	sdata <= buffer[BUFFER_SIZE-1-counter];
end

endmodule