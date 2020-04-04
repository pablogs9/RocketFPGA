module echo #(
	parameter BITSIZE = 16
)(	
	input wire enable,

	input wire bclk,    // 64 times lrclk 
	input wire lrclk,

	input wire signed [BITSIZE-1:0] left_in,
	input wire signed [BITSIZE-1:0] right_in,

	output wire [BITSIZE-1:0] left_out,
	output wire [BITSIZE-1:0] right_out,
);

if (BITSIZE == 24) begin
    $error("ECHO SUPPORT FOR 24 NOT AVAILABLE YET");
end

localparam ADDRLEN = 16;

reg [ADDRLEN-1:0] rd_ptr = 1;
reg [ADDRLEN-1:0] wr_ptr = 0;

reg [2:0] counter = 0;

reg wren;
reg [ADDRLEN-1:0] memaddr;
reg signed [BITSIZE-1:0] datain;
reg signed [BITSIZE-1:0] dataout;

memory  #( 
   .BITSIZE(BITSIZE),
   .ADDRLEN(ADDRLEN),
) M1 (
    .clk(bclk),
    .addr(memaddr),
    .datain(datain),
    .dataout(dataout),
	.wren(wren)
);

always @(posedge lrclk) begin
	if (enable) begin
		left_out <= (left_in >>> 1) + (dataout >>> 1);
		right_out <= (right_in >>> 1) + (dataout >>> 1);
	end else begin
		left_out <= left_in;
		right_out <= right_in;
	end

end

always @(posedge bclk) begin

	if(lrclk)
		counter <= 1;
		
	if (counter == 1) begin
		datain <= (left_in >>> 2) + (right_in >>> 2) + (dataout >>> 2);
		wren <= 1;
		memaddr <= wr_ptr;
		counter <= counter + 1;
	end else if (counter == 2) begin
		wren <= 0;
		memaddr <= rd_ptr;
		counter <= counter + 1;
	end else if (counter == 3) begin
		wr_ptr <= wr_ptr + 1;
		rd_ptr <= rd_ptr + 1;
		counter <= counter + 1;
	end
end

endmodule