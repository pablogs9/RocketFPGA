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

void USBDeviceCfg();
void USBDeviceIntCfg();
void USBDeviceEndPointCfg();
void usb_poll();
void uart_poll();
void usb_int();