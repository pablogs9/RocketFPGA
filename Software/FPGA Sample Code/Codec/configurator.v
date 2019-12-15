module configurator(	
	input wire clk,
	output reg cs,
	output wire spi_mosi, 
	output wire spi_sck,
	input wire reset,
	output reg done,
);

reg trigger = 0;
reg  [15:0] write_data;
wire ready;
reg idone = 0;

assign done = idone;

// Configuration Registers
parameter num_regs = 11 ; 
reg [6:0] addr [0:(num_regs-1)] ; 
reg [8:0] cmd [0:(num_regs-1)] ; 

// Reset device
assign addr[0] = {7'h0F}; 
assign cmd[0] = 9'b0000000000; 

// Power Down Control
assign addr[1] = {7'h06} ; 
assign cmd[1] = {9'b0000000000} ; 

// Repeat Power Down Control
assign addr[2] = {7'h06} ; 
parameter POWEROFF = 1'b0; 
parameter CLKOUTPD = 1'b0; 
parameter OSCPD = 1'b0; 
parameter OUTPD = 1'b1; 
parameter DACPD = 1'b0; 
parameter ADCPD = 1'b0; 
parameter MICPD = 1'b0; 
parameter LINEINPD = 1'b0; 
assign cmd[2] = {1'b0,POWEROFF,CLKOUTPD,OSCPD,OUTPD,DACPD,ADCPD,MICPD,LINEINPD} ; 

// Set both line channels mute and volume
assign addr[3] = {7'h00} ; 
parameter LRINBOTH = 1'b1; 
parameter LINMUTE = 1'b0; 
parameter LINVOL = 5'd23; 	// 12 dB (31) ... 0 dB (23) ... -34.5 dB (0) -- 1.5 dB step
assign cmd[3] = {LRINBOTH,LINMUTE,2'b00,LINVOL} ; 

// Set both headphone channels mute and volume
assign addr[4] = {7'h02} ; 
parameter LRHPBOTH = 1'b1; 
parameter LZCEN = 1'b0;  	// Zerocross
parameter LHPVOL = 7'd110; 	// 6 dB (127) ... 0 dB ... -73 dB (48) ... lower mutes -- 1 dB step
assign cmd[4] = {LRHPBOTH,LZCEN,LHPVOL} ; 

// Analogue Audio Path Control
assign addr[5] = {7'h04} ; 
parameter MICBOOST = 1'b0; 
parameter MUTEMIC = 1'b0; 
parameter INSEL = 1'b0; 	// 0 - line , 1 - mic 
parameter BYPASS = 1'b0; 
parameter DACSEL = 1'b1; 
parameter SIDETONE = 1'b0; 
parameter SIDEATT = 2'b00; 	// Side Tone Attenuation -15 dB (11) -12 dB (10) -9 dB (01) -6 dB (00)
assign cmd[5] = {1'b0,SIDEATT,SIDETONE,DACSEL,BYPASS,INSEL,MUTEMIC,MICBOOST} ; 


// Digital Audio Path Control
assign addr[6] = {7'h05} ; 
parameter ADCHPD = 1'b1; 	// ADC high pass filter
parameter DEEMP = 2'b11; 	// Deemphasis 00 disabled
parameter DACMU = 1'b0; 	// DAC Soft Mute Control
parameter HPOR = 1'b0; 		// Store dc offset when High Pass Filter disabled
assign cmd[6] = {4'b0000,HPOR,DACMU,DEEMP,ADCHPD} ; 


// Digital Audio Interface Format
assign addr[7] = {7'h07} ; 
parameter BCLKINV = 1'b0; 
parameter MS = 1'b1; 
parameter LRSWAP = 1'b0; 
parameter LRP = 1'b0; 		// CUIDADO CON ESTO 
parameter IWL = 2'b10; 		// Data len 32 bits 11, 24 bits 10, 20 bits 01, 16 bits 00
parameter FORMAT = 2'b10; 	// Format DSP 11, I2S 10, left 01, right 00,
assign cmd[7] = {1'b0,BCLKINV,MS,LRSWAP,LRP,IWL,FORMAT} ; 

// Sampling Control
assign addr[8] = {7'h08} ; 
parameter CLKODIV2 = 1'b0; 
parameter CLKIDIV2 = 1'b0; 
parameter SR = 4'b0111; 	// CUIDADO CON ESTO
parameter BOSR = 1'b0; 
parameter USB = 1'b0; 
assign cmd[8] = {1'b0,CLKODIV2,CLKIDIV2,SR,BOSR,USB} ; 

// Active Control
assign addr[9] = {7'h09} ; 
parameter ACTIVE = 1'b1; 
assign cmd[9] = {8'b00000000,ACTIVE} ; 

// Power Down Control
assign addr[10] = {7'h06} ; 
parameter OUTPD2 = 1'b0;  
assign cmd[10] = {1'b0,POWEROFF,CLKOUTPD,OSCPD,OUTPD2,DACPD,ADCPD,MICPD,LINEINPD} ;

SPI spimaster (
    .MOSI(spi_mosi),
    .SCK(spi_sck),
    .CS(),
	.RESET(reset),
    .CLK(clk), 
    .DATA(write_data),
    .TRG(trigger), 
    .RDY(ready), 
);


reg [7:0] counter = 0;
reg csreg = 1;
assign cs = csreg;
reg [3:0] state = 0;

always @(posedge clk) begin
	if (reset) begin
		state <= 0;
		counter <= 0;
		trigger <= 0;
		csreg <= 1;
	end
	else begin
		if (ready == 1 && trigger != 1 && state == 0 && counter < num_regs) begin
			write_data <= {addr[counter], cmd[counter]};
			trigger <= 1;
			state <= state + 1;
			counter <= counter + 1;
		end
		else if (ready == 1 && trigger != 1 && state == 1) begin
			csreg <= 0;
			state <= state + 1;
		end
		else if (ready == 1 && trigger != 1 && state == 2) begin
			csreg <= 1;
			state <= 0;
			if (counter == num_regs) begin
				idone <= 1;
			end
		end
		else begin
			trigger <= 0;
		end
	end
end


endmodule

