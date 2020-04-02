// out = (n1 * in1) + (n2 * in2)
// multiplication -> signed Q1.22 * signed Q1.22 = signed Q
module mixer #(
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

// SB_MAC16 #(
//     .C_REG(0), 
//     .A_REG(0), 
//     .B_REG(0), 
//     .D_REG(0), 
//     .TOP_8x8_MULT_REG(0), 
//     .BOT_8x8_MULT_REG(0),
//     .PIPELINE_16x16_MULT_REG1(0), 
//     .PIPELINE_16x16_MULT_REG2(0), 
//     .TOPOUTPUT_SELECT(0), 
//     .TOPADDSUB_LOWERINPUT(2),
//     .TOPADDSUB_UPPERINPUT(0), 
//     .TOPADDSUB_CARRYSELECT(0), 
//     .BOTOUTPUT_SELECT(0), 
//     .BOTADDSUB_LOWERINPUT(2), 
//     .BOTADDSUB_UPPERINPUT(0),
//     .BOTADDSUB_CARRYSELECT(0), 
//     .MODE_8x8(0), 
//     .A_SIGNED(0), 
//     .B_SIGNED(0))
// SB_MAC16_inst(
//     .CLK(clk), .CE(dsp_ce), .C(dsp_c), .A(dsp_a), .B(dsp_b), .D(dsp_d),
//     .IRSTTOP(dsp_irsttop), .IRSTBOT(dsp_irstbot), .ORSTTOP(dsp_orsttop), .ORSTBOT(dsp_orstbot),
//     .AHOLD(dsp_ahold), .BHOLD(dsp_bhold), .CHOLD(dsp_chold), .DHOLD(dsp_dhold), .OHOLDTOP(dsp_oholdtop), .OHOLDBOT(dsp_oholdbot),
//     .ADDSUBTOP(dsp_addsubtop), .ADDSUBBOT(dsp_addsubbot), .OLOADTOP(dsp_oloadtop), .OLOADBOT(dsp_oloadbot),
//     .CI(dsp_ci), .O(dsp_o), .CO(dsp_co)
// );

reg [2:0] counter = 0;
reg signed [(BITSIZE*2)-1:0] auxout1;
reg signed [(BITSIZE*2)-1:0] auxout2;

always @(posedge lrclk) begin
    // out <= auxout >>> (BITSIZE/2);
    // auxout <= (in1 * n1) + (in2 * n2);
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
        auxout2 <= auxout1[(BITSIZE*2)-1:(BITSIZE)-2];
    end else if (counter == 3) begin
        auxout2 <=  auxout2 + auxout1[(BITSIZE*2)-1:(BITSIZE)-2];
	end
end


endmodule