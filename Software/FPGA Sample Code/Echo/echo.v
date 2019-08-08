module echo #(
	parameter BITSIZE = 24
)(	
	// Parallel audio interface
	input wire bclk,
	input wire lrclk,

	input wire [DATALEN-1:0] left_in,
	input wire [DATALEN-1:0] right_in,

	output reg [DATALEN-1:0] left_out,
	output reg [DATALEN-1:0] right_out,
);
localparam N = 7;
localparam NPOS = 2**N;
localparam ADDRLEN = 14;
localparam DATALEN = 16;

reg [N-1:0] rd_ptr = 0;
reg [N-1:0] wr_ptr = NPOS/2;

reg [2:0] counter = 0;

wire wren;
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
    .POWEROFF(1'b0),
    .DATAOUT(dataout)
  );

always @(posedge lrclk) begin
	left_out <= left_in;
	counter <= 1;
end

always @(posedge bclk) begin
	if (counter === 1) begin
		datain <= right_in;
		wren <= 1;
		memaddr <= wr_ptr;
		counter <= 2;
	end else if (counter === 2) begin
		wren <= 0;
		memaddr <= rd_ptr;
		counter <= 3;
	end else if (counter === 3) begin
		right_out <= dataout;
		wr_ptr <= ((wr_ptr + 1) % NPOS);
		rd_ptr <= ((rd_ptr + 1) % NPOS);
		counter <= 0;
	end
end

endmodule