;-----------------------------------------------------------------------------------------------------------------------
;
;	File:		os.asm
;
;	Project:	os.001
;
;	Description:	This sample program defines a valid boot sector that displays a message and waits for a key
;			to be pressed to restart the system. Using assembly directives, either a simple boot sector
;			or an entire floppy disk image is generated. Real mode BIOS interrupts are used to display
;			the message and poll for a keypress.
;
;	Revised:	January 1, 2017
;
;	Assembly:	nasm os.asm -f bin -o os.dat -l os.dat.lst -DBUILDBOOT
;			nasm os.asm -f bin -o os.dsk -l os.dsk.lst -DBUILDDISK
;
;	Assembler:	Netwide Assembler (NASM) 2.13.01
;
;			Copyright (C) 2010-2017 by David J. Walling. All Rights Reserved.
;
;-----------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------
;
;	Assembly Directives
;
;	Use one of the following as an assembly directive (-D) with NASM.
;
;	BUILDBOOT	Creates os.dat, a 512-byte boot sector as a standalone file.
;	BUILDDISK	Creates os.dsk, a 1.44MB (3.5") floppy disk image file.
;
;-----------------------------------------------------------------------------------------------------------------------
%ifdef BUILDDISK
%define BUILDBOOT
%endif
;-----------------------------------------------------------------------------------------------------------------------
;
;	Equates
;
;	The equate (equ) statements define symbolic names for fixed values so that these values can be defined and
;	verified once and then used throughout the code. Using symbolic names simplifies searching for where logical
;	values are used. Equate names are in all-caps and are the only symbolic names that begin with the letter 'E'.
;	Equates are grouped into related sets. Hardware-based values are listed first, followed by BIOS and protocol
;	values and, lastly, application values.
;
;-----------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------
;
;	8042 Keyboard Controller						EKEY...
;
;	The 8042 Keyboard Controller (8042) is a programmable controller that accepts input signals from the keyboard
;	device. It also signals a hardware interrupt to the CPU when the low-order bit of I/O port 0x64 is set to zero.
;
;-----------------------------------------------------------------------------------------------------------------------
EKEYPORTSTAT		equ	064h						;8042 status port
EKEYCMDRESET		equ	0FEh						;8042 drive B0 low to restart
;-----------------------------------------------------------------------------------------------------------------------
;
;	BIOS Interrupts and Functions						EBIOS...
;
;	Basic Input/Output System (BIOS) functions are grouped and accessed by issuing an interrupt call. Each
;	BIOS interrupt supports several funtions. The function code is typically passed in the AH register.
;
;-----------------------------------------------------------------------------------------------------------------------
EBIOSINTVIDEO		equ	010h						;BIOS video services interrupt
EBIOSFNTTYOUTPUT	equ	00Eh						;BIOS video TTY output function
EBIOSINTKEYBOARD	equ	016h						;BIOS keyboard services interrupt
EBIOSFNKEYSTATUS	equ	001h						;BIOS keyboard status function
;-----------------------------------------------------------------------------------------------------------------------
;
;	Boot Sector and Loader Constants
;
;	Equates in this section support the boot sector and the 16-bit operating system loader, which will be
;	responsible for placing the CPU into protected mode and calling the initial operating system task.
;
;-----------------------------------------------------------------------------------------------------------------------
EBOOTSECTORBYTES	equ	512						;bytes per floppy disk sector
EBOOTDISKSECTORS	equ	2880						;sectors on a 1.44MB 3.5" floppy disk
EBOOTDISKBYTES		equ	(EBOOTSECTORBYTES*EBOOTDISKSECTORS)		;calculated total bytes on disk
EBOOTSTACKTOP		equ	400h						;boot sector stack top relative to DS
%ifdef BUILDBOOT
;-----------------------------------------------------------------------------------------------------------------------
;
;	Boot Sector Code							@disk: 000000	@mem: 007c00
;
;	The first sector of the disk is the boot sector. The BIOS will load the boot sector into memory and pass
;	control to the code at the start of the sector. The boot sector code is responsible for loading the operating
;	system into memory. The boot sector contains a disk parameter table describing the geometry and allocation
;	of the disk. Following the disk parameter table is code to load the operating system kernel into memory.
;
;	The 'cpu' directive limits emitted code to those instructions supported by the most primitive processor
;	we expect to ever execute our code. The 'vstart' parameter indicates addressability of symbols so as to
;	emulating the DOS .COM program model. Although the BIOS is expected to load the boot sector at address 7c00,
;	we do not make that assumption. The CPU starts in 16-bit addressing mode. A three-byte jump instruction is
;	immediately followed by a disk parameter table.
;
;-----------------------------------------------------------------------------------------------------------------------
			cpu	8086						;assume minimal CPU
section			boot	vstart=0100h					;emulate .COM (CS,DS,ES=PSP) addressing
			bits	16						;16-bit code at power-up
Boot			jmp	word Boot.10					;jump over parameter table
;-----------------------------------------------------------------------------------------------------------------------
;
;	Disk Parameter Table
;
;	The disk parameter table informs the BIOS of the floppy disk architecture. Here, we use parameters for the
;	3.5" 1.44MB floppy disk since this format is widely supported by virtual machine hypervisors.
;
;-----------------------------------------------------------------------------------------------------------------------
			db	"CustomOS"					;eight-byte label
			dw	EBOOTSECTORBYTES				;bytes per sector
			db	1						;sectors per cluster
			dw	1						;reserved sectors
			db	2						;file allocation table copies
			dw	224						;max directory entries
			dw	EBOOTDISKSECTORS				;sectors per disk
			db	0F0h						;1.44MB
			dw	9						;sectors per FAT copy
			dw	18						;sectors per track
			dw	2						;sides per disk
			dw	0						;special sectors
;
;	BIOS typically loads the boot sector at absolute address 7c00 and sets the stack pointer at 512 bytes past the
;	end of the boot sector. But, since BIOS code varies, we don't make any assumptions as to where our boot sector
;	is loaded. For example, the initial CS:IP could be 0:7c00, 700:c00, 7c0:0, etc. So, to avoid assumptions, we
;	first normalize CS:IP to get the absolute segment address in BX. The comments below show the effect of this code
;	given several possible starting values for CS:IP.
;
										;CS:IP	 0:7c00 700:c00 7c0:0
Boot.10			call	word .20					;[ESP] =   7c21     c21    21
.@20			equ	$-$$						;.@20 = 021h
.20			pop	ax						;AX =	   7c21     c21    21
			sub	ax,.@20						;BX =	   7c00     c00     0
			mov	cl,4						;shift count
			shr	ax,cl						;AX =	    7c0      c0     0
			mov	bx,cs						;BX =	      0     700   7c0
			add	bx,ax						;BX =	    7c0     7c0   7c0
;
;	Now, since we are assembling our boot code to emulate the addressing of a .COM file, we need DS and ES
;	registers to be set to where a Program Segment Prefix (PSP) would be, exactly 100h (256) bytes prior to
;	the start of our code. This will correspond to our assembled data address offsets. Note that we instructed
;	the assembler to produce addresses for our symbols that are offset from our code by 100h. See the "vstart"
;	parameter for the "section" directive above. We also set SS to the PSP and SP to the address of our i/o
;	buffer. This leaves 256 bytes of usable stack from 7b0:300 to 7b0:400.
;
			sub	bx,16						;BX = 07b0
			mov	ds,bx						;DS = 07b0 = psp
			mov	es,bx						;ES = 07b0 = psp
			mov	ss,bx						;SS = 07b0 = psp
			mov	sp,EBOOTSTACKTOP				;SP = 0400
;
;	Our boot addressability is now set up according to the following diagram.
;
;	DS,ES,SS ----->	007b00	+-----------------------------------------------+ DS:0000
;				|  Unused (DOS Program Segment Prefix)		|
;			007c00	+-----------------------------------------------+ DS:0100
;				|  Boot Sector Code (vstart=100h)		|
;				|						|
;			007e00	+-----------------------------------------------+ DS:0300
;				|  Boot Stack					|
;	SS:SP --------> 007f00	+-----------------------------------------------+ DS:0400
;
;	Write a message to the console so we know we have our addressability established.
;
			mov	si,czStartingMsg				;starting message
			call	PutTTYString					;display loader message
;
;	Now we want to wait for a keypress. We can use a keyboard interrupt function for this (INT 16h, AH=0).
;	However, some hypervisor BIOS implementations have been seen to implement the "wait" as simply a fast
;	iteration of the keyboard status function call (INT 16h, AH=1), causing a CPU race condition. So, instead
;	we will use the keyboard status call and iterate over a halt (HLT) instruction until a key is pressed.
;	By convention, we enable maskable interrupts with STI before issuing HLT, so as not to catch fire.
;
.30			mov	ah,EBIOSFNKEYSTATUS				;keyboard status function
			int	EBIOSINTKEYBOARD				;call BIOS keyboard interrupt
			jnz	.40						;exit if key pressed
			sti							;enable maskable interrupts
			hlt							;wait for interrupt
			jmp	short .30					;repeat until keypress
;
;	Now that a key has been pressed, we signal the system to restart by driving the B0 line on the 8042
;	keyboard controller low (OUT 64h,0feh). The restart may take some microseconds to kick in, so we issue
;	HLT until the system resets.
;
.40			mov	al,EKEYCMDRESET					;8042 pulse output port pin
			out	EKEYPORTSTAT,al					;drive B0 low to restart
.50			sti							;enable maskable interrupts
			hlt							;stop until reset, int, nmi
			jmp	short .50					;loop until restart kicks in
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	PutTTYString
;
;	Description:	This routine sends a NUL-terminated string of characters to the TTY output device. We use the
;			TTY output function of the BIOS video interrupt, passing the address of the string in DS:SI
;			and the BIOS teletype function code in AH. After a return from the BIOS interrupt, we repeat
;			for the next string character until a NUL is found. Note that we clear the direction flag (DF)
;			with CLD before each LODSB. This is just in case the direction flag is ever returned as set
;			by the video interrupt. This is a precaution since a well-written BIOS should preserve all
;			registers and flags unless used to indicate return status.
;
;	In:		DS:SI	address of string
;
;-----------------------------------------------------------------------------------------------------------------------
PutTTYString		cld							;forward strings
			lodsb							;load next byte at DS:SI in AL
			test	al,al						;end of string?
			jz	.10						;... yes, exit our loop
			mov	ah,EBIOSFNTTYOUTPUT				;BIOS teletype function
			int	EBIOSINTVIDEO					;call BIOS display interrupt
			jmp	short PutTTYString				;repeat until done
.10			ret							;return to caller
;-----------------------------------------------------------------------------------------------------------------------
;
;	Loader Data
;
;	Our only "data" is the string displayed when system starts. It ends with ASCII carriage-return (13) and line-
;	feed (10) values. The remainder of the boot sector is filled with NUL. The boot sector finally ends with the
;	required two-byte signature checked by the BIOS. Note that recent versions of NASM will issue a warning if
;	the calculated address for the end-of-sector signature produces a negative value for "510-($-$$)". This will
;	indicate if we have added too much data and exceeded the length of the sector.
;
;-----------------------------------------------------------------------------------------------------------------------
czStartingMsg		db	"Starting ...",13,10,0				;loader message
			times	510-($-$$) db 0h				;zero fill to end of sector
			db	055h,0AAh					;end of sector signature
%endif
%ifdef BUILDDISK
;-----------------------------------------------------------------------------------------------------------------------
;
;	Free Disk Space								@disk: 000200	@mem:  n/a
;
;	Following the convention introduced by DOS, we use the value 'F6' to indicate unused floppy disk storage.
;
;-----------------------------------------------------------------------------------------------------------------------
section			unused							;unused disk space
			times 	EBOOTDISKBYTES-0200h db 0F6h			;fill to end of disk image
%endif
