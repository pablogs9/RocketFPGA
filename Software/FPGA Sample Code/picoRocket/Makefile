
CROSS=/opt/riscv32ic/bin/riscv32-unknown-elf-
CFLAGS=
DEV=/dev/ttyACM1

# Gateware

icebreaker.json: icebreaker.v ice40up5k_spram.v spimemio.v simpleuart.v picosoc.v picorv32.v ../WaveformGenerators/sinegenerator.v ../I2S/i2s_rx.v ../I2S/i2s_tx.v ../Codec/configurator.v ../Codec/SPI.v
	yosys -ql icebreaker.log -p 'synth_ice40 -top icebreaker -json icebreaker.json' $^

icebreaker.asc: icebreaker.pcf icebreaker.json
	nextpnr-ice40 --freq 13 --up5k --asc icebreaker.asc --pcf icebreaker.pcf --json icebreaker.json

icebreaker.bin: icebreaker.asc
	icetime -d up5k -c 12 -mtr icebreaker.rpt icebreaker.asc
	icepack icebreaker.asc icebreaker.bin

# Firmware

icebreaker_sections.lds: sections.lds
	$(CROSS)cpp -P -DICEBREAKER -o $@ $^

icebreaker_fw.elf: icebreaker_sections.lds start.s firmware.c
	$(CROSS)gcc $(CFLAGS) -DICEBREAKER -march=rv32ic -mabi=ilp32 -Wl,-Bstatic,-T,icebreaker_sections.lds,--strip-debug -ffreestanding -static-libgcc -lgcc -nostdlib -o icebreaker_fw.elf start.s firmware.c /opt/riscv32ic/lib/gcc/riscv32-unknown-elf/8.2.0/libgcc.a

icebreaker_fw.hex: icebreaker_fw.elf
	$(CROSS)objcopy -O verilog icebreaker_fw.elf icebreaker_fw.hex

icebreaker_fw.bin: icebreaker_fw.elf
	$(CROSS)objcopy -O binary icebreaker_fw.elf icebreaker_fw.bin

# Clean

clean:
	rm -f icebreaker_sections.lds icebreaker_fw.elf icebreaker_fw.hex icebreaker_fw.bin icebreaker.bin icebreaker.asc icebreaker.json

clean_fw:
	rm -f icebreaker_fw.elf icebreaker_fw.hex icebreaker_fw.bin

clean_gw:
	rm -f icebreaker.bin icebreaker.asc icebreaker.json


# Alls

all: icebreaker.bin icebreaker_fw.bin
	python3 ../../Code\ Uploader/fpga_upload.py -d $(DEV) -f icebreaker.bin -o 0
	python3 ../../Code\ Uploader/fpga_upload.py -d $(DEV) -f icebreaker_fw.bin -o 1048576

all_fw: icebreaker_fw.bin
	python3 ../../Code\ Uploader/fpga_upload.py -d $(DEV) -f icebreaker_fw.bin -o 1048576;

all_gw: icebreaker.bin
	python3 ../../Code\ Uploader/fpga_upload.py -d $(DEV) -f icebreaker.bin -o 0

# .PHONY: spiflash_tb clean
# .PHONY: hx8kprog hx8kprog_fw hx8ksim hx8ksynsim
# .PHONY: icebprog icebprog_fw icebsim icebsynsim
