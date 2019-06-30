#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define DEFAULT_ENDP0_SIZE	64
#define DEFAULT_ENDP1_SIZE	64
#include <ch554.h>
#include <ch554_usb.h>
#include <debug.h>
#include "FPGA_flash.h"
#include "VUART_tx.h"


#define BOOT_ADDR  0x3800

/* This function provided a way to access the internal bootloader */
void jump_to_bootloader(){
	USB_INT_EN = 0;
	USB_CTRL = 0x06;
	
	mDelaymS(100);
	
	EA = 0;/* Disable all interrupts */
	
	__asm
		LJMP BOOT_ADDR /* Jump to bootloader */
	__endasm;	
	while(1); 
}
void DeviceInterrupt(void) __interrupt (INT_NO_USB) {
	usb_int();
}


// Main loop

main(){	
	int i = 0;
	CfgFsys( );														   
	mDelaymS(5);														 
	mInitSTDIO( );													
	USBDeviceCfg();
	USBDeviceEndPointCfg();											
	USBDeviceIntCfg();												
	SPIMasterModeSet(0);
	while(1){
		usb_poll();
		uart_poll();			
	}
}
