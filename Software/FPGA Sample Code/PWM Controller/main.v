`define PWM_INSTANCES 				3

module main (
	input  wire clk_i,
	input  wire nrst_i,
	output wire [`PWM_INSTANCES - 1:0] pwm_o,
	input  wire spi_mosi_i,
	input  wire spi_ncs_i,
	input  wire spi_clk_i,
	output wire spi_miso_o
);

	reg [20:0] divider;
	reg [7:0] dividerSelector = 3;

	wire  mainClock;


	wire [7:0] b_addr;
	wire [7:0] b_data_r;
	wire [7:0] b_data_w;
	wire       b_write;

	reg [7:0] dutys[`PWM_INSTANCES - 1:0];

	genvar instance_index;

	spi i_spi (
		.spi_mosi_i(spi_mosi_i),
		.spi_ncs_i (spi_ncs_i ),
		.spi_clk_i (spi_clk_i ),
		.spi_miso_o(spi_miso_o),
		.b_addr_o  (b_addr    ),
		.b_data_i  (b_data_r  ),
		.b_data_o  (b_data_w  ),
		.b_write_o (b_write   ),
		.pwm_clk_i (clk_i ),
		.pwm_rst_i (nrst_i    )
	);

	always @(posedge b_write) begin
		if (b_addr == 0) begin
			dividerSelector <= b_data_w;
		end else begin
			dutys[b_addr-1] <= b_data_w;
		end
    	
	end

	always @(posedge clk_i) begin
    	divider <= divider + 1;
	end

	generate
		for (instance_index = 0; instance_index < `PWM_INSTANCES; instance_index = instance_index + 1) begin: i_pwm_gen
			pwm i_pwm_0 (
				.clk (mainClock),
				.duty (dutys[instance_index]),
				.out (pwm_o[instance_index])
			);
		end
	endgenerate

	assign mainClock = divider[dividerSelector];


endmodule
