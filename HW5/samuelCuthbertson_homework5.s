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

		movia		r4, begin_str   		# Call print on our first string
		call 		print

		call		wait_ent						# Wait for enter

    # Do the first thing - disable write protection
		movia 	r8, ONCHIP_FLASH_CSR_CONTROL
		ldwio 	r9, (r8)
		movia		r10, setup_ctrl
		ldw			r11, (r10)
		and 		r9, r11, r9  # Unset all erase addresses, unset write protect sector 1
		stwio		r9, (r8)

		# Wait for flash to become idle
		call 		wait_flash

		# Do the next thing - do sector erase
		ldwio 	r9, (r8)
		movi 		r11, 0b0001	 # Unset write protect, set clear sector 1
		slli		r11, r11, 20 # Shift into position
		add 		r9, r11, r9
		stwio		r9, (r8)

		# Wait for flash to become idle
		call 		wait_flash
		# Did erase succeed?
		andi		r13, r13, 0b10000
		bne			r13, r0, check_erase_mem

		movia		r4, erase_failed
		call 		print
		break

check_erase_mem:
		# Read first 32bits of flash
		movia		r14, ONCHIP_FLASH_SECTOR1_BASE
		ldwio		r15, (r14)
		nor 		r15, r0, r15
		beq 		r15, r0, begin_write

		movia		r4, erase_chk_fail
		call 		print
		break

begin_write:
		movia 	r5, the_data
		movia		r6,	ONCHIP_FLASH_SECTOR1_BASE
		addi 		r20, r5, 512

write:
		ldw 		r7, (r5) # Load next 4 bytes
		stwio		r7, (r6) # Store in flash

		# Check for failure
		call 		wait_flash
		andi 		r13, r13, 0b1000
		addi 		r21, r0, 0b1000
		beq 		r13, r21, write_cont

		# Log failure
		movia		r4, write_fail
		call 		print
		break

write_cont:
		addi 		r5, r5, 4
		addi 		r6, r6, 4

		# Check for end of loop
		bne			r20, r5, write

		# We're done!
		# Do the last thing - enable write protection
		movia 	r8, ONCHIP_FLASH_CSR_CONTROL
		ldwio 	r9, (r8)
		movia		r10, shutdown_ctrl
		ldw			r11, (r10)
		or 			r9, r11, r9  # Reset everything
		stwio		r9, (r8)

		movia		r4, done
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

		# ------------------------------------------------------------
		# wait_ent ()
		# Blocks until 0x0A from enter.
		#
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

		# ------------------------------------------------------------
		# wait_flash ()
		# Blocks until flash is idle.
		#
wait_flash:
		movia		r12, ONCHIP_FLASH_CSR_STATUS
		ldwio		r13, (r12)
		andi		r14, r13, 0b11
		bne			r14, r0, wait_flash

		ret

		# ---------------------------------------------------------
		# DATA SECTION
		# ---------------------------------------------------------
		.data

		.align  2^2             # align to 4-byte boundary


the_data:      # 16 x 4-bytes = 64-bytes, data values to program into flash
					.word       0x03020100
					.word       0x07060504
					.word       0x0b0a0908
					.word       0x0f0e0d0c

					.word       0x13121110
					.word       0x17161514
					.word       0x1b1a1918
					.word       0x1f1e1d1c

					.word       0x23222120
					.word       0x27262524
					.word       0x2b2a2928
					.word       0x2f2e2d2c

					.word       0x33323130
					.word       0x37363534
					.word       0x3b3a3938
					.word       0x3f3e3d3c

setup_ctrl:				.word			 0xFF000000
shutdown_ctrl:		.word			 0x3FFFFFFF

begin_str:				.asciz		"Ready to program NOR flash, press the enter key to begin\n"
erase_failed:			.asciz		"Erase operation failed!\n"
erase_chk_fail:		.asciz		"Erase operation failed to set all bits to 1\n"
write_fail:				.asciz		"A programming operation failed\n"
done:							.asciz		"NOR flash programming complete\n"

		.end							# end of assembly.
