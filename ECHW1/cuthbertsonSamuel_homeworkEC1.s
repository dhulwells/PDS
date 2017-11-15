# --------------------------------------------------------------
#      Author: Samuel Cuthbertson
#  Assignment: ECHW1
#        Date: 11/5/2017
#      System: DE10-Lite PDS Computer
# Description: Displays a number of LEDs proportional to
#               accelerometer readings, using interrupts.
# Attribution: Some pieces copied verbatim from class examples.
# --------------------------------------------------------------

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


# --------------------------------------------------------------
# Insert your ISR initialization code here
# --------------------------------------------------------------

		# ---------------------------------------------------
        # Configure devices to generate interrupts
		# ---------------------------------------------------
		# enable accelerometer to create an IRQ to the CPU

    movia 			r5, 0x20 # Set activity threshold to 32 (2g)
    movia       r4, 0x24 # Write this to the INT_ENABLE reg
    call        accel_write

		# movia 			r5, 0b00010000 # Enable interrupts from activity
		movia 			r5, 0b00000000 # Enable interrupts from activity
   	movia       r4, 0x2E # Write this to the INT_ENABLE reg
    call        accel_write

		# ---------------------------------------------------
		# Configure CPU to take external hardware interrupts
		# ---------------------------------------------------

		# Enable input on irq[3]
		movia				r7, IRQ_ACCEL_MASK
		wrctl				ienable, r7

		# Set status[PIE] to enable the CPU
		movi				r7, 0b0001
		wrctl				status, r7

		/* ----------------------------------------------------------
		 * Finish initialization
		---------------------------------------------------------- */
		# Get initial gravity value
    movia       r4, ADXL345_DATAZH
    call        accel_read

    mov         r15, r2
    slli        r15, r15, 27       # Shift high bits into place

    movia       r4, ADXL345_DATAZL
    call        accel_read

		slli 				r2, r2, 19
    add         r15, r2, r15       # Read low bits

		srai 				r15, r15, 19			 # Sign extend, initial Z is now in r15

# --------------------------------------------------------------
# main program
# --------------------------------------------------------------
loop:
    # Do nothing
    br      loop

# --------------------------------------------------------------
# End of main program
# --------------------------------------------------------------

# --------------------------------------------------------------
# accel_write ()
# Takes as argument register number in r4, writes value from r5.
# --------------------------------------------------------------
accel_write:
        movia       r16, ACCEL_SPI_BASE
       	stbio       r4, (r16)
        stbio       r5, 0x8(r16)

				ret

# --------------------------------------------------------------
# accel_read ()
# Takes as argument register number in r4, reads value to r2.
# --------------------------------------------------------------
accel_read:
        movia       r16, ACCEL_SPI_BASE
       	stbio       r4, (r16)
        ldbio       r2, 0x8(r16)

				ret

# ---------------------------------------------------------
# Exception Handler / Interrupt Service Routine
# ---------------------------------------------------------
interrupt_service_routine:

		# Adjust the size of the stack frame as needed by your code
		.equ		ISR_STACKSIZE,	9*4 		# 7 32-bit words

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
        stw         r4,  12(sp)		# save the registers we use in this routine
        stw         r5,  16(sp)
        stw         r6,  20(sp)
        stw         r7,  24(sp)

        stw         r16,  28(sp)  # used by print
        stw         r17,  32(sp)

		# bail if IRQ is not external hardware interrupt
        beq         et, r0, end_isr     # interrupt is not external IRQ

		# Determine source of the interrupt
    # Can only be the accelerometer in this example

		# Service the interrupting device
		# Get initial gravity value
				movia       r4, ADXL345_DATAZH
				call        accel_read

				mov         r12, r2
				slli        r12, r12, 8       # Shift high bits into place

				movia       r4, ADXL345_DATAZL
				call        accel_read

				add         r12, r2, r12       # Read low bits

				# srai 				r12, r12, 19			 # Sign extend, initial Z is now in r15

		# Clear the interrupt
				movia						r4, ADXL345_INT_SOURCE
				call						accel_read

end_isr:
        # restore registers we used
        ldw         et,  0(sp)
        ldw         ea,  4(sp)
        ldw         ra,  8(sp)
        ldw         r4, 12(sp)
        ldw         r5, 16(sp)
				ldw					r6, 20(sp)
				ldw         r7, 24(sp)

				ldw         r16,  28(sp)  # used by print
        ldw         r17,  32(sp)

        # free the stack frame
        addi        sp, sp, ISR_STACKSIZE


		eret		# return from exception


		# ---------------------------------------------------------
		# DATA SECTION
		# ---------------------------------------------------------
		.data
		    				.align 		2	# align to 2^2=4 byte boundary

accel_led_table:
		.byte					0x3F /* 0 */
		.byte					0x06 /* 1 */
		.byte					0x5B /* 2 */
		.byte					0x4F /* 3 */

		.byte					0x66 /* 4 */
		.byte		  		0x6D /* 5 */
		.byte					0x7D /* 6 */
		.byte					0x07 /* 7 */

		.byte					0x7F /* 8 */
		.byte					0x67 /* 9 */
		.byte					0x77 /* A */
		.byte					0x7C /* b */

		.byte					0x39 /* C */
		.byte					0x5E /* d */
		.byte					0x79 /* E */
		.byte					0x71 /* F */


		.end		# end of assembly.
