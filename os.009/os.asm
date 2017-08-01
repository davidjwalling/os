;-----------------------------------------------------------------------------------------------------------------------
;
;	File:		os.asm
;
;	Project:	os.009
;
;	Description:	In this sample, the console task is expanded to support commands that take parameters and new
;			commands "mem" and "memory".
;
;	Revised:	January 1, 2017
;
;	Assembly:	nasm os.asm -f bin -o os.dat     -l os.dat.lst     -DBUILDBOOT
;			nasm os.asm -f bin -o os.dsk     -l os.dsk.lst     -DBUILDDISK
;			nasm os.asm -f bin -o os.com     -l os.com.lst     -DBUILDCOM
;			nasm os.asm -f bin -o osprep.com -l osprep.com.lst -DBUILDPREP
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
;	BUILDCOM	Creates os.com, the OS loader and kernel as a standalone DOS program.
;	BUILDPREP	Creates osprep.com, a DOS program that prepares a floppy disk to boot the OS
;
;-----------------------------------------------------------------------------------------------------------------------
%ifdef BUILDDISK
%define BUILDBOOT
%define BUILDCOM
%endif
%ifdef BUILDPREP
%define BUILDBOOT
%endif
;-----------------------------------------------------------------------------------------------------------------------
;
;	Conventions
;
;	Labels:		Labels within a routine are numeric and begin with a period (.10, .20).
;			Labels within a routine begin at ".10" and increment by 10.
;
;	Comments:	A comment that spans the entire line begins with a semicolon in column 1.
;			A comment that accompanies code on a line begins with a semicolon in column 81.
;
;	Alignment:	Assembly instructions (mnemonics) begin in column 25.
;			Assembly operands begin in column 33.
;			Lines should not extend beyond column 120.
;
;	Routines:	Routine names are in mixed case (GetYear, ReadRealTimeClock)
;			Routine names begin with a verb (Get, Read, etc.)
;
;	Constants:	Symbolic constants (equates) are named in all-caps beginning with 'E' (EDATAPORT).
;			Constant stored values are named in camel case, starting with 'c'.
;			The 2nd letter of the constant label indicates the storage type.
;
;			cq......	constant quad-word (dq)
;			cd......	constant double-word (dd)
;			cw......	constant word (dw)
;			cb......	constant byte (db)
;			cz......	constant ASCIIZ (null-terminated) string
;
;	Variables:	Variables are named in camel case, starting with 'w'.
;			The 2nd letter of the variable label indicates the storage type.
;
;			wq......	variable quad-word (resq)
;			wd......	variable double-word (resd)
;			ww......	variable word (resw)
;			wb......	variable byte (resb)
;
;	Structures:	Structure names are in all-caps (DATETIME).
;			Structure names do not begin with a verb.
;
;	Macros:		Macro names are in camel case (getDateString).
;			Macro names do begin with a verb.
;
;	Registers:	Registers EBX, ESI, EDI, EBP, SS, CS, DS and ES are preserved by all OS routines.
;			Registers EAX and ECX are preferred for returning response/result values.
;			Register EBX is preferred for passing a context (structure) address parameter.
;			Registers EAX, EDX, ECX and EBX are preferred for passing integral parameters.
;
;-----------------------------------------------------------------------------------------------------------------------
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
EKEYPORTDATA		equ	060h						;8042 data port
EKEYPORTSTAT		equ	064h						;8042 status port
EKEYCMDRESET		equ	0FEh						;8042 drive B0 low to restart
EKEYBITOUT		equ	001h						;8042 output buffer status bit
EKEYBITIN		equ	002h						;8042 input buffer status bit
EKEYCMDLAMPS		equ	0EDh						;8042 set/reset lamps command
EKEYWAITLOOP		equ	010000h						;8042 wait loop
										;---------------------------------------
										;	Keyboard Scan Codes
										;---------------------------------------
EKEYCTRLDOWN		equ	01Dh						;control key down
EKEYPAUSEDOWN		equ	01Dh						;pause key down (e1 1d ... )
EKEYSHIFTLDOWN		equ	02Ah						;left shift key down
EKEYPRTSCRDOWN		equ	02Ah						;print-screen key down (e0 2a ...)
EKEYSLASH		equ	035h						;slash
EKEYSHIFTRDOWN		equ	036h						;right shift key down
EKEYALTDOWN		equ	038h						;alt key down
EKEYCAPSDOWN		equ	03Ah						;caps-lock down
EKEYNUMDOWN		equ	045h						;num-lock down
EKEYSCROLLDOWN		equ	046h						;scroll-lock down
EKEYINSERTDOWN		equ	052h						;insert down (e0 52)
EKEYUP			equ	080h						;up
EKEYCTRLUP		equ	09Dh						;control key up
EKEYSHIFTLUP		equ	0AAh						;left shift key up
EKEYSLASHUP		equ	0B5h						;slash key up
EKEYSHIFTRUP		equ	0B6h						;right shift key up
EKEYPRTSCRUP		equ	0B7h						;print-screen key up (e0 b7 ...)
EKEYALTUP		equ	0B8h						;alt key up
EKEYCAPSUP		equ	0BAh						;caps-lock up
EKEYNUMUP		equ	0C5h						;num-lock up
EKEYSCROLLUP		equ	0C6h						;scroll-lock up
EKEYINSERTUP		equ	0D2h						;insert up (e0 d2)
EKEYCODEEXT0		equ	0E0h						;8042 extended scan code 0
EKEYCODEEXT1		equ	0E1h						;8042 extended scan code 1
;-----------------------------------------------------------------------------------------------------------------------
;
;	8253 Programmable Interrupt Timer					EPIT...
;
;	The Intel 8253 Programmable Interrupt Time (PIT) is a chip that produces a hardware interrupt (IRQ0)
;	approximately 18.2 times per second.
;
;-----------------------------------------------------------------------------------------------------------------------
EPITDAYTICKS		equ	1800B0h						;8253 ticks per day
;-----------------------------------------------------------------------------------------------------------------------
;
;	8259 Peripheral Interrupt Controller					EPIC...
;
;	The 8259 Peripheral Interrupt Controller (PIC) is a programmable controller that accepts interrupt signals from
;	external devices and signals a hardware interrupt to the CPU.
;
;-----------------------------------------------------------------------------------------------------------------------
EPICPORTPRI		equ	020h						;8259 primary control port 0
EPICPORTPRI1		equ	021h						;8259 primary control port 1
EPICPORTSEC		equ	0A0h						;8259 secondary control port 0
EPICPORTSEC1		equ	0A1h						;8259 secondary control port 1
EPICEOI			equ	020h						;8259 non-specific EOI code
;-----------------------------------------------------------------------------------------------------------------------
;
;	6845 Cathode Ray Tube (CRT) Controller					ECRT...
;
;	The Motorola 6845 CRT Controller (CRTC) is a programmable controller
;	for CGA, EGA, VGA and compatible video modes.
;
;-----------------------------------------------------------------------------------------------------------------------
ECRTPORTHI		equ	003h						;CRT controller port hi
ECRTPORTLO		equ	0D4h						;CRT controller port lo
ECRTCURLOCHI		equ	00Eh						;CRT cursor loc reg hi
ECRTCURLOCLO		equ	00Fh						;CRT cursor loc reg lo
;-----------------------------------------------------------------------------------------------------------------------
;
;	NEC 765 Floppy Disk Controller (FDC)					EFDC...
;
;	The NEC 765 FDC is a programmable controller for floppy disk drives.
;
;-----------------------------------------------------------------------------------------------------------------------
EFDCPORTHI		equ	003h						;FDC controller port hi
EFDCPORTLOOUT		equ	0F2h						;FDC digital output register lo
EFDCPORTLOSTAT		equ	0F4h						;FDC main status register lo
EFDCSTATBUSY		equ	010h						;FDC main status is busy
EFDCMOTOROFF		equ	00Ch						;FDC motor off / enable / DMA
;-----------------------------------------------------------------------------------------------------------------------
;
;	Motorola MC 146818 Real-Time Clock					ERTC...
;
;	The Motorola MC 146818 was the original real-time clock in PCs.
;
;-----------------------------------------------------------------------------------------------------------------------
ERTCREGPORT		equ	70h						;register select port
ERTCDATAPORT		equ	71h						;data port
ERTCSECONDREG		equ	00h						;second
ERTCMINUTEREG		equ	02h						;minute
ERTCHOURREG		equ	04h						;hour
ERTCWEEKDAYREG		equ	06h						;weekday
ERTCDAYREG		equ	07h						;day
ERTCMONTHREG		equ	08h						;month
ERTCYEARREG		equ	09h						;year of the century
ERTCSTATUSREG		equ	0bh						;status
ERTCCENTURYREG		equ	32h						;century
ERTCBINARYVALS		equ	00000100b					;values are binary
;-----------------------------------------------------------------------------------------------------------------------
;
;	x86 Descriptor Access Codes						EACC...
;
;	The x86 architecture supports the classification of memory areas or segments. Segment attributes are defined by
;	structures known as descriptors. Within a descriptor are access type codes that define the type of the segment.
;
;	0.......	Segment is not present in memory (triggers int 11)
;	1.......	Segment is present in memory
;	.LL.....	Segment is of privilege level LL (0,1,2,3)
;	...0....	Segment is a system segment
;	...00010		Local Descriptor Table
;	...00101		Task Gate
;	...010B1		Task State Segment (B:0=Available,1=Busy)
;	...01100		Call Gate (386)
;	...01110		Interrupt Gate (386)
;	...01111		Trap Gate (386)
;	...1...A	Segment is a code or data (A:1=Accesssed)
;	...10DW.		Data (D:1=Expand Down,W:1=Writable)
;	...11CR.		Code (C:1=Conforming,R:1=Readable)
;
;-----------------------------------------------------------------------------------------------------------------------
EACCLDT			equ	10000010b					;local descriptor table
EACCTASK		equ	10000101b					;task gate
EACCTSS			equ	10001001b					;task-state segment
EACCGATE		equ	10001100b					;call gate
EACCINT			equ	10001110b					;interrupt gate
EACCTRAP		equ	10001111b					;trap gate
EACCDATA		equ	10010011b					;upward writable data
EACCCODE		equ	10011011b					;non-conforming readable code
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
EBIOSINTDISKETTE	equ	013h						;BIOS diskette services interrupt
EBIOSINTMISC		equ	015h						;BIOS miscellaneous services interrupt
EBIOSFNINITPROTMODE	equ	089h						;BIOS initialize protected mode fn
EBIOSINTKEYBOARD	equ	016h						;BIOS keyboard services interrupt
EBIOSFNKEYSTATUS	equ	001h						;BIOS keyboard status function
;-----------------------------------------------------------------------------------------------------------------------
;
;	ASCII									EASCII...
;
;-----------------------------------------------------------------------------------------------------------------------
EASCIIBACKSPACE		equ	8						;ASCII backspace
EASCIILINEFEED		equ	10						;ASCII line feed
EASCIIRETURN		equ	13						;ASCII carriage return
EASCIIESCAPE		equ	27						;ASCII escape
EASCIISPACE		equ	32						;ASCII space
EASCIIUPPERA		equ	65						;ASCII 'A'
EASCIIUPPERZ		equ	90						;ASCII 'Z'
EASCIILOWERA		equ	97						;ASCII 'a'
EASCIILOWERZ		equ	122						;ASCII 'z'
EASCIITILDE		equ	126						;ASCII '~'
EASCIICASE		equ	00100000b					;ASCII case bit
EASCIICASEMASK		equ	11011111b					;ASCII case mask
;-----------------------------------------------------------------------------------------------------------------------
;
;	Boot Sector and Loader Constants
;
;	Equates in this section support the boot sector and the 16-bit operating system loader, which will be
;	responsible for placing the CPU into protected mode and calling the initial operating system task.
;
;-----------------------------------------------------------------------------------------------------------------------
EBOOTSECTORBYTES	equ	512						;bytes per sector
EBOOTDISKSECTORS	equ	2880						;sectors per disk
EBOOTDISKBYTES		equ	(EBOOTSECTORBYTES*EBOOTDISKSECTORS)		;bytes per disk
EBOOTSTACKTOP		equ	400h						;boot sector stack top relative to DS
EMAXTRIES		equ	5						;max read retries
;-----------------------------------------------------------------------------------------------------------------------
;	Global Descriptor Table (GDT) Selectors					ESEL...
;-----------------------------------------------------------------------------------------------------------------------
ESELDAT			equ	18h						;kernel data selector
ESELCGA			equ	20h						;cga video selector
ESELOSCODE		equ	48h						;os kernel selector
;-----------------------------------------------------------------------------------------------------------------------
;	LDT Selectors								ESEL...
;-----------------------------------------------------------------------------------------------------------------------
ESELMQ			equ	2Ch						;console task message queue
;-----------------------------------------------------------------------------------------------------------------------
;	Kernel Constants							EKRN...
;-----------------------------------------------------------------------------------------------------------------------
EKRNDESLEN		equ	8						;size of descriptor
EKRNADR			equ	1000h						;kernel base address
EKRNSEG			equ	(EKRNADR >> 4)					;kernel base segment
;-----------------------------------------------------------------------------------------------------------------------
;	Keyboard Flags								EKEY...
;-----------------------------------------------------------------------------------------------------------------------
EKEYCTRLLEFT		equ	00000001b					;left control
EKEYSHIFTLEFT		equ	00000010b					;left shift
EKEYALTLEFT		equ	00000100b					;left alt
EKEYCTRLRIGHT		equ	00001000b					;right control
EKEYSHIFTRIGHT		equ	00010000b					;right shift
EKEYSHIFT		equ	00010010b					;left or right shift
EKEYALTRIGHT		equ	00100000b					;right alt
EKEYLOCKSCROLL		equ	00000001b					;scroll-lock flag
EKEYLOCKNUM		equ	00000010b					;num-lock flag
EKEYLOCKCAPS		equ	00000100b					;cap-lock flag
EKEYTIMEOUT		equ	10000000b					;controller timeout
;-----------------------------------------------------------------------------------------------------------------------
;	Console Constants							ECON...
;-----------------------------------------------------------------------------------------------------------------------
ECONCOLS		equ	80						;columns per row
ECONROWS		equ	24						;console rows
ECONOIAROW		equ	24						;operator information area row
ECONCOLBYTES		equ	2						;bytes per column
ECONROWBYTES		equ	(ECONCOLS*ECONCOLBYTES)				;bytes per row
ECONROWDWORDS		equ	(ECONROWBYTES/4)				;double-words per row
ECONCLEARDWORD		equ	07200720h					;attribute and ASCII space
ECONOIADWORD		equ	70207020h					;attribute and ASCII space
;-----------------------------------------------------------------------------------------------------------------------
;	Kernel Message Identifiers						EMSG...
;-----------------------------------------------------------------------------------------------------------------------
EMSGKEYDOWN		equ	41000000h					;message: key-down
EMSGKEYUP		equ	41010000h					;message: key-up
EMSGKEYCHAR		equ	41020000h					;message: character
;-----------------------------------------------------------------------------------------------------------------------
;
;	Structures
;
;-----------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------
;
;	DATETIME
;
;	The DATETIME structure stores date and time values from the real-time clock.
;
;-----------------------------------------------------------------------------------------------------------------------
struc			DATETIME
.second			resb	1						;seconds
.minute			resb	1						;minutes
.hour			resb	1						;hours
.weekday		resb	1						;day of week
.day			resb	1						;day of month
.month			resb	1						;month of year
.year			resb	1						;year of century
.century		resb	1						;century
EDATETIMEL		equ	($-.second)
endstruc
;-----------------------------------------------------------------------------------------------------------------------
;
;	MQUEUE
;
;	The MQUEUE structure maps memory used for a message queue.
;
;-----------------------------------------------------------------------------------------------------------------------
struc			MQUEUE
MQHead			resd	1						;000 head ptr
MQTail			resd	1						;004 tail ptr
MQData			resd	254						;message queue
endstruc
;-----------------------------------------------------------------------------------------------------------------------
;
;	OSDATA
;
;	The OSDATA structure maps low-memory addresses used by the OS. Some of these addresses are predetermined and
;	used by the BIOS.
;
;-----------------------------------------------------------------------------------------------------------------------
struc			OSDATA
			resb	400h						;000 real mode interrupt vectors
			resw	1						;400 COM1 port address
			resw	1						;402 COM2 port address
			resw	1						;404 COM3 port address
			resw	1						;406 COM4 port address
			resw	1						;408 LPT1 port address
			resw	1						;40A LPT2 port address
			resw	1						;40C LPT3 port address
			resw	1						;40E LPT4 port address
			resb	2						;410 equipment list flags
			resb	1						;412 errors in PCjr infrared keybd link
			resw	1						;413 memory size (kb) INT 12H
			resb	1						;415 mfr error test scratchpad
			resb	1						;416 PS/2 BIOS control flags
			resb	1						;417 keyboard flag byte 0
			resb	1						;418 keyboard flag byte 1
			resb	1						;419 alternate keypad entry
			resw	1						;41A keyboard buffer head offset
			resw	1						;41C keyboard buffer tail offset
			resb	32						;41E keyboard buffer
wbFDCStatus		resb	1						;43E drive recalibration status
wbFDCControl		resb	1						;43F FDC motor status/control byte
wbFDCMotor		resb	1						;440 FDC motor timeout byte
			resb	1						;441 status of last diskette operation
			resb	7						;442 NEC diskette controller status
			resb	1						;449 current video mode
			resw	1						;44A screen columns
			resw	1						;44C video regen buffer size
			resw	1						;44E current video page offset
			resw	8						;450 cursor postions of pages 1-8
			resb	1						;460 cursor ending scanline
			resb	1						;461 cursor start scanline
			resb	1						;462 active display page number
			resw	1						;463 CRTC base port address
			resb	1						;465 CRT mode control register value
			resb	1						;466 CGA current color palette mask
			resw	1						;467 CS:IP for 286 return from PROT MODE
			resb	3						;469 vague
wfClockTicks		resd	1						;46C clock ticks
wbClockDays		resb	1						;470 clock days
			resb	1						;471 bios break flag
			resw	1						;472 soft reset
			resb	1						;474 last hard disk operation status
			resb	1						;475 hard disks attached
			resb	1						;476 XT fised disk drive control byte
			resb	1						;477 port offset to current fixed disk adapter
			resb	4						;478 LPT timeout values
			resb	4						;47C COM timeout values
			resw	1						;480 keyboard buffer start offset
			resw	1						;482 keyboard buffer end offset
			resb	1						;484 Rows on screen less 1 (EGA+)
			resb	1						;485 point height of character matrix (EGA+)
			resb	1						;486 PC Jr initial keybd delay
			resb	1						;487 EGA+ video mode ops
			resb	1						;488 EGA feature bit switches
			resb	1						;489 VGA video display data area
			resb	1						;48A EGA+ display combination code
			resb	1						;48B last diskette data rate selected
			resb	1						;48C hard disk status from controller
			resb	1						;48D hard disk error from controller
			resb	1						;48E hard disk interrupt control flag
			resb	1						;48F combination hard/floppy disk card
			resb	4						;490 drive 0,1,2,3 media state
			resb	1						;494 track currently seeked to on drive 0
			resb	1						;495 track currently seeked to on drive 1
			resb	1						;496 keyboard mode/type
			resb	1						;497 keyboard LED flags
			resd	1						;498 pointer to user wait complete flag
			resd	1						;49C user wait time-out value in microseconds
			resb	1						;4A0 RTC wait function flag
			resb	1						;4A1 LANA DMA channel flags
			resb	2						;4A2 status of LANA 0,1
			resd	1						;4A4 saved hard disk interrupt vector
			resd	1						;4A8 BIOS video save/override pointer table addr
			resb	8						;4AC reserved
			resb	1						;4B4 keyboard NMI control flags
			resd	1						;4B5 keyboard break pending flags
			resb	1						;4B9 Port 60 single byte queue
			resb	1						;4BA scan code of last key
			resb	1						;4BB NMI buffer head pointer
			resb	1						;4BC NMI buffer tail pointer
			resb	16						;4BD NMI scan code buffer
			resb	1						;4CD unknown
			resw	1						;4CE day counter
			resb	32						;4D0 unknown
			resb	16						;4F0 intra-app comm area
			resb	1						;500 print-screen status byte
			resb	3						;501 used by BASIC
			resb	1						;504 DOS single diskette mode
			resb	10						;505 POST work area
			resb	1						;50F BASIC shell flag
			resw	1						;510 BASIC default DS (DEF SEG)
			resd	1						;512 BASIC INT 1C interrupt handler
			resd	1						;516 BASIC INT 23 interrupt handler
			resd	1						;51A BASIC INT 24 interrupt handler
			resw	1						;51E unknown
			resw	1						;520 DOS dynamic storage
			resb	14						;522 DOS diskette initialization table (INT 1E)
			resb	4						;530 MODE command
			resb	460						;534 unused
			resb	256						;700 i/o drivers from io.sys/ibmbio.com
;-----------------------------------------------------------------------------------------------------------------------
;
;	OS Variables								@disk: N/A	@mem: 000800
;
;	These operating system variables are system global. They are defined at low memory address 800h and are
;	accessible by any kernel task or interrupt.
;
;-----------------------------------------------------------------------------------------------------------------------
ECONDATA		equ	($)
wfConsoleMemAddr	resd	1						;console memory address
wbConsoleColumn		resb	1						;console column
wbConsoleRow		resb	1						;console row
wbConsoleShift		resb	1						;console shift flags
wbConsoleLock		resb	1						;console lock flags
wbConsoleStatus		resb	1						;controller status
wbConsoleScan0		resb	1						;scan code
wbConsoleScan1		resb	1						;scan code
wbConsoleScan2		resb	1						;scan code
wbConsoleScan3		resb	1						;scan code
wbConsoleScan4		resb	1						;scan code
wbConsoleScan5		resb	1						;scan code
wbConsoleChar		resb	1						;ASCII code
wzConsoleInBuffer	resb	80						;command input buffer
wzConsoleToken		resb	80						;token buffer
wzConsoleOutBuffer	resb	80						;response output buffer
wsConsoleDateTime	resb	EDATETIMEL					;date-time buffer
ECONDATALEN		equ	($-ECONDATA)					;size of console data area
endstruc
;-----------------------------------------------------------------------------------------------------------------------
;
;	Macros
;
;	These macros are used to assist in defining descriptor tables and interrupt table offsets.
;
;-----------------------------------------------------------------------------------------------------------------------
%macro			mint	1
_%1			equ	($-$$) / EKRNDESLEN
			dq	((?%1 >> 16) << 32) | (EACCINT << 40) | ((ESELOSCODE & 0FFFFh) << 16) | (?%1 & 0FFFFh)
%endmacro
%macro			mtrap	1
_%1			equ	($-$$) / EKRNDESLEN
			dq	((?%1 >> 16) << 32) | (EACCTRAP << 40) | ((ESELOSCODE & 0FFFFh) << 16) | (?%1 & 0FFFFh)
%endmacro
%macro			menter	1
?%1			equ	($-$$)
%endmacro
%macro			tsvce	1
e%1			equ	($-tsvc)/4
			dd	%1
%endmacro
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
%ifdef BUILDPREP
Boot			jmp	word Prep					;jump to preparation code
%else
Boot			jmp	word Boot.10					;jump over parameter table
%endif
;-----------------------------------------------------------------------------------------------------------------------
;
;	Disk Parameter Table
;
;	The disk parameter table informs the BIOS of the floppy disk architecture. Here, we use parameters for the
;	3.5" 1.44MB floppy disk since this format is widely supported by virtual machine hypervisors.
;
;-----------------------------------------------------------------------------------------------------------------------
			db	"CustomOS"					;eight-byte label
cwSectorBytes		dw	EBOOTSECTORBYTES				;bytes per sector
cbClusterSectors	db	1						;sectors per cluster
cwReservedSectors	dw	1						;reserved sectors
cbFatCount		db	2						;file allocation table copies
cwDirEntries		dw	224						;max directory entries
cwDiskSectors		dw	EBOOTDISKSECTORS				;sectors per disk
cbDiskType		db	0F0h						;1.44MB
cwFatSectors		dw	9						;sectors per FAT copy
cbTrackSectors		equ	$						;sectors per track (as byte)
cwTrackSectors		dw	18						;sectors per track (as word)
cwDiskSides		dw	2						;sides per disk
cwSpecialSectors	dw	0						;special sectors
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
;				|  File Allocation Table (FAT) I/O Buffer	|
;				|  9x512-byte sectors = 4,608 = 1200h bytes	|
;				|						|
;			009100	+-----------------------------------------------+ DS:1600
;				|  Directory Sector Buffer & Kernel Load Area	|
;				|						|
;			009300	+-----------------------------------------------+ DS:1800
;
;	On entry, DL indicates the drive being booted from.
;
			mov	[wbDrive],dl					;[drive] = drive being booted from
;
;	Compute directory i/o buffer address.
;
			mov	ax,[cwFatSectors]				;AX = 0009 = FAT sectors
			mul	word [cwSectorBytes]				;DX:AX = 0000:1200 = FAT bytes
			add	ax,EBOOTSTACKTOP				;AX = 1600 = end of FAT buffer
			mov	[wwDirBuffer],ax				;[dirbuffer] = 1600
;
;	Compute segment where os.com will be loaded.
;
			shr	ax,cl						;AX = 0160
			add	ax,bx						;AX = 0160 + 07b0 = 0910
			sub	ax,16						;AX = 0900
			mov	[wwLoadSegment],ax				;[loadsegment] = 0900
;
;	Write a message to the console so we know we have our addressability established.
;
			mov	si,czLoadMsg					;loading message
			call	BootPrint					;display loader message
;
;	Initialize the number of directory sectors to search.
;
			mov	ax,[cwDirEntries]				;AX = 224 = max dir entries
			mov	[wwEntriesLeft],ax				;[entriesleft] = 224
;
;	Compute number of directory sectors and initialize overhead count.
;
			mov	cx,ax						;CX = 00e0 = 224 entries
			mul	word [cwEntryLen]				;DX:AX = 224 * 32 = 7168
			div	word [cwSectorBytes]				;AX = 7168 / 512 = 14 = dir sectors
			mov	[wwOverhead],ax					;[overhead] = 000e
;
;	Compute directory entries per sector.
;
			xchg	ax,cx						;DX:AX = 0:00e0, DX = 0000e
			div	cx						;AX = 0010 = entries per dir sector
			mov	[wwSectorEntries],ax				;[sectorentries] = 0010
;
;	Compute first logical directory sector and update overhead count.
;
			mov	ax,[cwFatSectors]				;AX = 0009 = FAT sectors per copy
			mul	byte [cbFatCount]				;AX = 0012 = FAT sectors
			add	ax,[cwReservedSectors]				;AX = 0013 = FAT plus reserved
			add	ax,[cwSpecialSectors]				;AX = 0013 = FAT + reserved + special
			mov	[wwLogicalSector],ax				;[logicalsector] = 0013
			add	[wwOverhead],ax					;[overhead] = 0021 = res+spec+FAT+dir
;
;	Read directory sector.
;
.30			mov	al,1						;sector count
			mov	[wbReadCount],al				;[readcount] = 01
			mov	bx,[wwDirBuffer]				;BX = 1600
			call	ReadSector					;read sector into es:bx
;
;	Setup variables to search this directory sector.
;
			mov	ax,[wwEntriesLeft]				;directory entries to search
			cmp	ax,[wwSectorEntries]				;need to search more sectors?
			jna	.40						;no, continue
			mov	ax,[wwSectorEntries]				;yes, limit search to sector
.40			sub	[wwEntriesLeft],ax				;update entries left to searh
			mov	si,cbKernelProgram				;program name
			mov	di,[wwDirBuffer]				;DI = 1600
;
;	Loop through directory sectors searching for kernel program.
;
.50			push	si						;save kernel name address
			push	di						;save dir i/o buffer address
			mov	cx,11						;length of 8+3 name
			cld							;forward strings
			repe	cmpsb						;compare entry name
			pop	di						;restore dir i/o buffer address
			pop	si						;restore kernel name address
			je	.60						;exit loop if found
			add	di,[cwEntryLen]					;point to next dir entry
			dec	ax						;decrement remaining entries
			jnz	.50						;next entry
;
;	Repeat search if we are not at the end of the directory.
;
			inc	word [wwLogicalSector]				;increment logical sector
			cmp	word [wwEntriesLeft],0				;done with directory?
			jne	.30						;no, get next sector
			mov	si,czNoKernel					;missing kernel message
			jmp	BootExit					;display message and exit
;
;	If we find the kernel program in the directory, read the FAT.
;
.60			mov	ax,[cwReservedSectors]				;AX = 0001
			mov	[wwLogicalSector],ax				;start past boot sector
			mov	ax,[cwFatSectors]				;AX = 0009
			mov	[wbReadCount],al				;[readcount] = 09
			mov	bx,EBOOTSTACKTOP				;BX = 0400
			call	ReadSector					;read FAT into buffer
;
;	Get the starting cluster of the kernel program and target address.
;
			mov	ax,[di+26]					;AX = starting cluster of file
			les	bx,[wwLoadOffset]				;ES:BX = kernel load address
;
;	Read each program cluster into RAM.
;
.70			push	ax						;save cluster nbr
			sub	ax,2						;AX = cluster nbr base 0
			mov	cl,[cbClusterSectors]				;CL = sectors per cluster
			mov	[wbReadCount],cl				;save sectors to read
			xor	ch,ch						;CX = sectors per cluster
			mul	cx						;DX:AX = logical cluster sector
			add	ax,[wwOverhead]					;AX = kernel sector nbr
			mov	[wwLogicalSector],ax				;save logical sector nbr
			call	ReadSector					;read sectors into es:bx
;
;	Update buffer pointer for next cluster.
;
			mov	al,[cbClusterSectors]				;AL = sectors per cluster
			xor	ah,ah						;AX = sectors per cluster
			mul	word [cwSectorBytes]				;DX:AX = cluster bytes
			add	bx,ax						;BX = next cluster target address
			pop	ax						;AX = restore cluster nbr
;
;	Compute next cluster number.
;
			mov	cx,ax						;CX = cluster nbr
			mov	di,ax						;DI = cluster nbr
			shr	ax,1						;AX = cluster/2
			mov	dx,ax						;DX = cluster/2
			add	ax,dx						;AX = 2*(cluster/2)
			add	ax,dx						;AX = 3*(cluster/2)
			and	di,1						;get low bit
			add	di,ax						;add one if cluster is odd
			add	di,EBOOTSTACKTOP				;add FAT buffer address
			mov	ax,[di]						;get cluster bytes
;
;	Adjust cluster nbr by 4 bits if cluster is odd; test for end of chain.
;
			test	cl,1						;is cluster odd?
			jz	.80						;no, skip ahead
			mov	cl,4						;shift count
			shr	ax,cl						;shift nybble low
.80			and	ax,0FFFh					;mask for 24 bits; next cluster nbr
			cmp	ax,0FFFh					;end of chain?
			jne	.70						;no, continue
;
;	Transfer control to the operating system program.
;
			db	0EAh						;jmp seg:offset
wwLoadOffset		dw	0100h						;kernel entry offset
wwLoadSegment		dw	0900h						;kernel entry segment (computed)
;
;	Read [readcount] disk sectors from [logicalsector] into ES:BX.
;
ReadSector		mov	ax,[cwTrackSectors]				;AX = sectors per track
			mul	word [cwDiskSides]				;DX:AX = sectors per cylinder
			mov	cx,ax						;CX = sectors per cylinder
			mov	ax,[wwLogicalSector]				;DX:AX = logical sector
			div	cx						;AX = cylinder; DX = cyl sector
			mov	[wbTrack],al					;[track] = cylinder
			mov	ax,dx						;AX = cyl sector
			div	byte [cbTrackSectors]				;AH = sector, AL = head
			inc	ah						;AH = sector (1,2,3,...)
			mov	[wbHead],ax					;[head]= head, [sector]= sector
;
;	Try maxtries times to read sector.
;
			mov	cx,EMAXTRIES					;CX = 0005
.10			push	bx						;save buffer address
			push	cx						;save retry count
			mov	dx,[wwDriveHead]				;DH = head, DL = drive
			mov	cx,[wwSectorTrack]				;CH = track, CL = sector
			mov	ax,[wwReadCountCommand]				;AH = fn., AL = sector count
			int	EBIOSINTDISKETTE				;read sector
			pop	cx						;restore retry count
			pop	bx						;restore buffer address
			jnc	BootReturn					;skip ahead if done
			loop	.10						;retry
;
;	Handle disk error: convert to ASCII and store in error string.
;
			mov	al,ah						;AL = bios error code
			xor	ah,ah						;AX = bios error code
			mov	dl,16						;divisor for base 16
			div	dl						;AL = hi order, AH = lo order
			or	ax,3030h					;apply ASCII zone bits
			cmp	ah,3Ah						;range test ASCII numeral
			jb	.20						;continue if numeral
			add	ah,7						;adjust for ASCII 'A'-'F'
.20			cmp	al,3Ah						;range test ASCII numeral
			jb	.30						;continue if numeral
			add	ah,7						;adjust for ASCII 'A'-'F'
.30			mov	[wzErrorCode],ax				;store ASCII error code
			mov	si,czErrorMsg					;error message address
BootExit		call	BootPrint					;display messge to console
.10			mov	ah,EBIOSFNKEYSTATUS				;bios keyboard status function
			int	EBIOSINTKEYBOARD				;get keyboard status
			jnz	.20						;continue if key pressed
			sti							;enable maskable interrupts
			hlt							;wait for interrupt
			jmp	.10						;repeat
.20			mov	al,EKEYCMDRESET					;8042 pulse output port pin
			out	EKEYPORTSTAT,al					;drive B0 low to restart
.30			sti							;enable maskable interrupts
			hlt							;stop until reset, int, nmi
			jmp	.30						;loop until restart kicks in
;
;	Display text message.
;
BootPrint		cld							;forward strings
			lodsb							;load next byte at DS:SI in AL
			test	al,al						;end of string?
			jz	BootReturn					;... yes, exit our loop
			mov	ah,EBIOSFNTTYOUTPUT				;BIOS teletype function
			int	EBIOSINTVIDEO					;call BIOS display interrupt
			jmp	BootPrint					;repeat until done
BootReturn		ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Constants
;
;-----------------------------------------------------------------------------------------------------------------------
			align	2
cwEntryLen		dw	32						;length of directory entry
cbKernelProgram		db	"OS      COM"					;kernel program name
czLoadMsg		db	"Loading ...",13,10,0				;loading message
czErrorMsg		db	"Disk error "					;error message
wzErrorCode		db	20h,20h,0					;error code and null terminator
czNoKernel		db	"OS.COM missing",0				;missing kernel message
;-----------------------------------------------------------------------------------------------------------------------
;
;	Work Areas
;
;-----------------------------------------------------------------------------------------------------------------------
			align	2
wwDirBuffer		dw	0						;directory i/o buffer address
wwEntriesLeft		dw	0						;directory entries to search
wwOverhead		dw	0						;overhead sectors
wwSectorEntries		dw	0						;directory entries per sector
wwLogicalSector		dw	0						;current logical sector
wwReadCountCommand	equ	$						;read count and command
wbReadCount		db	0						;sectors to read
cbReadCommand		db	2						;BIOS read disk fn code
wwDriveHead		equ	$						;drive, head (word)
wbDrive			db	0						;drive
wbHead			db	0						;head
wwSectorTrack		equ	$						;sector, track (word)
			db	0						;sector
wbTrack			db	0						;track
			times	510-($-$$) db 0h				;zero fill to end of sector
			db	055h,0AAh					;end of sector signature
%endif
%ifdef BUILDPREP
;-----------------------------------------------------------------------------------------------------------------------
;
;	Diskette Preparation Code
;
;	This routine writes the OS boot sector code to a formatted floppy diskette. The diskette parameter table,
;	which is located in the first 30 bytes of the boot sector is first read from the diskette and overlayed onto
;	the OS bootstrap code so that the diskette format parameters are preserved.
;
;-----------------------------------------------------------------------------------------------------------------------
;
;	Query the user to insert a flopppy diskette and press enter or cancel.
;
Prep			mov	si,czPrepMsg10					;starting message address
			call	BootPrint					;display message
;
;	Exit if the Escape key is pressed or loop until Enter is pressed.
;
.10			mov	ah,EBIOSFNKEYSTATUS				;BIOS keyboard status function
			int	EBIOSINTKEYBOARD				;get keyboard status
			jnz	.12						;continue if key pressed
			sti							;enable interrupts
			hlt							;wait for interrupt
			jmp	.10						;repeat
.12			cmp	al,EASCIIRETURN					;Enter key pressed?
			je	.15						;yes, branch
			cmp	al,EASCIIESCAPE					;Escape key pressed?
			jne	.10						;no, repeat
			jmp	.90						;yes, exit program
;
;	Display writing-sector message and patch the JMP instruction.
;
.15			mov	si,czPrepMsg12					;writing-sector message address
			call	BootPrint					;display message
			mov	bx,Boot+1					;address of JMP instruction operand
			mov	ax,01Bh						;address past disk parameter table
			mov	[bx],ax						;update the JMP instruction
;
;	Try to read the boot sector.
;
			mov	cx,EMAXTRIES					;try up to five times
.20			push	cx						;save remaining tries
			mov	bx,wcPrepInBuf					;input buffer address
			mov	dx,0						;head zero, drive zero
			mov	cx,1						;track zero, sector one
			mov	ax,0201h					;read one sector
			int	EBIOSINTDISKETTE				;attempt the read
			pop	cx						;restore remaining retries
			jnc	.30						;skip ahead if successful
			loop	.20						;try again
			mov	si,czPrepMsg20					;read-error message address
			jmp	.50						;branch to error routine
;
;	Copy diskette parms from input buffer to output buffer.
;
.30			mov	si,wcPrepInBuf					;input buffer address
			add	si,11						;skip over JMP and system ID
			mov	di,Boot						;output buffer address
			add	di,11						;skip over JMP and system ID
			mov	cx,19						;length of diskette parameters
			cld							;forward string copies
			rep	movsb						;copy diskette parameters
;
;	Try to write boot sector to diskette.
;
			mov	cx,EMAXTRIES					;try up to five times
.40			push	cx						;save remaining tries
			mov	bx,Boot						;output buffer address
			mov	dx,0						;head zero, drive zero
			mov	cx,1						;track zero, sector one
			mov	ax,0301h					;write one sector
			int	EBIOSINTDISKETTE				;attempt the write
			pop	cx						;restore remaining retries
			jnc	.80						;skip ahead if successful
			loop	.40						;try again
			mov	si,czPrepMsg30					;write-error message address
;
;	Convert the error code to ASCII and display the error message.
;
.50			push	ax						;save error code
			mov	al,ah						;copy error code
			mov	ah,0						;AX = error code
			mov	dl,10h						;hexadecimal divisor
			idiv	dl						;AL = hi-order, AH = lo-order
			or	ax,3030h					;add ASCII zone digits
			cmp	ah,3Ah						;AH ASCII numeral?
			jb	.60						;yes, continue
			add	ah,7						;no, make ASCII 'A'-'F'
.60			cmp	al,3Ah						;al ASCII numeral?
			jb	.70						;yes, continue
			add	al,7						;no, make ASCII
.70			mov	[si+17],ax					;put ASCII error code in message
			call	BootPrint					;write error message
			pop	ax						;restore error code
;
;	Display the completion message.
;
.80			mov	si,czPrepMsgOK					;assume successful completion
			mov	al,ah						;BIOS return code
			cmp	al,0						;success?
			je	.85						;yes, continue
			mov	si,czPrepMsgErr1				;disk parameter error message
			cmp	al,1						;disk parameter error?
			je	.85						;yes, continue
			mov	si,czPrepMsgErr2				;address mark not found message
			cmp	al,2						;address mark not found?
			je	.85						;yes, continue
			mov	si,czPrepMsgErr3				;protected disk message
			cmp	al,3						;protected disk?
			je	.85						;yes, continue
			mov	si,czPrepMsgErr6				;diskette removed message
			cmp	al,6						;diskette removed?
			je	.85						;yes, continue
			mov	si,czPrepMsgErr80				;drive timed out message
			cmp	al,80H						;drive timed out?
			je	.85						;yes, continue
			mov	si,czPrepMsgErrXX				;unknown error message
.85			call	BootPrint					;display result message
.90			mov	ax,4C00H					;terminate with zero result code
			int	21h						;terminate DOS program
			ret							;return (should not execute)
;-----------------------------------------------------------------------------------------------------------------------
;
;	Diskette Preparation Messages
;
;-----------------------------------------------------------------------------------------------------------------------
czPrepMsg10		db	13,10,"CustomOS Boot-Diskette Preparation Program"
			db	13,10,"Copyright (C) 2010-2017 David J. Walling. All rights reserved."
			db	13,10
			db	13,10,"This program overwrites the boot sector of a diskette with startup code that"
			db	13,10,"will load the operating system into memory when the computer is restarted."
			db	13,10,"To proceed, place a formatted diskette into drive A: and press the Enter key."
			db	13,10,"To exit this program without preparing a diskette, press the Escape key."
			db	13,10,0
czPrepMsg12		db	13,10,"Writing the boot sector to the diskette ..."
			db	13,10,0
czPrepMsg20		db	13,10,"The error-code .. was returned from the BIOS while reading from the disk."
			db	13,10,0
czPrepMsg30		db	13,10,"The error-code .. was returned from the BIOS while writing to the disk."
			db	13,10,0
czPrepMsgOK		db	13,10,"The boot-sector was written to the diskette. Before booting your computer with"
			db	13,10,"this diskette, make sure that the file OS.COM is copied onto the diskette."
			db	13,10,0
czPrepMsgErr1		db	13,10,"(01) Invalid Disk Parameter"
			db	13,10,"This is an internal error caused by an invalid value being passed to a system"
			db	13,10,"function. The OSBOOT.COM file may be corrupt. Copy or download the file again"
			db	13,10,"and retry."
			db	13,10,0
czPrepMsgErr2		db	13,10,"(02) Address Mark Not Found"
			db	13,10,"This error indicates a physical problem with the floppy diskette. Please retry"
			db	13,10,"using another diskette."
			db	13,10,0
czPrepMsgErr3		db	13,10,"(03) Protected Disk"
			db	13,10,"This error is usually caused by attempting to write to a write-protected disk."
			db	13,10,"Check the 'write-protect' setting on the disk or retry using using another disk."
			db	13,10,0
czPrepMsgErr6		db	13,10,"(06) Diskette Removed"
			db	13,10,"This error may indicate that the floppy diskette has been removed from the"
			db	13,10,"diskette drive. On some systems, this code may also occur if the diskette is"
			db	13,10,"'write protected.' Please verify that the diskette is not write-protected and"
			db	13,10,"is properly inserted in the diskette drive."
			db	13,10,0
czPrepMsgErr80		db	13,10,"(80) Drive Timed Out"
			db	13,10,"This error usually indicates that no diskette is in the diskette drive. Please"
			db	13,10,"make sure that the diskette is properly seated in the drive and retry."
			db	13,10,0
czPrepMsgErrXX		db	13,10,"(??) Unknown Error"
			db	13,10,"The error-code returned by the BIOS is not a recognized error. Please consult"
			db	13,10,"your computer's technical reference for a description of this error code."
			db	13,10,0
wcPrepInBuf		equ	$
%endif
%ifdef BUILDDISK
;-----------------------------------------------------------------------------------------------------------------------
;
;	File Allocation Tables
;
;	The disk contains two copies of the File Allocation Table (FAT). On our disk, each FAT copy is 1200h bytes in
;	length. Each FAT entry contains the logical number of the next cluster. The first two entries are reserved. Our
;	OS.COM file will be 5200h bytes in length. The first 200h bytes is the 16-bit loader code. The remaining 5000h
;	bytes is the 32-bit kernel code. Our disk parameter table defines a cluster as containing one sector and each
;	sector having 200h bytes. Therefore, our FAT table must reserve 41 clusters for OS.COM. The clusters used by
;	OS.COM, then, will be cluster 2 through 43. The entry for cluster 43 is set to "0FFFh" to indicate that it is
;	the last cluster in the chain.
;
;	Every three bytes encode two FAT entries as follows:
;
;	db	0abh,0cdh,0efh	;even cluster: 0dabh, odd cluster: 0efch
;
;-----------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------
;
;	FAT copy 1								@disk: 000200	@mem: n/a
;
;-----------------------------------------------------------------------------------------------------------------------
section			fat1							;first copy of FAT
			db	0F0h,0FFh,0FFh,	003h,040h,000h
			db	005h,060h,000h,	007h,080h,000h
			db	009h,0A0h,000h,	00Bh,0C0h,000h
			db	00Dh,0E0h,000h,	00Fh,000h,001h
			db	011h,020h,001h,	013h,040h,001h
			db	015h,060h,001h,	017h,080h,001h
			db	019h,0A0h,001h,	01Bh,0C0h,001h
			db	01Dh,0E0h,001h,	01Fh,000h,002h
			db	021h,020h,002h,	023h,040h,002h
			db	025h,060h,002h,	027h,080h,002h
			db	029h,0A0h,002h,	0FFh,00Fh,000h
			times	(9*512)-($-$$) db 0				;zero fill to end of section
;-----------------------------------------------------------------------------------------------------------------------
;
;	FAT copy 2								@disk: 001400	@mem: n/a
;
;-----------------------------------------------------------------------------------------------------------------------
section			fat2							;second copy of FAT
			db	0F0h,0FFh,0FFh,	003h,040h,000h
			db	005h,060h,000h,	007h,080h,000h
			db	009h,0A0h,000h,	00Bh,0C0h,000h
			db	00Dh,0E0h,000h,	00Fh,000h,001h
			db	011h,020h,001h,	013h,040h,001h
			db	015h,060h,001h,	017h,080h,001h
			db	019h,0A0h,001h,	01Bh,0C0h,001h
			db	01Dh,0E0h,001h,	01Fh,000h,002h
			db	021h,020h,002h,	023h,040h,002h
			db	025h,060h,002h,	027h,080h,002h
			db	029h,0A0h,002h,	0FFh,00Fh,000h
			times	(9*512)-($-$$) db 0				;zero fill to end of section
;-----------------------------------------------------------------------------------------------------------------------
;
;	Diskette Directory							@disk: 002600	@mem: n/a
;
;	The disk contains one copy of the diskette directory. Each directory entry is 32 bytes long. Our directory
;	contains only one entry. Unused entries are set to all nulls. The directory immediately follows the second FAT
;	copy.
;
;-----------------------------------------------------------------------------------------------------------------------
section			dir							;diskette directory
			db	"OS      COM"					;file name (must contain spaces)
			db	20h						;attribute (archive bit set)
			times	10 db 0;					;unused
			dw	0h						;time
			db	01000001b					;mmm = 10 MOD 8 = 2; ddddd = 1
			db	01001001b					;yyyyyyy = 2016-1980 = 36 = 24h; m/8 = 1
			dw	2						;first cluster
			dd	5200h						;file size
			times	(224*32)-($-$$) db 0h				;zero fill to end of section
%endif
%ifdef BUILDCOM
;-----------------------------------------------------------------------------------------------------------------------
;
;	OS.COM
;
;	The operating system file is assembled at the start of the data area of the floppy disk image, which
;	immediately follows the directory. This corresponds to logical cluster 2, even though the physical address of
;	this sector on the disk varies depending on the disk type. The os.com file consists of two parts, the OS loader
;	and the OS kernel. The Loader is 16-bit code that receives control directly from the boot sector code after the
;	OS.COM file is loaded into memory. The kernel is 32-bit code that receives control after the Loader has
;	initialized protected-mode tables and 32-bit interrupt handlers and switched the CPU into protected mode.
;
;	Our loader addressability is set up according to the following diagram.
;
;	SS -----------> 007b00	+-----------------------------------------------+ SS:0000
;				|  Boot Sector & Loader Stack Area		|
;				|						|
;	SS:SP -------->	007f00	+-----------------------------------------------+ SS:0400
;
;
;	CS,DS,ES ----->	009000	+-----------------------------------------------+ CS:0000
;				|  Unused (DOS Program Segment Prefix)		|
;	CS:IP -------->	009100	+-----------------------------------------------+ CS:0100
;				|  Loader Code					|
;				|						|
;			009300	+-----------------------------------------------+ CS:0200
;
;-----------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------
;
;	OS Loader								@disk: 004200	@mem: 009100
;
;	This code is the operating system loader. It resides on the boot disk at the start of the data area, following
;	the directory. The loader occupies several clusters that are mapped in the file allocation tables above. The
;	size of the loader is limited to 65,280 bytes since the bootstrap will copy the loader into memory at 0:9100.
;	The loader executes 16-bit instructions in real mode. It performs several initialization functions such as
;	determining whether the CPU and other resources are sufficient to run the operating system. If all minimum
;	resources are present, the loader initializes protected mode tables, places the CPU into protected mode and
;	starts the kernel task. Since the loader was called either from the bootstrap or as a .com file on the boot
;	disk, we can assume that the initial ip is 0x100 and not perform any absolute address fix-ups on our segment
;	registers.
;
;-----------------------------------------------------------------------------------------------------------------------
			cpu	8086						;assume minimal CPU
section			loader	vstart=100h					;use .COM compatible addressing
			bits	16						;this is 16-bit code
Loader			push	cs						;use the code segment
			pop	ds						;...as our data segment
			push	cs						;use the code segment
			pop	es						;...as our extra segment
;
;	Write a message to the console so we know we have our addressability established.
;
			mov	si,czStartingMsg				;starting message
			call	PutTTYString					;display loader message
;
;	Determine the CPU type, generally. Exit if the CPU is not at least an 80386.
;
			call	GetCPUType					;AL = cpu type
			mov	si,czCPUErrorMsg				;loader error message
			cmp	al,3						;80386+?
			jb	LoaderExit					;no, exit with error message
			cpu	386						;allow 80386 instructions
			mov	si,czCPUOKMsg					;cpu ok message
			call	PutTTYString					;display message
;
;	Fixup the GDT descriptor for the current (loader) code segment.
;
			mov	si,300h						;GDT offset
			mov	ax,cs						;AX:SI = gdt source
			rol	ax,4						;AX = phys addr bits 11-0,15-12
			mov	cl,al						;CL = phys addr bits 3-0,15-12
			and	al,0F0h						;AL = phys addr bits 11-0
			and	cl,00Fh						;CL = phys addr bits 15-12
			mov	word [si+30h+2],ax				;lo-order loader code (0-15)
			mov	byte [si+30h+4],cl				;lo-order loader code (16-23)
			mov	si,czGDTOKMsg					;GDT prepared message
			call	PutTTYString					;display message
;
;	Move the 32-bit kernel to its appropriate memory location.
;
			push	EKRNSEG						;use kernel segment ...
			pop	es						;... as target segment
			xor	di,di						;ES:DI = target address
			mov	si,300h						;DS:SI = source address
			mov	cx,5000h					;CX = kernel size
			cld							;forward strings
			rep	movsb						;copy kernel image
			mov	si,czKernelLoadedMsg				;kernel moved message
			call	PutTTYString					;display message
;
;	Switch to protected mode.
;
			xor	si,si						;ES:SI = gdt addr
			mov	ss,si						;protected mode ss
			mov	sp,1000h					;SS:SP = protected mode ss:sp
			mov	ah,EBIOSFNINITPROTMODE				;initialize protected mode fn.
			mov	bx,2028h					;BH,BL = IRQ int bases
			mov	dx,001Fh					;outer delay loop count
.10			mov	cx,0FFFFh					;inner delay loop count
			loop	$						;wait out pending interrupts
			dec	dx						;restore outer loop count
			jnz	.10						;continue outer loop
			int	EBIOSINTMISC					;call BIOS to set protected mode
;
;	Enable hardware and maskable interrupts
;
			xor	al,al						;enable all registers code
			out	EPICPORTPRI1,al					;enable all primary 8259A ints
			out	EPICPORTSEC1,al					;enable all secondary 8259A ints
			sti							;enable maskable interrupts
;
;	Load the Task State Segment (TSS) and Local Descriptor Table (LDT) registers and jump to the initial task.
;
			ltr	[cs:cwLoaderTSS]				;load task register
			lldt	[cs:cwLoaderLDT]				;load local descriptor table register
			jmp	0058h:0						;jump to task state segment selector
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	LoaderExit
;
;	Description:	This routine displays the message at DS:SI, waits for a keypress and resets the system.
;
;	In:		DS:SI	string address
;
;-----------------------------------------------------------------------------------------------------------------------
LoaderExit		call	PutTTYString					;display error message
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
			jmp	.30						;repeat until keypress
;
;	Now that a key has been pressed, we signal the system to restart by driving the B0 line on the 8042
;	keyboard controller low (OUT 64h,0feh). The restart may take some microseconds to kick in, so we issue
;	HLT until the system resets.
;
.40			mov	al,EKEYCMDRESET					;8042 pulse output port pin
			out	EKEYPORTSTAT,al					;drive B0 low to restart
.50			sti							;enable maskable interrupts
			hlt							;stop until reset, int, nmi
			jmp	.50						;loop until restart kicks in
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	GetCPUType
;
;	Description:	The loader needs only to determine that the cpu is at least an 80386 or an equivalent. Note that
;			the CPUID instruction was not introduced until the SL-enhanced 80486 and Pentium processors, so
;			to distinguish whether we have at least an 80386, other means must be used.
;
;	Output:		AX	0 = 808x, v20, etc.
;				1 = 80186
;				2 = 80286
;				3 = 80386
;
;-----------------------------------------------------------------------------------------------------------------------
GetCPUType		mov	al,1						;AL = 1
			mov	cl,32						;shift count
			shr	al,cl						;try a 32-bit shift
			or	al,al						;did the shift happen?
			jz	.10						;yes, cpu is 808x, v20, etc.
			cpu	186
			push	sp						;save stack pointer
			pop	cx						;...into cx
			cmp	cx,sp						;did sp decrement before push?
			jne	.10						;yes, cpu is 80186
			cpu	286
			inc	ax						;AX = 2
			sgdt	[cbLoaderGDT]					;store gdt reg in work area
			mov	cl,[cbLoaderGDTHiByte]				;cl = hi-order byte
			inc	cl						;was hi-byte of GDTR 0xff?
			jz	.10						;yes, cpu is 80286
			inc	ax						;AX = 3
.10			ret							;return
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
			jmp	PutTTYString					;repeat until done
.10			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Loader Data
;
;	The loader data is updated to include constants defining the initial (Loader) TSS and LDT selectors in the
;	GDT, a work area to build the GDTR, and additional text messages.
;
;-----------------------------------------------------------------------------------------------------------------------
			align	2
cwLoaderTSS		dw	0068h						;TSS selector
cwLoaderLDT		dw	0060h						;LDT selector
cbLoaderGDT		times	5 db 0						;6-byte GDTR work area
cbLoaderGDTHiByte	db	0						;hi-order byte
czCPUErrorMsg		db	"The operating system requires an i386 "
			db	"or later processor.",13,10,
			db	"Please press any key to restart the "
			db	"computer.",13,10,0
czCPUOKMsg		db	"CPU ok",13,10,0
czGDTOKMsg		db	"GDT prepared",13,10,0
czKernelLoadedMsg	db	"Kernel loaded",13,10,0
czStartingMsg		db	"Starting ...",13,10,0				;loader message
			times	510-($-$$) db 0h				;zero fill to end of sector
			db	055h,0AAh					;end of sector signature
;-----------------------------------------------------------------------------------------------------------------------
;
;	OS Kernel								@disk: 004400	@mem: 001000
;
;	This code is the operating system kernel. It resides on the boot disk image as part of the OS.COM file,
;	following the 16-bit loader code above. The Kernel executes only 32-bit code in protected mode and contains one
;	task, the Console, which performs a loop accepting user input from external devices (keyboard, etc.), processes
;	commands and displays ouput to video memory. The Kernel also includes a library of system functions accessible
;	through software interrupt 58 (30h). Finally, the Kernel provides CPU and hardware interrupt handlers.
;
;-----------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------
;
;	Tables
;
;-----------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------
;
;	Global Descriptor Table							@disk: 004400	@mem: 001000
;
;	The Global Descriptor Table (GDT) consists of eight-byte descriptors that define reserved memory areas. The
;	first descriptor must be all nulls.
;
;	6   5         4         3         2         1         0
;	3210987654321098765432109876543210987654321098765432109876543210
;	----------------------------------------------------------------
;	h......hffffmmmma......ab......................bn..............n
;	00000000			all areas have base addresses below 2^24
;	        0100     		(0x4) 32-bit single-byte granularity
;		1100    		(0xC) 32-bit 4KB granularity
;	            1001		present, ring-0, selector
;
;	h...h	hi-order base address (bits 24-31)
;	ffff	flags
;	mmmm	hi-order limit (bits 16-19)
;	a...a	access
;	b...b	lo-order base address (bits 0-23)
;	n...n	lo-order limit (bits 0-15)
;
;-----------------------------------------------------------------------------------------------------------------------
section			gdt							;global descriptor table
			dq	0000000000000000h				;00 required null selector
			dq	00409300100007FFh				;08 2KB  writable data (GDT)
			dq	00409300180007FFh				;10 2KB  writable data (IDT)
			dq	00CF93000000FFFFh				;18 4GB  writable data (OS data)
			dq	0040930B80000FFFh				;20 4KB  writable data (CGA video)
			dq	0040930000000FFFh				;28 4KB  writable data (Loader stack)
			dq	00009B000000FFFFh				;30 64KB readable 16-bit code (Loader)
			dq	00009BFF0000FFFFh				;38 64KB readable 16-bit code (BIOS)
			dq	004093000400FFFFh				;40 64KB writable data (BIOS data)
			dq	00409B0020001FFFh				;48 8KB  readable code (OS code)
			dq	004082004700007Fh				;50 80B  writable system (Console LDT)
			dq	004089004780007Fh				;58 80B  writable system (Console TSS)
			dq	004082000F00007Fh				;60 80B  writable system (Loader LDT)
			dq	004089000F80007Fh				;68 80B  writable system (Loader TSS)
			times	2048-($-$$) db 0h				;zero fill to end of section
;-----------------------------------------------------------------------------------------------------------------------
;
;	Interrupt Descriptor Table						@disk: 004C00	@mem: 001800
;
;	The Interrupt Descriptor Table (IDT) consists of one eight-byte entry (descriptor) for each interrupt. The
;	descriptors here are of two kinds, interrupt gates and trap gates. The "mint" and "mtrap" macros define the
;	descriptors, taking only the name of the entry point for the code handling the interrupt.
;
;	6   5         4         3         2         1         0
;	3210987654321098765432109876543210987654321098765432109876543210
;	----------------------------------------------------------------
;	h..............hPzzStttt00000000S..............Sl..............l
;
;	h...h	high-order offset (bits 16-31)
;	P	present (0=unused interrupt)
;	zz	descriptor privilege level
;	S	storage segment (must be zero for IDT)
;	tttt	type: 0101=task, 1110=int, 1111=trap
;	S...S	handling code selector in GDT
;	l...l	lo-order offset (bits 0-15)
;
;-----------------------------------------------------------------------------------------------------------------------
section			idt							;interrupt descriptor table
			mint	dividebyzero					;00 divide by zero
			mint	singlestep					;01 single step
			mint	nmi						;02 non-maskable
			mint	break						;03 break
			mint	into						;04 into
			mint	bounds						;05 bounds
			mint	badopcode					;06 bad op code
			mint	nocoproc					;07 no coprocessor
			mint	doublefault					;08 double-fault
			mint	operand						;09 operand
			mint	badtss						;0A bad TSS
			mint	notpresent					;0B not-present
			mint	stacklimit					;0C stack limit
			mint	protection					;0D general protection fault
			mint	int14						;0E (reserved)
			mint	int15						;0F (reserved)
			mint	coproccalc					;10 (reserved)
			mint	int17						;11 (reserved)
			mint	int18						;12 (reserved)
			mint	int19						;13 (reserved)
			mint	int20						;14 (reserved)
			mint	int21						;15 (reserved)
			mint	int22						;16 (reserved)
			mint	int23						;17 (reserved)
			mint	int24						;18 (reserved)
			mint	int25						;19 (reserved)
			mint	int26						;1A (reserved)
			mint	int27						;1B (reserved)
			mint	int28						;1C (reserved)
			mint	int29						;1D (reserved)
			mint	int30						;1E (reserved)
			mint	int31						;1F (reserved)
			mtrap	clocktick					;20 IRQ0 clock tick
			mtrap	keyboard					;21 IRQ1 keyboard
			mtrap	iochannel					;22 IRQ2 second 8259A cascade
			mtrap	com2						;23 IRQ3 com2
			mtrap	com1						;24 IRQ4 com1
			mtrap	lpt2						;25 IRQ5 lpt2
			mtrap	diskette					;26 IRQ6 diskette
			mtrap	lpt1						;27 IRQ7 lpt1
			mtrap	rtclock						;28 IRQ8 real-time clock
			mtrap	retrace						;29 IRQ9 CGA vertical retrace
			mtrap	irq10						;2A IRQA (reserved)
			mtrap	irq11						;2B IRQB (reserved)
			mtrap	ps2mouse					;2C IRQC ps/2 mouse
			mtrap	coprocessor					;2D IRQD coprocessor
			mtrap	fixeddisk					;2E IRQE fixed disk
			mtrap	irq15						;2F IRQF (reserved)
			mtrap	svc						;30 OS services
			times	2048-($-$$) db 0h				;zero fill to end of section
;-----------------------------------------------------------------------------------------------------------------------
;
;	Interrupt Handlers							@disk: 005400	@mem:  002000
;
;	Interrupt handlers are 32-bit routines that receive control either in response to events or by direct
;	invocation from other kernel code. The interrupt handlers are of three basic types. CPU interrupts occur when a
;	CPU exception is detected. Hardware interrupts occur when an external device (timer, keyboard, disk, etc.)
;	signals the CPU on an interrupt request line. Software interrupts occur when directly called by other code
;	using the INT instruction. Each interrupt handler routine is defined by using our "menter" macro, which simply
;	establishes a label defining the offset address of the entry point from the start of the kernel section. This
;	label is referenced in the "mint" and "mtrap" macros found in the IDT to specify the address of the handlers.
;
;-----------------------------------------------------------------------------------------------------------------------
section			kernel	vstart=0h					;data offsets relative to 0
			cpu	386						;allow 80386 instructions
			bits	32						;this is 32-bit code
;-----------------------------------------------------------------------------------------------------------------------
;
;	CPU Interrupt Handlers
;
;	The first 32 entries in the Interrupt Descriptor Table are reserved for use by CPU interrupts.
;
;-----------------------------------------------------------------------------------------------------------------------
			menter	dividebyzero					;divide by zero
			push	0						;
			jmp	intcpu						;
			menter	singlestep					;single step
			push	1						;
			jmp	intcpu						;
			menter	nmi						;non-maskable
			push	2						;
			jmp	intcpu						;
			menter	break						;break
			push	3						;
			jmp	intcpu						;
			menter	into						;into
			push	4						;
			jmp	intcpu						;
			menter	bounds						;bounds
			push	5						;
			jmp	intcpu						;
			menter	badopcode					;bad opcode interrupt
			push	6						;
			jmp	intcpu						;
			menter	nocoproc					;no coprocessor interrupt
			push	7						;
			jmp	intcpu						;
			menter	doublefault					;doublefault interrupt
			push	8						;
			jmp	intcpu						;
			menter	operand						;operand interrupt
			push	9						;
			jmp	intcpu						;
			menter	badtss						;bad tss interrupt
			push	10						;
			jmp	intcpu						;
			menter	notpresent					;not present interrupt
			push	11						;
			jmp	intcpu						;
			menter	stacklimit					;stack limit interrupt
			push	12						;
			jmp	intcpu						;
			menter	protection					;protection fault interrupt
			push	13						;
			jmp	intcpu						;
			menter	int14						;(reserved)
			push	14						;
			jmp	intcpu						;
			menter	int15						;(reserved)
			push	15						;
			jmp	intcpu						;
			menter	coproccalc					;coprocessor calculation
			push	16						;
			jmp	intcpu						;
			menter	int17						;(reserved)
			push	17						;
			jmp	intcpu						;
			menter	int18						;(reserved)
			push	18						;
			jmp	intcpu						;
			menter	int19						;(reserved)
			push	19						;
			jmp	intcpu						;
			menter	int20						;(reserved)
			push	20						;
			jmp	intcpu						;
			menter	int21						;(reserved)
			push	21						;
			jmp	intcpu						;
			menter	int22						;(reserved)
			push	22						;
			jmp	intcpu						;
			menter	int23						;(reserved)
			push	23						;
			jmp	intcpu						;
			menter	int24						;(reserved)
			push	24						;
			jmp	intcpu						;
			menter	int25						;(reserved)
			push	25						;
			jmp	intcpu						;
			menter	int26						;(reserved)
			push	26						;
			jmp	intcpu						;
			menter	int27						;(reserved)
			push	27						;
			jmp	intcpu						;
			menter	int28						;(reserved)
			push	28						;
			jmp	intcpu						;
			menter	int29						;(reserved)
			push	29						;
			jmp	intcpu						;
			menter	int30						;(reserved)
			push	30						;
			jmp	intcpu						;
			menter	int31						;(reserved)
			push	31						;
intcpu			pop	eax						;
			iretd							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Hardware Device Interupts
;
;	The next 16 interrupts are defined as our hardware interrupts. These interrupts vectors (20h-2Fh) are mapped to
;	the hardware interrupts IRQ0-IRQF by the BIOS when the call to the BIOS is made invoking BIOS function 89h
;	(BX=2028h).
;
;-----------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------
;
;	IRQ0	Clock Tick Interrupt
;
;	PC compatible systems contain or emulate the function of the Intel 8253 Programmable Interval Timer (PIT).
;	Channel 0 of this chip decrements an internal counter to zero and then issues a hardware interrupt. The default
;	rate at which IRQ0 occurs is approximately 18.2 times per second or, more accurately, 1,573,040 times per day.
;
;	Every time IRQ0 occurs, a counter at 40:6c is incremented. When the number of ticks reaches the maximum for one
;	day, the counter is set to zero and the number of days counter at 40:70 is incremented.
;
;	This handler also decrements the floppy drive motor count at 40:40 if it is not zero. When this count reaches
;	zero, the floppy disk motors are turned off.
;
;-----------------------------------------------------------------------------------------------------------------------
			menter	clocktick					;clock tick interrupt
			push	eax						;save modified regs
			push	edx						;
			push	ds						;
			push	ESELDAT						;load OS data selector ...
			pop	ds						;... into data segment register
			mov	eax,[wfClockTicks]				;eax = clock ticks
			inc	eax						;increment clock ticks
			cmp	eax,EPITDAYTICKS				;clock ticks per day?
			jb	irq0.10						;no, skip ahead
			inc	byte [wbClockDays]				;increment clock days
			xor	eax,eax						;reset clock ticks
irq0.10			mov	dword [wfClockTicks],eax			;save clock ticks
			cmp	byte [wbFDCMotor],0				;floppy motor timeout?
			je	irq0.20						;yes, skip ahead
			dec	byte [wbFDCMotor]				;decrement motor timeout
			jnz	irq0.20						;skip ahead if non-zero
			sti							;enable maskable interrupts
irq0.15 		mov	dh,EFDCPORTHI					;FDC controller port hi
			mov	dl,EFDCPORTLOSTAT				;FDC main status register
			in	al,dx						;FDC main status byte
			test	al,EFDCSTATBUSY					;test FDC main status for busy
			jnz	irq0.15						;wait while busy
			mov	al,EFDCMOTOROFF					;motor-off / enable/ DMA setting
			mov	byte [wbFDCControl],al				;save motor-off setting
			mov	dh,EFDCPORTHI					;fdc port hi
			mov	dl,EFDCPORTLOOUT				;fdc digital output register
			out	dx,al						;turn motor off
irq0.20			call	PutPrimaryEndOfInt				;send end-of-interrupt to PIC
			pop	ds						;restore modified regs
			pop	edx						;
			pop	eax						;
			iretd							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	IRQ1	Keyboard Interrupt
;
;	This handler is called when an IRQ1 hardware interrupt occurs, caused by a keyboard event. The scan-code(s)
;	corresponding to the keyboard event are read and message events are appended to the message queue. Since this
;	code is called in response to a hardware interrupt, no task switch occurs. We need to preseve the state of
;	ALL modified registers upon return.
;
;-----------------------------------------------------------------------------------------------------------------------
			menter	keyboard					;keyboard interrrupt
			push	eax						;save non-volatile regs
			push	ebx						;
			push	ecx						;
			push	esi						;
			push	ds						;
			push	ESELDAT						;load OS data selector ...
			pop	ds						;... into data segment register
			xor	al,al						;zero
			mov	[wbConsoleScan0],al				;clear scan code 0
			mov	[wbConsoleScan1],al				;clear scan code 1
			mov	[wbConsoleScan2],al				;clear scan code 2
			mov	[wbConsoleScan3],al				;clear scan code 3
			mov	[wbConsoleScan4],al				;clear scan code 4
			mov	[wbConsoleScan5],al				;clear scan code 5
			mov	al,' '						;space
			mov	[wbConsoleChar],al				;set character to space
			mov	al,EKEYTIMEOUT					;controller timeout flag
			not	al						;controller timeout mask
			and	[wbConsoleStatus],al				;clear controller timeout flag
			mov	bl,[wbConsoleShift]				;shift flags
			mov	bh,[wbConsoleLock]				;lock flags
			call	WaitForKeyOutBuffer				;controller timeout?
			jz	irq1.140					;yes, skip ahead
			in	al,EKEYPORTDATA					;read scan code 0
			mov	[wbConsoleScan0],al				;save scan code 0
			mov	ah,al						;copy scan code 0
			mov	al,EKEYSHIFTLEFT				;left shift flag
			cmp	ah,EKEYSHIFTLDOWN				;left shift key down code?
			je	irq1.30						;yes, set flag
			cmp	ah,EKEYSHIFTLUP					;left shift key up code?
			je	irq1.40						;yes, reset flag
			mov	al,EKEYSHIFTRIGHT				;right shift flag
			cmp	ah,EKEYSHIFTRDOWN				;right shift key down code?
			je	irq1.30						;yes, set flag
			cmp	ah,EKEYSHIFTRUP					;right shift key up code?
			je	irq1.40						;yes, reset flag
			mov	al,EKEYCTRLLEFT					;left control flag
			cmp	ah,EKEYCTRLDOWN					;control key down code?
			je	irq1.30						;yes, set flag
			cmp	ah,EKEYCTRLUP					;control key up code?
			je	irq1.40						;yes, reset flag
			mov	al,EKEYALTLEFT					;left alt flag
			cmp	ah,EKEYALTDOWN					;alt key down code?
			je	irq1.30						;yes, set flag
			cmp	ah,EKEYALTUP					;alt key up code?
			je	irq1.40						;yes, reset flag
			mov	al,EKEYLOCKCAPS					;caps-lock flag
			cmp	ah,EKEYCAPSDOWN					;caps-lock key down code?
			je	irq1.50						;yes, toggle lamps and flags
			mov	al,EKEYLOCKNUM					;num-lock flag
			cmp	ah,EKEYNUMDOWN					;num-lock key down code?
			je	irq1.50						;yes, toggle lamps and flags
			mov	al,EKEYLOCKSCROLL				;scroll-lock flag
			cmp	ah,EKEYSCROLLDOWN				;scroll-lock key down code?
			je	irq1.50						;yes, toggle lamps and flags
			cmp	ah,EKEYCODEEXT0					;extended scan code 0?
			jne	irq1.70 					;no, skip ahead
			call	WaitForKeyOutBuffer				;controller timeout?
			jz	irq1.140					;yes, skip ahead
			in	al,EKEYPORTDATA					;read scan code 1
			mov	[wbConsoleScan1],al				;save scan code 1
			mov	ah,al						;copy scan code 1
			mov	al,EKEYCTRLRIGHT				;right control flag
			cmp	ah,EKEYCTRLDOWN					;control key down code?
			je	irq1.30						;yes, set flag
			cmp	ah,EKEYCTRLUP					;control key up code?
			je	irq1.40						;yes, reset flag
			mov	al,EKEYALTRIGHT					;right alt flag
			cmp	ah,EKEYALTDOWN					;alt key down code?
			je	irq1.30						;yes, set flag
			cmp	ah,EKEYALTUP					;alt key up code?
			je	irq1.40						;yes, reset flag
			cmp	ah,EKEYSLASH					;slash down code?
			je	irq1.80						;yes, skip ahead
			cmp	ah,EKEYSLASHUP					;slash up code?
			je	irq1.80						;yes, skip ahead
			cmp	ah,EKEYPRTSCRDOWN				;print screen down code?
			je	irq1.10						;yes, continue
			cmp	ah,EKEYPRTSCRUP					;print screen up code?
			jne	irq1.20						;no, skip ahead
irq1.10			call	WaitForKeyOutBuffer				;controller timeout?
			jz	irq1.140					;yes, skip ahead
			in	al,EKEYPORTDATA					;read scan code 2
			mov	[wbConsoleScan2],al				;save scan code 2
			call	WaitForKeyOutBuffer				;controller timeout?
			jz	irq1.140					;yes, skip ahead
			in	al,EKEYPORTDATA					;read scan code 3
			mov	[wbConsoleScan3],al				;read scan code 3
irq1.20			jmp	irq1.150					;finish keyboard handling
irq1.30			or	bl,al						;set shift flag
			jmp	irq1.60						;skip ahead
irq1.40			not	al						;convert flag to mask
			and	bl,al						;reset shift flag
			jmp	irq1.60						;skip ahead
irq1.50			xor	bh,al						;toggle lock flag
			call	SetKeyboardLamps				;update keyboard lamps
irq1.60			mov	[wbConsoleShift],bl				;save shift flags
			mov	[wbConsoleLock],bh				;save lock flags
			call	PutConsoleOIAShift				;update OIA indicators
			jmp	irq1.150					;finish keyboard handling
irq1.70			cmp	ah,EKEYCODEEXT1					;extended scan code 1?
			jne	irq1.80						;no continue
			call	WaitForKeyOutBuffer				;controller timeout?
			jz	irq1.140					;yes, skip ahead
			in	al,EKEYPORTDATA					;read scan code 1
			mov	[wbConsoleScan1],al				;save scan code 1
			mov	ah,al						;copy scan code 1
			cmp	ah,EKEYPAUSEDOWN				;pause key down code?
			jne	irq1.150					;no, finish keyboard handling
			call	WaitForKeyOutBuffer				;controller timeout?
			jz	irq1.140					;yes, skip ahead
			in	al,EKEYPORTDATA					;read scan code 2
			mov	[wbConsoleScan2],al				;save scan code 2
			call	WaitForKeyOutBuffer				;controller timeout?
			jz	irq1.140					;yes, skip ahead
			in	al,EKEYPORTDATA					;read scan code 3
			mov	[wbConsoleScan3],al				;save scan code 3
			call	WaitForKeyOutBuffer				;controller timeout?
			jz	irq1.140					;yes, skip ahead
			in	al,EKEYPORTDATA					;read scan code 4
			mov	[wbConsoleScan4],al				;save scan code 4
			call	WaitForKeyOutBuffer				;controller timeout?
			jz	irq1.140					;yes, skip ahead
			in	al,EKEYPORTDATA					;read scan code 5
			mov	[wbConsoleScan5],al				;save scan code 5
			jmp	irq1.150					;continue
irq1.80			xor	al,al						;assume no ASCII translation
			test	ah,EKEYUP					;release code?
			jnz	irq1.110					;yes, skip ahead
			mov	esi,tscan2ascii					;scan-to-ascii table address
			test	bl,EKEYSHIFT					;either shift key down?
			jz	irq1.90						;no, skip ahead
			mov	esi,tscan2shift					;scan-to-shifted table address
irq1.90			movzx	ecx,ah						;scan code offset
			mov	al,[cs:ecx+esi]					;al = ASCII code
			test	bh,EKEYLOCKCAPS					;caps-lock on?
			jz	irq1.100					;no skip ahead
			mov	cl,al						;copy ASCII code
			and	cl,EASCIICASEMASK				;clear case mask of copy
			cmp	cl,EASCIIUPPERA					;less than 'A'?
			jb	irq1.100					;yes, skip ahead
			cmp	cl,EASCIIUPPERZ					;greater than 'Z'?
			ja	irq1.100					;yes, skip ahead
			xor	al,EASCIICASE					;switch case
irq1.100		mov	[wbConsoleChar],al				;save ASCII code
irq1.110		mov	edx,EMSGKEYDOWN					;assume key-down event
			test	ah,EKEYUP					;release scan-code?
			jz	irq1.120					;no, skip ahead
			mov	edx,EMSGKEYUP					;key-up event
irq1.120		and	eax,0FFFFh					;clear high-order word
			or	edx,eax						;msg id and codes
			xor	ecx,ecx						;null param
			push	eax						;save codes
			call	PutMessage					;put message to console
			pop	eax						;restore codes
			test	al,al						;ASCII translation?
			jz	irq1.130					;no, skip ahead
			mov	edx,EMSGKEYCHAR					;key-character event
			and	eax,0FFFFh					;clear high-order word
			or	edx,eax						;msg id and codes
			xor	ecx,ecx						;null param
			call	PutMessage					;put message to console
irq1.130		jmp	irq1.150					;finish keyboard handling
irq1.140		mov	al,EKEYTIMEOUT					;controller timeout flag
			or	[wbConsoleStatus],al				;set controller timeout flag
irq1.150		call	PutConsoleOIAChar				;update operator info area
			call	PutPrimaryEndOfInt				;send end-of-interrupt to PIC
			pop	ds						;restore non-volatile regs
			pop	esi						;
			pop	ecx						;
			pop	ebx						;
			pop	eax						;
			iretd							;return
;-----------------------------------------------------------------------------------------------------------------------
;	Scan-Code to ASCII Translation Tables
;-----------------------------------------------------------------------------------------------------------------------
tscan2ascii		db	000h,01Bh,031h,032h,033h,034h,035h,036h		;00-07
			db	037h,038h,039h,030h,02Dh,03Dh,008h,009h		;08-0F
			db	071h,077h,065h,072h,074h,079h,075h,069h		;10-17
			db	06Fh,070h,05Bh,05Dh,00Dh,000h,061h,073h		;18-1F
			db	064h,066h,067h,068h,06Ah,06Bh,06Ch,03Bh		;20-27
			db	027h,060h,000h,05Ch,07Ah,078h,063h,076h		;28-2F
			db	062h,06Eh,06Dh,02Ch,02Eh,02Fh,000h,02Ah		;30-37
			db	000h,020h,000h,000h,000h,000h,000h,000h		;38-3F
			db	000h,000h,000h,000h,000h,000h,000h,037h		;40-47
			db	038h,039h,02Dh,034h,035h,036h,02Bh,031h		;48-4F
			db	032h,033h,030h,02Eh,000h,000h,000h,000h		;50-57
			db	000h,000h,000h,000h,000h,000h,000h,000h		;58-5F
			db	000h,000h,000h,000h,000h,000h,000h,000h		;60-67
			db	000h,000h,000h,000h,000h,000h,000h,000h		;68-6F
			db	000h,000h,000h,000h,000h,000h,000h,000h		;70-77
			db	000h,000h,000h,000h,000h,000h,000h,000h		;78-7F
tscan2shift		db	000h,01Bh,021h,040h,023h,024h,025h,05Eh		;80-87
			db	026h,02Ah,028h,029h,05Fh,02Bh,008h,000h		;88-8F
			db	051h,057h,045h,052h,054h,059h,055h,049h		;90-97
			db	04Fh,050h,07Bh,07Dh,00Dh,000h,041h,053h		;98-9F
			db	044h,046h,047h,048h,04Ah,04Bh,04Ch,03Ah		;A0-A7
			db	022h,07Eh,000h,07Ch,05Ah,058h,043h,056h		;A8-AF
			db	042h,04Eh,04Dh,03Ch,03Eh,03Fh,000h,02Ah		;B0-B7
			db	000h,020h,000h,000h,000h,000h,000h,000h		;B8-BF
			db	000h,000h,000h,000h,000h,000h,000h,037h		;C0-C7
			db	038h,039h,02Dh,034h,035h,036h,02Bh,031h		;C8-CF
			db	032h,033h,030h,02Eh,000h,000h,000h,000h		;D0-D7
			db	000h,000h,000h,000h,000h,000h,000h,000h		;D8-DF
			db	000h,000h,000h,000h,000h,000h,000h,000h		;E0-E7
			db	000h,000h,000h,000h,000h,000h,000h,000h		;E8-EF
			db	000h,000h,000h,000h,000h,000h,000h,000h		;F0-F7
			db	000h,000h,000h,000h,000h,000h,000h,000h		;F8-FF
;-----------------------------------------------------------------------------------------------------------------------
;
;	IRQ2	Secondary 8259A Cascade Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
			menter	iochannel					;secondary 8259A cascade
			push	eax						;
			jmp	hwint						;
;-----------------------------------------------------------------------------------------------------------------------
;
;	IRQ3	Communication Port 2 Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
			menter	com2						;serial port 2 interrupt
			push	eax						;
			jmp	hwint						;
;-----------------------------------------------------------------------------------------------------------------------
;
;	IRQ4	Communication Port 1 Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
			menter	com1						;serial port 1 interrupt
			push	eax						;
			jmp	hwint						;
;-----------------------------------------------------------------------------------------------------------------------
;
;	IRQ5	Parallel Port 2 Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
			menter	lpt2						;parallel port 2 interrupt
			push	eax						;
			jmp	hwint						;
;-----------------------------------------------------------------------------------------------------------------------
;
;	IRQ6	Diskette Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
			menter	diskette					;floppy disk interrupt
			push	eax						;save non-volatile regs
			push	ds						;
			push	ESELDAT						;load OS data selector ...
			pop	ds						;... into DS register
			mov	al,[wbFDCStatus]				;al = FDC calibration status
			or	al,10000000b					;set IRQ flag
			mov	[wbFDCStatus],al				;update FDC calibration status
			pop	ds						;restore non-volatile regs
			jmp	hwint						;end primary PIC interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;	IRQ7	Parallel Port 1 Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
			menter	lpt1						;parallel port 1 interrupt
			push	eax						;
			jmp	hwint						;
;-----------------------------------------------------------------------------------------------------------------------
;
;	IRQ8	Real-time Clock Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
			menter	rtclock						;real-time clock interrupt
			push	eax						;
			jmp	hwwint						;
;-----------------------------------------------------------------------------------------------------------------------
;
;	IRQ9	CGA Vertical Retrace Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
			menter	retrace						;CGA vertical retrace interrupt
			push	eax						;
			jmp	hwwint						;
;-----------------------------------------------------------------------------------------------------------------------
;
;	IRQ10	Reserved Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
			menter	irq10						;reserved
			push	eax						;
			jmp	hwwint						;
;-----------------------------------------------------------------------------------------------------------------------
;
;	IRQ11	Reserved Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
			menter	irq11						;reserved
			push	eax						;
			jmp	hwwint						;
;-----------------------------------------------------------------------------------------------------------------------
;
;	IRQ12	PS/2 Mouse Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
			menter	ps2mouse					;PS/2 mouse interrupt
			push	eax						;
			jmp	hwwint						;
;-----------------------------------------------------------------------------------------------------------------------
;
;	IRQ13	Coprocessor Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
			menter	coprocessor					;coprocessor interrupt
			push	eax						;
			jmp	hwwint						;
;-----------------------------------------------------------------------------------------------------------------------
;
;	IRQ14	Fixed Disk Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
			menter	fixeddisk					;fixed disk interrupt
			push	eax						;
			jmp	hwwint						;
;-----------------------------------------------------------------------------------------------------------------------
;
;	IRQ15	Reserved Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
			menter	irq15						;reserved
			push	eax						;save modified regs
;-----------------------------------------------------------------------------------------------------------------------
;
;	Exit from hardware interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
hwwint			call	PutSecondaryEndOfInt				;send EOI to secondary PIC
			jmp	hwint90						;skip ahead
hwint			call	PutPrimaryEndOfInt				;send EOI to primary PIC
hwint90			pop	eax						;restore modified regs
			iretd							;return from interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;	INT 30h Operating System Software Service Interrupt
;
;	Interrupt 30h is used by our operating system as an entry point for many commonly-used subroutines reusable by
;	any task. These routines include low-level i/o functions that shield applications from having to handle
;	device-specific communications. On entry to this interrupt, AL contains a function number that is used to load
;	the entry address of the specific function from a table.
;
;-----------------------------------------------------------------------------------------------------------------------
			menter	svc
			cmp	al,maxtsvc					;is our function out of range?
			jae	svc90						;yes, skip ahead
			movzx	eax,al						;function
			shl	eax,2						;offset into table
			call	dword [cs:tsvc+eax]				;far call to indirect address
svc90			iretd							;return from interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;	Service Request Table
;
;
;	These tsvce macros expand to define an address vector table for the service request interrupt (int 30h).
;
;-----------------------------------------------------------------------------------------------------------------------
tsvc			tsvce	PutConsoleString				;tty output asciiz string
			tsvce	GetConsoleString				;get string input
			tsvce	ClearConsoleScreen				;clear console screen
			tsvce	PlaceCursor					;place the cursor at the current loc
			tsvce	UpperCaseString					;upper-case string
			tsvce	CompareMemory					;compare memory
			tsvce	ResetSystem					;reset system using 8042 chip
			tsvce	PutDateString					;put MM/DD/YYYY string
			tsvce	PutTimeString					;put HH:MM:SS string
			tsvce	ReadRealTimeClock				;get real-time clock date and time
			tsvce	UnsignedToDecimalString 			;convert unsigned integer to decimal string
			tsvce	UnsignedToHexadecimal				;convert unsigned integer to hexadecimal string
			tsvce	HexadecimalToUnsigned				;convert hexadecimal string to unsigned integer
maxtsvc			equ	($-tsvc)/4					;function out of range
;-----------------------------------------------------------------------------------------------------------------------
;
;	Service Request Macros
;
;	These macros provide positional parameterization of service request calls.
;
;-----------------------------------------------------------------------------------------------------------------------
%macro			putConsoleString 0
			mov	al,ePutConsoleString				;AL = put string fn.
			int	_svc						;invoke OS service
%endmacro
%macro			putConsoleString 1
			mov	edx,%1						;EDX = string address
			mov	al,ePutConsoleString				;AL = put string fn.
			int	_svc						;invoke OS service
%endmacro
%macro			getConsoleString 4
			mov	edx,%1						;EDX = buffer address
			mov	ecx,%2						;ECX = max characters
			mov	bh,%3						;BH = echo indicator
			mov	bl,%4						;BL = terminator
			mov	al,eGetConsoleString				;AL = get string fn.
			int	_svc						;invoke OS service
%endmacro
%macro			clearConsoleScreen 0
			mov	al,eClearConsoleScreen				;AL = clear console fn.
			int	_svc						;invoke OS service
%endmacro
%macro			placeCursor 0
			mov	al,ePlaceCursor					;AL = set cursor fn.
			int	_svc						;invoke OS service
%endmacro
%macro			upperCaseString 0
			mov	al,eUpperCaseString				;AL = upper case fn.
			int	_svc						;invoke OS service
%endmacro
%macro			compareMemory 0
			mov	al,eCompareMemory				;AL = compare memory fn.
			int	_svc						;invoke OS service
%endmacro
%macro			resetSystem 0
			mov	al,eResetSystem					;AL = system reset fn.
			int	_svc						;invoke OS service
%endmacro
%macro			putDateString 0
			mov	al,ePutDateString				;function code
			int	_svc						;invoke OS service
%endmacro
%macro			putDateString 2
			mov	ebx,%1						;DATETIME addr
			mov	edx,%2						;output buffer addr
			mov	al,ePutDateString				;function code
			int	_svc						;invoke OS service
%endmacro
%macro			putTimeString 0
			mov	al,ePutTimeString				;function code
			int	_svc						;invoke OS service
%endmacro
%macro			putTimeString 2
			mov	ebx,%1						;DATETIME addr
			mov	edx,%2						;output buffer addr
			mov	al,ePutTimeString				;function code
			int	_svc						;invoke OS service
%endmacro
%macro			readRealTimeClock 0
			mov	al,eReadRealTimeClock				;function code
			int	_svc						;invoke OS service
%endmacro
%macro			readRealTimeClock 1
			mov	ebx,%1						;DATETIME addr
			mov	al,eReadRealTimeClock				;function code
			int	_svc						;invoke OS service
%endmacro
%macro			unsignedToDecimalString 0
			mov	al,eUnsignedToDecimalString			;AL = function code
			int	_svc						;invoke OS service
%endmacro
%macro			unsignedToHexadecimal 0
			mov	al,eUnsignedToHexadecimal			;AL = unsigned to hexademcial fn.
			int	_svc						;invoke OS service
%endmacro
%macro			hexadecimalToUnsigned 0
			mov	al,eHexadecimalToUnsigned			;AL = hex to unsigned fn.
			int	_svc						;invoke OS service
%endmacro
;-----------------------------------------------------------------------------------------------------------------------
;
;	Kernel Function Library
;
;-----------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------
;
;	Date and Time Helper Routines
;
;	PutDateString
;	PutTimeString
;
;-----------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	PutDateString
;
;	Description:	This routine returns an ASCIIZ mm/dd/yyyy string at ds:edx from the date in the DATETIME
;			structure at ds:ebx.
;
;	In:		DS:EBX	DATETIME address
;			DS:EDX	output buffer address
;
;-----------------------------------------------------------------------------------------------------------------------
PutDateString		push	ecx						;save non-volatile regs
			push	edi						;
			push	es						;
			push	ds						;store data selector ...
			pop	es						;... in extra segment reg
			mov	edi,edx						;output buffer address
			mov	cl,10						;divisor
			mov	edx,002f3030h					;ASCIIZ "00/" (reversed)
			movzx	eax,byte [ebx+DATETIME.month]			;month
			div	cl						;ah = rem; al = quotient
			or	eax,edx						;apply ASCII zones and delimiter
			cld							;forward strings
			stosd							;store "mm/"nul
			dec	edi						;address of terminator
			movzx	eax,byte [ebx+DATETIME.day]			;day
			div	cl						;ah = rem; al = quotient
			or	eax,edx						;apply ASCII zones and delimiter
			stosd							;store "dd/"nul
			dec	edi						;address of terminator
			movzx	eax,byte [ebx+DATETIME.century]			;century
			div	cl						;ah = rem; al = quotient
			or	eax,edx						;apply ASCII zones and delimiter
			stosd							;store "cc/"null
			dec	edi						;address of terminator
			dec	edi						;address of delimiter
			movzx	eax,byte [ebx+DATETIME.year]			;year (yy)
			div	cl						;ah = rem; al = quotient
			or	eax,edx						;apply ASCII zones and delimiter
			stosb							;store quotient
			mov	al,ah						;remainder
			stosb							;store remainder
			xor	al,al						;null terminator
			stosb							;store terminator
			pop	es						;restore non-volatile regs
			pop	edi						;
			pop	ecx						;
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	PutTimeString
;
;	Description:	This routine returns an ASCIIZ hh:mm:ss string at ds:edx from the date in the DATETIME
;			structure at ds:ebx.
;
;	In:		DS:EBX	DATETIME address
;			DS:EDX	output buffer address
;
;-----------------------------------------------------------------------------------------------------------------------
PutTimeString		push	ecx						;save non-volatile regs
			push	edi						;
			push	es						;
			push	ds						;store data selector ...
			pop	es						;... in extra segment reg
			mov	edi,edx						;output buffer address
			mov	cl,10						;divisor
			mov	edx,003a3030h					;ASCIIZ "00:" (reversed)
			movzx	eax,byte [ebx+DATETIME.hour]			;hour
			div	cl						;ah = rem; al = quotient
			or	eax,edx						;apply ASCII zones and delimiter
			cld							;forward strings
			stosd							;store "mm/"nul
			dec	edi						;address of terminator
			movzx	eax,byte [ebx+DATETIME.minute]			;minute
			div	cl						;ah = rem; al = quotient
			or	eax,edx						;apply ASCII zones and delimiter
			stosd							;store "dd/"nul
			dec	edi						;address of terminator
			movzx	eax,byte [ebx+DATETIME.second]			;second
			div	cl						;ah = rem; al = quotient
			or	eax,edx						;apply ASCII zones and delimiter
			stosb							;store quotient
			mov	al,ah						;remainder
			stosb							;store remainder
			xor	al,al						;null terminator
			stosb							;store terminator
			pop	es						;restore non-volatile regs
			pop	edi						;
			pop	ecx						;
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	String Helper Routines
;
;	UpperCaseString
;	CompareMemory
;
;-----------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	UpperCaseString
;
;	Description:	This routine places all characters in the given string to upper case.
;
;	In:		DS:EDX	string address
;
;	Out:		EDX	string address
;
;-----------------------------------------------------------------------------------------------------------------------
UpperCaseString		push	esi						;save non-volatile regs
			mov	esi,edx						;string address
			cld							;forward strings
.10			lodsb							;string character
			test	al,al						;null?
			jz	.20						;yes, skip ahead
			cmp	al,EASCIILOWERA					;lower-case? (lower bounds)
			jb	.10						;no, continue
			cmp	al,EASCIILOWERZ					;lower-case? (upper bounds)
			ja	.10						;no, continue
			and	al,EASCIICASEMASK				;mask for upper case
			mov	[esi-1],al					;upper character
			jmp	.10						;continue
.20			pop	esi						;restore non-volatile regs
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	CompareMemory
;
;	Description:	This routine compares two byte arrays.
;
;	In:		DS:EDX	first source address
;			DS:EBX	second source address
;			ECX	comparison length
;
;	Out:		EDX	first source address
;			EBX	second source address
;			ECX	0	array 1 = array 2
;				<0	array 1 < array 2
;				>0	array 1 > array 2
;
;-----------------------------------------------------------------------------------------------------------------------
CompareMemory		push	esi						;save non-volatile regs
			push	edi						;
			push	es						;
			push	ds						;copy DS
			pop	es						;... to ES
			mov	esi,edx						;first source address
			mov	edi,ebx						;second source address
			cld							;forward strings
			rep	cmpsb						;compare bytes
			mov	al,0						;default result
			jz	.10						;branch if arrays equal
			mov	al,1						;positive result
			jnc	.10						;branch if target > source
			mov	al,-1						;negative result
.10			movsx	ecx,al						;extend sign
			pop	es						;restore regs
			pop	edi						;
			pop	esi						;
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Console Helper Routines
;
;	PutConsoleString
;	GetConsoleString
;	GetConsoleChar
;	Yield
;	PreviousConsoleColumn
;	NextConsoleColumn
;	FirstConsoleColumn
;	NextConsoleRow
;	PutConsoleChar
;	PutConsoleOIAShift
;	PutConsoleOIAChar
;	PutConsoleHexByte
;
;-----------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	PutConsoleString
;
;	Description:	This routine writes a sequence of ASCII characters to the console until null and updates the
;			console position as needed.
;
;	In:		EDX	source address
;			DS	OS data selector
;
;-----------------------------------------------------------------------------------------------------------------------
PutConsoleString	push	esi						;save non-volatile regs
			mov	esi,edx						;source address
			cld							;forward strings
.10			lodsb							;ASCII character
			or	al,al						;end of string?
			jz	.40						;yes, skip ahead
			cmp	al,EASCIIRETURN					;carriage return?
			jne	.20						;no, skip ahead
			call	FirstConsoleColumn				;move to start of row
			jmp	.10						;next character
.20			cmp	al,EASCIILINEFEED				;line feed?
			jne	.30						;no, skip ahead
			call	NextConsoleRow					;move to next row
			jmp	.10						;next character
.30			call	PutConsoleChar					;output character to console
			call	NextConsoleColumn				;advance to next column
			jmp	.10						;next character
.40			pop	esi						;restore non-volatile regs
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	GetConsoleString
;
;	Description:	This routine accepts keyboard input into a buffer.
;
;	Input:		DS:EDX	target buffer address
;			ECX	maximum number of characters to accept
;			BH	echo to terminal
;			BL	terminating character
;
;-----------------------------------------------------------------------------------------------------------------------
GetConsoleString	push	ecx						;save non-volatile regs
			push	esi						;
			push	edi						;
			push	es						;
			push	ds						;load data segment selector ...
			pop	es						;... into extra segment register
			mov	edi,edx						;edi = target buffer
			push	ecx						;save maximum characters
			xor	al,al						;zero register
			cld							;forward strings
			rep	stosb						;zero fill buffer
			pop	ecx						;maximum characters
			mov	edi,edx						;edi = target buffer
			mov	esi,edx						;esi = target buffer
.10			jecxz	.50						;exit if max-length is zero
.20			call	GetConsoleChar					;al = next input char
			cmp	al,bl						;is this the terminator?
			je	.50						;yes, exit
			cmp	al,EASCIIBACKSPACE				;is this a backspace?
			jne	.30						;no, skip ahead
			cmp	esi,edi						;at start of buffer?
			je	.20						;yes, get next character
			dec	edi						;backup target pointer
			mov	byte [edi],0					;zero previous character
			inc	ecx						;increment remaining chars
			test	bh,1						;echo to console?
			jz	.20						;no, get next character
			call	PreviousConsoleColumn				;backup console position
			mov	al,EASCIISPACE					;ASCII space
			call	PutConsoleChar					;write space to console
			call	PlaceCursor					;position the cursor
			jmp	.20						;get next character
.30			cmp	al,EASCIISPACE					;printable? (lower bounds)
			jb	.20						;no, get another character
			cmp	al,EASCIITILDE					;printable? (upper bounds)
			ja	.20						;no, get another character
			stosb							;store character in buffer
			test	bh,1						;echo to console?
			jz	.40						;no, skip ahead
			call	PutConsoleChar					;write character to console
			call	NextConsoleColumn				;advance console position
			call	PlaceCursor					;position the cursor
.40			dec	ecx						;decrement remaining chars
			jmp	.10						;next
.50			xor	al,al						;null
			stosb							;terminate buffer
			pop	es						;restore non-volatile regs
			pop	edi						;
			pop	esi						;
			pop	ecx						;
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	GetConsoleChar
;
;	Description:	This routine waits for EMSGKEYCHAR message and return character code.
;
;	Output:		AL	ASCII character code
;			AH	keyboard scan code
;
;-----------------------------------------------------------------------------------------------------------------------
GetConsoleChar.10	call	Yield						;pass control or halt
GetConsoleChar		call	GetMessage					;get the next message
			or	eax,eax						;do we have a message?
			jz	GetConsoleChar.10				;no, skip ahead
			push	eax						;save key codes
			and	eax,0FFFF0000h					;mask for message type
			cmp	eax,EMSGKEYCHAR					;key-char message?
			pop	eax						;restore key codes
			jne	GetConsoleChar					;no, try again
			and	eax,0000ffffh					;mask for key codes
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	Yield
;
;	Description:	This routine passes control to the next ready task or enter halt.
;
;-----------------------------------------------------------------------------------------------------------------------
Yield			sti							;enable maskagle interrupts
			hlt							;halt until external interrupt
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	PreviousConsoleColumn
;
;	Description:	This routine retreats the cursor one logical column. If the cursor was at the start of a row,
;			the column is set to the last position in the row and the row is decremented.
;
;	Input:		DS	OS data selector
;
;-----------------------------------------------------------------------------------------------------------------------
PreviousConsoleColumn	mov	al,[wbConsoleColumn]				;current column
			or	al,al						;start of row?
			jnz	.10						;no, skip ahead
			mov	ah,[wbConsoleRow]				;current row
			or	ah,ah						;top of screen?
			jz	.20						;yes, exit with no change
			dec	ah						;decrement row
			mov	[wbConsoleRow],ah				;save row
			mov	al,ECONCOLS					;set maximum column
.10			dec	al						;decrement column
			mov	[wbConsoleColumn],al				;save column
.20			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	NextConsoleColumn
;
;	Description:	This routine advances the console position one column. The columnn is reset to zero and the row
;			incremented if the end of the current row is reached.
;
;	In:		DS	OS data selector
;
;-----------------------------------------------------------------------------------------------------------------------
NextConsoleColumn	mov	al,[wbConsoleColumn]				;current column
			inc	al						;increment column
			mov	[wbConsoleColumn],al				;save column
			cmp	al,ECONCOLS					;end of row?
			jb	.10						;no, skip ahead
			call	FirstConsoleColumn				;reset column to start of row
			call	NextConsoleRow					;line feed to next row
.10			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	FirstConsoleColumn
;
;	Description:	This routine resets the console column to start of the row.
;
;	In:		DS	OS data selector
;
;-----------------------------------------------------------------------------------------------------------------------
FirstConsoleColumn	xor	al,al						;zero column
			mov	[wbConsoleColumn],al				;save column
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	NextConsoleRow
;
;	Description:	This routine advances the console position one line. Scroll the screen one row if needed.
;
;	In:		DS	OS data selector
;
;-----------------------------------------------------------------------------------------------------------------------
NextConsoleRow		mov	al,[wbConsoleRow]				;current row
			inc	al						;increment row
			mov	[wbConsoleRow],al				;save row
			cmp	al,ECONROWS					;end of screen?
			jb	.10						;no, skip ahead
			call	ScrollConsoleRow				;scroll up one row
			mov	al,[wbConsoleRow]				;row
			dec	al						;decrement row
			mov	[wbConsoleRow],al				;save row
.10			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	PutConsoleChar
;
;	Description:	This routine writes one ASCII character to the console screen.
;
;	In:		AL	ASCII character
;			DS	OS data selector
;
;-----------------------------------------------------------------------------------------------------------------------
PutConsoleChar		push	ecx						;save non-volatile regs
			push	es						;
			push	ESELCGA						;load CGA selector ...
			pop	es						;... into extra segment reg
			mov	cl,[wbConsoleColumn]				;column
			mov	ch,[wbConsoleRow]				;row
			call	SetConsoleChar					;put character at row, column
			pop	es						;restore non-volatile regs
			pop	ecx						;
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	PutConsoleOIAShift
;
;	Description:	This routine updates the shift/ctrl/alt/lock indicators in the operator information area (OIA).
;
;	In:		BL	shift flags
;			BH	lock flags
;			DS	OS data selector
;
;-----------------------------------------------------------------------------------------------------------------------
PutConsoleOIAShift	push	ecx						;save non-volatile regs
			push	es						;
			push	ESELCGA						;load CGA selector ...
			pop	es						;... into ES register
			mov	ch,ECONOIAROW					;OIA row
			mov	al,EASCIISPACE					;space is default character
			test	bl,EKEYSHIFTLEFT				;left-shift indicated?
			jz	.10						;no, skip ahead
			mov	al,'S'						;yes, indicate with 'S'
.10			mov	cl,14						;indicator column
			call	SetConsoleChar					;display ASCII character
			mov	al,EASCIISPACE					;ASCII space
			test	bl,EKEYSHIFTRIGHT				;right-shift indicated?
			jz	.20						;no, skip ahead
			mov	al,'S'						;yes, indicate with 'S'
.20			mov	cl,64						;indicator column
			call	SetConsoleChar					;display ASCII character
			mov	al,EASCIISPACE					;ASCII space
			test	bl,EKEYCTRLLEFT					;left-ctrl indicated?
			jz	.30						;no, skip ahead
			mov	al,'C'						;yes, indicate with 'C'
.30			mov	cl,15						;indicator column
			call	SetConsoleChar					;display ASCII character
			mov	al,EASCIISPACE					;ASCII space
			test	bl,EKEYCTRLRIGHT				;right-ctrl indicated?
			jz	.40						;no, skip ahead
			mov	al,'C'						;yes, indicate with 'C'
.40			mov	cl,63						;indicator column
			call	SetConsoleChar					;display ASCII character
			mov	al,EASCIISPACE					;ASCII space
			test	bl,EKEYALTLEFT					;left-alt indicated?
			jz	.50						;no, skip ahead
			mov	al,'A'						;yes, indicate with 'A'
.50			mov	cl,16						;indicator column
			call	SetConsoleChar					;display ASCII character
			mov	al,EASCIISPACE					;ASCII space
			test	bl,EKEYALTRIGHT					;right-alt indicated?
			jz	.60						;no, skip ahead
			mov	al,'A'						;yes, indicate with 'A'
.60			mov	cl,62						;indicator column
			call	SetConsoleChar					;display ASCII character
			mov	al,EASCIISPACE					;ASCII space
			test	bh,EKEYLOCKCAPS					;caps-lock indicated?
			jz	.70						;no, skip ahead
			mov	al,'C'						;yes, indicate with 'C'
.70			mov	cl,78						;indicator column
			call	SetConsoleChar					;display ASCII character
			mov	al,EASCIISPACE					;ASCII space
			test	bh,EKEYLOCKNUM					;num-lock indicated?
			jz	.80						;no, skip ahead
			mov	al,'N'						;yes, indicate with 'N'
.80			mov	cl,77						;indicator column
			call	SetConsoleChar					;display ASCII character
			mov	al,EASCIISPACE					;ASCII space
			test	bh,EKEYLOCKSCROLL				;scroll-lock indicated?
			jz	.90						;no, skip ahead
			mov	al,'S'						;yes, indicate with 'S'
.90			mov	cl,76						;indicator column
			call	SetConsoleChar					;display ASCII character
			pop	es						;restore non-volatile regs
			pop	ecx						;
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	PutConsoleOIAChar
;
;	Description:	This routine updates the Operator Information Area (OIA).
;
;	In:		DS	OS data selector
;
;-----------------------------------------------------------------------------------------------------------------------
PutConsoleOIAChar	push	ebx						;save non-volatile regs
			push	ecx						;
			push	esi						;
			push	ds						;
			push	es						;
			push	ESELDAT						;load OS data selector ...
			pop	ds						;... into data segment register
			push	ESELCGA						;load CGA selector ...
			pop	es						;... into extra segment register
			mov	esi,wbConsoleScan0				;scan codes address
			mov	bh,ECONOIAROW					;OIA row
			mov	bl,0						;starting column
			mov	ecx,6						;maximum scan codes
.10			push	ecx						;save remaining count
			mov	ecx,ebx						;row, column
			lodsb							;read scan code
			or	al,al						;scan code present?
			jz	.20						;no, skip ahead
			call	PutConsoleHexByte				;display scan code
			jmp	.30						;continue
.20			mov	al,' '						;ASCII space
			call	SetConsoleChar					;display space
			inc	cl
			mov	al,' '						;ASCII space
			call	SetConsoleChar					;display space
.30			add	bl,2						;next column (+2)
			pop	ecx						;restore remaining
			loop	.10						;next code
			mov	al,[wbConsoleChar]				;console ASCII character
			cmp	al,32						;printable? (lower-bounds)
			jb	.40						;no, skip ahead
			cmp	al,126						;printable? (upper-bounds)
			ja	.40						;no, skip ahead
			mov	ch,bh						;OIA row
			mov	cl,40						;character display column
			call	SetConsoleChar					;display ASCII character
.40			pop	es						;restore non-volatile regs
			pop	ds						;
			pop	esi						;
			pop	ecx						;
			pop	ebx						;
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	PutConsoleHexByte
;
;	Description:	This routine writes two ASCII characters to the console screen representing the value of a byte.
;
;	In:		AL	byte value
;			CH	row
;			CL	column
;			DS	OS data selector
;			ES	CGA selector
;
;-----------------------------------------------------------------------------------------------------------------------
PutConsoleHexByte	push	ebx						;save non-volatile regs
			mov	bl,al						;save byte value
			shr	al,4						;hi-order nybble
			or	al,030h						;apply ASCII zone
			cmp	al,03ah						;numeric?
			jb	.10						;yes, skip ahead
			add	al,7						;add ASCII offset for alpha
.10			call	SetConsoleChar					;display ASCII character
			inc	cl						;increment column
			mov	al,bl						;byte value
			and	al,0fh						;lo-order nybble
			or	al,30h						;apply ASCII zone
			cmp	al,03ah						;numeric?
			jb	.20						;yes, skip ahead
			add	al,7						;add ASCII offset for alpha
.20			call	SetConsoleChar					;display ASCII character
			pop	ebx						;restore non-volatile regs
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Data-Type Conversion Helper Routines
;
;	UnsignedToDecimalString
;	UnsignedToHexadecimal
;	HexadecimalToUnsigned
;
;-----------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	UnsignedToDecimalString
;
;	Description:	This routine creates an ASCIIZ string representing the decimal value of binary input.
;
;	Input:		BH	flags		bit 0: 1 = trim leading zeros
;						bit 1: 1 = include comma grouping delimiters
;						bit 4: 1 = non-zero digit found (internal)
;			ECX	32-bit binary
;			DS:EDX	output buffer address
;
;-----------------------------------------------------------------------------------------------------------------------
UnsignedToDecimalString push	ebx						;save non-volatile regs
			push	ecx						;
			push	edi						;
			push	es						;
			push	ds						;load data selector
			pop	es						;... into extra segment reg
			mov	edi,edx 					;output buffer address
			and	bh,00001111b					;zero internal flags
			mov	edx,ecx 					;binary
			mov	ecx,1000000000					;10^9 divisor
			call	.30						;divide and store
			mov	ecx,100000000					;10^8 divisor
			call	.10						;divide and store
			mov	ecx,10000000					;10^7 divisor
			call	.30						;divide and store
			mov	ecx,1000000					;10^6 divisor
			call	.30						;divide and store
			mov	ecx,100000					;10^5 divisor
			call	.10						;divide and store
			mov	ecx,10000					;10^4 divisor
			call	.30						;divide and store
			mov	ecx,1000					;10^3 divisor
			call	.30						;divide and store
			mov	ecx,100 					;10^2 divisor
			call	.10						;divide and store
			mov	ecx,10						;10^2 divisor
			call	.30						;divide and store
			mov	eax,edx 					;10^1 remainder
			call	.40						;store
			xor	al,al						;null terminator
			stosb
			pop	es						;restore non-volatile regs
			pop	edi						;
			pop	ecx						;
			pop	ebx						;
			ret							;return
.10			test	bh,00000010b					;comma group delims?
			jz	.30						;no, skip ahead
			test	bh,00000001b					;trim leading zeros?
			jz	.20						;no, store delim
			test	bh,00010000b					;non-zero found?
			jz	.30						;no, skip ahead
.20			mov	al,','						;delimiter
			stosb							;store delimiter
.30			mov	eax,edx 					;lo-orer dividend
			xor	edx,edx 					;zero hi-order
			div	ecx						;divide by power of 10
			or	al,al						;zero?
			jz	.50						;yes, skip ahead
			or	bh,00010000b					;non-zero found
.40			or	al,30h						;ASCII zone
			stosb							;store digit
			ret							;return
.50			test	bh,00000001b					;trim leading zeros?
			jz	.40						;no, store and return
			test	bh,00010000b					;non-zero found?
			jnz	.40						;yes, store and return
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	UnsignedToHexadecimal
;
;	Description:	This routine creates an ASCIIZ string representing the hexadecimal value of binary input
;
;	Input:		DS:EDX	output buffer address
;			ECX	32-bit binary
;
;-----------------------------------------------------------------------------------------------------------------------
UnsignedToHexadecimal	push	edi						;store non-volatile regs
			mov	edi,edx						;output buffer address
			mov	edx,ecx						;32-bit unsigned
			xor	ecx,ecx						;zero register
			mov	cl,8						;nybble count
.10			rol	edx,4						;next hi-order nybble in bits 0-3
			mov	al,dl						;????bbbb
			and	al,0fh						;mask out bits 4-7
			or	al,30h						;mask in ascii zone
			cmp	al,3ah						;A through F?
			jb	.20						;no, skip ahead
			add	al,7						;41h through 46h
.20			stosb							;store hexnum
			loop	.10						;next nybble
			xor	al,al						;zero reg
			stosb							;null terminate
			pop	edi						;restore non-volatile regs
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	HexadecimalToUnsigned
;
;	Description:	This routine returns an unsigned integer of the value of the input ASCIIZ hexadecimal string.
;
;	Input:		DS:EDX	null-terminated hexadecimal string address
;
;	Output: 	EAX	unsigned integer value
;
;-----------------------------------------------------------------------------------------------------------------------
HexadecimalToUnsigned	push	esi						;save non-volatile regs
			mov	esi,edx						;source address
			xor	edx,edx						;zero register
.10			lodsb							;source byte
			test	al,al						;end of string?
			jz	.30						;yes, skip ahead
			cmp	al,'9'						;hexadecimal?
			jna	.20						;no, skip ahead
			sub	al,37h						;'A' = 41h, less 37h = 0Ah
.20			and	eax,0fh						;remove ascii zone
			shl	edx,4						;previous total x 16
			add	edx,eax						;add prior value x 16
			jmp	.10						;next
.30			mov	eax,edx						;result
			pop	esi						;restore non-volatile regs
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Message Queue Helper Routines
;
;	PutMessage
;	GetMessage
;
;-----------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	PutMessage
;
;	Description:	This routine adda a message to the message queue.
;
;	Input:		ECX	hi-order data word
;			EDX	lo-order data word
;
;	Output:		CY	0 = success
;				1 = fail: queue is full
;
;-----------------------------------------------------------------------------------------------------------------------
PutMessage		push	ds						;save non-volatile regs
			push	ESELMQ						;load task message queue selector ...
			pop	ds						;... into data segment register
			mov	eax,[MQTail]					;tail ptr
			cmp	dword [eax],0					;is queue full?
			stc							;assume failure
			jne	.20						;yes, cannot store
			mov	[eax],edx					;store lo-order data
			mov	[eax+4],ecx					;store hi-order data
			add	eax,8						;next queue element adr
			and	eax,03fch					;at end of queue?
			jnz	.10						;no, skip ahead
			mov	al,8						;reset to top of queue
.10			mov	[MQTail],eax					;save new tail ptr
			clc							;indicate success
.20			pop	ds						;restore non-volatile regs
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	GetMessage
;
;	Description:	This routine reads and removes a message from the message queue.
;
;	Output:		EAX	lo-order message data
;			EDX	hi-order message data
;
;			CY	0 = message read
;				1 = no message to read
;
;-----------------------------------------------------------------------------------------------------------------------
GetMessage		push	ebx						;save non-volatile regs
			push	ecx						;
			push	ds						;
			push	ESELMQ						;load message queue selector ...
			pop	ds						;... into data segment register
			mov	ebx,[MQHead]					;head ptr
			mov	eax,[ebx]					;lo-order 32 bits
			mov	edx,[ebx+4]					;hi-order 32 bits
			or	eax,edx						;is queue empty?
			stc							;assume queue is emtpy
			jz	.20						;yes, skip ahead
			xor	ecx,ecx						;store zero
			mov	[ebx],ecx					;... in lo-order dword
			mov	[ebx+4],ecx					;... in hi-order dword
			add	ebx,8						;next queue element
			and	ebx,03fch					;at end of queue?
			jnz	.10						;no, skip ahead
			mov	bl,8						;reset to 1st entry
.10			mov	[MQHead],ebx					;save new head ptr
			clc							;indicate message read
.20			pop	ds						;restore non-volatile regs
			pop	ecx						;
			pop	ebx						;
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Memory-Mapped Video Routines
;
;	These routines read and/or write directly to CGA video memory (B800:0)
;
;	ClearConsoleScreen
;	ScrollConsoleRow
;	SetConsoleChar
;
;-----------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	ClearConsoleScreen
;
;	Description:	This routine clears the console (CGA) screen.
;
;-----------------------------------------------------------------------------------------------------------------------
ClearConsoleScreen	push	ecx						;save non-volatile regs
			push	edi						;
			push	ds						;
			push	es						;
			push	ESELDAT						;load OS Data selector ...
			pop	ds						;... into DS register
			push	ESELCGA						;load CGA selector ...
			pop	es						;... into ES register
			mov	eax,ECONCLEARDWORD				;initializtion value
			mov	ecx,ECONROWDWORDS*(ECONROWS)			;double-words to clear
			xor	edi,edi						;target offset
			cld							;forward strings
			rep	stosd						;reset screen body
			mov	eax,ECONOIADWORD				;OIA attribute and space
			mov	ecx,ECONROWDWORDS				;double-words per row
			rep	stosd						;reset OIA line
			xor	al,al						;zero register
			mov	[wbConsoleRow],al				;reset console row
			mov	[wbConsoleColumn],al				;reset console column
			call	PlaceCursor					;place cursor at current position
			pop	es						;restore non-volatile regs
			pop	ds						;
			pop	edi						;
			pop	ecx						;
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	ScrollConsoleRow
;
;	Description:	This routine scrolls the console (text) screen up one row.
;
;-----------------------------------------------------------------------------------------------------------------------
ScrollConsoleRow	push	ecx						;save non-volatile regs
			push	esi						;
			push	edi						;
			push	ds						;
			push	es						;
			push	ESELCGA						;load CGA video selector ...
			pop	ds						;... into DS
			push	ESELCGA						;load CGA video selector ...
			pop	es						;... into ES
			mov	ecx,ECONROWDWORDS*(ECONROWS-1)			;double-words to move
			mov	esi,ECONROWBYTES				;esi = source (line 2)
			xor	edi,edi						;edi = target (line 1)
			cld							;forward strings
			rep	movsd						;move 24 lines up
			mov	eax,ECONCLEARDWORD				;attribute and ASCII space
			mov	ecx,ECONROWDWORDS				;double-words per row
			rep	stosd						;clear bottom row
			pop	es						;restore non-volatile regs
			pop	ds						;
			pop	edi						;
			pop	esi						;
			pop	ecx						;
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	SetConsoleChar
;
;	Description:	This routine outputs an ASCII character at the given row and column.
;
;	In:		AL	ASCII character
;			CL	column
;			CH	row
;			ES	CGA selector
;
;-----------------------------------------------------------------------------------------------------------------------
SetConsoleChar		mov	dl,al						;ASCII character
			movzx	eax,ch						;row
			mov	ah,ECONCOLS					;cols/row
			mul	ah						;row * cols/row
			add	al,cl						;add column
			adc	ah,0						;handle carry
			shl	eax,1						;screen offset
			mov	[es:eax],dl					;store character
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Input/Output Routines
;
;	These routines read and/or write directly to ports.
;
;	PlaceCursor
;	PutPrimaryEndOfInt
;	PutSecondaryEndOfInt
;	ReadRealTimeClock
;	ResetSystem
;	SetKeyboardLamps
;	WaitForKeyInBuffer
;	WaitForKeyOutBuffer
;
;-----------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	PlaceCursor
;
;	Description:	This routine positions the cursor on the console.
;
;	In:		DS	OS data selector
;
;-----------------------------------------------------------------------------------------------------------------------
PlaceCursor		push	ecx						;save non-volatile regs
			mov	al,[wbConsoleRow]				;al = row
			mov	ah,ECONCOLS					;ah = cols/row
			mul	ah						;row offset
			add	al,[wbConsoleColumn]				;add column
			adc	ah,0						;add overflow
			mov	ecx,eax						;screen offset
			mov	dl,ECRTPORTLO					;crt controller port lo
			mov	dh,ECRTPORTHI					;crt controller port hi
			mov	al,ECRTCURLOCHI					;crt cursor loc reg hi
			out	dx,al						;select register
			inc	edx						;data port
			mov	al,ch						;hi-order cursor loc
			out	dx,al						;store hi-order loc
			dec	edx						;register select port
			mov	al,ECRTCURLOCLO					;crt cursor loc reg lo
			out	dx,al						;select register
			inc	edx						;data port
			mov	al,cl						;lo-order cursor loc
			out	dx,al						;store lo-order loc
			pop	ecx						;restore non-volatile regs
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	PutPrimaryEndOfInt
;
;	Description:	This routine sends a non-specific end-of-interrupt signal to the primary PIC.
;
;-----------------------------------------------------------------------------------------------------------------------
PutPrimaryEndOfInt	sti							;enable maskable interrupts
			mov	al,EPICEOI					;non-specific end-of-interrupt
			out	EPICPORTPRI,al					;send EOI to primary PIC
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	PutSecondaryEndOfInt
;
;	Description:	This routine sends a non-specific end-of-interrupt signal to the secondary PIC.
;
;-----------------------------------------------------------------------------------------------------------------------
PutSecondaryEndOfInt	sti							;enable maskable interrupts
			mov	al,EPICEOI					;non-specific end-of-interrupt
			out	EPICPORTSEC,al					;send EOI to secondary PIC
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	ReadRealTimeClock
;
;	Description:	This routine gets current date time from the real-time clock.
;
;	In:		DS:EBX	DATETIME structure
;
;-----------------------------------------------------------------------------------------------------------------------
ReadRealTimeClock	push	esi						;save non-volatile regs
			push	edi						;
			push	es						;
			push	ds						;store data selector ...
			pop	es						;... in es register
			mov	edi,ebx						;date-time structure
			mov	al,ERTCSECONDREG				;second register
			out	ERTCREGPORT,al					;select second register
			in	al,ERTCDATAPORT					;read second register
			cld							;forward strings
			stosb							;store second value
			mov	al,ERTCMINUTEREG				;minute register
			out	ERTCREGPORT,al					;select minute register
			in	al,ERTCDATAPORT					;read minute register
			stosb							;store minute value
			mov	al,ERTCHOURREG					;hour register
			out	ERTCREGPORT,al					;select hour register
			in	al,ERTCDATAPORT					;read hour register
			stosb							;store hour value
			mov	al,ERTCWEEKDAYREG				;weekday register
			out	ERTCREGPORT,al					;select weekday register
			in	al,ERTCDATAPORT					;read weekday register
			stosb							;store weekday value
			mov	al,ERTCDAYREG					;day register
			out	ERTCREGPORT,al					;select day register
			in	al,ERTCDATAPORT					;read day register
			stosb							;store day value
			mov	al,ERTCMONTHREG					;month register
			out	ERTCREGPORT,al					;select month register
			in	al,ERTCDATAPORT					;read month register
			stosb							;store month value
			mov	al,ERTCYEARREG					;year register
			out	ERTCREGPORT,al					;select year register
			in	al,ERTCDATAPORT					;read year register
			stosb							;store year value
			mov	al,ERTCCENTURYREG				;century register
			out	ERTCREGPORT,al					;select century register
			in	al,ERTCDATAPORT					;read century register
			stosb							;store century value
			mov	al,ERTCSTATUSREG				;status register
			out	ERTCREGPORT,al					;select status register
			in	al,ERTCDATAPORT					;read status register
			test	al,ERTCBINARYVALS				;test if values are binary
			jnz	.20						;skip ahead if binary values
			mov	esi,ebx						;date-time structure address
			mov	edi,ebx						;date-time structure address
			mov	ecx,8						;loop counter
.10			lodsb							;BCD value
			mov	ah,al						;BCD value
			and	al,00001111b					;low-order decimal zone
			and	ah,11110000b					;hi-order decimal zone
			shr	ah,1						;hi-order decimal * 8
			add	al,ah						;low-order + hi-order * 8
			shr	ah,2						;hi-order decimal * 2
			add	al,ah						;low-order + hi-order * 10
			stosb							;replace BCD with binary
			loop	.10						;next value
.20			pop	es						;restore non-volatile regs
			pop	edi						;
			pop	esi						;
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	ResetSystem
;
;	Description:	This routine restarts the system using the 8042 controller.
;
;-----------------------------------------------------------------------------------------------------------------------
ResetSystem		mov	ecx,001fffffh					;delay to clear ints
			loop	$						;clear interrupts
			mov	al,EKEYCMDRESET					;mask out bit zero
			out	EKEYPORTSTAT,al					;drive bit zero low
.10			sti							;enable maskable interrupts
			hlt							;halt until interrupt
			jmp	.10						;repeat until reset kicks in
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	SetKeyboardLamps
;
;	Description:	This routine sends the set/reset mode indicators command to the keyboard device.
;
;	In:		BH	00000CNS (C:Caps Lock,N:Num Lock,S:Scroll Lock)
;
;-----------------------------------------------------------------------------------------------------------------------
SetKeyboardLamps	call	WaitForKeyInBuffer				;wait for input buffer ready
			mov	al,EKEYCMDLAMPS					;set/reset lamps command
			out	EKEYPORTDATA,al					;send command to 8042
			call	WaitForKeyOutBuffer				;wait for 8042 result
			in	al,EKEYPORTDATA					;read 8042 'ACK' (0fah)
			call	WaitForKeyInBuffer				;wait for input buffer ready
			mov	al,bh						;set/reset lamps value
			out	EKEYPORTDATA,al					;send lamps value
			call	WaitForKeyOutBuffer				;wait for 8042 result
			in	al,EKEYPORTDATA					;read 8042 'ACK' (0fah)
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	WaitForKeyInBuffer
;
;	Description:	This routine waits for keyboard input buffer to be ready for input.
;
;	Out:		ZF	1 = Input buffer ready
;				0 = Input buffer not ready after timeout
;
;-----------------------------------------------------------------------------------------------------------------------
WaitForKeyInBuffer	push	ecx						;save non-volatile regs
			mov	ecx,EKEYWAITLOOP				;keyboard controller timeout
.10			in	al,EKEYPORTSTAT					;keyboard status byte
			test	al,EKEYBITIN					;is input buffer still full?
			loopnz	.10						;yes, repeat till timeout
			pop	ecx						;restore non-volatile regs
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	WaitForKeyOutBuffer
;
;	Description:	This routine waits for keyboard output buffer to have data to read.
;
;	Out:		ZF	0 = Output buffer has data from controller
;				1 = Output buffer empty after timeout
;
;-----------------------------------------------------------------------------------------------------------------------
WaitForKeyOutBuffer	push	ecx						;save non-volatile regs
			mov	ecx,EKEYWAITLOOP				;keyboard controller timeout
.10			in	al,EKEYPORTSTAT					;keyboard status byte
			test	al,EKEYBITOUT					;output buffer status bit
			loopz	.10						;loop until output buffer bit
			pop	ecx						;restore non-volatile regs
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	End of the Kernel Function Library
;
;-----------------------------------------------------------------------------------------------------------------------
			times	8190-($-$$) db 0h				;zero fill to end of section
			db	055h,0AAh					;end of segment
;-----------------------------------------------------------------------------------------------------------------------
;
;	Console Task
;
;	The only task defined in the kernel is the console task. This task consists of code, data, stack, and task state
;	segments and a local descriptor table. The console task accepts and echos user keyboard input to the console
;	screen and responds to user commands.
;
;-----------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------
;
;	Console Stack								@disk: 007400	@mem:  004000
;
;	This is the stack for the console task. It supports 448 nested calls.
;
;-----------------------------------------------------------------------------------------------------------------------
section			constack						;console task stack
			times	1792-($-$$) db 0h				;zero fill to end of section
;-----------------------------------------------------------------------------------------------------------------------
;
;	Console Local Descriptor Table						@disk: 007B00	@mem:  004700
;
;	This is the LDT for the console task. It defines the stack, code, data and queue segments as well as data
;	aliases for the TSS LDT. Data aliases allow inspection and altering of the TSS and LDT. This LDT can hold up to
;	16 descriptors. Six are initially defined.
;
;-----------------------------------------------------------------------------------------------------------------------
section			conldt							;console local descriptors
			dq	004093004780007Fh				;04 TSS alias
			dq	004093004700007Fh				;0C LDT alias
			dq	00409300400006FFh				;14 stack
			dq	00CF93000000FFFFh				;1C data
			dq	00409B0050000FFFh				;24 code
			dq	00409300480007FFh				;2C message queue
			times	128-($-$$) db 0h				;zero fill to end of section
;-----------------------------------------------------------------------------------------------------------------------
;
;	Console Task State Segment						@disk: 007B80	@mem:  004780
;
;	This is the TSS for the console task. All rings share the same stack. DS and ES are set to the console data
;	segment. CS to console code.
;
;-----------------------------------------------------------------------------------------------------------------------
section			contss							;console task state segment
			dd	0						;00 back-link tss
			dd	0700h						;04 esp ring 0
			dd	0014h						;08 ss ring 0
			dd	0700h						;0C esp ring 1
			dd	0014h						;10 es ring 1
			dd	0700h						;14 esp ring 2
			dd	0014h						;18 ss ring 2
			dd	0						;1C cr ring 3
			dd	0						;20 eip
			dd	0200h						;24 eflags
			dd	0						;28 eax
			dd	0						;2C ecx
			dd	0						;30 edx
			dd	0						;34 ebx
			dd	0700h						;38 esp ring 3
			dd	0						;3C ebp
			dd	0						;40 esi
			dd	0						;44 edi
			dd	001Ch						;48 es
			dd	0024h						;4C cs
			dd	0014h						;50 ss ring 3
			dd	001Ch						;54 ds
			dd	0						;58 fs
			dd	0						;5c gs
			dd	0050h						;60 ldt selector in gdt
			times	128-($-$$) db 0h				;zero fill to end of section
;-----------------------------------------------------------------------------------------------------------------------
;
;	Console Message Queue							@disk: 007C00	@mem: 004800
;
;	The console message queue is 2048 bytes of memory organized as a queue of 510 double words (4 bytes each) and
;	two double word values that act as indices. The queue is a FIFO that is fed by the keyboard hardware interrupt
;	handler and consumed by a service routine called from a task. Each queue entry defines an input (keystroke)
;	event.
;
;-----------------------------------------------------------------------------------------------------------------------
section			conmque							;console message queue
			dd	8						;head pointer
			dd	8						;tail pointer
			times	510 dd 0					;queue elements
;-----------------------------------------------------------------------------------------------------------------------
;
;	Console Code								@disk: 008400	@mem: 005000
;
;	This is the code for the console task. The task is defined in the GDT in two descriptors, the Local Descriptor
;	Table (LDT) at 0050h and the Task State Segment (TSS) at 0058h. Jumping to or calling a TSS selector causes a
;	task switch, giving control to the code for the task at the CS:IP defined in the TSS for the current ring level.
;	The initial CS:IP in the Console TSS is 24h:0, where 24h is a selector in the LDT. This selector points to the
;	concode section, loaded into memory 5000h by the Loader. The console task is dedicated to accepting user key-
;	board input, echoing to the console screen and responding to user commands.
;
;	When control reaches this section, our addressability is set up according to the following diagram.
;
;	DS,ES --------> 000000	+-----------------------------------------------+ DS,ES:0000
;				|  Real Mode Interrupt Vectors			|
;			000400	+-----------------------------------------------+ DS,ES:0400
;				|  Reserved BIOS Memory Area			|
;			000800	+-----------------------------------------------+ DS,ES:0800
;				|  Shared Kernel Memory Area			|
;			001000	+-----------------------------------------------+		<-- GDTR
;				|  Global Descriptor Table (GDT)		|
;			001800	+-----------------------------------------------+		<-- IDTR
;				|  Interrupt Descriptor Table (IDT)		|
;			002000	+-----------------------------------------------+
;				|  Interrupt Handlers				|
;				|  Kernel Function Library			|
;	SS ----------->	004000	+===============================================+ SS:0000
;				|  Console Task Stack Area			|
;	SS:SP --------> 004700	+-----------------------------------------------+ SS:0700	<-- LDTR = GDT.SEL 0050h
;				|  Console Task Local Descriptor Table (LDT)	|
;			004780	+-----------------------------------------------+		<-- TR  = GDT.SEL 0058h
;				|  Console Task Task State Segment (TSS)	|
;			004800	+-----------------------------------------------+
;				|  Console Task Message Queue			|
;	CS,CS:IP ----->	005000	+-----------------------------------------------+ CS:0000
;				|  Console Task Code				|
;				|  Console Task Constants			|
;			006000	+===============================================+
;
;-----------------------------------------------------------------------------------------------------------------------
section			concode	vstart=5000h					;labels relative to 5000h
ConCode			call	ConInitializeData				;initialize console variables

			clearConsoleScreen					;clear the console screen
			putConsoleString czTitle				;display startup message
.10			putConsoleString czPrompt				;display input prompt
			placeCursor						;set CRT cursor location
			getConsoleString wzConsoleInBuffer,79,1,13		;accept keyboard input
			putConsoleString czNewLine				;newline

			mov	byte [wzConsoleToken],0				;null-terminate token buffer
			mov	edx,wzConsoleInBuffer				;console input buffer
			mov	ebx,wzConsoleToken				;token buffer
			call	ConTakeToken					;handle console input
			mov	edx,wzConsoleToken				;token buffer
			call	ConDetermineCommand				;determine command number
			cmp	eax,ECONJMPTBLCNT				;valid command number?
			jb	.20						;yes, branch

			putConsoleString czUnknownCommand			;display error message

			jmp	.10						;next command
.20			shl	eax,2						;index into jump table
			mov	edx,tConJmpTbl					;jump table base address
			mov	eax,[edx+eax]					;command handler routine address
			call	eax						;call command handler
			jmp	.10						;next command
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	ConInitializeData
;
;	Description:	This routine initializes console task variables.
;
;-----------------------------------------------------------------------------------------------------------------------
ConInitializeData	push	ecx						;save non-volatile regs
			push	edi						;
			push	es						;
			push	ESELDAT						;load OS data selector ...
			pop	es						;... into extra segment register
			mov	edi,ECONDATA					;OS console data address
			xor	al,al						;initialization value
			mov	ecx,ECONDATALEN					;size of OS console data
			cld							;forward strings
			rep	stosb						;initialize data
			pop	es						;restore non-volatile regs
			pop	edi						;
			pop	ecx						;
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	ConTakeToken
;
;	Description:	This routine extracts the next token from the given source buffer.
;
;	In:		DS:EDX	source buffer address
;			DS:EBX	target buffer address
;
;	Out:		DS:EDX	source buffer address
;			DS:EBX	target buffer address
;
;	Command Form:	Line	= *3( *SP 1*ALNUM )
;
;-----------------------------------------------------------------------------------------------------------------------
ConTakeToken		push	esi						;save non-volatile regs
			push	edi						;
			mov	esi,edx						;source buffer address
			mov	edi,ebx						;target buffer address
			cld							;forward strings
.10			lodsb							;load byte
			cmp	al,EASCIISPACE					;space?
			je	.10						;yes, continue
			test	al,al						;end of line?
			jz	.40						;yes, branch
.20			stosb							;store byte
			lodsb							;load byte
			test	al,al						;end of line?
			jz	.40						;no, continue
			cmp	al,EASCIISPACE					;space?
			jne	.20						;no, continue
.30			lodsb							;load byte
			cmp	al,EASCIISPACE					;space?
			je	.30						;yes, continue
			dec	esi						;pre-position
.40			mov	byte [edi],0					;terminate buffer
			mov	edi,edx						;source buffer address
.50			lodsb							;remaining byte
			stosb							;move to front of buffer
			test	al,al						;end of line?
			jnz	.50						;no, continue
			pop	edi						;restore non-volatile regs
			pop	esi						;
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	ConDetermineCommand
;
;	Description:	This routine determines the command number for the command at DS:EDX.
;
;	input:		DS:EDX	command address
;
;	output:		EAX	>=0	= command nbr
;				0	= unknown command
;
;-----------------------------------------------------------------------------------------------------------------------
ConDetermineCommand	push	ebx						;save non-volatile regs
			push	esi						;
			push	edi						;

			upperCaseString						;upper-case string at EDX

			mov	esi,tConCmdTbl					;commands table
			xor	edi,edi						;intialize command number
			cld							;forward strings
.10			lodsb							;command length
			movzx	ecx,al						;command length
			jecxz	.20						;branch if end of table
			mov	ebx,esi						;table entry address
			add	esi,ecx						;next table entry address

			compareMemory						;compare byte arrays at EDX, EBX

			jecxz	.20						;branch if equal
			inc	edi						;increment command nbr
			jmp	.10						;repeat
.20			mov	eax,edi						;command number
			pop	edi						;restore non-volatile regs
			pop	esi						;
			pop	ebx						;
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	ConClear
;
;	Description:	This routine handles the CLEAR command and its CLS alias.
;
;-----------------------------------------------------------------------------------------------------------------------
ConClear		clearConsoleScreen					;clear console screen
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	ConDate
;
;	Description:	This routine handles the DATE command.
;
;-----------------------------------------------------------------------------------------------------------------------
ConDate			readRealTimeClock wsConsoleDateTime			;read RTC data into structure
			putDateString	  wsConsoleDateTime, wzConsoleOutBuffer	;format date string
			putConsoleString  wzConsoleOutBuffer			;write string to console
			putConsoleString  czNewLine				;write newline to console
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	ConExit
;
;	Description:	This routine handles the EXIT command and its SHUTDOWN and QUIT aliases.
;
;-----------------------------------------------------------------------------------------------------------------------
ConExit			resetSystem						;issue system reset
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	ConMem
;
;	Description:	This routine handles the MEMORY command and its MEM alias.
;
;	Input:		wzConsoleInBuffer contains parameter(s)
;
;-----------------------------------------------------------------------------------------------------------------------
ConMem			push	ebx						;save non-volatile regs
			push	esi						;
			push	edi						;
;
;			update the source address if a parameter is given
;
			mov	edx,wzConsoleInBuffer				;console input buffer address (params)
			mov	ebx,wzConsoleToken				;console command token address
			call	ConTakeToken					;take first param as token
			cmp	byte [wzConsoleToken],0				;token found?
			je	.10						;no, branch
			mov	edx,wzConsoleToken				;first param as token address

			hexadecimalToUnsigned					;convert string token to unsigned

			mov	[wfConsoleMemAddr],eax				;save console memory address
;
;			setup source address and row count
;
.10			mov	esi,[wfConsoleMemAddr]				;source memory address
			xor	ecx,ecx						;zero register
			mov	cl,16						;row count
;
;			start the row with the source address in hexadecimal
;
.20			push	ecx						;save remaining rows
			mov	edi,wzConsoleOutBuffer				;output buffer address
			mov	edx,edi						;output buffer address
			mov	ecx,esi						;console memory address

			unsignedToHexadecimal					;convert unsigned address to hex string

			add	edi,8						;end of memory addr hexnum
			mov	al,' '						;ascii space
			stosb							;store delimiter
;
;			output 16 ASCII hexadecimal byte values for the row
;
			xor	ecx,ecx						;zero register
			mov	cl,16						;loop count
.30			push	ecx						;save loop count
			lodsb							;memory byte
			mov	ah,al						;memory byte
			shr	al,4						;high-order in bits 3-0
			or	al,30h						;apply ascii numeric zone
			cmp	al,3ah						;numeric range?
			jb	.40						;yes, skip ahead
			add	al,7						;adjust ascii for 'A'-'F'
.40			stosb							;store ascii hexadecimal of high-order
			mov	al,ah						;low-order in bits 3-0
			and	al,0fh						;mask out high-order bits
			or	al,30h						;apply ascii numeric zone
			cmp	al,3ah						;numeric range?
			jb	.50						;yes, skip ahead
			add	al,7						;adjust ascii for 'A'-'F'
.50			stosb							;store ascii hexadecimal of low-order
			mov	al,' '						;ascii space
			stosb							;store ascii space delimiter
			pop	ecx						;loop count
			loop	.30						;next
;
;			output printable ASCII character section for the row
;
			sub	esi,16						;reset source pointer
			mov	cl,16						;loop count
.60			lodsb							;source byte
			cmp	al,32						;printable? (low-range test)
			jb	.70						;no, skip ahead
			cmp	al,128						;printable? (high-range test)
			jb	.80						;yes, skip ahead
.70			mov	al,' '						;display space instead of printable
.80			stosb							;store printable ascii byte
			loop	.60						;next source byte
			xor	al,al						;nul-terminator
			stosb							;terminate output line
;
;			display constructed output buffer and newline
;
			putConsoleString wzConsoleOutBuffer			;display constructed output
			putConsoleString czNewLine				;display new line
;
;			repeat until all lines displayed and preserve source address
;
			pop	ecx						;remaining rows
			loop	.20						;next row
			mov	[wfConsoleMemAddr],esi				;update console memory address
			pop	edi						;restore regs
			pop	esi						;
			pop	ebx						;
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	ConTime
;
;	Description:	This routine Handles the TIME command.
;
;-----------------------------------------------------------------------------------------------------------------------
ConTime			readRealTimeClock wsConsoleDateTime			;read RTC data into structure
			putTimeString	  wsConsoleDateTime,wzConsoleOutBuffer	;format time string
			putConsoleString  wzConsoleOutBuffer			;write string to console
			putConsoleString  czNewLine				;write newline to console
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Routine:	ConVersion
;
;	Description:	This routine handles the VERSION command and its alias, VER.
;
;-----------------------------------------------------------------------------------------------------------------------
ConVersion		putConsoleString czTitle				;display version message
			ret							;return
;-----------------------------------------------------------------------------------------------------------------------
;
;	Tables
;
;-----------------------------------------------------------------------------------------------------------------------
										;---------------------------------------
										;  Command Jump Table
										;---------------------------------------
tConJmpTbl		equ	$						;command jump table
			dd	ConExit		- ConCode			;shutdown command routine offset
			dd	ConVersion	- ConCode			;version command routine offset
			dd	ConMem		- ConCode			;memory command routine offset
			dd	ConClear	- ConCode			;clear command routine offset
			dd	ConDate		- ConCode			;date command routine offset
			dd	ConExit		- ConCode			;exit command routine offset
			dd	ConExit		- ConCode			;quit command routine offset
			dd	ConTime		- ConCode			;time command routine offset
			dd	ConClear	- ConCode			;cls command routine offset
			dd	ConMem		- ConCode			;mem command routine offset
			dd	ConVersion	- ConCode			;ver command routine offset
ECONJMPTBLL		equ	($-tConJmpTbl)					;table length
ECONJMPTBLCNT		equ	ECONJMPTBLL/4					;table entries
										;---------------------------------------
										;  Command Name Table
										;---------------------------------------
tConCmdTbl		equ	$						;command name table
			db	9,"SHUTDOWN",0					;shutdown command
			db	8,"VERSION",0					;version command
			db	7,"MEMORY",0					;memory command
			db	6,"CLEAR",0					;clear command
			db	5,"DATE",0					;date command
			db	5,"EXIT",0					;exit command
			db	5,"QUIT",0					;quit command
			db	5,"TIME",0					;time command
			db	4,"CLS",0					;cls command
			db	4,"MEM",0					;mem command
			db	4,"VER",0					;ver command
			db	0						;end of table
;-----------------------------------------------------------------------------------------------------------------------
;
;	Constants
;
;-----------------------------------------------------------------------------------------------------------------------
czTitle			db	"Custom Operating System 1.0",13,10,0		;version string
czPrompt		db	":",0						;prompt string
czUnknownCommand	db	"Unknown command",13,10,0			;unknown command response string
czNewLine		db	13,10,0						;new line string
			times	4094-($-$$) db 0h				;zero fill to end of section
			db	055h,0AAh					;end of section
%endif
%ifdef BUILDDISK
;-----------------------------------------------------------------------------------------------------------------------
;
;	Free Disk Space								@disk: 009400	@mem:  n/a
;
;	Following the convention introduced by DOS, we use the value 'F6' to indicate unused floppy disk storage.
;
;-----------------------------------------------------------------------------------------------------------------------
section			unused							;unused disk space
			times	EBOOTDISKBYTES-09400h db 0F6h			;fill to end of disk image
%endif
