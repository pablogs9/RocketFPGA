TARGET = main
XRAM_SIZE = 0x0100
XRAM_LOC = 0x0100
BUILD_DIR=build
BIN_DIR=bin
VPATH=include
SRC_PATH=.
SRCS=$(wildcard $(SRC_PATH)/*.c) \
	$(wildcard $(SRC_PATH)/include/*.c) \

RELS=$(addprefix $(BUILD_DIR)/,$(notdir $(SRCS:.c=.rel)))
CC = sdcc
OBJCOPY = objcopy
WCHISP ?= ./utils/vnproch551/vnproch551
FREQ_SYS ?= 16000000
XRAM_SIZE ?= 0x0400
XRAM_LOC ?= 0x0000
CODE_SIZE ?= 0x2800


ROOT_DIR := .
CFLAGS := -V -mmcs51 --model-small \
	--xram-size $(XRAM_SIZE) --xram-loc $(XRAM_LOC) \
	--code-size $(CODE_SIZE) \
	-I$(ROOT_DIR)/include -DFREQ_SYS=$(FREQ_SYS) \
	$(EXTRA_FLAGS)

LFLAGS := $(CFLAGS)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(RELS): $(BUILD_DIR)/%.rel: %.c 
	$(CC) -c -o  $@   $(CFLAGS)  $< 

$(BIN_DIR)/$(TARGET).ihx:  $(BIN_DIR) $(BUILD_DIR)  $(RELS)
	$(CC)   $(RELS) $(LFLAGS) -o $@ 

$(BIN_DIR)/$(TARGET).bin: $(BIN_DIR)/$(TARGET).ihx
	$(OBJCOPY) -I ihex -O binary $(BIN_DIR)/$(TARGET).ihx $(BIN_DIR)/$(TARGET).bin
	
flash:$(BIN_DIR)/$(TARGET).bin 
	$(WCHISP) $(BIN_DIR)/$(TARGET).bin
tools:
	$(MAKE) -C utils/vnproch551
.DEFAULT_GOAL := all
all: $(BIN_DIR)/$(TARGET).bin 

clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(BIN_DIR)
