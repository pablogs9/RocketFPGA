#include "spi_memory.h"
#include <debug.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ch554.h>
#include <ch554_usb.h>
#include <debug.h>
#include <spi.h>

void MEM_writeEnable(){
    CH554SPIMasterWrite(MEM_WREN);
}
void MEM_writeDisable(){
    CH554SPIMasterWrite(MEM_WRDI);
}
uint8_t MEM_getStatusRegister(){
    uint8_t stReg;
    CH554SPIMasterWrite(MEM_RDSR);
    stReg = CH554SPIMasterRead();
    return stReg;
}
void MEM_setStatusRegister(uint8_t st){
    CH554SPIMasterWrite(MEM_WRSR);
    CH554SPIMasterWrite(st);
}

void MEM_startRead(uint32_t addr){
    CH554SPIMasterWrite(MEM_READ);
    MEM_writeAddress(addr);
}

uint8_t MEM_read(){
    return CH554SPIMasterRead();
}

uint8_t MEM_readByte(uint32_t addr){
    uint8_t data;
    CH554SPIMasterWrite(MEM_READ);
    MEM_writeAddress(addr);
    data = CH554SPIMasterRead();
    return data;
}
void MEM_readFrom(uint32_t addr, uint8_t length, uint8_t * buf){
    uint32_t i;
    CH554SPIMasterWrite(MEM_READ);
    MEM_writeAddress(addr);
    for(i=0; i<length ;i++){
        buf[i] = CH554SPIMasterRead();
    }
}

void MEM_startWrite(uint32_t addr){
    CH554SPIMasterWrite(MEM_WRITE);
    MEM_writeAddress(addr);
}

void MEM_write(uint8_t data){
    CH554SPIMasterWrite(data);
}

void MEM_writeByteAt(uint32_t addr, uint8_t data){
    CH554SPIMasterWrite(MEM_WRITE);
    MEM_writeAddress(addr);
    CH554SPIMasterWrite(data);
}
void MEM_writeAt(uint32_t addr, uint8_t length, uint8_t * buf){
    uint32_t i;
    CH554SPIMasterWrite(MEM_WRITE);
    MEM_writeAddress(addr);
    for(i = 0; i < length; i++){
        CH554SPIMasterWrite(buf[i]);
    }
    
}

void MEM_writeAddress(uint32_t addr){
    CH554SPIMasterWrite((addr>>16)&0x000000FF);
    CH554SPIMasterWrite((addr>>8)&0x000000FF);
    CH554SPIMasterWrite((addr>>0)&0x000000FF);
}

void MEM_waitWriteCycle(){
    uint8_t ans;
    
    enableFlashSS();
    CH554SPIMasterWrite(MEM_RDSR);
    ans = CH554SPIMasterRead();
    while(ans & 0x01){
        ans = CH554SPIMasterRead();
    };

    disableFlashSS();
}

void MEM_chipErase(){
    uint8_t ans;

    enableFlashSS();
	MEM_writeEnable();
	disableFlashSS();

    enableFlashSS();
    CH554SPIMasterWrite(MEM_CHER);
    disableFlashSS();
    
    enableFlashSS();
    CH554SPIMasterWrite(MEM_RDSR);
    ans = CH554SPIMasterRead();
    while(ans & 0x01){
        ans = CH554SPIMasterRead();
    };

    disableFlashSS();
}

void MEM_chipErase64KBlock(uint8_t block){
    uint8_t ans;

    enableFlashSS();
	MEM_writeEnable();
	disableFlashSS();

    enableFlashSS();
    CH554SPIMasterWrite(0xD8);
    MEM_writeAddress(((uint32_t)block) * 0x10000);
    disableFlashSS();
    
    enableFlashSS();
    CH554SPIMasterWrite(MEM_RDSR);
    ans = CH554SPIMasterRead();
    while(ans & 0x01){
        ans = CH554SPIMasterRead();
    };

    disableFlashSS();
}

void MEM_chipErase4KSector(uint16_t sector){
    uint8_t ans;

    enableFlashSS();
	MEM_writeEnable();
	disableFlashSS();

    enableFlashSS();
    CH554SPIMasterWrite(0x20);
    MEM_writeAddress(((uint32_t)sector) * 0x1000);
    disableFlashSS();
    
    enableFlashSS();
    CH554SPIMasterWrite(MEM_RDSR);
    ans = CH554SPIMasterRead();
    while(ans & 0x01){
        ans = CH554SPIMasterRead();
    };

    disableFlashSS();
}

void MEM_releasePowerDown(){
    enableFlashSS();
	CH554SPIMasterWrite(MEM_RPWDN);
	disableFlashSS();
    mDelaymS(1);
}


