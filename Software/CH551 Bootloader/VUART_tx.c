#include "VUART_tx.h"
__idata uint8_t Receive_Uart_Buf[UART_REV_LEN];  
volatile __idata uint8_t Uart_Input_Point = 0;
volatile __idata uint8_t Uart_Output_Point = 0; 
volatile __idata uint8_t UartByteCount = 0;

void virtual_uart_tx(uint8_t tdata){
	Receive_Uart_Buf[Uart_Input_Point++] = tdata;
	UartByteCount++;				
	if(Uart_Input_Point>=UART_REV_LEN)
	{
		Uart_Input_Point = 0;
	}
}
void v_uart_puts(char *str){
	while(*str)
		virtual_uart_tx(*(str++));
}