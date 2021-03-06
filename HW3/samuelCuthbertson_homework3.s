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
		mov     r22, r0             # r22 -> last 4 chars reg

		movia		r8, buffer					# Buffer pointer
		movia		r9, buffer					# List pointer

_top:
    # Read from uart
		call read_byte
    # Print read byte
		call print_byte
    # Store byte in buffer
    call store_byte
    # Dump?
    call test_dump

    br  	_top # Do this forever


		# ------------------------------------------------------------
		# print_byte (char r4)
		# Takes as argument character in r4, prints r4 to UART.
		# ------------------------------------------------------------
print_byte:
		ldwio		r18, 4(r16)         # Is there space available in the TX FIFO?
		andhi   r18, r18, 0xFFFF    # Only look at the upper 16-bits.
		beq			r18, r0, print_byte # No space, wait for space to become available.

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
    ret

		# ------------------------------------------------------------
		# store_byte () : char r4
		# Takes as argument character in r4, stores r4 to buffer.
		# ------------------------------------------------------------
store_byte:
		# Store in buffer, tricky bit
		stb			r4, (r9)            # Store it
		addi		r9, r9, 1           # Set pointer to next pos
		addi		r11, r8, 32         # Check for overflow
		bne			r9,	r11, _store_ret # If no overflow, ret
		mov			r9, r8	            # Else, wrap back to beginning
_store_ret:
		ret

		# ------------------------------------------------------------
    # test_dump (char r4, char[4] r22)
    # Takes last character in r4, four characters before that in
    #   r22. If last five characters are 'dump\n', dumps buffer.
    # ------------------------------------------------------------
test_dump:
		subi    sp, sp, WORD        # Build stack fram
		stw     ra,  0(sp)          # Store return address

		movi		r19, 0x0A 					# Character of [enter]
		movia   r21, dump_str       # Load 'dump' from memory
		ldwio		r20, (r21)  		    # Put it in r20

		mov			r18, r4							# Make a copy to test for enter
		andi		r18, r18, 0xFF			# AND off everything but the character bits

		bne			r18, r19, _test_ret # If not enter, keep waiting
		bne			r22, r20, _test_ret # If last 4 chars not dump, keep waiting

		movia 	r10, 0              # Else, start dumping.
		movia		r11, 32             # Iterate over i <= 32
		addi		r13, r8, 32         # Find beginning of list
		mov			r12, r9             # Using the beginning of the buffer
_dump_all:
		beq			r10, r11, _test_ret     # We hit end of list
		bne			r12, r13, _dump_read    # We're not at the end of the buffer yet
		mov			r12, r8	                # Else, wrap back to beginning
_dump_read:
		ldbio		r4, (r12)           # Load next char to print
		addi 		r10, r10, 1         # Increment counter
		addi		r12, r12, 1         # Read next byte
		call    print_byte          # Print byte
		br      _dump_all           # Loop again

_test_ret:
		srli		r22, r22, 8					# shift last 4 chars over
		slli		r18, r18, 24        # shift newest char over to position
		add			r22, r22, r18				# add most recent char

		ldw			ra,  0(sp)          # Restore return address
		# free the stack frame
		addi   	sp, sp, WORD
		ret



		# ---------------------------------------------------------
		# DATA SECTION
		# ---------------------------------------------------------
		.data

buffer:     .space     32          # Our Buffer
dump_str:   .ascii     "dump" 	   # Test for 'dump'

		.end							# end of assembly.
