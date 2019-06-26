#include "FPGA_flash.h"


void enableFlashSS(){
    DISABLE_BIT(P3_MOD_OC,FLASH_SS_PIN);
    ENABLE_BIT(P3_DIR_PU,FLASH_SS_PIN);
    FLASH_SS = 0;
}

void enableFPGAReset(){
    DISABLE_BIT(P3_MOD_OC,RESET_FPGA_PIN);
    ENABLE_BIT(P3_DIR_PU,RESET_FPGA_PIN);
    RESET_FPGA = 0;
}

void disableFlashSS(){
    DISABLE_BIT(P3_MOD_OC,FLASH_SS_PIN);
    ENABLE_BIT(P3_DIR_PU,FLASH_SS_PIN);
    FLASH_SS = 1;
}

void disableFPGAReset(){
    DISABLE_BIT(P3_MOD_OC,RESET_FPGA_PIN);
    ENABLE_BIT(P3_DIR_PU,RESET_FPGA_PIN);
    RESET_FPGA = 1;
}

void triestateFlashSS(){
    FLASH_SS = 1;
    ENABLE_BIT(P3_MOD_OC,FLASH_SS_PIN);
    DISABLE_BIT(P3_DIR_PU,FLASH_SS_PIN);
}

void triestateFPGAReset(){
    RESET_FPGA = 1;	
    ENABLE_BIT(P3_MOD_OC,RESET_FPGA_PIN);
    DISABLE_BIT(P3_DIR_PU,RESET_FPGA_PIN);
}

void triestateSPI(){
    FLASH_DO = 1;
    ENABLE_BIT(P1_MOD_OC,FLASH_DO_PIN);
    DISABLE_BIT(P1_DIR_PU,FLASH_DO_PIN);

    FLASH_DI = 1;
    ENABLE_BIT(P1_MOD_OC,FLASH_DI_PIN);
    DISABLE_BIT(P1_DIR_PU,FLASH_DI_PIN);

    FLASH_CK = 1;
    ENABLE_BIT(P1_MOD_OC,FLASH_CK_PIN);
    DISABLE_BIT(P1_DIR_PU,FLASH_CK_PIN);
}

uint8_t state = 0;
uint8_t debug = 0;
uint8_t operation;
uint32_t transactionBytes = 0;
uint32_t memAddres = 0x00000000;
uint32_t memIndex = 0;
void runFPGA_Flash(uint8_t uart_data){
    if (state == 0 && (uart_data == 'W' || uart_data == 'R')) { // Write command received
        if(debug) printf("State 0. Mode %c. \r\n",uart_data);
        operation = uart_data;
        transactionBytes = 0;
        state = 1;
        enableFPGAReset();
        MEM_releasePowerDown();
    }else if (state == 0 && uart_data == 'd') {
        debug = !debug;
        if(debug) printf("Debug enabled\r\n");
    }else if (state == 0 && uart_data == 'D') {
        disableFPGAReset();
    }else if (state == 0 && uart_data == 'A') {
        triestateFlashSS();
        triestateSPI();
        
        enableFPGAReset();
        mDelaymS(5);
        triestateFPGAReset();
    }else if (state == 0 && uart_data == 'B') {
        jump_to_bootloader();
    }else if (state == 0 && uart_data == 'V') {
        v_uart_puts("HeimdalFPGA Bootloader V0.2\n");
    }else if (state == 1 || state == 2 || state == 3){
        if(debug) printf("Transaction Byte State %u, data: 0x%02X \r\n",state,uart_data);
        transactionBytes = transactionBytes | (((uint32_t) uart_data) << ((state-1)*8));
        state++;
    }else if (state == 4){
        if(debug) printf("Transaction Byte State %u, data: 0x%02X \r\n",state,uart_data);
        transactionBytes = transactionBytes | (uart_data << 24);
        if(debug) printf("Transaction Byte END, data: %lu \r\n",transactionBytes);

        if (operation == 'W') {
            if(debug) printf("Preparing memory to write\r\n");

            if(debug) printf("Erasing device\r\n");
            MEM_chipEraseFirst64k();

            enableFlashSS();
            MEM_writeEnable();
            disableFlashSS();

            memAddres = 0x00000000;
            memIndex = 0;
            enableFlashSS();
            if(debug) printf("Init write at %lu\r\n",memAddres);
            MEM_startWrite(memAddres);

            state = 5;
        }else if (operation == 'R'){
            if(debug) printf("Preparing memory to read\r\n");
            enableFlashSS();
            MEM_startRead(0x00);
            memIndex = 0;
            while(transactionBytes > 0){
                uint8_t data = MEM_read();
                if(debug) printf("Reading: %lu - 0x%02X (%c). Remaining: %lu\r\n",memIndex,data,data,transactionBytes);
                memIndex++;
                virtual_uart_tx(data);
                mDelayuS(80);
                transactionBytes--;
            }
            if(debug) printf("Reading done, returning to state 0\r\n");
            disableFlashSS();
            state = 0;
        }
    }else if (state == 5){
        MEM_write(uart_data);
        memIndex++;
        transactionBytes--;


        if (memIndex == PAGEBUFFERLEN) {
            if(debug) printf("--transactionBytes %lu\r\n",transactionBytes);
            if(debug) printf("--memIndex %lu\r\n",memIndex);

            disableFlashSS();
            if(debug) printf("Waiting write cycle\r\n");
            MEM_waitWriteCycle();
            if(debug) printf("Done write cycle\r\n");

            enableFlashSS();
            MEM_writeEnable();
            disableFlashSS();

            enableFlashSS();
            memIndex = 0;
            memAddres = memAddres + PAGEBUFFERLEN;
            if(debug) printf("Init write at %lu\r\n",memAddres);
            MEM_startWrite(memAddres);
        }
        

        if (transactionBytes == 0) {
            if(debug) printf("Write done!\r\n");
            disableFlashSS();
            MEM_waitWriteCycle();
            state = 0;
        }
    }
}