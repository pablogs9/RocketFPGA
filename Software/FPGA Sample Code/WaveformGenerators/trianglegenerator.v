module trianglegenerator #(
	parameter BITSIZE = 24,
    parameter PHASESIZE = 16,
)(	
    input wire enable,
	input wire lrclk,
    input wire [PHASESIZE-1:0]	freq,
	output reg [BITSIZE-1:0] out,
);

reg [PHASESIZE-1:0]	phase;

always @(posedge lrclk) begin
	phase <= phase + freq;
end

always @(posedge lrclk) begin
    if (!enable) 
        out <= 0;
    else if (BITSIZE == PHASESIZE)
        out <= phase;
    else if (BITSIZE > PHASESIZE)
        out <= {phase, {(BITSIZE-PHASESIZE){1'b0}}};
    else
        out <= phase[PHASESIZE-1:PHASESIZE-BITSIZE-1];
end


endmodule