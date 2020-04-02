module trianglegenerator #(
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
    if (BITSIZE == PHASESIZE) begin
        out <= phase;
    end else if (BITSIZE > PHASESIZE) begin
        out <= {phase, {(BITSIZE-PHASESIZE){1'b0}}};
    end else begin
        out <= phase[PHASESIZE-1:PHASESIZE-BITSIZE-1];
    end
end


endmodule