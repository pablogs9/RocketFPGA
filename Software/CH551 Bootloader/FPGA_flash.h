#include <compiler.h>
#include <ch554.h>
#include <spi.h>
#include "spi_memory.h"
#include <debug.h>
#include <stdio.h>
#include "VUART_tx.h"
#define PAGEBUFFERLEN 256

#define RESET_FPGA_PIN 3
#define FLASH_SS_PIN 2
#define FLASH_DO_PIN 5
#define FLASH_DI_PIN 6
#define FLASH_CK_PIN 7

#define ENABLE_BIT(R,B) R = R |	(1<<B)
#define DISABLE_BIT(R,B) R = R & ~(1<<B)

SBIT(FLASH_DO, 0x90, FLASH_DO_PIN);
SBIT(FLASH_DI, 0x90, FLASH_DI_PIN);
SBIT(FLASH_CK, 0x90, FLASH_CK_PIN);

SBIT(FLASH_SS, 0xB0, FLASH_SS_PIN);
SBIT(RESET_FPGA, 0xB0, RESET_FPGA_PIN);

void enableFlashSS();
void enableFPGAReset();
void disableFlashSS();
void disableFPGAReset();
void triestateFlashSS();
void triestateFPGAReset();
void runFPGA_Flash(uint8_t uart_data);