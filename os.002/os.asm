;-----------------------------------------------------------------------------------------------------------------------
;
;	File:		os.asm
;
;	Project:	os.002
;
;	Description:	This sample program adds code to load the operating system kernel program from the disk image.
;			The boot sector now searches the disk for the loader program, loads it into memory and runs it.
;			The loader program in this sample simply displays a greeting.
;
;	Revised:	January 1, 2017
;
;	Assembly:	nasm os.asm -f bin -o os.dat -l os.dat.lst -DBUILDBOOT
;			nasm os.asm -f bin -o os.dsk -l os.dsk.lst -DBUILDDISK
;			nasm os.asm -f bin -o os.com -l os.com.lst -DBUILDCOM
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
;	BUILDBOOT	Creates os.dat, a 512-byte boot sector, as a standalone file.
;	BUILDDISK	Creates os.dsk, a 1.44MB (3.5") floppy disk image file.
;	BUILDCOM	Creates os.com, the OS loader and kernel as a standalone DOS program.
;
;-----------------------------------------------------------------------------------------------------------------------
%ifdef BUILDDISK
%define BUILDBOOT
%define BUILDCOM
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
;
;	Routines:	Routine names are in mixed case (GetYear, ReadRealTimeClock)
;			Routine names begin with a verb (Get, Read, etc.)
;
;	Constants:	Symbolic constants (equates) are named in all-caps beginning with 'E' (EDATAPORT).
;			Constant stored values are named in camel case, starting with 'c'.
;			The 2nd letter indicates the storage type.
;			cq......	constant quad-word (dq)
;			cd......	constant double-word (dd)
;			cw......	constant word (dw)
;			cb......	constant byte (db)
;			cz......	constant ASCIIZ (null-terminated) string
;
;	Variables:	Variables are named in camel case, starting with 'w'.
;			The 2nd letter indicates storage type.
;			wq......	variable quad-word (resq)
;			wd......	variable double-word (resd)
;			ww......	variable word (resw)
;			wb......	variable byte (resb)
;
;	Structures:	Structure names are in all-caps (DATETIME).
;
;	Macros:		Macro names are in camel case (getDateString).
;
;	Registers:	Registers EBX, ECX, ESI, EDI, DS and ES are preserved by all OS routines.
;			Register EAX is preferred for returning a response/result value.
;			Register EBX is preferred for passing a context (structure) address parameter.
;			Registers EAX, EDX and EDX are preferred for passing integral parameters.
;
;-----------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------
;
;	Equates
;
;	The equate (equ) statements define symbolic names for fixed values so that these values can be defined and
;	verified once and then used throughout the code. Using symbolic names simplifies searching for where logical
;	values are used. Equate names are in all-caps and are the only symbolic names that begin with the letter 'E'.
;
;	Equates are grouped into related sets below. Hardware-based equates are listed first, followed by BIOS and
;	protocol equates and, lastly, application equates.
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
EBIOSINTDISKETTE	equ	013h						;BIOS diskette services interrupt
EBIOSINTKEYBOARD	equ	016h						;BIOS keyboard services interrupt
EBIOSFNKEYSTATUS	equ	001h						;BIOS keyboard status function
;-----------------------------------------------------------------------------------------------------------------------
;
;	Loader Constants
;
;-----------------------------------------------------------------------------------------------------------------------
EFATBUFFER		equ	400h						;FAT I/O address relative to DS:
EMAXTRIES		equ	5						;max read retries
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
cwSectorBytes		dw	512						;bytes per sector
cbClusterSectors	db	1						;sectors per cluster
cwReservedSectors	dw	1						;reserved sectors
cbFatCount		db	2						;file allocation table copies
cwDirEntries		dw	224						;max directory entries
cwDiskSectors		dw	2880						;sectors per disk
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
			sub	ax,word .@20					;BX =	   7c00     c00     0
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
			sub	bx,byte 16					;BX = 07b0
			mov	ds,bx						;DS = 07b0 = psp
			mov	es,bx						;ES = 07b0 = psp
			mov	ss,bx						;SS = 07b0 = psp
			mov	sp,EFATBUFFER					;SP = 0400
;
;	Our boot addressability is now set up according to the following diagram.
;
;	DS,ES,SS ----->	007b00	+-----------------------------------------------+
;				|  Program Segment Prefix (PSP)			|
;			007c00	+-----------------------------------------------+
;				|  Boot Sector Code				|
;				|						|
;			007e00	+-----------------------------------------------+
;				|  Boot Stack					|
;	SS:SP -------->	007f00	+-----------------------------------------------+
;				|  FAT I/O Buffer (used in later programs)	|
;				+-----------------------------------------------+
;
;	On entry, DL indicates the drive being booted from.
;
			mov	[wbDrive],dl					;[drive] = drive being booted from
;
;	Compute directory i/o buffer address.
;
			mov	ax,[cwFatSectors]				;AX = 0009 = FAT sectors
			mul	word [cwSectorBytes]				;DX:AX = 0000:1200 = FAT bytes
			add	ax,EFATBUFFER					;AX = 1600 = end of FAT buffer
			mov	[wwDirBuffer],ax				;[dirbuffer] = 1600
;
;	Compute segment where os.com will be loaded.
;
			shr	ax,cl						;AX = 0160
			add	ax,bx						;AX = 0160 + 07b0 = 0910
			sub	ax,byte 16					;AX = 0900
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
			mov	byte [wbReadCount],al				;[readcount] = 01
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
			cmp	word [wwEntriesLeft],byte 0			;done with directory?
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
			mov	bx,EFATBUFFER					;BX = 0400
			call	ReadSector					;read FAT into buffer
;
;	Get the starting cluster of the kernel program and target address.
;
			mov	ax,word [di+26]					;AX = starting cluster of file
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
			and	di,byte 1					;get low bit
			add	di,ax						;add one if cluster is odd
			add	di,EFATBUFFER					;add FAT buffer address
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
wwLoadSegment		dw	0900h						;kernel entry segment
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
			sti							;enable interrupts
			hlt							;wait for interrupt
			jmp	short .10					;repeat
.20			mov	al,EKEYCMDRESET					;8042 pulse output port pin
			out	EKEYPORTSTAT,al					;drive B0 low to restart
.30			sti							;enable interrupts
			hlt							;stop until reset, int, nmi
			jmp	short .30					;loop until restart kicks in
;
;	Display text message.
;
BootPrint		cld							;forward strings
			lodsb							;load next byte at DS:SI in AL
			test	al,al						;end of string?
			jz	BootReturn					;... yes, exit our loop
			mov	ah,EBIOSFNTTYOUTPUT				;BIOS teletype function
			int	EBIOSINTVIDEO					;call BIOS display interrupt
			jmp	short BootPrint					;repeat until done
BootReturn		ret							;return to caller
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
%ifdef BUILDDISK
;-----------------------------------------------------------------------------------------------------------------------
;
;	File Allocation Tables
;
;	The disk contains two copies of the File Allocation Table (FAT). On our disk, each FAT copy is 1200h bytes in
;	length. Each FAT entry contains the logical number of the next cluster. The first two entries are reserved. Our
;	OS.COM file here is 200h bytes in length. These 200h bytes contain familiar code that displays a message to the
;	screen. Our disk parameter table defines a cluster as containing one sector and each sector having 200h bytes.
;	Therefore, our FAT table must reserve only one cluster for OS.COM. The cluster used by OS.COM, then, will be
;	cluster 2. The entry value for this cluster is set to "0fffh" to indicate that it is the last cluster in the
;	chain.
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
			db	0F0h,0FFh,0FFh,	0FFh,00Fh,000h
			times	(9*512)-($-$$) db 0				;zero fill to end of section
;-----------------------------------------------------------------------------------------------------------------------
;
;	FAT copy 2								@disk: 001400	@mem: n/a
;
;-----------------------------------------------------------------------------------------------------------------------
section			fat2							;second copy of FAT
			db	0F0h,0FFh,0FFh,	0FFh,00Fh,000h
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
			dd	200h						;file size
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
;	Now we want to wait for a keypress. We can use a keyboard interrupt function for this (INT 16h, AH=0).
;	However, some BIOS implementations, such as VirtualBox, seem to implement the "wait" as simply a fast
;	iteration of the keyboard status function call (INT 16h, AH=1), causing a CPU race condition. So, instead
;	we will use the keyboard status call and iterate over a halt (HLT) instruction until a key is pressed.
;	By convention, we enable maskable interrupts with STI before issuing HLT, so as not to catch fire. j/k.
;
.30			mov	ah,EBIOSFNKEYSTATUS				;keyboard status function
			int	EBIOSINTKEYBOARD				;call BIOS keyboard interrupt
			jnz	.40						;exit if key pressed
			sti							;enable interrupts
			hlt							;wait for interrupt
			jmp	short .30					;repeat until keypress
;
;	Now that a key has been pressed, we signal the system to restart by driving the B0 line on the 8042
;	keyboard controller low (OUT 64h,0feh). The restart may take some microseconds to kick in, so we issue
;	HLT until the system resets.
;
.40			mov	al,EKEYCMDRESET					;8042 pulse output port pin
			out	EKEYPORTSTAT,al					;drive B0 low to restart
.50			sti							;enable interrupts
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
;	feed (10) values. The remainder of the sector is filled with the typical bit pattern of unused disk space. The
;	sector finally ends with a conventional two-byte signature. The use of filler helps indicate, when looking at
;	program listings or the assembled sector itself, how much space remains unused in the sector.
;
;-----------------------------------------------------------------------------------------------------------------------
czStartingMsg		db	"Starting ...",13,10,0				;loader message
			times	510-($-$$) db 0h				;zero fill to end of sector
			db	055h,0AAh					;end of sector signature
%endif
%ifdef BUILDDISK
;-----------------------------------------------------------------------------------------------------------------------
;
;	Free Disk Space								@disk: 004400	@mem:  n/a
;
;-----------------------------------------------------------------------------------------------------------------------
section			unused							;unused disk space
			times	1474560-17408 db 0F6h				;fill to end of disk image
%endif
