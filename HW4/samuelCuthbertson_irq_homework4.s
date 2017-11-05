# This is a bank template to use for your homework assignments

# --------------------------------------------------------------
#      Author: <fill in your name>
#  Assignment: homeworkN  <change N to the appropriate value>
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
    .equ		DELAY_VALUE, 200000
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
		# enable timer to create an IRQ to the CPU
    movia       r15, TIMER_BASE
		movia 			r7, time_delay
		ldw         r6, (r7)
    stwio       r6, 0x20(r15) # Set the period 1 reg
    movia       r6, 0b111
    stwio       r6, (r15) # Set the status to 1
    stwio       r6, 0x10(r15) # Set the ITO, CONT, and START to 1

		# ---------------------------------------------------
		# Configure CPU to take external hardware interrupts
		# ---------------------------------------------------

		# Enable input on irq[1]
		movia				r7, IRQ_TIMER_MASK
		wrctl				ienable, r7

		# Set status[PIE] to enable the CPU
		movi				r7, 0b0001
		wrctl				status, r7




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

		movia		r13, 0b1 # Min led pattern

		bne     r13, r11, loop # If we should still be going right, repeat

		movia   r12, 0b0 # Else, set the mode

    br      loop


		# ------------------------------------------------------------
		# print ()
		# Takes as argument string pointed to by r4, prints to UART.
		#
print:
		ldwio		r18, 4(r16)         # Is there space available in the TX FIFO?
		andhi   r18, r18, 0xFFFF    # Only look at the upper 16-bits.
		beq			r18, r0, print 		  # No space, wait for space to become available.

		# OK, there is space in the TX FIFO, send the character to the host
		ldb			r19, (r4)							# Load our character to be sent
		beq 		r0, r19, _print_ret		# If null, return. End of string
		stbio		r19, (r16)						# Else, send character

		# Iterate
		addi		r4, r4, 0x1
		br			print

_print_ret:
		ret

# --------------------------------------------------------------
# End of main program
# --------------------------------------------------------------





# ---------------------------------------------------------
# Exception Handler / Interrupt Service Routine
# ---------------------------------------------------------
interrupt_service_routine:

		# Adjust the size of the stack frame as needed by your code
		.equ		ISR_STACKSIZE,	6*4 		# 5 32-bit words

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
        stw         r11,  12(sp)		# save the registers we use in this routine
        stw         r12,  16(sp)
        stw         r8,  20(sp)

		# bail if IRQ is not external hardware interrupt
        beq         et, r0, end_isr     # interrupt is not external IRQ

		# Determine source of the interrupt

				movia		r4, counter_str   # Call print on our string
				call 		print

		# Service the interrupting device

		# Clear the source of the interrupt
        movia       r15, TIMER_BASE
        movia       r6, 0b0
        stwio       r6, (r15)


end_isr:
        # restore registers we used
        ldw         et,  0(sp)
        ldw         ea,  4(sp)
        ldw         ra,  8(sp)
        ldw         r11,  12(sp)
        ldw         r12, 16(sp)
				ldw					r8, 20(sp)



        # free the stack frame
        addi        sp, sp, ISR_STACKSIZE


		eret		# return from exception




















		# ---------------------------------------------------------
		# DATA SECTION
		# ---------------------------------------------------------
		.data

        				.align 		2	# align to 2^2=4 byte boundary
time_delay:  		.word   	40
counter_str:		.asciz		"The counter has rolled over\n"




		.end		# end of assembly.
