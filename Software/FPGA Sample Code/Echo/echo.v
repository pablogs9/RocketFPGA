module echo #(
	parameter BITSIZE = 16,
	parameter LENGHT = 1,
)(	
	input wire enable,

	input wire bclk,    // 64 times lrclk 
	input wire lrclk,

	input wire [16:0] offset,

	input wire signed [BITSIZE-1:0] in,
	output wire signed [BITSIZE-1:0] out,
);

if (BITSIZE == 24) begin
    $error("ECHO SUPPORT FOR 24 NOT AVAILABLE YET");
end

localparam ADDRLEN = (LENGHT == 4) ? 16 : ((LENGHT == 2) ? 15 : 14);

reg [ADDRLEN-1:0] wr_ptr = 0;

reg [2:0] counter = 0;
reg cleaning = 1;

reg wren;
reg [ADDRLEN-1:0] memaddr;
reg signed [BITSIZE-1:0] datain;
reg signed [BITSIZE-1:0] dataout;
wire signed [BITSIZE-1:0] outbuff;

memory  #( 
   .BITSIZE(BITSIZE),
   .LENGHT(LENGHT),
) M1 (
    .clk(bclk),
    .addr(memaddr),
    .datain(datain),
    .dataout(dataout),
	.wren(wren)
);

always @(posedge lrclk) begin
	if (cleaning) 
		out <= 0;
	else if (enable)
		out <= dataout;
	else
		out <= in;
end

always @(posedge bclk) begin
	if(lrclk)
		counter <= 1;
	
	if (wr_ptr == (2**ADDRLEN)-1)
		cleaning <= 0;
		
	if (counter == 1) begin
		if (cleaning)
			datain <= 0;
		else
			datain <= (in >>> 1) +  (dataout >>> 1);
		wren <= 1;
		memaddr <= wr_ptr;
		counter <= counter + 1;
	end else if (counter == 2) begin
		wren <= 0;
		memaddr <= wr_ptr + offset;  //Here is where lenght of echo is set
		counter <= counter + 1; 
	end else if (counter == 3) begin
		dataout <= outbuff;
		wr_ptr <= wr_ptr + 1;
		counter <= counter + 1;
	end
end

endmodule