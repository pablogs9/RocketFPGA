module sinegenerator #(
	parameter BITSIZE = 24,
    parameter PHASESIZE = 16,
    parameter TABLESIZE = 9,
)(	
	input wire lrclk,
    input wire [PHASESIZE-1:0]	freq,
	output reg [BITSIZE-1:0] out,
);

reg	[BITSIZE-1:0] quartertable [0:((2**TABLESIZE)-1)];

if (BITSIZE == 24) begin
    if (TABLESIZE == 12) begin
        initial	$readmemh("quartersinetable_24bits_depth12.hex", quartertable);
    end else if (TABLESIZE == 10) begin
        initial	$readmemh("quartersinetable_24bits_depth10.hex", quartertable);
    end else if (TABLESIZE == 9) begin
        initial	$readmemh("quartersinetable_24bits_depth9.hex", quartertable);
    end
end else begin
    initial	$readmemh("quartersinetable_16bits_depth9.hex", quartertable);
end

reg [PHASESIZE-1:0]	phase;
reg [TABLESIZE-1:0] index;
reg	[1:0]	        negate;
reg signed [BITSIZE-1:0] val;

always @(posedge lrclk) begin
	phase <= phase + freq;
end

always @(posedge lrclk) begin
    negate[0] <= phase[(PHASESIZE-1)];
    if (phase[(PHASESIZE-2)])
        index <= ~phase[PHASESIZE-3:PHASESIZE-TABLESIZE-2];
    else
        index <=  phase[PHASESIZE-3:PHASESIZE-TABLESIZE-2];

    val <= quartertable[index];

    negate[1] <= negate[0];

    if (negate[1])
        out <= -val;
    else
        out <=  val;
end


endmodule