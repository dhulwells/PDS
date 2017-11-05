# --------------------------------------------------------------
#      Author: Samuel Cuthbertson
#  Assignment: homework4
#        Date: <fill in the date you complete your code>
#      System: DE10-Lite PDS Computer
# Description: <write a short description of what your code does>
# --------------------------------------------------------------

# --------------------------------------------------------------------------------------
# This template is for developing code that implements interrupt driven IO.
# --------------------------------------------------------------------------------------


		# ---------------------------------------------------------
		# RESET SECTION
		# ---------------------------------------------------------
        # The Monitor Program places the ".reset" section at the reset location
        # specified in the CPU settings in Qsys.
        # Note: "ax" is REQUIRED to designate the section as allocatable and executable.

    # A real reset handler would fully initialize the CPU and then jump to start.
		# CPU's reset vector = 0x0000_0000
        .section    .reset, "ax"

reset:
        movia       r2, _start
        jmp         r2


		# ---------------------------------------------------------
		# EXCEPTION SECTION
		# ---------------------------------------------------------
        # The Monitor Program places the ".exceptions" section at the
        # exception location specified in the CPU settings in Qsys.
        # Note: "ax" is REQUIRED to designate the section as allocatable and executable.

		# CPU's exception vector = 0x0000_0020
        .section    .exceptions, "ax"

exception_handler:
		jmpi 		interrupt_service_routine





		# ---------------------------------------------------------
		# TEXT SECTION
		# ---------------------------------------------------------
		.text

		.include 	"address_map_nios2.s"

		.global 	_start

_start:

		# Nios II register usage convention
		#      r1     : assembler temporary, don't use this!
		#   r2-r3     : output from subroutine
		#   r4-r7     : input to subroutine
		#   r8  - r15 : Caller saved.
		#   r16 - r23 : Callee saved.
		#   r24 - r31 : Reserved/special function registers, stack pointer
		#               return address etc., don't use these as general
		#               purpose registers in the code you write!

# --------------------------------------------------------------
# Initialization code
# --------------------------------------------------------------
		# IMPORTANT: Set up the stack frame.
		# This is required if you will be calling subroutines/functions
		movia 	sp, SDRAM_CTRL_END
		movia 	fp, SDRAM_CTRL_END

		# main program initialization steps
    movia		r8, LED_OUT_BASE
    movia 	r11, 0b0000000001 # Initial led pattern
    mov		  r12, r0 # Initial move direction


# --------------------------------------------------------------
# Insert your ISR initialization code here
# --------------------------------------------------------------

		# ---------------------------------------------------
        # Configure devices to generate interrupts
		# ---------------------------------------------------

    # enable pushbutton 0 to create an IRQ to the CPU
    # Only button 0 will generate an interrupt, not button 1
    movia       r15, TIMER_BASE
    ldw         r7, time_delay # 1 second
    stwio       r7, (r15)

		# ---------------------------------------------------
		# Configure CPU to take external hardware interrupts
		# ---------------------------------------------------






# --------------------------------------------------------------
# main program
# --------------------------------------------------------------
loop:
		# Write our current pattern to the LEDs
		stwio		r11, (r8)

		# Wait, use a simple count down
		movia		r10, DELAY_VALUE

delay_loop1:
		subi		r10, r10, 1 # Decrement counter
		bne			r10, r0, delay_loop1 # Repeat if we're still waiting

		# Change pattern
		br      slide

slide:
		bne     r0, r12, slide_down # Are we in the down mode?

		movia		r13, 0b1000000000 # Max led pattern

		beq     r13, r11, slide_down # Should we now be in the down mode?

		slli    r11, r11, 0b1 # Shift left one LED

		br      loop

slide_down:
		movia   r12, 0b1 # Set the mode

		srli    r11, r11, 0b1 # Shift right one LED

		bne     r14, r11, loop # If we should still be going right, repeat

		movia   r12, 0b0 # Else, set the mode

    br      loop

# --------------------------------------------------------------
# End of main program
# --------------------------------------------------------------





# ---------------------------------------------------------
# Exception Handler / Interrupt Service Routine
# ---------------------------------------------------------
interrupt_service_routine:

		# Adjust the size of the stack frame as needed by your code
		.equ		ISR_STACKSIZE,	5*4 		# 5 32-bit words

        # make a stack frame
        subi        sp, sp, ISR_STACKSIZE

        # ---------------------------------
        # save the registers we use in here
        # ---------------------------------
        stw         et,  0(sp)

        # check for internal vs. external IRQ
        # decrement ea for external IRQ
        rdctl       et, ipending    # get all 32 bits that represent irq31 to irq0
        beq         et, r0, skip_ea_dec

        subi        ea, ea, 4       # must decrement ea by one instruction
                                    # for external interrupts, so that the
                                    # interrupted instruction will be run after eret
skip_ea_dec:
        stw         ea,  4(sp)		# save the exception address
        stw         ra,  8(sp)		# save the current subrountine's ra
        stw         rx,  12(sp)		# save the registers we use in this routine
        stw         rxx,  16(sp)
		# etc.


		# bail if IRQ is not external hardware interrupt
        beq         et, r0, end_isr     # interrupt is not external IRQ





        # -----------------------------------
        # do our stuff, service the interrupt
        # -----------------------------------

		# Determine source of the interrupt

		# Service the interrupting device

		# Clear the source of the interrupt




end_isr:
        # restore registers we used
        ldw         et,  0(sp)
        ldw         ea,  4(sp)
        ldw         ra,  8(sp)
        ldw         rx,  12(sp)
        ldw         rxx, 16(sp)



        # free the stack frame
        addi        sp, sp, ISR_STACKSIZE


		eret		# return from exception




















		# ---------------------------------------------------------
		# DATA SECTION
		# ---------------------------------------------------------
		.data

              .align  2	# align to 2^2=4 byte boundary

time_delay:   .word   40000000






		.end		# end of assembly.
