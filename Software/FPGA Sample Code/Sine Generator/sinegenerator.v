module sinegenerator #(
	parameter BITSIZE = 24,
    parameter PHASESIZE = 16,
)(	
	input wire lrclk,
    input wire [PHASESIZE-1:0]	freq,
	output reg [BITSIZE-1:0] out,
);

localparam TABLESIZE = 9;

reg	[BITSIZE-1:0] quartertable [0:((1<<TABLESIZE)-1)];

if (BITSIZE == 24) begin
    initial	$readmemh("quartersinetable_24bits_depth9.hex", quartertable);
end else begin
    initial	$readmemh("quartersinetable_16bits_depth9.hex", quartertable);
end

reg [PHASESIZE-1:0]	phase;
reg [TABLESIZE-1:0] index;
reg signed [BITSIZE-1:0] val;

always @(posedge lrclk) begin
	phase <= phase + freq;
end

always @(posedge lrclk) begin
    if (phase[PHASESIZE-2])
        index <= ~phase[PHASESIZE-3:PHASESIZE-TABLESIZE-2];
    else
        index <= phase[PHASESIZE-3:PHASESIZE-TABLESIZE-2];

    val <=  quartertable[index];

    if (phase[PHASESIZE-1]) begin
        out <= -val;
    end
    else begin
        out <= val;
    end
end


endmodule