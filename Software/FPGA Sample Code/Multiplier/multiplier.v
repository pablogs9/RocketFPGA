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

if (BITSIZE == 24) begin
    $error("MULTIPLIER SUPPORT FOR 24 NOT AVAILABLE YET");
end

reg signed [(BITSIZE*2)-1:0] aux;

assign aux = in1 * in2;

always @(posedge lrclk) begin
    out <= aux[(BITSIZE*2)-1:(BITSIZE)-2];
end


endmodule