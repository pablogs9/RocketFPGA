#include "FPGA_flash.h"

void SPI_highImpedance(){
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


void FPGAReset_enable(){
    DISABLE_BIT(P3_MOD_OC,RESET_FPGA_PIN);
    ENABLE_BIT(P3_DIR_PU,RESET_FPGA_PIN);
    RESET_FPGA = 0;
}


void FPGAReset_disable(){
    DISABLE_BIT(P3_MOD_OC,RESET_FPGA_PIN);
    ENABLE_BIT(P3_DIR_PU,RESET_FPGA_PIN);
    RESET_FPGA = 1;
}


void FPGAReset_highImpedance(){
    RESET_FPGA = 1;	
    ENABLE_BIT(P3_MOD_OC,RESET_FPGA_PIN);
    DISABLE_BIT(P3_DIR_PU,RESET_FPGA_PIN);
}



uint8_t state = 0;
enum state_enum  {
    START = 0,
    RECV_LENGTH_1ST_BYTE = 1,
    RECV_LENGTH_2ND_BYTE = 2,
    RECV_LENGTH_3RD_BYTE = 3,
    RECV_LENGTH_4TH_BYTE = 4,
    WRT_FLASH = 5
};
uint8_t debug = 0;
uint8_t operation;
uint32_t transactionBytes = 0;
uint32_t memAddres = 0x00000000;
uint32_t memIndex = 0;

void FPGA_runFlashStateMachine(uint8_t uart_data){
    if (state == START && (uart_data == 'W' || uart_data == 'R')) { // Write command received
        if(debug) printf("State 0. Mode %c. \r\n",uart_data);
        operation = uart_data;
        transactionBytes = 0;
        state = 1;
        FPGAReset_enable();
        MEM_releasePowerDown();
    }else if (state == START && uart_data == 'd') {
        debug = !debug;
        if(debug) printf("Debug enabled\r\n");
    }else if (state == START && uart_data == 'D') {
        FPGAReset_disable();
    }else if (state == START && uart_data == 'A') {
        MEM_highImpedanceSS();
        SPI_highImpedance();
        
        FPGAReset_enable();
        mDelaymS(5);
        FPGAReset_highImpedance();
    }else if (state == START && uart_data == 'B') {
        jump_to_bootloader();
    }else if (state == START && uart_data == 'V') {
        v_uart_puts("HeimdalFPGA Bootloader V0.2\n");
    }else if (state == RECV_LENGTH_1ST_BYTE 
            || state == RECV_LENGTH_2ND_BYTE 
            || state == RECV_LENGTH_3RD_BYTE){
        if(debug) printf("Transaction Byte State %u, data: 0x%02X \r\n",state,uart_data);
        transactionBytes = transactionBytes | (((uint32_t) uart_data) << ((state-1)*8));
        state++;
    }else if (state == RECV_LENGTH_4TH_BYTE){
        if(debug) printf("Transaction Byte State %u, data: 0x%02X \r\n",state,uart_data);
        transactionBytes = transactionBytes | (uart_data << 24);
        if(debug) printf("Transaction Byte END, data: %lu \r\n",transactionBytes);

        if (operation == 'W') {
            if(debug) printf("Preparing memory to write\r\n");

            if(debug) printf("Erasing device\r\n");
            MEM_chipEraseFirst64k();

            MEM_enableSS();
            MEM_writeEnable();
            MEM_disableSS();

            memAddres = 0x00000000;
            memIndex = 0;
            MEM_enableSS();
            if(debug) printf("Init write at %lu\r\n",memAddres);
            MEM_startWrite(memAddres);

            state = WRT_FLASH;
        }else if (operation == 'R'){
            if(debug) printf("Preparing memory to read\r\n");
            MEM_enableSS();
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
            MEM_disableSS();
            state = START;
        }
    }else if (state == WRT_FLASH){
        MEM_write(uart_data);
        memIndex++;
        transactionBytes--;
        if(debug) printf("--transactionBytes %lu\r\n",transactionBytes);


        if (memIndex == PAGEBUFFERLEN) {
            if(debug) printf("--transactionBytes %lu\r\n",transactionBytes);
            if(debug) printf("--memIndex %lu\r\n",memIndex);

            MEM_disableSS();
            if(debug) printf("Waiting write cycle\r\n");
            MEM_waitWriteCycle();
            if(debug) printf("Done write cycle\r\n");

            MEM_enableSS();
            MEM_writeEnable();
            MEM_disableSS();

            MEM_enableSS();
            memIndex = 0;
            memAddres = memAddres + PAGEBUFFERLEN;
            if(debug) printf("Init write at %lu\r\n",memAddres);
            MEM_startWrite(memAddres);
        }
        

        if (transactionBytes == 0) {
            if(debug) printf("Write done!\r\n");
            MEM_disableSS();
            MEM_waitWriteCycle();
            state = 0;
        }
    }
}