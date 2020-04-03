NAME = main
PINS = ../Utils/pins.pcf
PORT = /dev/ttyS20

all: sint
sint: $(NAME).bin
	
$(NAME).bin: $(PINS) $(NAME).v 
	
	#-- Synthesis
	yosys -Q -q -d -p 'synth_ice40 -dsp -top $(NAME) -json $(NAME).json' main.v mixer*  ../I2S/i2s_rx.v ../I2S/i2s_tx.v ../Codec/configurator.v ../Codec/SPI.v ../WaveformGenerators/sinegenerator.v

	#-- Place & route
	nextpnr-ice40 --up5k --package sg48  --json $(NAME).json --pcf $(PINS) --asc $(NAME).asc
	
	#-- Packing
	icepack $(NAME).asc $(NAME).bin


flash: $(NAME).bin
	fpga_upload -d $(PORT) -f $(NAME).bin 

clean:
	rm -f *.bin *.txt *.blif *.out *.vcd *~

.PHONY: all clean flash

