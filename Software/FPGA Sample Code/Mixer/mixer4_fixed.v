// out = (0.25 * in1) + (0.25 * in2) + (0.25 * in3) + (0.25 * in4)
module mixer4_fixed #(
	parameter BITSIZE = 16,
)(	
    input wire signed [BITSIZE-1:0] in1,
    input wire signed [BITSIZE-1:0] in2,
    input wire signed [BITSIZE-1:0] in3,
    input wire signed [BITSIZE-1:0] in4,
	output reg signed [BITSIZE-1:0] out,
);

assign out = (in1 >>> 2) + (in2 >>> 2) + (in3 >>> 2) + (in4 >>> 2);

endmodule