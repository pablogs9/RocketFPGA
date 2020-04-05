// out = (0.5 * in1) + (0.5 * in2)
module mixer2_fixed #(
	parameter BITSIZE = 16,
)(	
    input wire signed [BITSIZE-1:0] in1,
    input wire signed [BITSIZE-1:0] in2,
	output reg signed [BITSIZE-1:0] out,
);

assign out = (in1 >>> 1) + (in2 >>> 1);

endmodule