module squaregenerator #(
	parameter BITSIZE = 24,
    parameter PHASESIZE = 16,
)(	
	input wire lrclk,
    input wire [PHASESIZE-1:0]	freq,
	output reg [BITSIZE-1:0] out,
);

reg [PHASESIZE-1:0]	phase;

always @(posedge lrclk) begin
	phase <= phase + freq;
end

always @(posedge lrclk) begin
    out <= {BITSIZE{phase[0]}};
end

endmodule