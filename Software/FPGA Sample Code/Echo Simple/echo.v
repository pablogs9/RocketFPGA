module echo(	
	input wire bclk,
	input wire lrclk,

	input wire [DATALEN-1:0] right_in,
	output reg [DATALEN-1:0] right_out,
);

localparam ADDRLEN = 14;
localparam DATALEN = 16;

reg [ADDRLEN-1:0] rd_ptr = 0;
reg [ADDRLEN-1:0] wr_ptr = (2**ADDRLEN)/2;

reg [2:0] sm = 0;

reg wren;
reg [ADDRLEN-1:0] memaddr;
reg [DATALEN-1:0] datain;
reg [DATALEN-1:0] dataout;

SB_SPRAM256KA M1 (
    .ADDRESS(memaddr),
    .DATAIN(datain),
    .MASKWREN(4'b1111),
    .WREN(wren),
    .CHIPSELECT(1'b1),
    .CLOCK(bclk),
    .STANDBY(1'b0),
    .SLEEP(1'b0),
    .POWEROFF(1'b1),
    .DATAOUT(dataout)
  );

always @(posedge lrclk) begin
	sm <= 1;
end

always @(posedge bclk) begin
	if (sm === 1) begin
		datain <= right_in;
		wren <= 1;
		memaddr <= wr_ptr;
		sm <= 2;
	end else if (sm === 2) begin
		wren <= 0;
		memaddr <= rd_ptr;
		sm <= 3;
	end else if (sm === 3) begin
		right_out <= dataout;
		wr_ptr <= (wr_ptr + 1);
		rd_ptr <= (rd_ptr + 1);
		sm <= 0;
	end
end

endmodule