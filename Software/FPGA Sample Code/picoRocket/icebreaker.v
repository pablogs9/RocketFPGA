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

`ifdef PICOSOC_V
`error "icebreaker.v must be read before picosoc.v!"
`endif

module icebreaker (
    //49.152MHz MHz clock
    input OSC,

    //CODEC SPI Interface
    // output wire CODEC_SCLK,
    // output wire CODEC_MOSI,
    output wire CODEC_CS,

    //I2S Interface
    output wire MCLK,
    input wire BCLK,
    input wire ADCLRC,
    input wire DACLRC,
    input wire ADCDAT,
    output wire DACDAT,

    output wire LED,
    input wire USER_BUTTON,

    // input wire PRE_RESET,
    input wire TXD,
    input wire RXD,

    // output wire CAPACITOR,
    output wire POT_1,
    output wire POT_2,
    input wire DIFF_IN,

	output TXD,
	input RXD,

	output flash_csb,
	output flash_clk,
	inout  flash_io0,
	inout  flash_io1,
	inout  flash_io2,
	inout  flash_io3
);
	parameter integer MEM_WORDS = 16384;  //(16384 words x 32 bits/word / 1024 B/b = 64 KB)

	// Generating 12 MHz for RISCV
	wire clk;
	SB_HFOSC #(
	.CLKHF_DIV ("0b10"),
	) OSC12MHZ (
		.CLKHFEN(1'b1),
		.CLKHFPU(1'b1),
		.CLKHF(clk)
	);

	reg [5:0] reset_cnt = 0;
	wire resetn = &reset_cnt & codec_conf_done;

	always @(posedge clk) begin
		reset_cnt <= reset_cnt + !resetn;
	end

	wire flash_io0_oe, flash_io0_do, flash_io0_di;
	wire flash_io1_oe, flash_io1_do, flash_io1_di;
	wire flash_io2_oe, flash_io2_do, flash_io2_di;
	wire flash_io3_oe, flash_io3_do, flash_io3_di;

	SB_IO #(
		.PIN_TYPE(6'b 1010_01),
		.PULLUP(1'b 0)
	) flash_io_buf [3:0] (
		.PACKAGE_PIN({flash_io3, flash_io2, flash_io1, flash_io0}),
		.OUTPUT_ENABLE({flash_io3_oe, flash_io2_oe, flash_io1_oe, flash_io0_oe}),
		.D_OUT_0({flash_io3_do, flash_io2_do, flash_io1_do, flash_io0_do}),
		.D_IN_0({flash_io3_di, flash_io2_di, flash_io1_di, flash_io0_di})
	);

	wire        iomem_valid;
	reg         iomem_ready;
	wire [3:0]  iomem_wstrb;
	wire [31:0] iomem_addr;
	wire [31:0] iomem_wdata;
	reg  [31:0] iomem_rdata;

	reg [31:0] gpio;
	assign LED = !gpio[0];

	always @(posedge clk) begin
		if (!resetn) begin
			gpio <= 0;
		end else begin
			iomem_ready <= 0;
			if (iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h 03) begin
				iomem_ready <= 1;
				iomem_rdata <= gpio;
				if (iomem_wstrb[0]) gpio[ 7: 0] <= iomem_wdata[ 7: 0];
				if (iomem_wstrb[1]) gpio[15: 8] <= iomem_wdata[15: 8];
				if (iomem_wstrb[2]) gpio[23:16] <= iomem_wdata[23:16];
				if (iomem_wstrb[3]) gpio[31:24] <= iomem_wdata[31:24];
			end
			if (iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h 04) begin
				iomem_ready <= 1;
				iomem_rdata <= freq;
				if (iomem_wstrb[0]) freq[ 7: 0] <= iomem_wdata[ 7: 0];
				if (iomem_wstrb[1]) freq[15: 8] <= iomem_wdata[15: 8];
				if (iomem_wstrb[2]) freq[23:16] <= iomem_wdata[23:16];
				if (iomem_wstrb[3]) freq[31:24] <= iomem_wdata[31:24];
			end
		end
	end

	picosoc #(
		.MEM_WORDS(MEM_WORDS),
	) soc (
		.clk          (clk         ),
		.resetn       (resetn      ),

		.ser_tx       (TXD      ),
		.ser_rx       (RXD      ),

		.flash_csb    (flash_csb   ),
		.flash_clk    (flash_clk_rv),

		.flash_io0_oe (flash_io0_oe),
		.flash_io1_oe (flash_io1_oe),
		.flash_io2_oe (flash_io2_oe),
		.flash_io3_oe (flash_io3_oe),

		.flash_io0_do (flash_io0_do_rv),
		.flash_io1_do (flash_io1_do),
		.flash_io2_do (flash_io2_do),
		.flash_io3_do (flash_io3_do),

		.flash_io0_di (flash_io0_di),
		.flash_io1_di (flash_io1_di),
		.flash_io2_di (flash_io2_di),
		.flash_io3_di (flash_io3_di),

		.irq_5        (sample_irq),
		.irq_6        (1'b0        ),
		.irq_7        (1'b0        ),

		.iomem_valid  (iomem_valid ),
		.iomem_ready  (iomem_ready ),
		.iomem_wstrb  (iomem_wstrb ),
		.iomem_addr   (iomem_addr  ),
		.iomem_wdata  (iomem_wdata ),
		.iomem_rdata  (iomem_rdata )
	);

	// DANGER ZONE
	wire flash_clk_rv, flash_clk_codec;
	wire flash_io0_do_rv, flash_io0_do_codec;
	assign flash_clk = (codec_conf_done) ? flash_clk_rv : flash_clk_codec;
	assign flash_io0_do = (codec_conf_done) ? flash_io0_do_rv : flash_io0_do_codec;
	wire codec_conf_done;

	reg old_DACLRC;
	wire sample_irq = DACLRC & !old_DACLRC;
	always @(posedge clk) begin
		old_DACLRC <= DACLRC;
	end

	// Audio path

	localparam BITSIZE = 16;
	localparam SAMPLING = 96;

	// Clocking and reset
	reg [26:0] divider;
	always @(posedge OSC) begin
		divider <= divider + 1;
	end

	assign MCLK = divider[1]; // 12.288 MHz

	configurator #(
		.BITSIZE(BITSIZE),
		.SAMPLING(SAMPLING),
	)conf (
		.clk(divider[6]),
		.spi_mosi(flash_io0_do_codec), 
		.spi_sck(flash_clk_codec),
		.cs(CODEC_CS),
		.prereset(1'b1),
		.done(codec_conf_done)
	);

	// Path
	wire [BITSIZE-1:0] out;
	localparam PHASE_SIZE = 32;
	`define CALCULATE_PHASE_FROM_FREQ(f) $rtoi(f * $pow(2,PHASE_SIZE) / (SAMPLING * 1000.0))

	reg [PHASE_SIZE-1:0] freq = 0;

	sinegenerator #(
		.BITSIZE(BITSIZE),
		.PHASESIZE(PHASE_SIZE),
		.TABLESIZE(12),
	) S1 (
		.enable(1'b1),
		.lrclk(DACLRC),
		.out(out),
		.freq(freq),
	);

	i2s_tx #( 
		.BITSIZE(BITSIZE),
	) I2STX (
		.sclk (BCLK), 
		.lrclk (DACLRC),
		.sdata (DACDAT),
		.left_chan (out),
		.right_chan (out)
	);


endmodule
