#----------------------------------------
#-- Establecer nombre del componente
#----------------------------------------
NAME = main
PINS = pins.pcf
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
	# yosys -p "synth_ice40 -blif $(NAME).blif" $(NAME).v
	yosys -p 'synth_ice40 -top $(NAME) -json $(NAME).json' main.v pwm.v spi.v clock_synchronizer.v
	
	#-- Place & route
	# arachne-pnr -d 1k -p $(PINS) $(NAME).blif -o $(NAME).txt
	# nextpnr-ice40 --hx1k --package vq100 --json $(NAME).json --pcf pinsJC.pcf --asc $(NAME).asc
	nextpnr-ice40 --lp384 --package qn32 --json $(NAME).json --pcf $(PINS) --asc $(NAME).asc
	
	#-- Generar binario final, listo para descargar en fgpa
	icepack $(NAME).asc $(NAME).bin


flash: $(NAME).bin
	fpga_upload -d $(PORT) -f $(NAME).bin 




#-- Limpiar todo
clean:
	rm -f *.bin *.txt *.blif *.out *.vcd *~

.PHONY: all clean flash

