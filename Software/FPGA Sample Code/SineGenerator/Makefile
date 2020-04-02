#----------------------------------------
#-- Establecer nombre del componente
#----------------------------------------
NAME = main
PINS = ../Utils/pins.pcf
PORT = /dev/ttyS20

#-------------------------------------------------------
#-- Objetivo por defecto: hacer simulacion y sintesis
#-------------------------------------------------------
all: sint
sint: $(NAME).bin
	

#------------------------------
#-- Sintesis completa
#------------------------------
$(NAME).bin: $(PINS) $(NAME).v 
	
	#-- Sintesis
	# yosys -p 'synth_ice40 -top $(NAME) -json $(NAME).json' $(wildcard *.v)
	yosys -p 'synth_ice40 -top $(NAME) -json $(NAME).json' main.v squaregenerator.v trianglegenerator.v sinegenerator.v ../I2S/i2s_rx.v ../I2S/i2s_tx.v ../Codec/configurator.v ../Codec/SPI.v

	
	#-- Place & route
	# arachne-pnr -d 1k -p $(PINS) $(NAME).blif -o $(NAME).txt
	nextpnr-ice40 --up5k --package sg48  --json $(NAME).json --pcf $(PINS) --asc $(NAME).asc
	
	#-- Generar binario final, listo para descargar en fgpa
	icepack $(NAME).asc $(NAME).bin


flash: $(NAME).bin
	fpga_upload -d $(PORT) -f $(NAME).bin 

#-- Limpiar todo
clean:
	rm -f *.bin *.txt *.blif *.out *.vcd *~

.PHONY: all clean flash

