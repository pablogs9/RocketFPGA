/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
// #include <stdio.h>

#define MEM_TOTAL 0x10000 /* 64 KB */

// a pointer to this is a null pointer, but the compiler does not
// know that because "sram" is a linker symbol from sections.lds.
extern uint32_t sram;

#define reg_spictrl (*(volatile uint32_t*)0x02000000)
#define reg_uart_clkdiv (*(volatile uint32_t*)0x02000004)
#define reg_uart_data (*(volatile uint32_t*)0x02000008)
#define reg_led (*(volatile uint32_t*)0x03000000)
#define osc_1 (*(volatile uint32_t*)0x04000000)


void putchar(char c)
{
	if (c == '\n')
		putchar('\r');
	reg_uart_data = c;
}

void print(const char *p)
{
	while (*p)
		putchar(*(p++));
}


uint32_t counter_frequency = 12000000;  /* 50 times per second */

// IRQ Handling

uint32_t set_irq_mask(uint32_t mask); asm (
    ".global set_irq_mask\n"
    "set_irq_mask:\n"
    ".word 0x0605650b\n"
    "ret\n"
);

uint32_t set_timer_counter(uint32_t val); asm (
    ".global set_timer_counter\n"
    "set_timer_counter:\n"
    ".word 0x0a05650b\n"
    "ret\n"
);

uint32_t *irq(uint32_t *regs, uint32_t irqs){
	/* fast IRQ (4) */
	// if ((irqs & (1<<4)) != 0) {
	// 	print("[EXT-IRQ-4]");
	// }

	/* slow IRQ (5) */
	if ((irqs & (1<<5)) != 0) {
		print("[EXT-IRQ-5]\n");
	}

	/* timer IRQ */
	if ((irqs & 1) != 0) {
		// retrigger timer
		set_timer_counter(counter_frequency);
		print("[IRQ_TIMER]\n");
	}
	return regs;
}
// --------------------------------------------------------


void print_hex(uint32_t v, int digits)
{
	for (int i = 7; i >= 0; i--) {
		char c = "0123456789abcdef"[(v >> (4*i)) & 15];
		if (c == '0' && i >= digits) continue;
		putchar(c);
		digits = i;
	}
}

void print_dec(uint32_t v)
{
	if (v >= 1000) {
		print(">=1000");
		return;
	}

	if      (v >= 900) { putchar('9'); v -= 900; }
	else if (v >= 800) { putchar('8'); v -= 800; }
	else if (v >= 700) { putchar('7'); v -= 700; }
	else if (v >= 600) { putchar('6'); v -= 600; }
	else if (v >= 500) { putchar('5'); v -= 500; }
	else if (v >= 400) { putchar('4'); v -= 400; }
	else if (v >= 300) { putchar('3'); v -= 300; }
	else if (v >= 200) { putchar('2'); v -= 200; }
	else if (v >= 100) { putchar('1'); v -= 100; }

	if      (v >= 90) { putchar('9'); v -= 90; }
	else if (v >= 80) { putchar('8'); v -= 80; }
	else if (v >= 70) { putchar('7'); v -= 70; }
	else if (v >= 60) { putchar('6'); v -= 60; }
	else if (v >= 50) { putchar('5'); v -= 50; }
	else if (v >= 40) { putchar('4'); v -= 40; }
	else if (v >= 30) { putchar('3'); v -= 30; }
	else if (v >= 20) { putchar('2'); v -= 20; }
	else if (v >= 10) { putchar('1'); v -= 10; }

	if      (v >= 9) { putchar('9'); v -= 9; }
	else if (v >= 8) { putchar('8'); v -= 8; }
	else if (v >= 7) { putchar('7'); v -= 7; }
	else if (v >= 6) { putchar('6'); v -= 6; }
	else if (v >= 5) { putchar('5'); v -= 5; }
	else if (v >= 4) { putchar('4'); v -= 4; }
	else if (v >= 3) { putchar('3'); v -= 3; }
	else if (v >= 2) { putchar('2'); v -= 2; }
	else if (v >= 1) { putchar('1'); v -= 1; }
	else putchar('0');
}

char getchar_prompt(char *prompt)
{
	int32_t c = -1;

	uint32_t cycles_begin, cycles_now, cycles;
	__asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));

	reg_led = ~0;

	if (prompt)
		print(prompt);

	while (c == -1) {
		__asm__ volatile ("rdcycle %0" : "=r"(cycles_now));
		cycles = cycles_now - cycles_begin;
		if (cycles > 12000000) {
			if (prompt)
				print(prompt);
			cycles_begin = cycles_now;
			reg_led = ~reg_led;
		}
		c = reg_uart_data;
	}

	reg_led = 0;
	return c;
}

char getchar()
{
	return getchar_prompt(0);
}

uint32_t xorshift32(uint32_t *state)
{
	/* Algorithm "xor" from p. 4 of Marsaglia, "Xorshift RNGs" */
	uint32_t x = *state;
	x ^= x << 13;
	x ^= x >> 17;
	x ^= x << 5;
	*state = x;

	return x;
}

void cmd_memtest()
{
	int cyc_count = 5;
	int stride = 256;
	uint32_t state;

	volatile uint32_t *base_word = (uint32_t *) 0;
	volatile uint8_t *base_byte = (uint8_t *) 0;

	print("Running memtest ");

	// Walk in stride increments, word access
	for (int i = 1; i <= cyc_count; i++) {
		state = i;

		for (int word = 0; word < MEM_TOTAL / sizeof(int); word += stride) {
			*(base_word + word) = xorshift32(&state);
		}

		state = i;

		for (int word = 0; word < MEM_TOTAL / sizeof(int); word += stride) {
			if (*(base_word + word) != xorshift32(&state)) {
				print(" ***FAILED WORD*** at ");
				print_hex(4*word, 4);
				print("\n");
				return;
			}
		}

		print(".");
	}

	// Byte access
	for (int byte = 0; byte < 128; byte++) {
		*(base_byte + byte) = (uint8_t) byte;
	}

	for (int byte = 0; byte < 128; byte++) {
		if (*(base_byte + byte) != (uint8_t) byte) {
			print(" ***FAILED BYTE*** at ");
			print_hex(byte, 4);
			print("\n");
			return;
		}
	}

	print(" passed\n");
}

void cmd_echo()
{
	print("Return to menu by sending '!'\n\n");
	char c;
	while ((c = getchar()) != '!')
		putchar(c);
}

// int32_t power(int32_t x, int32_t y){
// 	int32_t r = 1;
// 	for (size_t i = 0; i < y; i++)
// 		r = r*x;	
// 	return r;
// }

// int32_t read_number(){
// 	char c;
// 	int32_t index = 0;
// 	int32_t result = 0;
// 	while ((c = getchar()) != '\n'){
// 		if (c >= 48 && c <= 57){
// 			result += (c-48) * power(10, index++);
// 			putchar(c);
// 		}
// 	}
// 	print_dec(result);
// 	return result;
// }

// --------------------------------------------------------

void main()
{
	reg_uart_clkdiv = 104;
	print("Booting..\n");

	// Set SPI dual mode
	reg_spictrl = (reg_spictrl & ~0x007f0000) | 0x00400000;

	print("Enabling IRQs..\n");
    set_irq_mask(0x00);

	while (getchar_prompt("Press ENTER to continue..\n") != '\n') { /* wait */ }

	print("\n");
	print("  _____            _        _   ______ _____   _____          \n");
	print(" |  __ \\          | |      | | |  ____|  __ \\ / ____|   /\\    \n");
	print(" | |__) |___   ___| | _____| |_| |__  | |__) | |  __   /  \\   \n");
	print(" |  _  // _ \\ / __| |/ / _ \\ __|  __| |  ___/| | |_ | / /\\ \\  \n");
	print(" | | \\ \\ (_) | (__|   <  __/ |_| |    | |    | |__| |/ ____ \\ \n");
	print(" |_|  \\_\\___/ \\___|_|\\_\\___|\\__|_|    |_|     \\_____/_/    \\_\\\n");
	print("\n");
	print(" The Hardcore Audio Processor\n");
	print("\n");

	print("Total memory: ");
	print_dec(MEM_TOTAL / 1024);
	print(" KiB\n");
	print("\n");

	cmd_memtest();
	print("\n");


	osc_1 = 0;

	while (1)
	{
		print("\n");

		print("Select an action:\n");
		print("\n");
		print("   [1] Read SPI Flash ID\n");
		print("   [2] Read SPI Config Regs\n");
		print("   [3] Switch to default mode\n");
		print("   [4] Switch to Dual I/O mode\n");
		print("   [5] Switch to Quad I/O mode\n");
		print("   [6] Switch to Quad DDR mode\n");
		print("   [7] Toggle continuous read mode\n");
		print("   [9] Run simplistic benchmark\n");
		print("   [0] Benchmark all configs\n");
		print("   [M] Run Memtest\n");
		print("   [S] Print SPI state\n");
		print("   [e] Echo UART\n");
		print("   [f] Set OSC_1 frequency\n");
		print("\n");

		for (int rep = 10; rep > 0; rep--)
		{
			print("Command> ");
			char cmd = getchar();
			if (cmd > 32 && cmd < 127)
				putchar(cmd);
			print("\n");

			switch (cmd)
			{
			case 'M':
				cmd_memtest();
				break;
			case 'e':
				cmd_echo();
				break;
			case 'f':
				osc_1 = osc_1 + 4473900;
				break;
			case 'v':
				osc_1 = osc_1 - 4473900;
				break;
			case 'g':
				osc_1 = osc_1 * (double)0.457;
				break;
			case 'b':
				osc_1 = osc_1 / 1.34;
				break;
			default:
				continue;
			}

			break;
		}
	}
}
