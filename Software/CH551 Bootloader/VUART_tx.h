#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ch554.h>
#include <debug.h>

#define UART_REV_LEN  64
extern __idata uint8_t Receive_Uart_Buf[UART_REV_LEN];  
extern volatile __idata uint8_t Uart_Input_Point;
extern volatile __idata uint8_t Uart_Output_Point; 
extern volatile __idata uint8_t UartByteCount;

void virtual_uart_tx(uint8_t tdata);
void v_uart_puts(char *str);