module configurator(	
	input wire clk,
	output reg cs,
	output wire spi_mosi, 
	output wire spi_sck,
	input wire reset,
	output wire done,
);

reg trigger = 0;
reg  [7:0] write_data;
wire ready;
reg idone = 0;
assign done = idone;

// Configuration Registers
parameter num_regs = 8 ; 
wire [6:0] addr [0:(num_regs-1)] ; 
wire [8:0] cmd [0:(num_regs-1)] ; 

// Set both line channels mute and volume
assign addr[0] = {7'h00} ; 
parameter LRINBOTH = 1'b1; 
parameter LINMUTE = 1'b0; 
parameter LINVOL = 5'd23; 	// 12 dB (31) ... 0 dB (23) ... -34.5 dB (0) -- 1.5 dB step
assign cmd[0] = {LRINBOTH,LINMUTE,2'b00,LINVOL} ; 

// Set both headphone channels mute and volume
assign addr[1] = {7'h02} ; 
parameter LRHPBOTH = 1'b1; 
parameter LZCEN = 1'b0;  	// Zerocross
parameter LHPVOL = 7'd100; 	// 6 dB (127) ... 0 dB ... -73 dB (48) ... lower mutes -- 1 dB step
assign cmd[1] = {LRHPBOTH,LZCEN,LHPVOL} ; 

// Analogue Audio Path Control
assign addr[2] = {7'h04} ; 
parameter MICBOOST = 1'b1; 
parameter MUTEMIC = 1'b0; 
parameter INSEL = 1'b0; 	// 0 - line , 1 - mic 
parameter BYPASS = 1'b0; 
parameter DACSEL = 1'b1; 
parameter SIDETONE = 1'b1; 
parameter SIDEATT = 2'b00; 	// Side Tone Attenuation -15 dB (11) -12 dB (10) -9 dB (01) -6 dB (00)
assign cmd[2] = {1'b0,SIDEATT,SIDETONE,DACSEL,BYPASS,INSEL,MUTEMIC,MICBOOST} ; 


// Digital Audio Path Control
assign addr[3] = {7'h05} ; 
parameter ADCHPD = 1'b1; 	// ADC high pass filter
parameter DEEMP = 2'b00; 	// Deemphasis 00 disabled
parameter DACMU = 1'b0; 	// DAC Soft Mute Control
parameter HPOR = 1'b1; 		// Store dc offset when High Pass Filter disabled
assign cmd[3] = {4'h0,HPOR,DACMU,DEEMP,ADCHPD} ; 

// Power Down Control
assign addr[4] = {7'h06} ; 
parameter POWEROFF = 1'b0; 
parameter CLKOUTPD = 1'b0; 
parameter OSCPD = 1'b0; 
parameter OUTPD = 1'b0; 
parameter DACPD = 1'b0; 
parameter ADCPD = 1'b0; 
parameter MICPD = 1'b0; 
parameter LINEINPD = 1'b0; 
assign cmd[4] = {1'h0,POWEROFF,CLKOUTPD,OSCPD,OUTPD,DACPD,ADCPD,MICPD,LINEINPD} ; 

// Digital Audio Interface Format
assign addr[5] = {7'h07} ; 
parameter BCLKINV = 1'b0; 
parameter MS = 1'b0; 
parameter LRSWAP = 1'b0; 
parameter LRP = 1'b0; 		// CUIDADO CON ESTO 
parameter IWL = 2'b00; 		// Data len 32 bits 11, 24 bits 10, 20 bits 01, 16 bits 00
parameter FORMAT = 2'b10; 	// Format DSP 11, I2S 10, left 01, right 00,
assign cmd[5] = {1'h0,BCLKINV,MS,LRSWAP,LRP,IWL,FORMAT} ; 

// Sampling Control
assign addr[6] = {7'h08} ; 
parameter CLKODIV2 = 1'b0; 
parameter CLKIDIV2 = 1'b0; 
parameter SR = 4'b0000; 	// CUIDADO CON ESTO
parameter BOSR = 1'b0; 
parameter USB = 1'b0; 
assign cmd[6] = {1'h0,CLKODIV2,CLKIDIV2,SR,BOSR,USB} ; 

// Active Control
assign addr[7] = {7'h09} ; 
parameter ACTIVE = 1'b1; 
assign cmd[7] = {8'h0,ACTIVE} ; 

// Reset
// assign addr[8] = {7'h0F} ; 
// parameter RESET = 9'h1; 
// assign cmd[8] = {RESET}; 


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
	if (ready == 1 && trigger != 1 && state == 0 && counter < 8) begin
		write_data <= {addr[counter],cmd[counter][8]};
		trigger <= 1;
		state <= state + 1;
	end
	else if (ready == 1 && trigger != 1 && state == 1 && counter < 8) begin
		write_data <= cmd[counter][7:0];
		trigger <= 1;
		counter <= counter + 1;
		state <= state + 1;
	end
	else if (ready == 1 && trigger != 1 && state == 2) begin
		csreg <= 0;
		state <= state + 1;
	end
	else if (ready == 1 && trigger != 1 && state == 3) begin
		csreg <= 1;
		state <= 0;
		if (counter == 8) begin
			idone <= 1;
		end
	end
	else begin
		trigger <= 0;
	end
end


endmodule

