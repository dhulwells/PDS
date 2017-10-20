# --------------------------------------------------------------
# Base addresses of hardware devices for the
# DE10-Lite development board PDS Computer System for ECEN 3350.
# Last edited on 06-02-2017.
# --------------------------------------------------------------

.equ	WORD,				4		# number of bytes in 1 word of memory


# ---------------------------------------------
# These peripherals live on the CPU's main bus
# ---------------------------------------------

.equ SDRAM_CTRL_BASE,      	0x00000000 # 64 Mbytes
.equ SDRAM_CTRL_END,       	0x03FFFFFC

# The VGA frame buffers live in DRAM at the following addresses.
# If you are not using the VGA hardware, you can ignore these equates.
# The VGA logic runs at a fixed resolution of 640 pixels wide by 480 pixels tall.
# The pixel at coordinate y=0, x=0 is in the upper-left corner of the frame,
# this is typical for graphics systems. Each pixel uses 30-bits of information
# to display the color for each pixel; 10-bits for red, 10-bits for green and
# 10-bits for blue. The size in bytes of 1 frame buffer is:
#    640 x 480 * 4 bytes/pixel = 1,228,800 bytes (0x0012_C000 in hex).
# So these two frame buffers together consume 2,457,600 bytes, leaving
# aproximately 13.5 Mbytes for the stack.
# My Qsys configuration put these frame buffers in the 4th 16MB chunk of
# DRAM. 
.equ VGA_BUFFER_WIDTH,		640
.equ VGA_BUFFER_HEIGHT,		480
.equ VGA_PIXEL_DEPTH,		4			# 4-bytes per pixel
.equ VGA_X_ADDR_BITS,		10
.equ VGA_Y_ADDR_BITS,		9
.equ VGA_BUFFER_SIZE,		VGA_BUFFER_WIDTH*VGA_BUFFER_HEIGHT*VGA_PIXEL_DEPTH 	# size of 1 buffer in bytes, 0x0012C000
.equ VGA_BUFFER_BASE,		0x03000000 	# buffer 1, this is fixed in hardware
.equ VGA_BACKBUFFER_BASE,	VGA_BUFFER_BASE+VGA_BUFFER_SIZE 	# buffer 2, this can be written, 0x0312C000
.equ VGA_BUFFER_END,		(2 * VGA_BUFFER_SIZE) - 4  # 0x03257FFC
.equ VGA_RED_PIXEL,			0x3FF00000 # a red pixel
.equ VGA_GREEN_PIXEL,		0x000FFC00 # a green pixel
.equ VGA_BLUE_PIXEL,		0x000003FF # a blue pixel 


.equ ONCHIP_SRAM_BASE,     	0x08000000 	# 16 Kbytes
.equ ONCHIP_SRAM_END,      	0x08003FFC

# UFM = User Flash Memory
# CFM = Configuration Flash Memory
# M50 part: max parallel interface operation = 116MHz
# Config:
#    Parallel I/F, incrementing, read burst count = 8
#    Pages per sector = 4
#    Page size = 64Kbits or 8Kbytes
#
# Modes of operation:
#   Read
#   Burst read
#   Program (write), single 32-bit program
#   Sector erase
#   Page erase
#
#                      Byte addresses from Qsys      Word/32-bit address 
#                      -------------------------------------------------------------------------
#   UFM, R/W, Sector 1 = 0x00_0000 to 0x00_7FFF : 0x00_0000 to 0x00_1FFC - 32Kbytes, 4 pages 
#   UFM, R/W, Sector 2 = 0x00_8000 to 0x00_FFFF : 0x00_2000 to 0x00_3FFC - 32Kbytes, 4 pages
#   UFM, R/W, Sector 3 = 0x01_0000 to 0x06_FFFF : 0x00_4000 ro 0x01_BFFC - 384Kbytes, 48 pages 
#   CFM, R/W, Sector 4 = 0x07_0000 to 0x0B_7FFF : 0x01_C000 to 0x02_DFFC
#   CFM, R/W, Sector 5 = 0x0B_8000 to 0x15_FFFF : 0x02_E000 to 0x05_7FFC 
.equ ONCHIP_FLASH_BASE, 		0x09000000
.equ ONCHIP_FLASH_SECTOR1_BASE,	0x09000000
.equ ONCHIP_FLASH_SECTOR2_BASE,	0x09002000
.equ ONCHIP_FLASH_SECTOR3_BASE,	0x09004000
.equ ONCHIP_FLASH_END,     		0x0915FFFC
.equ ONCHIP_FLASH_PAGE_SIZE,	8192		# bytes

.equ ONCHIP_FLASH_CSR_BASE,		0x0a000000  # control and status registers for flash 
.equ ONCHIP_FLASH_CSR_STATUS,   0x0a000000
# resets to 0xFFFF_FC00
#  [1:0] = 00 Idle
#        = 01 Busy erase
#        = 10 Busy program/write 
#        = 11 Busy read
#    [2] = 1 read sucessful
#    [3] = 1 write sucessful
#    [4] = 1 erase sucessful
#    [9:5] = RO, sector 5,4,3,2,1; =1 sector protection
#  [31:10] = pad = 1's 
.equ ONCHIP_FLASH_CSR_CONTROL,  0x0a000004 
# resets to 3FFF_FFFF
#   [19:0] = page erase address 
#  [22:20] = sector erase address; 001 thru 101
#  [27:23] = sector 5,4,3,2,1; =1 write protection
#  [31:28] = pad = 0011, 

# Basic DMA Qsys configuration:
#   Length register = 14-bits, max value 2^14 - 1 = 16,383 bytes 
#   Burst transfers = disabled
#   Soft reset enabled = true
#   Fifo depth = 16
#   Use registers for FIFO implementation = false
.equ DMA_BASE,              0x0b000000 # DMA controller
.equ DMA_STATUS,			0x0b000000
#    [0] = Done, =1, write 0 to status reg to clear Done bit 
#    [1] = Busy
#    [2] = REOP, =1 read end-of-packet 
#    [3] = WEOP, =1 write end-of-packet 
#    [4] = LEN,  =1 when length register decrements to 0 
.equ DMA_MSTR_READ_START,	0x0b000004
.equ DMA_MSTR_WRITE_START,	0x0b000008
.equ DMA_LENGTH,			0x0b00000C # length in bytes, 14-bits, max value = 16,383 bytes 
.equ DMA_CONTROL,			0x0b000018
#    [0] = Byte
#    [1] = Half-word
#    [2] = Word
#    [3] = Go    start DMA operation 
#    [4] = I_EN  generates IRQ when Done bit is set 
#    [5] = REEN  ends transcation when read master is done
#    [6] = WEEN  ends transaction when write master is done
#    [7] = LEEN  ends transaction when length reg = 0
#    [8] = RCON  holds read address constant
#    [9] = WCON  holds write address constant 
#   [10] = Double word
#   [11] = Quad word
#   [12] = SOFTWARERESET, write twice to 1 to reset 


.equ NIOS2_DEBUG_MEM_SLAVE,	0x0e000000
.equ NIOS2_BREAK_ADDR,      0x0e000020

.equ PLL_BASE,            	0x0f000000



# ----------------------------------------------------
# These peripherals live on the slow peripheral bridge
# ----------------------------------------------------

.equ UART_BASE,            	0x10000000 # UART, INFO: DE10-Lite JTAG TCK runs at ~12 mhz.

.equ TIMER_BASE,         	0x10000020 # Timer, 1 unit = 1 clock

.equ SYSID_BASE,         	0x10000040 # System ID register
.equ SYSID_VALUE,			0xFACEFACE

.equ LED_OUT_BASE,       	0x10000060 # 10 LEDs

.equ SWITCHES_IN_BASE,    	0x10000080 # 10 switches

.equ SEGA_OUT_BASE,       	0x100000a0 # 4 of the 7-segments
.equ SEGB_OUT_BASE,       	0x100000c0 # 2 of the 7-segments

# Keys config:
#   Edge capture = true, synchronous, rising, enable bit-clearing
#   IRQ type - Edge (when any edge bit is set)  
.equ KEYS_IN_BASE,        	0x100000e0 # 2 push buttons, data in [1:0]
.equ KEYS_IN_IRQ_MASK,		0x100000e8 # [1:0]
.equ KEYS_IN_EDGE,			0x100000eC # [1:0] - Write 1 to clear (W1C)

.equ ACCEL_SPI_BASE,      	0x10000100  # SPI accelerometer access registers 
										# [15:8] r/w data
										#  [7:0] w   address
										
# Accelerometer register addresses
.equ ADXL345_INT_SOURCE,	0x30		# Interrupt source register, clear IRQ by reading this register

.equ ADXL345_DATAXL,		0x32		# X  [7:0], 2's complement value
.equ ADXL345_DATAXH,		0x33		# X [12:8]

.equ ADXL345_DATAYL,		0x34		# Y  [7:0], 2's complement value
.equ ADXL345_DATAYH,		0x35		# Y [12:8]

.equ ADXL345_DATAZL,		0x36		# Z  [7:0], 2's complement value
.equ ADXL345_DATAZH,		0x37		# Z [12:8]

# From the auto-init hardware built by Qsys in Quartus 
#	case (rom_address)        addr  value
#	0		:	data	<=	{6'h24, 8'h20}; // 8-bits, unsigned, threshold activity    = 32 * 62.5 mg = 2000 mg 
#	1		:	data	<=	{6'h25, 8'h03}; // 8-bits, unsigned, threshold inactivity  =  3 * 62.5 mg = 187.5 mg
#	2		:	data	<=	{6'h26, 8'h01}; // 8-bits, unsigned, time inactivity       =  1 * 1 sec   = 1 sec 
#	3		:	data	<=	{6'h27, 8'h7f}; // 8-bits, Activity/inactivity control/detection
#                                              Act DC coupled,     ACT x,y,z = 1
#                                              Inact AC coupled, INACT x,y,z = 1
#	4		:	data	<=	{6'h28, 8'h09}; // 8-bits, unsigned, Threshold Free-fall   = 9 * 62.5 mg  = 562.5 mg 
#	5		:	data	<=	{6'h29, 8'h46}; // 8-bits, Time free-fall                  = 70 * 5 ms    = 350 ms 
#	6		:	data	<=	{6'h2c, 8'h09}; // bandwidth rate, data rate and power mode control 
#                                           //   low-power [4] = 0, rate = 9 -> output data rate : 50 Hz  
#	7		:	data	<=	{6'h2E, 8'h10}; // Interrupt enable, Activity [4] = 1
#	8		:	data	<=	{6'h2F, 8'h10}; // Interrupt map, 0's set INT1 pin, 1's set INT2 pin, Activity [4] -> INT2 
#	9		:	data	<=	{6'h31, 8'h40}; // Data format SPI [6] = 1 -> 3 wire SPI mode; Int Invert [5] = IRQ signal is =1 
#	10		:	data	<=	{6'h2d, 8'h08}; // Power control, power saving, measure [3] = 1, puts part into measurement mode 
#	default	:	data	<=	14'h0000;
#	endcase

# VGA controller
.equ VGA_BASE,              0x10000120  # VGA controller registers 
.equ VGA_BUFFER,     		0x10000120  # Read-only, Buffer start address 
.equ VGA_BACKBUFFER,        0x10000124  # Read/Write, Back buffer start address 
.equ VGA_RESOLUTION,        0x10000128  # Read-only, [31:16]=Y, [15:0]=X
.equ VGA_STATUS,            0x1000012C  # Read-only, 
										# [31:24] = m, width of Y coordinate address 
										# [23:16] = n, width of X coordinate address
										#   [7:4] = B, number of bytes per pixel
										#     [1] = A, addressing mode, (X-Y or consecutive)
										#     [0] = S, swap

# ---------------------------------------------------
# Interrupt enable/mask bits for CPU ienable register 
# ---------------------------------------------------
.equ		IRQ_UART_MASK,			0b00001
.equ		IRQ_TIMER_MASK,			0b00010
.equ		IRQ_PUSHBUTTON_MASK,	0b00100
.equ		IRQ_ACCEL_MASK,			0b01000
.equ		IRQ_DMA_MASK,			0b10000





