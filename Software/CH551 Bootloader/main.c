#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "spi_memory.h"
#define DEFAULT_ENDP0_SIZE	64
#define DEFAULT_ENDP1_SIZE	64
#include <ch554.h>
#include <ch554_usb.h>
#include <debug.h>
#include <math.h>
#include <spi.h>
#include "rocketFPGA_config.h"

__xdata __at (0x0000) uint8_t  Ep0Buffer[DEFAULT_ENDP0_SIZE];	
__xdata __at (0x0040) uint8_t  Ep1Buffer[DEFAULT_ENDP1_SIZE];
__xdata __at (0x0080) uint8_t  Ep2Buffer[2*MAX_PACKET_SIZE];

uint8_t usb_uart_mode = 0;

uint16_t SetupLen;
uint8_t   SetupReq,Count,UsbConfig;
const uint8_t *  pDescr;
USB_SETUP_REQ   SetupReqBuf;
#define UsbSetupBuf	 ((PUSB_SETUP_REQ)Ep0Buffer)

#define  SET_LINE_CODING					0X20			// Configures DTE rate, stop-bits, parity, and number-of-character
#define  GET_LINE_CODING					0X21			// This request allows the host to find out the currently configured line coding.
#define  SET_CONTROL_LINE_STATE				0X22			// This request generates RS-232/V.24 style control signals.

uint32_t Baud = 0;

__code uint8_t DevDesc[] = {0x12, //18 bytes
							0x01, //device descriptor (always 1)
							0x10, //USB 1.1 (byte LSB)
							0x01, ////USB 1.1 (byte MSB)
							0x02, //device class 2 (doent matter)
							0x00, //device subclass
							0x00, //device protocol
							DEFAULT_ENDP0_SIZE, //MAX packet size
							0x86, //idVendor
							0x1a, //idVendor
							0x22, //idProduct
							0x57, //idProduct
							0x00, //device release type
							0x01,//device release type
							0x01,//manufacurer
							0x02,//product
							0x03,//serial number
							0x01//num of configuration
						   };
#define Device_Version			"1.0.1"

__code uint8_t CfgDesc[] ={
	//configuration descriptor
	0x09,0x02,0x43,0x00,0x02,0x01,0x00,0xa0,0x32,			 
	//interface descriptor
	0x09,0x04,0x00,0x00,0x01,0x02,0x02,0x01,0x00,			
	0x05,0x24,0x00,0x10,0x01,							
	0x05,0x24,0x01,0x00,0x00,
	0x04,0x24,0x02,0x02,
	0x05,0x24,0x06,0x00,0x01,
	0x07,0x05,0x81,0x03,0x10,0x00,0x40,
	0x09,0x04,0x01,0x00,0x02,0x0a,0x00,0x00,0x00,
	0x07,0x05,0x02,0x02,0x40,0x00,0x00,	
	0x07,0x05,0x82,0x02,0x40,0x00,0x00,
};

unsigned char  __code LangDes[]={0x04,0x03,0x09,0x04};
unsigned char  __code SerDes[]={
				0x14,0x03,
				'2',0x00,'0',0x00,'1',0x00,'8',0x00,'-',0x00,
				'3',0x00,'-',0x00,
				'1',0x00,'7',0x00
				};


unsigned char  __code Prod_Des[]={
				32,0x03,
				'R',0x00,'o',0x00,'c',0x00,'k',0x00,'e',0x00,'t',0x00, 'F', 0x00, 
				'P',0x00,'G',0x00,'A',0x00,' ',0x00,' ',0x00,' ',0x00,' ',0x00,' ',0x00
				};

unsigned char  __code Manuf_Des[]={
	0x18,0x03,
	'L', 0x00, 'u', 0x00, 'i', 0x00,'s',0x00,' ', 0x00, 'P', 0x00, 'a', 0x00, 'b', 0x00, 
	'l', 0x00, 'o', 0x00, ' ', 0x00
};

__xdata uint8_t LineCoding[7]={0x00,0xe1,0x00,0x00,0x00,0x00,0x08};   

#define UART_REV_LEN  64
__idata uint8_t Receive_Uart_Buf[UART_REV_LEN];  
volatile __idata uint8_t Uart_Input_Point = 0;
volatile __idata uint8_t Uart_Output_Point = 0; 
volatile __idata uint8_t UartByteCount = 0;
volatile __idata uint8_t USBByteCount = 0;
volatile __idata uint8_t USBBufOutPoint = 0;
volatile __idata uint8_t UpPoint2_Busy  = 0;

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

void USBDeviceCfg(){
	USB_CTRL = 0x00;
	USB_CTRL &= ~bUC_HOST_MODE;										
	USB_CTRL |=  bUC_DEV_PU_EN | bUC_INT_BUSY | bUC_DMA_EN;			
	USB_DEV_AD = 0x00;													
	//	 USB_CTRL |= bUC_LOW_SPEED;
	//	 UDEV_CTRL |= bUD_LOW_SPEED;											
	USB_CTRL &= ~bUC_LOW_SPEED;
	UDEV_CTRL &= ~bUD_LOW_SPEED;											
	UDEV_CTRL = bUD_PD_DIS;  
	UDEV_CTRL |= bUD_PORT_EN;												
}

void USBDeviceIntCfg(){
	USB_INT_EN |= bUIE_SUSPEND;											  
	USB_INT_EN |= bUIE_TRANSFER;											  
	USB_INT_EN |= bUIE_BUS_RST;											  
	USB_INT_FG |= 0x1F;													 
	IE_USB = 1;															
	EA = 1;														
}

void USBDeviceEndPointCfg(){
	// TODO: Is casting the right thing here? What about endianness?
	UEP1_DMA = (uint16_t) Ep1Buffer;													 
	UEP2_DMA = (uint16_t) Ep2Buffer;													
	UEP2_3_MOD = 0xCC;														
	UEP2_CTRL = bUEP_AUTO_TOG | UEP_T_RES_NAK | UEP_R_RES_ACK;				

	UEP1_CTRL = bUEP_AUTO_TOG | UEP_T_RES_NAK;							
	UEP0_DMA = (uint16_t) Ep0Buffer;									
	UEP4_1_MOD = 0X40;													
	UEP0_CTRL = UEP_R_RES_ACK | UEP_T_RES_NAK;							
}

void DeviceInterrupt(void) __interrupt (INT_NO_USB){
	uint16_t len;
	if(UIF_TRANSFER) //USB transfer finished?										
	{
		//switch with PID token and Endpoint destination
		//PID tells what the USB message purpose Is
		//=>https://www.beyondlogic.org/usbnutshell/usb3.shtml
		//MASK_UIS_TOKEN =>00 means OUT packet; 01 means SOF packet; 10 means IN packet; 11 means SETUP packet.
		switch (USB_INT_ST & (MASK_UIS_TOKEN | MASK_UIS_ENDP))
		{
		//Input packet on ENP 1
		//the host whishes to read information
		case UIS_TOKEN_IN | 1:
			//set output data length to 0 							
			UEP1_T_LEN = 0; 
			//answer ack? 
			//TODO: Change by UEP_T_RES_ACK and se if it works
			UEP1_CTRL = UEP1_CTRL & ~ MASK_UEP_T_RES | UEP_T_RES_NAK;
			break;
		case UIS_TOKEN_IN | 2:
		//the host whishes to read information										//endpoint 2# Endpoint Bulk Upload
		{
			UEP2_T_LEN = 0;													
			//answer ACK (the original comment was: DEFAULT RESPONSE NACK)
			UEP2_CTRL = UEP2_CTRL & ~ MASK_UEP_T_RES | UEP_T_RES_NAK;	
			//clear busy flag	   
			UpPoint2_Busy = 0;												  
		}
			break;
		case UIS_TOKEN_OUT | 2:
		//Enpoint 2 out
			//is packet synced?? (valid)	
			//usb transmssion starts with a sync (http://www.usbmadesimple.co.uk/ums_3.htm)						
			if ( U_TOG_OK )													 
			{
				USBByteCount = USB_RX_LEN; //usb receiving length
				USBBufOutPoint = 0;//reset pointer
				UEP2_CTRL = UEP2_CTRL & ~ MASK_UEP_R_RES | UEP_R_RES_NAK;//send nak?
			}
			break;
		case UIS_TOKEN_SETUP | 0:												//SETUP
			len = USB_RX_LEN;
			if(len == (sizeof(USB_SETUP_REQ)))
			{
				// https://www.beyondlogic.org/usbnutshell/usb6.shtml
				SetupLen = ((uint16_t)UsbSetupBuf->wLengthH<<8) | (UsbSetupBuf->wLengthL); //number of bytes to send if transaction is to be made
				len = 0;	
				//type												  
				SetupReq = UsbSetupBuf->bRequest;
				if ( ( UsbSetupBuf->bRequestType & USB_REQ_TYP_MASK ) != USB_REQ_TYP_STANDARD )//non standard request
				{
					switch( SetupReq )
					{
					case GET_LINE_CODING:   //0x21  currently configured
						pDescr = LineCoding;
						len = sizeof(LineCoding);
						len = SetupLen >= DEFAULT_ENDP0_SIZE ? DEFAULT_ENDP0_SIZE : SetupLen; 
						memcpy(Ep0Buffer,pDescr,len);
						SetupLen -= len;
						pDescr += len;
						break;
					case SET_CONTROL_LINE_STATE:  //0x22  generates RS-232/V.24 style control signals
						if(UsbSetupBuf->wValueL==0x03){
							usb_uart_mode = 0; // Brigde mode
						}
						else{
							usb_uart_mode = 1; // Programming mode
						}
						break;
					case SET_LINE_CODING:	  //0x20  Configure
						break;
					default:
						len = 0xFF;  								 								
						break;
					}
				}
				else//standadr request
				{
					switch(SetupReq)											 
					{
					case USB_GET_DESCRIPTOR:
						switch(UsbSetupBuf->wValueH)
						{
						//USB get descriptor
						case 1:													   
							//put device descriptor into buffer
							pDescr = DevDesc;										
							len = sizeof(DevDesc);
							break;
						case 2:														
							//get config descript
							pDescr = CfgDesc;										
							len = sizeof(CfgDesc);
							break;
						case 3:
							if(UsbSetupBuf->wValueL == 0)
							{
								pDescr = LangDes;
								len = sizeof(LangDes);
							}
							else if(UsbSetupBuf->wValueL == 1)
							{
								pDescr = Manuf_Des;
								len = sizeof(Manuf_Des);
							}
							else if(UsbSetupBuf->wValueL == 2)
							{
								pDescr = Prod_Des;
								len = sizeof(Prod_Des);
							}
							else
							{
								pDescr = SerDes;
								len = sizeof(SerDes);
							}
							break;
						default:
							len = 0xff;												//error
							break;
						}
					if ( SetupLen > len )
						{
							SetupLen = len;	//limit length
						}
						len = SetupLen >= DEFAULT_ENDP0_SIZE ? DEFAULT_ENDP0_SIZE : SetupLen;	//take whatever is smaller
						//load data int buffer
						memcpy(Ep0Buffer,pDescr,len);								
						SetupLen -= len;
						pDescr += len;
						break;
					case USB_SET_ADDRESS:
						SetupLen = UsbSetupBuf->wValueL;						
						break;
					case USB_GET_CONFIGURATION:
						Ep0Buffer[0] = UsbConfig;
						if ( SetupLen >= 1 )
						{
							len = 1;
						}
						break;
					case USB_SET_CONFIGURATION:
						UsbConfig = UsbSetupBuf->wValueL;
						break;
					case USB_GET_INTERFACE:
						break;
					case USB_CLEAR_FEATURE:											//Clear Feature
						if( ( UsbSetupBuf->bRequestType & 0x1F ) == USB_REQ_RECIP_DEVICE )				  /* 清除设备 */
						{
							if( ( ( ( uint16_t )UsbSetupBuf->wValueH << 8 ) | UsbSetupBuf->wValueL ) == 0x01 )
							{
								if( CfgDesc[ 7 ] & 0x20 )
								{
									/* 唤醒 */
								}
								else
								{
									len = 0xFF;										
								}
							}
							else
							{
								len = 0xFF;											
							}
						}
						else if ( ( UsbSetupBuf->bRequestType & USB_REQ_RECIP_MASK ) == USB_REQ_RECIP_ENDP )// 端点
						{
							switch( UsbSetupBuf->wIndexL )
							{
							case 0x83:
								UEP3_CTRL = UEP3_CTRL & ~ ( bUEP_T_TOG | MASK_UEP_T_RES ) | UEP_T_RES_NAK;
								break;
							case 0x03:
								UEP3_CTRL = UEP3_CTRL & ~ ( bUEP_R_TOG | MASK_UEP_R_RES ) | UEP_R_RES_ACK;
								break;
							case 0x82:
								UEP2_CTRL = UEP2_CTRL & ~ ( bUEP_T_TOG | MASK_UEP_T_RES ) | UEP_T_RES_NAK;
								break;
							case 0x02:
								UEP2_CTRL = UEP2_CTRL & ~ ( bUEP_R_TOG | MASK_UEP_R_RES ) | UEP_R_RES_ACK;
								break;
							case 0x81:
								UEP1_CTRL = UEP1_CTRL & ~ ( bUEP_T_TOG | MASK_UEP_T_RES ) | UEP_T_RES_NAK;
								break;
							case 0x01:
								UEP1_CTRL = UEP1_CTRL & ~ ( bUEP_R_TOG | MASK_UEP_R_RES ) | UEP_R_RES_ACK;
								break;
							default:
								len = 0xFF;										
								break;
							}
						}
						else
						{
							len = 0xFF;											
						}
						break;
					case USB_SET_FEATURE:										  /* Set Feature */
						if( ( UsbSetupBuf->bRequestType & 0x1F ) == USB_REQ_RECIP_DEVICE )				 
						{
							if( ( ( ( uint16_t )UsbSetupBuf->wValueH << 8 ) | UsbSetupBuf->wValueL ) == 0x01 )
							{
								if( CfgDesc[ 7 ] & 0x20 )
								{
									/* 休眠 */
#ifdef DE_PRINTF
									printf( "suspend\n" );															
#endif
									while ( XBUS_AUX & bUART0_TX )
									{
										;	
									}
									SAFE_MOD = 0x55;
									SAFE_MOD = 0xAA;
									WAKE_CTRL = bWAK_BY_USB | bWAK_RXD0_LO | bWAK_RXD1_LO;					
									PCON |= PD;															
									SAFE_MOD = 0x55;
									SAFE_MOD = 0xAA;
									WAKE_CTRL = 0x00;
								}
								else
								{
									len = 0xFF;									
								}
							}
							else
							{
								len = 0xFF;										
							}
						}
						else if( ( UsbSetupBuf->bRequestType & 0x1F ) == USB_REQ_RECIP_ENDP )			
						{
							if( ( ( ( uint16_t )UsbSetupBuf->wValueH << 8 ) | UsbSetupBuf->wValueL ) == 0x00 )
							{
								switch( ( ( uint16_t )UsbSetupBuf->wIndexH << 8 ) | UsbSetupBuf->wIndexL )
								{
								case 0x83:
									UEP3_CTRL = UEP3_CTRL & (~bUEP_T_TOG) | UEP_T_RES_STALL;
									break;
								case 0x03:
									UEP3_CTRL = UEP3_CTRL & (~bUEP_R_TOG) | UEP_R_RES_STALL;
									break;
								case 0x82:
									UEP2_CTRL = UEP2_CTRL & (~bUEP_T_TOG) | UEP_T_RES_STALL;
									break;
								case 0x02:
									UEP2_CTRL = UEP2_CTRL & (~bUEP_R_TOG) | UEP_R_RES_STALL;
									break;
								case 0x81:
									UEP1_CTRL = UEP1_CTRL & (~bUEP_T_TOG) | UEP_T_RES_STALL;
									break;
								case 0x01:
									UEP1_CTRL = UEP1_CTRL & (~bUEP_R_TOG) | UEP_R_RES_STALL;
								default:
									len = 0xFF;								
									break;
								}
							}
							else
							{
								len = 0xFF;									
							}
						}
						else
						{
							len = 0xFF;										  
						}
						break;
					case USB_GET_STATUS:
						Ep0Buffer[0] = 0x00;
						Ep0Buffer[1] = 0x00;
						if ( SetupLen >= 2 )
						{
							len = 2;
						}
						else
						{
							len = SetupLen;
						}
						break;
					default:
						len = 0xff;									
						break;
					}
				}
			}
			else
			{
				len = 0xff;												
			}
			if(len == 0xff)
			{
				SetupReq = 0xFF;
				UEP0_CTRL = bUEP_R_TOG | bUEP_T_TOG | UEP_R_RES_STALL | UEP_T_RES_STALL;//STALL
			}
			else if(len <= DEFAULT_ENDP0_SIZE)													 
			{
				UEP0_T_LEN = len;
				UEP0_CTRL = bUEP_R_TOG | bUEP_T_TOG | UEP_R_RES_ACK | UEP_T_RES_ACK;
			}
			else
			{
				UEP0_T_LEN = 0;  
				UEP0_CTRL = bUEP_R_TOG | bUEP_T_TOG | UEP_R_RES_ACK | UEP_T_RES_ACK;
			}
			break;
		case UIS_TOKEN_IN | 0:													  //endpoint0 IN
			switch(SetupReq)
			{
			case USB_GET_DESCRIPTOR:
				len = SetupLen >= DEFAULT_ENDP0_SIZE ? DEFAULT_ENDP0_SIZE : SetupLen;								 
				memcpy( Ep0Buffer, pDescr, len );								   
				SetupLen -= len;
				pDescr += len;
				UEP0_T_LEN = len;
				UEP0_CTRL ^= bUEP_T_TOG;											
				break;
			case USB_SET_ADDRESS:
				USB_DEV_AD = USB_DEV_AD & bUDA_GP_BIT | SetupLen;
				UEP0_CTRL = UEP_R_RES_ACK | UEP_T_RES_NAK;
				break;
			default:
				UEP0_T_LEN = 0;													
				UEP0_CTRL = UEP_R_RES_ACK | UEP_T_RES_NAK;
				break;
			}
			break;
		case UIS_TOKEN_OUT | 0:  // endpoint0 OUT
			if(SetupReq == SET_LINE_CODING)  
			{
				if( U_TOG_OK )
				{
					memcpy(LineCoding,UsbSetupBuf,USB_RX_LEN);
					*((uint8_t *)&Baud) = LineCoding[0];
					*((uint8_t *)&Baud+1) = LineCoding[1];
					*((uint8_t *)&Baud+2) = LineCoding[2];
					*((uint8_t *)&Baud+3) = LineCoding[3];
					
					if(Baud > 999999) Baud = 57600;
					
					UEP0_T_LEN = 0;
					UEP0_CTRL |= UEP_R_RES_ACK | UEP_T_RES_ACK;  
				}
			}
			else
			{
				UEP0_T_LEN = 0;
				UEP0_CTRL |= UEP_R_RES_ACK | UEP_T_RES_ACK;  
			}
			break;



		default:
			break;
		}
		UIF_TRANSFER = 0;														  
	}
	if(UIF_BUS_RST)																 
	{
#ifdef DE_PRINTF
		printf( "reset\n" );															
#endif
		UEP0_CTRL = UEP_R_RES_ACK | UEP_T_RES_NAK;
		UEP1_CTRL = bUEP_AUTO_TOG | UEP_T_RES_NAK;
		UEP2_CTRL = bUEP_AUTO_TOG | UEP_T_RES_NAK | UEP_R_RES_ACK;
		USB_DEV_AD = 0x00;
		UIF_SUSPEND = 0;
		UIF_TRANSFER = 0;
		UIF_BUS_RST = 0;													
		Uart_Input_Point = 0;   
		Uart_Output_Point = 0;  
		UartByteCount = 0;	  
		USBByteCount = 0;	
		UsbConfig = 0;		 
		UpPoint2_Busy = 0;
	}
	if (UIF_SUSPEND)																
	{
		UIF_SUSPEND = 0;
		if ( USB_MIS_ST & bUMS_SUSPEND )										
		{
#ifdef DE_PRINTF
			printf( "suspend\n" );														
#endif
			while ( XBUS_AUX & bUART0_TX )
			{
				;	
			}
			SAFE_MOD = 0x55;
			SAFE_MOD = 0xAA;
			WAKE_CTRL = bWAK_BY_USB | bWAK_RXD0_LO | bWAK_RXD1_LO;				
			PCON |= PD;																
			SAFE_MOD = 0x55;
			SAFE_MOD = 0xAA;
			WAKE_CTRL = 0x00;
		}
	}
	else {																		
		USB_INT_FG = 0xFF;															

	}
}

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

void usb_poll(){
	uint8_t length;
	static uint8_t Uart_Timeout = 0;
	if(UsbConfig)
	{
		if(UartByteCount)
			Uart_Timeout++;
		if(!UpPoint2_Busy)  
		{
			length = UartByteCount;
			if(length>0)
			{
				if(length>39 || Uart_Timeout>100)
				{
					Uart_Timeout = 0;
					if(Uart_Output_Point+length>UART_REV_LEN)
						length = UART_REV_LEN-Uart_Output_Point;
					UartByteCount -= length;
					memcpy(Ep2Buffer+MAX_PACKET_SIZE,&Receive_Uart_Buf[Uart_Output_Point],length);
					Uart_Output_Point+=length;
					if(Uart_Output_Point>=UART_REV_LEN)
						Uart_Output_Point = 0;
					UEP2_T_LEN = length;													
					UEP2_CTRL = UEP2_CTRL & ~ MASK_UEP_T_RES | UEP_T_RES_ACK;		
					UpPoint2_Busy = 1;
				}
			}
		}
	}
}

// FPGA Programming State machine

uint8_t state = 0;
uint8_t debug = 0;
uint8_t operation;
uint32_t transactionBytes = 0;

#define PAGEBUFFERLEN 256
uint32_t memAddress = 0x00000000;
uint32_t memIndex = 0;

uint16_t sector_removal_start;
uint16_t sector_removal_end;

void uart_poll(){
	uint8_t uart_data;
	if(USBByteCount) {	
		uart_data = Ep2Buffer[USBBufOutPoint++];

		if(usb_uart_mode == 1){
			if (state == 0 && (uart_data == 'W' || uart_data == 'R')) { // Write command received
				if(debug) printf("State 0. Mode %c. \r\n",uart_data);
				operation = uart_data;
				transactionBytes = 0;
				state = 1;
				// SPIMasterModeSet(0);
				enableLED();
				
				enablePreFlash();
				mDelaymS(20); // Prevent FPGA for a reset
				disablePreFlash();

				enableFPGAReset();
				MEM_releasePowerDown();
			}else if (state == 0 && uart_data == 'd') {
				debug = !debug;
				if(debug) printf("Debug enabled\r\n");
			}else if (state == 0 && uart_data == 'D') {
				disableFPGAReset();
			}else if (state == 0 && uart_data == 'Z') {
				enableLED();
				enableFPGAReset();
				MEM_releasePowerDown();
				MEM_chipErase();
				disableFPGAReset();
				disableLED();
			}else if (state == 0 && uart_data == 'A') {
				triestateFlashSS();
				triestateSPI();
				enableFPGAReset();
				mDelaymS(5);
				triestateFPGAReset();
			}else if (state == 0 && uart_data == 'B') {
				jump_to_bootloader();
			}else if (state == 0 && uart_data == 'V') {
				printf("RocketFPGA Bootloader V0.5.0\n");
			}
			// Memory offset operations state machine
			else if (state == 0 && uart_data == 'M') {
				if(debug) printf("State 0. Mode %c. \r\n",uart_data);
				operation = uart_data;
				memAddress = 0x00000000;
				state = 1;
			}else if (operation == 'M' && (state == 1 || state == 2 || state == 3 || state == 4)){
				if(debug) printf("Transaction Byte State %u, data: 0x%02X \r\n",state,uart_data);
				memAddress = memAddress | (((uint32_t) uart_data) << ((state-1)*8));
				state++;
				if(state == 5){
					state = 0;
				}
			}
			// Sectors removal state machine
			else if (state == 0 && uart_data == 'S') {
				operation = uart_data;
				sector_removal_start = 0x0000;
				sector_removal_end = 0x0000;
				state = 1;
			}else if (operation == 'S') {
				if (state == 1 || state == 2){
					sector_removal_start = sector_removal_start | (((uint16_t) uart_data) << ((state-1)*8));
				}else if (state == 3 || state == 4){
					sector_removal_end = sector_removal_end | (((uint16_t) uart_data) << ((state-3)*8));
				}

				state++;

				if (state == 5){
					uint16_t i;

					enableLED();
					enableFPGAReset();
					MEM_releasePowerDown();

					for (i = sector_removal_start; i < sector_removal_end; i++){
						MEM_chipErase4KSector(i);
					}

					disableFPGAReset();
					disableLED();
					state = 0;
				}
			}
			// Read / Write operations state machine
			else if ((operation == 'W' || operation == 'R') && (state == 1 || state == 2 || state == 3)){
				if(debug) printf("Transaction Byte State %u, data: 0x%02X \r\n",state,uart_data);
				transactionBytes = transactionBytes | (((uint32_t) uart_data) << ((state-1)*8));
				state++;
			}else if ((operation == 'W' || operation == 'R') && state == 4){
				if(debug) printf("Transaction Byte State %u, data: 0x%02X \r\n", state, uart_data);
				transactionBytes = transactionBytes | (uart_data << 24);
				if(debug) printf("Transaction Byte END, data: %lu \r\n",memAddress + transactionBytes);

				if (operation == 'W') {
					if(debug) printf("Preparing memory to write at 0x%08X \r\n", memAddress);

					if(debug) printf("Erasing device sectors from\r\n");

					// MEM_chipEraseNBlocks(	(uint8_t) (((float)memAddress)/65536.0) , 
					// 						(uint8_t) (((float)(transactionBytes))/65536.0) + 1
					// 					);

					enableFlashSS();
					MEM_writeEnable();
					disableFlashSS();

					memIndex = memAddress;
					enableFlashSS();
					MEM_startWrite(memIndex);


					state = 5;
				}else if (operation == 'R'){
					if(debug) printf("Preparing memory to read\r\n");
					enableFlashSS();
					MEM_startRead(memAddress);

					while(transactionBytes > 0){
						uint8_t data = MEM_read();
						virtual_uart_tx(data);
						usb_poll();
						// mDelayuS(80);
						transactionBytes--;
					}

					if(debug) printf("Reading done, returning to state 0\r\n");
					disableFlashSS();
					disableLED();
					state = 0;
				}
			}else if ((operation == 'W' || operation == 'R') && state == 5){
				MEM_write(uart_data);
				memIndex++;
				transactionBytes--;


				if (memIndex % 256 == 0) {

					disableFlashSS();
					MEM_waitWriteCycle();

					enableFlashSS();
					MEM_writeEnable();
					disableFlashSS();

					enableFlashSS();
					MEM_startWrite(memIndex);
				}
				
				// virtual_uart_tx(0x01);

				if (transactionBytes == 0) {
					if(debug) printf("Write done!\r\n");
					disableFlashSS();
					MEM_waitWriteCycle();
					disableLED();
					state = 0;
				}
			}
		}else{
			CH554UART0SendByte(uart_data);
		}


		USBByteCount--;
		if(USBByteCount==0) UEP2_CTRL = UEP2_CTRL & ~ MASK_UEP_R_RES | UEP_R_RES_ACK;
	}
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
	UEP0_T_LEN = 0;
	UEP1_T_LEN = 0;													
	UEP2_T_LEN = 0;	
	SPIMasterModeSet(0);
	disableLED();
	
	while(1){
		usb_poll();
		uart_poll();

		if(RI != 0){ // Check data on USB to UART brigde
			RI = 0;
			if(usb_uart_mode == 0){
				virtual_uart_tx(SBUF);
			}
		}		
	}
}
