module echo #(
	parameter BITSIZE = 24
)(	
	input wire bclk,
	input wire lrclk,

	input wire [DATALEN-1:0] left_in,
	input wire [DATALEN-1:0] right_in,

	output reg [DATALEN-1:0] left_out,
	output reg [DATALEN-1:0] right_out,
);
localparam N = 7;
localparam NPOS = 2**N;
localparam ADDRLEN = 14 + 2;
localparam DATALEN = 16;

reg [ADDRLEN-1:0] rd_ptr = 0;
reg [ADDRLEN-1:0] wr_ptr = 10;

reg [5:0] counter = 0;

reg wren;
reg [ADDRLEN-1:0] memaddr;
reg [DATALEN-1:0] datain;
reg [DATALEN-1:0] dataout;

// assign right_out = dataout +  right_out;

memory M1 (
    .clk(bclk),
    .addr(memaddr),
    .datain(datain),
    .dataout(dataout),
);

always @(posedge lrclk) begin
	left_out <= left_in;
end

always @(posedge bclk) begin
	counter <= counter + 1;
	if (counter === 1) begin
		datain <= dataout/2 + right_in/2;
		wren <= 1;
		memaddr <= wr_ptr;
	end else if (counter === 2) begin
		wren <= 0;
		memaddr <= rd_ptr;
	end else if (counter === 3) begin
		right_out <= dataout/2 + right_in/2;
		wr_ptr <= ((wr_ptr + 1) % NPOS);
		rd_ptr <= ((rd_ptr + 1) % NPOS);
	end
end

endmodule