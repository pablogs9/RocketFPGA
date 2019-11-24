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

reg  [7:0] write_data = 8'h08;
wire  [7:0] read_data;
reg  [7:0] address = 8'hff;
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
assign IO[4] = state[0];
assign IO[5] = read_data[4];
assign IO[6] = readyreset;

assign readyreset = ready & !reset;

SPI spi0 (
	.clk(clk), //input				// system clock
	.rst(reset), //input				// system reset
	.cs(internal_cs), //input				// chip select
	.we(wr), //input				// write enable
	.addr(address), //input [7:0]		// register select
	.din(write_data), //input [7:0]		// data bus input
	.dout(read_data), //output [7:0]		// data bus output
	.rdy(ready), //output				// low-true processor stall
	// .irq(), //output				// high-true interrupt request
	.spi0_mosi(spi_mosi), //inout		// spi core 0 mosi
	.spi0_miso(spi_miso), //inout		// spi core 0 miso
	.spi0_sclk(spi_sck), //inout		// spi core 0 sclk
	.spi0_cs0(cs) //inout			// spi core 0 cs
);

always @(posedge readyreset)
begin
	internal_cs <= 1'b1;
	if (state == 0) begin
		write_data <= 8'h09; 
		address    <= 8'h84;
		state <= state + 1 ;
		end
	else if (state == 1) begin
		write_data <= 8'h0A; 
		address    <= 8'hc0;
		state <= state + 1 ;
		end
	else if (state == 2) begin
		write_data <= 8'h0B; 
		address    <= 8'h02;
		state <= state + 1 ;
		end
	else if (state == 3) begin
		write_data <= 8'h0F; 
		address    <= 8'h0F;
		state <= state + 1 ;
		end
	else if (state == 4) begin
		write_data <= 8'h0F; 
		address    <= 8'hFE;
		state <= state + 1 ;
		end
	else if (state == 5) begin
		wr <= 1'b0;
		address <= 8'h0C;
		if (read_data[4]) begin
			state <= state + 1 ;
		end
		end
	else if (state == 6) begin
		wr <= 1'b1;
		write_data <= 8'hAA; 
		address    <= 8'h0D;
		state <= state + 1 ;
	end
	else if (state == 7) begin
		wr <= 1'b0;
		address <= 8'h0C;
		if (read_data[3]) begin
			state <= state + 1 ;
		end
	end
	else if (state == 8) begin
		wr <= 1'b0;
		address <= 8'h0E;
		state <= state + 1 ;
	end
	else if (state == 9) begin
		write_data <= 8'h0F; 
		address    <= 8'h0F;
		state <= 3 ;
	end

	// 	case (state)
	// 	0 :
	// 		begin
	// 			write_data <= 8'b00000000; //ALL LOW POWER MODES OFF
	// 			address    <= 8'b00000110;
	// 			strobe     <= 1'b1;
	// 			state      <= state + 1;
	// 		end
	// 	4 :
	// 		begin							
	// 			// if (spi_ack==0)
	// 			// 	state      <= state;
	// 			// else 
	// 			// begin
	// 				strobe     <= 1'b0;
	// 				state      <= state + 1;
	// 			// end
	// 		end
	// 	8 :
	// 		begin
	// 			write_data <= 8'b01011111; //LEFT AND RIGHT HP OUT TO MAX GAIN
	// 			address    <= 8'b00000010;
	// 			strobe     <= 1'b1;
	// 			state      <= state + 1;
	// 		end
	// 	12 :
	// 		begin							
	// 			// if (spi_ack==0)
	// 			// 	state      <= state;
	// 			// else 
	// 			// begin
	// 				strobe     <= 1'b0;
	// 				state      <= state + 1;
	// 			// end
	// 		end
	// 	16 :
	// 		begin
	// 			write_data <= 8'b11111111; //ACTIVATE INTERFACE I2S
	// 			address    <= 8'b00001001;
	// 			strobe     <= 1'b1;
	// 			state      <= state + 1;
	// 		end
	// 	20 :
	// 		begin							
	// 			// if (spi_ack==0)
	// 			// 	state      <= state;
	// 			// else 
	// 			// begin
	// 				strobe     <= 1'b0;
	// 				state      <= state + 1;
	// 			// end
	// 		end
	// 	24 :
	// 		begin
	// 			write_data <= 8'b00111001; //DAC SEL
	// 			address    <= 8'b00000100;
	// 			strobe     <= 1'b1;
	// 			state      <= state + 1;
	// 		end
	// 	28 :
	// 		begin							
	// 			// if (spi_ack==0)
	// 			// 	state      <= state;
	// 			// else 
	// 			// begin
	// 				strobe     <= 1'b0;
	// 				state      <= state + 1;
	// 			// end
	// 		end
	// 	32 :
	// 		begin
	// 			write_data <= 8'b00000001; //DAC SEL
	// 			address    <= 8'b00000101;
	// 			strobe     <= 1'b1;
	// 			state      <= state + 1;
	// 		end
	// 	36 :
	// 		begin							
	// 			// if (spi_ack==0)
	// 			// 	state      <= state;
	// 			// else 
	// 			// begin
	// 				strobe     <= 1'b0;
	// 				state      <= state + 1;
	// 			// end
	// 		end
	// 	default :
	// 		begin							
	// 			state      <= state + 1;
	// 		end
	// endcase
end

endmodule

