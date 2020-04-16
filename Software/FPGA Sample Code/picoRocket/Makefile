
CROSS=/opt/riscv32ic/bin/riscv32-unknown-elf-
CFLAGS=
DEV=/dev/ttyACM1

icebreaker.json: icebreaker.v ice40up5k_spram.v spimemio.v simpleuart.v picosoc.v picorv32.v
	yosys -ql icebreaker.log -p 'synth_ice40 -top icebreaker -json icebreaker.json' $^

icebreaker.asc: icebreaker.pcf icebreaker.json
	nextpnr-ice40 --freq 13 --up5k --asc icebreaker.asc --pcf icebreaker.pcf --json icebreaker.json

icebreaker.bin: icebreaker.asc
	icetime -d up5k -c 12 -mtr icebreaker.rpt icebreaker.asc
	icepack icebreaker.asc icebreaker.bin

all: icebreaker.bin icebreaker_fw.bin
	python3 ../../Code\ Uploader/fpga_upload.py -d $(DEV) -f icebreaker.bin -o 0
	python3 ../../Code\ Uploader/fpga_upload.py -d $(DEV) -f icebreaker_fw.bin -o 1048576

all_fw: icebreaker_fw.bin
	python3 ../../Code\ Uploader/fpga_upload.py -d $(DEV) -f icebreaker_fw.bin -o 1048576;

icebreaker_sections.lds: sections.lds
	$(CROSS)cpp -P -DICEBREAKER -o $@ $^

icebreaker_fw.elf: icebreaker_sections.lds start.s firmware.c
	$(CROSS)gcc $(CFLAGS) -DICEBREAKER -march=rv32ic -Wl,-Bstatic,-T,icebreaker_sections.lds,--strip-debug -ffreestanding -nostdlib -o icebreaker_fw.elf start.s firmware.c

icebreaker_fw.hex: icebreaker_fw.elf
	$(CROSS)objcopy -O verilog icebreaker_fw.elf icebreaker_fw.hex

icebreaker_fw.bin: icebreaker_fw.elf
	$(CROSS)objcopy -O binary icebreaker_fw.elf icebreaker_fw.bin

# ---- Clean ----

clean:
	rm -f icebreaker_fw.elf icebreaker_fw.hex icebreaker_fw.bin

clean_all:
	rm -f icebreaker_sections.lds icebreaker_fw.elf icebreaker_fw.hex icebreaker_fw.bin

.PHONY: spiflash_tb clean
.PHONY: hx8kprog hx8kprog_fw hx8ksim hx8ksynsim
.PHONY: icebprog icebprog_fw icebsim icebsynsim
