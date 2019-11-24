module configurator(	
	input wire clk,
	output reg cs,
	output wire spi_mosi, 
	input wire spi_miso, 
	output wire spi_sck,

	output wire [7:0] IO,
);

reg reset = 1'b1;
wire ready;
wire readyreset;
reg internal_cs = 1'b0;

reg strobe = 1'b0;
reg ack;

reg  [7:0] write_data;
wire  [7:0] read_data;
reg  [7:0] address;
reg send = 1'b0;
reg wr = 1'b1;

reg [3:0] state = 0;

// Delayed init
reg [30:0] delayregister;
always @(posedge clk) begin
	delayregister <= delayregister + 1;
	if (delayregister > 500) begin
		reset <= 0;
	end
end

// Debug
assign IO[4] = ready;
assign IO[5] = ack;
assign IO[6] = readyreset;

assign readyreset = ready & !reset;

SPI spi0 (
    // Chip Interface
    .SPI1_MISO(spi_miso), //inout wire 
    .SPI1_MOSI(spi_mosi), //inout wire 
    .SPI1_SCK(spi_sck), //inout wire 
    // SPI1_SCSN(), //input wire 
    // SPI1_MCSN(), //output wire [3:0] 
    // Fabric Interface
    .RST(reset), //input wire Reset(), 
    .IPLOAD(reset), //input wire 
    // Rising Edge triggers Hard IP Configuration
    .IPDONE(ready), //output wire 
    // 1: Hard IP Configuration is complete
    .SBCLKi(clk), //input wire 
    // System bus interface to all 4 Hard IP blocks
    .SBWRi(wr), //input wire 
    //  This bus is available when IPDONE = 1
    .SBSTBi(strobe), //input wire 
    .SBADRi(address), //input wire [7:0] 
    .SBDATi(write_data), //input wire [7:0] 
    .SBDATo(read_data), //output wire [7:0] 
    .SBACKo(ack), //output wire 
        
    // I2CPIRQ(), //output wire [1:0] 
    // I2CPWKUP(), //output wire [1:0] 
    // SPIPIRQ(), //output wire [1:0] 
    // SPIPWKUP(), //output wire [1:0]
);

reg [7:0] dout;
reg [7:0] din;
reg rdy;
reg we;
reg [7:0] addr;
reg [7:0] timeout;

wire readyresetwb = rdy & !reset;

always @(posedge clk)
		if(readyreset == 0'b1)
		begin
			// clear all at reset
			dout <= 8'h00;
			rdy <= 1'b1;
			timeout <= 4'h0;
			strobe <= 1'b0;
			address <= 8'h00;
			wr <= 1'b1;
			write_data <= 8'h00;
		end
		else
		begin
			if(rdy == 1'b1)
			begin
				// No transaction pending - start new one
					strobe <= 1'b1;
					address <= addr;
					wr <= we;
					rdy <= 1'b0;
					timeout <= 4'hf;
					
					if(we == 1'b1)
					begin
						// write cycle
						write_data <= din;
					end
			end
			else
			begin
				// Transaction in process
				if((ack == 1'b1) || (|timeout == 1'b0))
				begin
					// finish cycle
					strobe <= 1'b0;
					rdy <= 1'b1;
					if((wr == 1'b0) && (|timeout == 1'b1))
					begin
						// finish read cycle
						dout <= read_data;
					end
				end
				
				// update timeout counter
				timeout <= timeout - 4'h1;
			end
		end


always @(posedge readyresetwb)
begin
	internal_cs <= 1'b1;
	if (state == 0) begin
		we <= 1'b0;
		addr <= 8'h0C;
		if (read_data[4]) begin
			state <= state + 1 ;
		end
		end
	else if (state == 2) begin
		we <= 1'b1;
		din <= 8'hAA; 
		addr    <= 8'h0D;
		state <= state + 1 ;
	end
	else if (state == 3) begin
		we <= 1'b0;
		addr <= 8'h0C;
		if (read_data[3]) begin
			state <= state + 1 ;
		end
	end
	else if (state == 4) begin
		we <= 1'b0;
		addr <= 8'h0E;
		state <= 0;
	end
end

endmodule

