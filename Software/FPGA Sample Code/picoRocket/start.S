#include "custom_ops.S"

.section .data
irq_regs:
	// registers are saved to this memory region during interrupt handling
	// the program counter is saved as register 0
	.fill 32,4

	// stack for the interrupt handler
	.fill 128,4
irq_stack:


.section .text
reset_vec:
	// no more than 16 bytes here !
	# picorv32_waitirq_insn(zero)
	# picorv32_maskirq_insn(zero, zero)
	j start

/* Interrupt handler
 **********************************/

.balign 16
irq_vec:

	sw gp,   0*4(zero)
	sw x1,   1*4(zero)
	sw x2,   2*4(zero)
	sw x5,   5*4(zero)
	sw x6,   6*4(zero)
	sw x7,   7*4(zero)
	sw x10, 10*4(zero)
	sw x11, 11*4(zero)
	sw x12, 12*4(zero)
	sw x13, 13*4(zero)
	sw x14, 14*4(zero)
	sw x15, 15*4(zero)
	sw x16, 16*4(zero)
	sw x17, 17*4(zero)
	sw x28, 28*4(zero)
	sw x29, 29*4(zero)
	sw x30, 30*4(zero)
	sw x31, 31*4(zero)

	/* call interrupt handler C function */

	lui sp, %hi(irq_stack)
	addi sp, sp, %lo(irq_stack)

	// arg0 = address of regs
	lui a0, %hi(irq_regs)
	addi a0, a0, %lo(irq_regs)

	// arg1 = interrupt type
	addi a1, tp, 0

	// call to C function
	jal ra, irq

	/* restore registers */

	// new irq_regs address returned from C code in a0
	addi a1, zero, 0x000
	beq a0, a1, 1f
	ebreak
1:

	lw gp,   0*4(zero)
	lw x1,   1*4(zero)
	lw x2,   2*4(zero)
	lw x5,   5*4(zero)
	lw x6,   6*4(zero)
	lw x7,   7*4(zero)
	lw x10, 10*4(zero)
	lw x11, 11*4(zero)
	lw x12, 12*4(zero)
	lw x13, 13*4(zero)
	lw x14, 14*4(zero)
	lw x15, 15*4(zero)
	lw x16, 16*4(zero)
	lw x17, 17*4(zero)
	lw x28, 28*4(zero)
	lw x29, 29*4(zero)
	lw x30, 30*4(zero)
	lw x31, 31*4(zero)

	picorv32_retirq_insn()

/* Main program
 **********************************/
 start:
    # zero-initialize register file
    addi x1, zero, 0
    # x2 (sp) is initialized by reset
    addi x3, zero, 0
    addi x4, zero, 0
    addi x5, zero, 0
    addi x6, zero, 0
    addi x7, zero, 0
    addi x8, zero, 0
    addi x9, zero, 0
    addi x10, zero, 0
    addi x11, zero, 0
    addi x12, zero, 0
    addi x13, zero, 0
    addi x14, zero, 0
    addi x15, zero, 0
    addi x16, zero, 0
    addi x17, zero, 0
    addi x18, zero, 0
    addi x19, zero, 0
    addi x20, zero, 0
    addi x21, zero, 0
    addi x22, zero, 0
    addi x23, zero, 0
    addi x24, zero, 0
    addi x25, zero, 0
    addi x26, zero, 0
    addi x27, zero, 0
    addi x28, zero, 0
    addi x29, zero, 0
    addi x30, zero, 0
    addi x31, zero, 0

    # zero initialize entire scratchpad memory
    li a0, 0x00000000
    setmemloop:
    sw a0, 0(a0)
    addi a0, a0, 4
    blt a0, sp, setmemloop

    # copy data section
    la a0, _sidata
    la a1, _sdata
    la a2, _edata
    bge a1, a2, end_init_data
    loop_init_data:
    lw a3, 0(a0)
    sw a3, 0(a1)
    addi a0, a0, 4
    addi a1, a1, 4
    blt a1, a2, loop_init_data
    end_init_data:

    # zero-init bss section
    la a0, _sbss
    la a1, _ebss
    bge a0, a1, end_init_bss
    loop_init_bss:
    sw zero, 0(a0)
    addi a0, a0, 4
    blt a0, a1, loop_init_bss
    end_init_bss:

    # call main
    call main
    loop:
    j loop

.balign 4
