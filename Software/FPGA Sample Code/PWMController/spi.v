module spi (
	// SPI interface
	input  wire       spi_mosi_i,
	input  wire       spi_ncs_i ,
	input  wire       spi_clk_i ,
	output wire       spi_miso_o,
	// Data bus
	output reg  [7:0] b_addr_o  ,
	input  wire [7:0] b_data_i  ,
	output reg  [7:0] b_data_o  ,
	output wire       b_write_o ,
	// For write frag synchronization
	input  wire       pwm_clk_i ,
	input  wire       pwm_rst_i
);

	wire byte_transfer_finished;
	wire transfer_read;

	reg  [2:0] state           ;
	reg  [2:0] bit_counter     ;
	reg  [7:0] spi_data_out    ;
	reg  [7:0] spi_data_in     ;
	wire [3:0] bit_counter_next;
	reg        b_write         ;

	localparam STATE_START = 'b000;
	localparam STATE_READ_START = 'b001;
	localparam STATE_READ = 'b010;
	localparam STATE_WRITE = 'b011;
	localparam STATE_FINISHED = 'b111;

	clock_synchronizer i_clock_synchronizer (
		.clk_i(pwm_clk_i),
		.nrst_i(pwm_rst_i),
		.data_i(b_write),
		.data_o(b_write_o)
	);

	always @(posedge spi_clk_i or posedge spi_ncs_i) begin : proc_main
		if(spi_ncs_i) begin
			state <= STATE_START;
		end else begin
			case (state)
				STATE_START: begin
					if (byte_transfer_finished) begin
						if (transfer_read) begin
							state <= STATE_WRITE;
						end else begin
							state <= STATE_READ_START;
						end
						b_write <= 0;
						b_addr_o <= { spi_data_in[6:0], spi_mosi_i };
					end
				end

				STATE_WRITE: begin
					if (byte_transfer_finished) begin
						b_data_o <= { spi_data_in[6:0], spi_mosi_i };

						b_write <= 'b1;
						state <= STATE_FINISHED;
					end
				end

				STATE_READ_START: begin
					state <= STATE_READ;
				end

				STATE_READ: begin
					if (byte_transfer_finished) begin
						state <= STATE_FINISHED;
					end
				end

				STATE_FINISHED: begin end
			endcase
		end
	end

	always @(negedge spi_clk_i or posedge spi_ncs_i) begin
		if(spi_ncs_i) begin
			spi_data_out <= 0;
		end else begin
			case (state) 
				STATE_READ_START: begin 
					spi_data_out <= b_data_i;
				end

				STATE_READ: begin
					spi_data_out <= spi_data_out << 1;
				end

				default: begin end
			endcase
		end
	end

	always @(posedge spi_clk_i or posedge spi_ncs_i) begin: proc_byte
		if(spi_ncs_i) begin
			bit_counter <= 0;
			spi_data_in <= 0;
		end else begin
			bit_counter <= bit_counter_next[2:0];
			spi_data_in <= spi_data_in << 1;
			spi_data_in[0] <= spi_mosi_i;
		end
	end

	assign spi_miso_o             = spi_data_out[7];
	assign byte_transfer_finished = bit_counter == 'b111;
	assign transfer_read          = spi_data_in[6] == 'b0;
	assign bit_counter_next       = bit_counter + 1;

endmodule