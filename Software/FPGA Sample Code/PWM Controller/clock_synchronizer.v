module clock_synchronizer (
	input wire clk_i,
	input wire nrst_i,
	input wire data_i,
	output wire data_o
);

	reg data_next;
	reg data_edge;

	always @(posedge clk_i or negedge nrst_i) begin
		if(~nrst_i) begin
			data_edge <= 0;
			data_next <= 0;
		end else begin
			data_next <= data_i;
			data_edge <= data_next;
		end
	end

	assign data_o = !data_edge && data_next;

endmodule
