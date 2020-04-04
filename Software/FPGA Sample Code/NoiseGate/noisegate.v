// out = (n1 * in1) + (n2 * in2)
module noisegate #(
	parameter BITSIZE = 16,
)(	
    input wire signed [BITSIZE-1:0] in,
    input wire signed [BITSIZE-1:0] val,

	output reg signed [BITSIZE-1:0] out,
);


assign out = (in > val) ?  in : 0;

endmodule