// out = (in2 * in1)
module multiplier #(
	parameter BITSIZE = 16,
)(	
    input wire lrclk,
	input wire bclk,    // 64 times lrclk 

    input wire signed [BITSIZE-1:0] in1,
    input wire signed [BITSIZE-1:0] in2,

	output reg signed [BITSIZE-1:0] out,
);

reg signed [(BITSIZE*2)-1:0] aux;

assign aux = in1 * in2;

always @(posedge lrclk) begin
    // aux <= in1 * in2;
    out <= aux[(BITSIZE*2)-1:(BITSIZE)-2];
end

always @(posedge bclk) begin
    
end


endmodule