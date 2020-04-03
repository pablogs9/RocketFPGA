// out = (n1 * in1) + (n2 * in2)
module mixer2 #(
	parameter BITSIZE = 16,
)(	
    input wire lrclk,
	input wire bclk,    // 64 times lrclk 

    input wire signed [BITSIZE-1:0] in1,
    input wire signed [BITSIZE-1:0] in2,

    input wire signed [BITSIZE-1:0] n1,    // Q1.(BITSIZE-2)
    input wire signed [BITSIZE-1:0] n2,    // Q1.(BITSIZE-2)

	output reg signed [BITSIZE-1:0] out,
);

reg [2:0] counter = 0;
reg signed [(BITSIZE*2)-1:0] auxout1;
reg signed [(BITSIZE*2)-1:0] auxout2;

always @(posedge lrclk) begin
    out <= auxout2;
end

always @(posedge bclk) begin
    if(lrclk)
		counter <= 1;
    else
        counter <= counter + 1;
		
	if (counter == 1) begin
        auxout1 <= (in1 * n1);
        auxout2 <= 0;
	end else if (counter == 2) begin
		auxout1 <= (in2 * n2);
        auxout2 <= auxout2 + auxout1[(BITSIZE*2)-1:(BITSIZE)-2];
    end else if (counter == 3) begin
        auxout2 <=  auxout2 + auxout1[(BITSIZE*2)-1:(BITSIZE)-2];
	end
end


endmodule