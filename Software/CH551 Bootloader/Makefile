TARGET = main

XRAM_SIZE = 0x0100
XRAM_LOC = 0x0100
BUILD_PATH = build
BIN_PATH = bin
C_FILES = \
	main.c \
	include/spi_memory.c\
	include/debug.c \
	include/spi.c \
	include/rocketFPGA_config.c 

CC = sdcc
OBJCOPY = objcopy
PACK_HEX = packihx
WCHISP = wchisptool

ifndef FREQ_SYS
FREQ_SYS = 16000000
endif

ifndef XRAM_SIZE
XRAM_SIZE = 0x0400
endif

ifndef XRAM_LOC
XRAM_LOC = 0x0000
endif

ifndef CODE_SIZE
CODE_SIZE = 0x2800
endif

ROOT_DIR := .

CFLAGS := -V -mmcs51 --model-small \
	--xram-size $(XRAM_SIZE) --xram-loc $(XRAM_LOC) \
	--code-size $(CODE_SIZE) \
	-I$(ROOT_DIR)/include -DFREQ_SYS=$(FREQ_SYS) \
	$(EXTRA_FLAGS)

LFLAGS := $(CFLAGS)

RELS :=   $(C_FILES:.c=.rel)
print-%  : ; @echo $* = $($*)

%.rel : %.c
	$(CC) -c -o $(BUILD_PATH)/$(nopath $@ )  $(CFLAGS)  $< 

$(TARGET).ihx: $(RELS)
	$(CC)  $(addprefix $(BUILD_PATH)/, $(notdir $(RELS))) $(LFLAGS) -o $(BIN_PATH)/$(TARGET).ihx

$(TARGET).hex: $(TARGET).ihx
	$(PACK_HEX) $(BIN_PATH)/$(TARGET).ihx > $(BIN_PATH)/$(TARGET).hex

$(TARGET).bin: $(TARGET).ihx
	$(OBJCOPY) -I ihex -O binary $(BIN_PATH)/$(TARGET).ihx $(BIN_PATH)/$(TARGET).bin
	
flash: $(TARGET).bin pre-flash
	$(WCHISP) -f $(TARGET).bin -g

.DEFAULT_GOAL := all
all: $(TARGET).bin $(TARGET).hex

clean:
	rm -f \
	$(notdir $(RELS:.rel=.asm)) \
	$(notdir $(RELS:.rel=.lst)) \
	$(notdir $(RELS:.rel=.mem)) \
	$(notdir $(RELS:.rel=.rel)) \
	$(notdir $(RELS:.rel=.rst)) \
	$(notdir $(RELS:.rel=.sym)) \
	$(notdir $(RELS:.rel=.adb)) \
	$(TARGET).lk \
	$(TARGET).map \
	$(TARGET).mem \
	$(TARGET).ihx \
	$(TARGET).hex \
	$(TARGET).bin 
	rm $(BUILD_PATH)/*
	rm $(BIN_PATH)/*
CFLAGS += -I include
