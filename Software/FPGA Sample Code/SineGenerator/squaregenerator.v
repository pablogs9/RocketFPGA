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

    if (phase[(PHASESIZE-2)])
        out <= {24{1'b1}};
    else
        out <= {1'b0,{23{1'b1}}};
end

endmodule