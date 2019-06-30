#include <compiler.h>
#include <ch554.h>
#include <spi.h>
#include "spi_memory.h"
#include <debug.h>
#include <stdio.h>
#include "VUART_tx.h"
#define PAGEBUFFERLEN 256

#define RESET_FPGA_PIN 3
#define FLASH_DO_PIN 5
#define FLASH_DI_PIN 6
#define FLASH_CK_PIN 7

SBIT(FLASH_DO, 0x90, FLASH_DO_PIN);
SBIT(FLASH_DI, 0x90, FLASH_DI_PIN);
SBIT(FLASH_CK, 0x90, FLASH_CK_PIN);
SBIT(RESET_FPGA, 0xB0, RESET_FPGA_PIN);

void FPGAReset_enable();
void FPGAReset_disable();
void FPGAReset_highImpedance();
void SPI_highImpedance();
void FPGA_runFlashStateMachine(uint8_t uart_data);