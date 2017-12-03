# --------------------------------------------------------------
#      Author: Samuel Cuthbertson
#  Assignment: homework5
#        Date: 10/19/17
#      System: DE10-Lite PDS Computer
# Description: Outputs messages in a manner described in the
#               homework5 writeup.
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

		movia		r4, press_ent_str   # Call print on our first string
		call 		print

		call		wait_ent						# Wait for enter

    # Do the second thing 

		movia		r4, hello_world_str # Call print on our second string
		call 		print

		movia		r4, cont_ent_str    # Call print on our third string
		call 		print

		call		wait_ent						# Wait for enter

		movia		r4, done_str				# Call print on our last string
		call 		print

self:		br  	self							# Hang out here forever

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

wait_ent:
		movi		r19, 0x0A 				# Character of enter
		ldwio		r17, (r16)	# [15] = RVALID, when == 1 we have a !empty RX FIFO
		mov			r18, r17		# make a copy to test for RVALID set
		andi		r18, r18, 0x8000	# AND off everything but the RVALID bit
		beq			r18, r0, wait_ent	# if r18 == 0, no character received

		mov			r18, r17	# make a copy to test for enter
		andi		r18, r18, 0xFF	# AND off everything but the character bits
		bne			r18, r19, wait_ent # If not enter, keep waiting
		# Else, return
		ret

		# ---------------------------------------------------------
		# DATA SECTION
		# ---------------------------------------------------------
		.data

press_ent_str:		.asciz		"Press the enter key to begin\n"
hello_world_str:	.asciz		"Hello World!\n"
cont_ent_str:			.asciz		"Press the enter key to continue\n"
done_str:					.asciz		"We are done!\n"

		.end							# end of assembly.
