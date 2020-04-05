// out = (n1 * in1) + (n2 * in2)
module mixer2 #(
	parameter BITSIZE = 16,
)(	
    // input wire lrclk,
	// input wire bclk,    // 64 times lrclk 

    input wire signed [BITSIZE-1:0] in1,
    input wire signed [BITSIZE-1:0] in2,

    input wire signed [BITSIZE-1:0] n1,    // Q1.(BITSIZE-2)
    input wire signed [BITSIZE-1:0] n2,    // Q1.(BITSIZE-2)

	output reg signed [BITSIZE-1:0] out,
);

wire signed [(BITSIZE*2)-1:0] auxout1;
wire signed [(BITSIZE*2)-1:0] auxout2;

assign out = auxout1 + auxout2;

multiplier #(
    .BITSIZE(BITSIZE),
) M1 (
	// .bclk(bclk),
	.in1(in1),
	.in2(n1),
    .out(auxout1),
);

multiplier #(
    .BITSIZE(BITSIZE),
) M2 (
	// .bclk(bclk),
	.in1(in2),
	.in2(n2),
    .out(auxout2),
);


endmodule