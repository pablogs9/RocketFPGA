#include "rocketFPGA_config.h"
#include <debug.h>

void enablePreFlash(){
    enableFlashSS();
}

void disablePreFlash(){
    disableFlashSS();
}

void enableLED(){
    DISABLE_BIT(P1_MOD_OC,LED_PIN);
    ENABLE_BIT(P1_DIR_PU,LED_PIN);
    LED = 1;
}

void disableLED(){
    DISABLE_BIT(P1_MOD_OC,LED_PIN);
    ENABLE_BIT(P1_DIR_PU,LED_PIN);
    LED = 0;
}

void enableFPGAReset(){
    DISABLE_BIT(P3_MOD_OC,RESET_FPGA_PIN);
    ENABLE_BIT(P3_DIR_PU,RESET_FPGA_PIN);
    RESET_FPGA = 0;
}

void disableFPGAReset(){
    DISABLE_BIT(P3_MOD_OC,RESET_FPGA_PIN);
    ENABLE_BIT(P3_DIR_PU,RESET_FPGA_PIN);
    RESET_FPGA = 1;
}

void disableFlashSS(){
    DISABLE_BIT(P3_MOD_OC,FLASH_SS_PIN);
    ENABLE_BIT(P3_DIR_PU,FLASH_SS_PIN);
    FLASH_SS = 1;
}

void triestateFPGAReset(){
    RESET_FPGA = 1;	
    ENABLE_BIT(P3_MOD_OC,RESET_FPGA_PIN);
    DISABLE_BIT(P3_DIR_PU,RESET_FPGA_PIN);
}

void enableFlashSS(){
    DISABLE_BIT(P3_MOD_OC,FLASH_SS_PIN);
    ENABLE_BIT(P3_DIR_PU,FLASH_SS_PIN);
    FLASH_SS = 0;
}

void triestateFlashSS(){
    FLASH_SS = 1;
    ENABLE_BIT(P3_MOD_OC,FLASH_SS_PIN);
    DISABLE_BIT(P3_DIR_PU,FLASH_SS_PIN);
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