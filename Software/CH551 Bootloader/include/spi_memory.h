#ifndef __SPI_MEMORY_H__
#define __SPI_MEMORY_H__

#include <spi.h>
#include "rocketFPGA_config.h"

#define MEM_WREN 0x06
#define MEM_WRDI 0x04
#define MEM_RDSR 0x05
#define MEM_WRSR 0x01
#define MEM_READ 0x03
#define MEM_WRITE 0x02
#define MEM_RDID 0x83
#define MEM_WRID 0x82
#define MEM_CHER 0xC7
#define MEM_RPWDN 0xAB

void MEM_writeEnable();
void MEM_writeDisable();
uint8_t MEM_getStatusRegister();
void MEM_setStatusRegister(uint8_t st);
void MEM_startRead(uint32_t addr);
uint8_t MEM_read();
uint8_t MEM_readByte(uint32_t addr);
void MEM_readFrom(uint32_t addr, uint8_t length, uint8_t * buf);
void MEM_startWrite(uint32_t addr);
void MEM_write(uint8_t data);
void MEM_writeByteAt(uint32_t addr, uint8_t data);
void MEM_writeAt(uint32_t addr, uint8_t length, uint8_t * buf);
void MEM_writeAddress(uint32_t addr);
void MEM_waitWriteCycle();
void MEM_chipErase64KBlock(uint8_t block);
void MEM_chipErase4KSector(uint16_t sector);
void MEM_chipErase();
void MEM_releasePowerDown();


#endif