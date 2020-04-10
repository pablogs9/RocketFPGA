NAME = main
PINS = ../Utils/pins.pcf
PORT = /dev/tty.usbmodem1411

all: sint
sint: $(NAME).bin
	
$(NAME).bin: $(PINS) $(NAME).v 
	
	#-- Synthesis
	yosys -Q -d -p 'synth_ice40 -top $(NAME) -json $(NAME).json' main.v ../Filters/lowpassfilter.v ../Filters/parametericfilter.v ../Tempo/tempo.v ../WaveformGenerators/sinegenerator.v ../I2S/i2s_rx.v ../I2S/i2s_tx.v ../Codec/configurator.v ../Codec/SPI.v ../Multiplier/multiplier.v

	#-- Place & route
	nextpnr-ice40 --up5k --package sg48  --json $(NAME).json --pcf $(PINS) --asc $(NAME).asc
	
	#-- Packing
	icepack $(NAME).asc $(NAME).bin


flash: $(NAME).bin
	python3 ../../Code\ Uploader/fpga_upload.py -d $(PORT) -f $(NAME).bin --no-verify

clean:
	rm -f *.bin *.txt *.blif *.out *.vcd *.json *.asc *~

.PHONY: all clean flash

