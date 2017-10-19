# This is a bank template to use for your homework assignments

# --------------------------------------------------------------
#      Author: <fill in your name>
#  Assignment: homeworkN  <change N to the appropriate value>
#        Date: <fill in the date you complete your code>
#      System: DE10-Lite PDS Computer
# Description: <write a short description of what your code does>
# --------------------------------------------------------------

# This is a comment line.

/*
     This is a comment block
 */

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

		movia   r16, UART_BASE		# r16 -> UART base address

    # Call print on our first string

    # Wait for enter

    # Call print on our second string

    # Wait for enter

    # Call print on our third string

    # Hang out here forever
self:		br  	self

# -------------------------------------------------------------
# print ()
# Takes as argument
#
print:

		# ---------------------------------------------------------
		# DATA SECTION
		# ---------------------------------------------------------
		.data







		.end							# end of assembly.
