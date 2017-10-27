# --------------------------------------------------------------
#      Author: Samuel Cuthbertson
#  Assignment: homework3
#        Date: 10/19/17
#      System: DE10-Lite PDS Computer
# Description: Outputs messages in a manner described in the homework3 writeup
# Attribution: Some lines used verbatim from class examples
# --------------------------------------------------------------

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

    # perform initialization
    movia		sp, SDRAM_CTRL_END
    movia		fp, SDRAM_CTRL_END

		movia   r16, UART_BASE			# r16 -> UART base address

		movia		r8, buffer					# Buffer pointer
		movia		r9, buffer					# End of list pointer
		movia		r10, buffer					# Beginning of list pointer
		addi		r11, r8, 32					# Max buffer address

_top:
    # Read into buffer
		call read_byte
		call print_byte
    # Check if dump

    br  	_top # Do this forever


		# ------------------------------------------------------------
		# print_byte (char r4)
		# Takes as argument character in r4, prints r4 to UART.
		# ------------------------------------------------------------
print_byte:
		ldwio		r18, 4(r16)         # Is there space available in the TX FIFO?
		andhi   r18, r18, 0xFFFF    # Only look at the upper 16-bits.
		beq			r18, r0, print 		  # No space, wait for space to become available.

		# OK, there is space in the TX FIFO, send the character to the host
		stbio		r4, (r16)
		ret

		# ------------------------------------------------------------
		# read_byte () : char r4
		# Reads byte from UART, stores in r4. Trivial enough assignment
		# 	that we can get away with sloppyness like this.
		# ------------------------------------------------------------
read_byte:
		ldwio		r4, (r16)	# [15] = RVALID, when == 1 we have a !empty RX FIFO
		mov			r18, r4		# make a copy to test for RVALID set
		andi		r18, r18, 0x8000		# AND off everything but the RVALID bit
		beq			r18, r0, read_byte	# if r18 == 0, no character received

		# Store in buffer, tricky bit
		stb			r4, r9
		addi		r9, r9, 1
		bne			r9,	r11, _test_begin
		mov			r9, r8	# Wrap back to beginning
_test_begin:
		bne			r9, r10, _read_ret # Is the beginning now also the end?
		addi		r10, r10, 1
		bne			r10,	r11, _read_ret
		mov			r10, r8	# Wrap back to beginning

_read_ret:
		ret






		# Test r4 to see if it's an enter
test_dump:
		movi		r19, 0x0A 			# Character of enter
		mov			r18, r4					# make a copy to test for enter
		andi		r18, r18, 0xFF	# AND off everything but the character bits

		ret



		# ---------------------------------------------------------
		# DATA SECTION
		# ---------------------------------------------------------
		.data

buffer:     .buffer     32    # Our Buffer

		.end							# end of assembly.
