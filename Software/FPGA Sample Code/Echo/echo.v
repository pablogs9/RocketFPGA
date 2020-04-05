module echo #(
	parameter BITSIZE = 16
)(	
	input wire enable,

	input wire bclk,    // 64 times lrclk 
	input wire lrclk,

	input wire [ADDRLEN-1:0] offset,

	input wire signed [BITSIZE-1:0] in,
	output wire signed [BITSIZE-1:0] out,
);

if (BITSIZE == 24) begin
    $error("ECHO SUPPORT FOR 24 NOT AVAILABLE YET");
end

localparam ADDRLEN = 14;

reg [ADDRLEN-1:0] wr_ptr = 0;

reg [2:0] counter = 0;
reg cleaning = 1;

reg wren;
reg [ADDRLEN-1:0] memaddr;
reg signed [BITSIZE-1:0] datain;
reg signed [BITSIZE-1:0] dataout;
wire signed [BITSIZE-1:0] outbuff;

SB_SPRAM256KA M1 (
  .ADDRESS (memaddr), 
  .DATAIN (datain), 
  .DATAOUT (outbuff),
  .MASKWREN (4'b1111),
  .WREN (wren),
  .CHIPSELECT (1'b1),
  .CLOCK (bclk),
  .STANDBY (1'b0),
  .SLEEP (1'b0),
  .POWEROFF (1'b1)
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