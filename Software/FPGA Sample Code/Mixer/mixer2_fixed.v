// out = (0.5 * in1) + (0.5 * in2)
module mixer2_fixed #(
	parameter BITSIZE = 16,
)(	
    input wire lrclk,
	input wire bclk,    // 64 times lrclk 

    input wire signed [BITSIZE-1:0] in1,
    input wire signed [BITSIZE-1:0] in2,

	output reg signed [BITSIZE-1:0] out,
);

reg [2:0] counter = 0;
reg signed [BITSIZE-1:0] auxout1;
reg signed [BITSIZE-1:0] auxout2;

always @(posedge lrclk) begin
    out <= (in1 >>> 1) + (in2 >>> 1);
end


endmodule