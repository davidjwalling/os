;=======================================================================================================================
;
;       File:           os.asm
;
;       Project:        os.005
;
;       Description:    This sample program extends the console task to add support for panels, groups of fields
;                       displayed together on the screen. A main panel is defined for the console task.
;
;       Revised:        1 January 2020
;
;       Assembly:       nasm os.asm -f bin -o os.dat     -l os.dat.lst     -DBUILDBOOT
;                       nasm os.asm -f bin -o os.dsk     -l os.dsk.lst     -DBUILDDISK
;                       nasm os.asm -f bin -o os.com     -l os.com.lst     -DBUILDCOM
;                       nasm os.asm -f bin -o osprep.com -l osprep.com.lst -DBUILDPREP
;
;       Assembler:      Netwide Assembler (NASM) 2.14.02, 26 Dec 2018
;
;       Notice:         Copyright (C) 2010-2020 David J. Walling
;
;=======================================================================================================================
;-----------------------------------------------------------------------------------------------------------------------
;
;       Assembly Directives
;
;       Use one of the following as an assembly directive (-D) with NASM.
;
;       BUILDBOOT       Creates os.dat, a 512-byte boot sector as a standalone file.
;       BUILDDISK       Creates os.dsk, a 1.44MB (3.5") floppy disk image file.
;       BUILDCOM        Creates os.com, the OS loader and kernel as a standalone DOS program.
;       BUILDPREP       Creates osprep.com, a DOS program that prepares a floppy disk to boot the OS.
;
;-----------------------------------------------------------------------------------------------------------------------
%ifdef BUILDDISK                                                                ;if we are building a disk image ...
%define BUILDBOOT                                                               ;... also build the boot sector
%define BUILDCOM                                                                ;... and the OS kernel
%endif
%ifdef BUILDPREP                                                                ;if creating the disk prep program ...
%define BUILDBOOT                                                               ;... also build the boot sector
%endif
;-----------------------------------------------------------------------------------------------------------------------
;
;       Conventions
;
;       Alignment:      In this document, columns are numbered beginning with 1. Logical tabs are set after every
;                       eight columns. Tabs are simulated using SPACE characters. Comments that span an entire line
;                       have a semicolon in line 1 and text begins in column 9. Assembly instructions (mnemonics)
;                       begin in column 25. Assembly operands begin in column 33. Inline comments begin in column 81.
;                       Lines should not extend beyond column 120.
;
;       Arguments:      Arguments are passed as registers and generally follow this order: EAX, ECX, EDX, EBX. ECX
;                       may be used as the sole parameter if a test for zero is required. EBX and EBP may be used as
;                       parameters if the routine is considered a "method" of an "object". In this case, EBX or EBP
;                       will address the object storage. If the routine is a general-purpose string or byte-array
;                       manipulator, ESI and EDI may be used as parameters to address input and/or ouput buffers.
;
;       Code Order:     Routines should appear in the order of their first likely use. Negative relative call or jump
;                       addresses usually, therefore, indicate reuse.
;
;       Comments:       A comment that spans the entire line begins with a semicolon in column 1. A comment that
;                       accompanies code on a line begins with a semicolon in column 81. Register names in comments
;                       are in upper case (EAX, EDI). Hexadecimal values in comments are in lower case (01fh, 0dah).
;                       Routines are preceded with a comment box that includes the routine name, description, and
;                       register contents on entry and exit, if applicable.
;
;       Constants:      Symbolic constants (equates) are named in all-caps beginning with 'E' (EDATAPORT). Constant
;                       stored values are named in camel case, starting with 'c' (cbMaxLines). The 2nd letter of the
;                       constant label indicates the storage type.
;
;                       cq......        constant quad-word (dq)
;                       cd......        constant double-word (dd)
;                       cw......        constant word (dw)
;                       cb......        constant byte (db)
;                       cz......        constant ASCIIZ (null-terminated) string
;                       cs......        constant non-terminated string (sequence of characters)
;
;       Instructions:   32-bit instructions are generally favored. 8-bit instructions and data are preferred for
;                       flags and status fields, etc. 16-bit instructions are avoided wherever possible to limit
;                       the generation of prefix bytes.
;
;       Labels:         Labels within a routine are numeric and begin with a period (.10, .20). Labels within a
;                       routine begin at ".10" and increment by 10.
;
;       Literals:       Literal values defined by external standards should be defined as symbolic constants
;                       (equates). Hexadecimal literals in code are in upper case with a leading '0' and trailing
;                       'h' (01Fh). Binary literal values in source code are encoded with a final 'b' (1010b).
;                       Decimal literal values in source code are strictly numerals (2048). Octal literal values
;                       are avoided. String literals are enclosed in double quotes, e.g. "Loading OS". Single
;                       character literals are enclosed in single quotes, e.g. 'A'.
;
;       Macros:         Macro names are in camel case, beginning with a lower-case letter (getDateString). Macro
;                       names describe an action and begin with a verb.
;
;       Memory Use:     Operating system memory allocation is avoided. Buffers are kept to as small a size as
;                       practicable. Data and code intermingling is avoided.
;
;       Registers:      Register names in comments are in upper case (EAX, EDX). Register names in source code are
;                       in lower case (eax, edx).
;
;       Return Values:  Routines return result values in EAX or ECX or both. Routines should indicate failure by
;                       setting the carry flag to 1. Routines may prefer the use of ECX as a return value if the
;                       value is to be tested for null upon return (using the jecxz instruction).
;
;       Routines:       Routine names are in mixed case and capitalized (GetYear, ReadRealTimeClock). Routine names
;                       begin with a verb (Get, Read, Load). Routines should have a single entry address and a single
;                       exit instruction (ret, iretd, etc.). Routines that serve as wrappers for library functions
;                       carry the same name as the library function but begin with a leading underscore (_) character.
;
;       Structures:     Structure names are in all-caps (DATETIME). Structure names describe a "thing" and so do NOT
;                       begin with a verb.
;
;       Usage:          Registers EBX, ECX, EBP, SS, CS, DS and ES are preserved by routines. Registers ESI and EDI
;                       are preserved unless they are input parameters. Registers EAX and ECX are preferred for
;                       returning response/result values. Registers EBX and EBP are preferred for context (structure)
;                       address parameters. Registers EAX, ECX, EDX and EBX are preferred for integral parameters.
;
;       Variables:      Variables are named in camel case, starting with 'w'. The 2nd letter of the variable label
;                       indicates the storage type.
;
;                       wq......        variable quad-word (resq)
;                       wd......        variable double-word (resd)
;                       ww......        variable word (resw)
;                       wb......        variable byte (resb)
;                       ws......        writable structure
;
;-----------------------------------------------------------------------------------------------------------------------
;=======================================================================================================================
;
;       Equates
;
;       The equate (equ) statement defines a symbolic name for a fixed value so that such a value can be defined and
;       verified once and then used throughout the code. Using symbolic names simplifies searching for where logical
;       values are used. Equate names are in all-caps and begin with the letter 'E'. Equates are grouped into related
;       sets. Equates in this sample program are defined in the following groupings:
;
;       Hardware-Defined Values
;
;       ECRT...         6845 Cathode Ray Tube (CRT) Controller values
;       EFDC...         NEC 765 Floppy Disk Controller (FDC) values
;       EKEYB...        8042 or "PS/2 Controller" (Keyboard Controller) values
;       EPIC...         8259 Programmable Interrupt Controller (PIC) values
;       EPIT...         8253 Programmable Interval Timer (PIT) values
;       EX86...         Intel x86 CPU architecture values
;
;       Firmware-Defined Values
;
;       EBIOS...        Basic Input/Output System (BIOS) values
;
;       Standards-Based Values
;
;       EASCII...       American Standard Code for Information Interchange (ASCII) values
;
;       Operating System Values
;
;       EBOOT...        Boot sector and loader values
;       ECON...         Console values (dimensions and attributes)
;       EGDT...         Global Descriptor Table (GDT) selector values
;       EKRN...         Kernel values (fixed locations and sizes)
;
;=======================================================================================================================
;-----------------------------------------------------------------------------------------------------------------------
;
;       Hardware-Defined Values
;
;-----------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------
;
;       6845 Cathode Ray Tube (CRT) Controller                                  ECRT...
;
;       The Motorola 6845 CRT Controller (CRTC) is a programmable controller
;       for CGA, EGA, VGA and compatible video modes.
;
;-----------------------------------------------------------------------------------------------------------------------
ECRTPORTHI              equ     003h                                            ;controller port hi
ECRTPORTLO              equ     0D4h                                            ;controller port lo
ECRTCURLOCHI            equ     00Eh                                            ;cursor loc reg hi
ECRTCURLOCLO            equ     00Fh                                            ;cursor loc reg lo
;-----------------------------------------------------------------------------------------------------------------------
;
;       NEC 765 Floppy Disk Controller (FDC)                                    EFDC...
;
;       The NEC 765 FDC is a programmable controller for floppy disk drives.
;
;-----------------------------------------------------------------------------------------------------------------------
EFDCPORTHI              equ     003h                                            ;controller port hi
EFDCPORTLOOUT           equ     0F2h                                            ;digital output register lo
EFDCPORTLOSTAT          equ     0F4h                                            ;main status register lo
EFDCSTATBUSY            equ     010h                                            ;main status is busy
EFDCMOTOROFF            equ     00Ch                                            ;motor off / enable / DMA
;-----------------------------------------------------------------------------------------------------------------------
;
;       8042 Keyboard Controller                                                EKEYB...
;
;       The 8042 Keyboard Controller (8042) is a programmable controller that accepts input signals from the keyboard
;       device. It also signals a hardware interrupt to the CPU when the low-order bit of I/O port 64h is set to zero.
;
;-----------------------------------------------------------------------------------------------------------------------
EKEYBPORTSTAT           equ     064h                                            ;status port
EKEYBCMDRESET           equ     0FEh                                            ;reset bit 0 to restart system
;-----------------------------------------------------------------------------------------------------------------------
;
;       8259 Peripheral Interrupt Controller                                    EPIC...
;
;       The 8259 Peripheral Interrupt Controller (PIC) is a programmable controller that accepts interrupt signals from
;       external devices and signals a hardware interrupt to the CPU.
;
;-----------------------------------------------------------------------------------------------------------------------
EPICPORTPRI             equ     020h                                            ;primary control port 0
EPICPORTPRI1            equ     021h                                            ;primary control port 1
EPICPORTSEC             equ     0A0h                                            ;secondary control port 0
EPICPORTSEC1            equ     0A1h                                            ;secondary control port 1
EPICEOI                 equ     020h                                            ;non-specific EOI code
;-----------------------------------------------------------------------------------------------------------------------
;
;       8253 Programmable Interval Timer                                        EPIT...
;
;       The Intel 8253 Programmable Interval Timer (PIT) is a chip that produces a hardware interrupt (IRQ0)
;       approximately 18.2 times per second.
;
;-----------------------------------------------------------------------------------------------------------------------
EPITDAYTICKS            equ     01800B0h                                        ;ticks per day
;-----------------------------------------------------------------------------------------------------------------------
;
;       x86 CPU Architecture                                                    ;EX86...
;
;-----------------------------------------------------------------------------------------------------------------------
EX86DESCLEN             equ     8                                               ;size of a protected mode descriptor
;-----------------------------------------------------------------------------------------------------------------------
;
;       x86 Descriptor Access Codes                                             EX86ACC...
;
;       The x86 architecture supports the classification of memory areas or segments. Segment attributes are defined by
;       structures known as descriptors. Within a descriptor are access type codes that define the type of the segment.
;
;       0.......        Segment is not present in memory (triggers int 11)
;       1.......        Segment is present in memory
;       .LL.....        Segment is of privilege level LL (0,1,2,3)
;       ...0....        Segment is a system segment
;       ...00010                Local Descriptor Table
;       ...00101                Task Gate
;       ...010B1                Task State Segment (B:0=Available,1=Busy)
;       ...01100                Call Gate (386)
;       ...01110                Interrupt Gate (386)
;       ...01111                Trap Gate (386)
;       ...1...A        Segment is a code or data (A:1=Accesssed)
;       ...10DW.                Data (D:1=Expand Down,W:1=Writable)
;       ...11CR.                Code (C:1=Conforming,R:1=Readable)
;
;-----------------------------------------------------------------------------------------------------------------------
EX86ACCINT              equ     10001110b                                       ;interrupt gate
EX86ACCTRAP             equ     10001111b                                       ;trap gate
;-----------------------------------------------------------------------------------------------------------------------
;
;       Firmware-Defined Values
;
;-----------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------
;
;       BIOS Interrupts and Functions                                           EBIOS...
;
;       Basic Input/Output System (BIOS) functions are grouped and accessed by issuing an interrupt call. Each
;       BIOS interrupt supports several functions. The function code is typically passed in the AH register.
;
;-----------------------------------------------------------------------------------------------------------------------
EBIOSINTVIDEO           equ     010h                                            ;video services interrupt
EBIOSFNSETVMODE         equ     000h                                            ;video set mode function
EBIOSMODETEXT80         equ     003h                                            ;video mode 80x25 text
EBIOSFNTTYOUTPUT        equ     00Eh                                            ;video TTY output function
EBIOSINTDISKETTE        equ     013h                                            ;diskette services interrupt
EBIOSFNREADSECTOR       equ     002h                                            ;diskette read sector function
EBIOSFNWRITESECTOR      equ     003h                                            ;diskette write sector function
EBIOSINTMISC            equ     015h                                            ;miscellaneous services interrupt
EBIOSFNINITPROTMODE     equ     089h                                            ;initialize protected mode fn
EBIOSINTKEYBOARD        equ     016h                                            ;keyboard services interrupt
EBIOSFNKEYSTATUS        equ     001h                                            ;keyboard status function
;-----------------------------------------------------------------------------------------------------------------------
;
;       Standards-Based Values
;
;-----------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------
;
;       ASCII                                                                   EASCII...
;
;-----------------------------------------------------------------------------------------------------------------------
EASCIIRETURN            equ     00Dh                                            ;carriage return
EASCIIESCAPE            equ     01Bh                                            ;escape
EASCIISPACE             equ     020h                                            ;space
;-----------------------------------------------------------------------------------------------------------------------
;
;       Operating System Values
;
;-----------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------
;
;       Boot Sector and Loader Constants                                        EBOOT...
;
;       Equates in this section support the boot sector and the 16-bit operating system loader, which will be
;       responsible for placing the CPU into protected mode and calling the initial operating system task.
;
;-----------------------------------------------------------------------------------------------------------------------
EBOOTSTACKTOP           equ     0100h                                           ;boot sector stack top relative to DS
EBOOTSECTORBYTES        equ     512                                             ;bytes per sector
EBOOTDIRENTRIES         equ     224                                             ;directory entries (1.44MB 3.5" FD)
EBOOTDISKSECTORS        equ     2880                                            ;sectors per disk (1.44MB 3.5" FD)
EBOOTDISKBYTES          equ     (EBOOTSECTORBYTES*EBOOTDISKSECTORS)             ;bytes per disk
EBOOTFATBASE            equ     (EBOOTSTACKTOP+EBOOTSECTORBYTES)                ;offset of FAT I/O buffer rel to DS
EBOOTMAXTRIES           equ     5                                               ;max read retries
;-----------------------------------------------------------------------------------------------------------------------
;       Console Constants                                                       ECON...
;-----------------------------------------------------------------------------------------------------------------------
ECONCOLS                equ     80                                              ;columns per row
ECONROWS                equ     24                                              ;console rows
ECONCOLBYTES            equ     2                                               ;bytes per column
ECONROWBYTES            equ     (ECONCOLS*ECONCOLBYTES)                         ;bytes per row
ECONROWDWORDS           equ     (ECONROWBYTES/4)                                ;double-words per row
ECONCLEARDWORD          equ     007200720h                                      ;attribute and ASCII space
ECONOIADWORD            equ     070207020h                                      ;attribute and ASCII space
;-----------------------------------------------------------------------------------------------------------------------
;       Global Descriptor Table (GDT) Selectors                                 EGDT...
;-----------------------------------------------------------------------------------------------------------------------
EGDTOSDATA              equ     018h                                            ;kernel data selector
EGDTCGA                 equ     020h                                            ;cga video selector
EGDTLOADERCODE          equ     030h                                            ;loader code selector
EGDTOSCODE              equ     048h                                            ;os kernel code selector
EGDTLOADERLDT           equ     050h                                            ;loader local descriptor table selector
EGDTLOADERTSS           equ     058h                                            ;loader task state segment selector
EGDTCONSOLELDT          equ     060h                                            ;console local descriptor table selector
EGDTCONSOLETSS          equ     068h                                            ;console task state segment selector
;-----------------------------------------------------------------------------------------------------------------------
;       Kernel Constants                                                        EKRN...
;-----------------------------------------------------------------------------------------------------------------------
EKRNCODEBASE            equ     01000h                                          ;kernel base address (0000:1000)
EKRNCODESEG             equ     (EKRNCODEBASE >> 4)                             ;kernel code segment (0100:0000)
EKRNCODELEN             equ     05000h                                          ;kernel code size (1000h to 6000h)
EKRNCODESRCADR          equ     0500h                                           ;kernel code offset to loader DS:
;=======================================================================================================================
;
;       Structures
;
;=======================================================================================================================
;-----------------------------------------------------------------------------------------------------------------------
;
;       OSDATA
;
;       The OSDATA structure maps low-memory addresses used by the BIOS and the OS. Areas that may be in use by DOS or
;       other host operating systems that may be running when this OS is launched are avoided.
;
;-----------------------------------------------------------------------------------------------------------------------
struc                   OSDATA
                        resb    0400h                                           ;000 real mode interrupt vectors
                        resw    1                                               ;400 COM1 port address
                        resw    1                                               ;402 COM2 port address
                        resw    1                                               ;404 COM3 port address
                        resw    1                                               ;406 COM4 port address
                        resw    1                                               ;408 LPT1 port address
                        resw    1                                               ;40a LPT2 port address
                        resw    1                                               ;40c LPT3 port address
                        resw    1                                               ;40e LPT4 port address
                        resb    2                                               ;410 equipment list flags
                        resb    1                                               ;412 errors in PCjr infrared keybd link
                        resw    1                                               ;413 memory size (kb) INT 12h
                        resb    1                                               ;415 mfr error test scratchpad
                        resb    1                                               ;416 PS/2 BIOS control flags
                        resb    1                                               ;417 keyboard flag byte 0
                        resb    1                                               ;418 keyboard flag byte 1
                        resb    1                                               ;419 alternate keypad entry
                        resw    1                                               ;41a keyboard buffer head offset
                        resw    1                                               ;41c keyboard buffer tail offset
                        resb    32                                              ;41e keyboard buffer
wbFDCStatus             resb    1                                               ;43e drive recalibration status
wbFDCControl            resb    1                                               ;43f FDC motor status/control byte
wbFDCMotor              resb    1                                               ;440 FDC motor timeout byte
                        resb    1                                               ;441 status of last diskette operation
                        resb    7                                               ;442 NEC diskette controller status
                        resb    1                                               ;449 current video mode
                        resw    1                                               ;44a screen columns
                        resw    1                                               ;44c video regen buffer size
                        resw    1                                               ;44e current video page offset
                        resw    8                                               ;450 cursor postions of pages 1-8
                        resb    1                                               ;460 cursor ending scanline
                        resb    1                                               ;461 cursor start scanline
                        resb    1                                               ;462 active display page number
                        resw    1                                               ;463 CRTC base port address
                        resb    1                                               ;465 CRT mode control register value
                        resb    1                                               ;466 CGA current color palette mask
                        resw    1                                               ;467 CS:IP for 286 return from PROT MODE
                        resb    3                                               ;469 vague
wdClockTicks            resd    1                                               ;46c clock ticks
wbClockDays             resb    1                                               ;470 clock days
                        resb    1                                               ;471 bios break flag
                        resw    1                                               ;472 soft reset
                        resb    1                                               ;474 last hard disk operation status
                        resb    1                                               ;475 hard disks attached
                        resb    1                                               ;476 XT fised disk drive control byte
                        resb    1                                               ;477 port offset to current fixed disk adapter
                        resb    4                                               ;478 LPT timeout values
                        resb    4                                               ;47c COM timeout values
                        resw    1                                               ;480 keyboard buffer start offset
                        resw    1                                               ;482 keyboard buffer end offset
                        resb    1                                               ;484 Rows on screen less 1 (EGA+)
                        resb    1                                               ;485 point height of character matrix (EGA+)
                        resb    1                                               ;486 PC Jr initial keybd delay
                        resb    1                                               ;487 EGA+ video mode ops
                        resb    1                                               ;488 EGA feature bit switches
                        resb    1                                               ;489 VGA video display data area
                        resb    1                                               ;48a EGA+ display combination code
                        resb    1                                               ;48b last diskette data rate selected
                        resb    1                                               ;48c hard disk status from controller
                        resb    1                                               ;48d hard disk error from controller
                        resb    1                                               ;48e hard disk interrupt control flag
                        resb    1                                               ;48f combination hard/floppy disk card
                        resb    4                                               ;490 drive 0,1,2,3 media state
                        resb    1                                               ;494 track currently seeked to on drive 0
                        resb    1                                               ;495 track currently seeked to on drive 1
                        resb    1                                               ;496 keyboard mode/type
                        resb    1                                               ;497 keyboard LED flags
                        resd    1                                               ;498 pointer to user wait complete flag
                        resd    1                                               ;49c user wait time-out value in microseconds
                        resb    1                                               ;4a0 RTC wait function flag
                        resb    1                                               ;4a1 LANA DMA channel flags
                        resb    2                                               ;4a2 status of LANA 0,1
                        resd    1                                               ;4a4 saved hard disk interrupt vector
                        resd    1                                               ;4a8 BIOS video save/override pointer table addr
                        resb    8                                               ;4ac reserved
                        resb    1                                               ;4b4 keyboard NMI control flags
                        resd    1                                               ;4b5 keyboard break pending flags
                        resb    1                                               ;4b9 Port 60 single byte queue
                        resb    1                                               ;4ba scan code of last key
                        resb    1                                               ;4bb NMI buffer head pointer
                        resb    1                                               ;4bc NMI buffer tail pointer
                        resb    16                                              ;4bd NMI scan code buffer
                        resb    1                                               ;4cd unknown
                        resw    1                                               ;4de day counter
                        resb    32                                              ;4d0 unknown
                        resb    16                                              ;4f0 intra-app comm area
                        resb    1                                               ;500 print-screen status byte
                        resb    3                                               ;501 used by BASIC
                        resb    1                                               ;504 DOS single diskette mode
                        resb    10                                              ;505 POST work area
                        resb    1                                               ;50f BASIC shell flag
                        resw    1                                               ;510 BASIC default DS (DEF SEG)
                        resd    1                                               ;512 BASIC INT 1C interrupt handler
                        resd    1                                               ;516 BASIC INT 23 interrupt handler
                        resd    1                                               ;51a BASIC INT 24 interrupt handler
                        resw    1                                               ;51e unknown
                        resw    1                                               ;520 DOS dynamic storage
                        resb    14                                              ;522 DOS diskette initialization table (INT 1e)
                        resb    4                                               ;530 MODE command
                        resb    460                                             ;534 unused
                        resb    256                                             ;700 i/o drivers from io.sys/ibmbio.com
;-----------------------------------------------------------------------------------------------------------------------
;
;       Kernel Variables                                                        @disk: N/A      @mem: 000800
;
;       Kernel variables may be accessed by interrupts or by the initial task (Console).
;
;-----------------------------------------------------------------------------------------------------------------------
ECONDATA                equ     ($)
                                                                                ;---------------------------------------
                                                                                ;  panel handling
                                                                                ;---------------------------------------
wdConsolePanel          resd    1                                               ;panel definition addr
wdConsoleField          resd    1                                               ;active field definition addr
wzConsoleInBuffer       resb    80                                              ;command input buffer
                                                                                ;---------------------------------------
                                                                                ;  cursor placement
                                                                                ;---------------------------------------
wbConsoleColumn         resb    1                                               ;console column
wbConsoleRow            resb    1                                               ;console row
ECONDATALEN             equ     ($-ECONDATA)                                    ;size of console data area
;-----------------------------------------------------------------------------------------------------------------------
;
;       End of OS Variables
;
;-----------------------------------------------------------------------------------------------------------------------
endstruc
;-----------------------------------------------------------------------------------------------------------------------
;
;       Macros
;
;       These macros are used to assist in defining descriptor tables and interrupt table offsets.
;
;-----------------------------------------------------------------------------------------------------------------------
%macro                  mint    1
_%1                     equ     ($-$$) / EX86DESCLEN
                        dq      ((?%1 >> 16) << 32) | (EX86ACCINT << 40) | ((EGDTOSCODE & 0FFFFh) << 16) | (?%1 & 0FFFFh)
%endmacro
%macro                  mtrap   1
_%1                     equ     ($-$$) / EX86DESCLEN
                        dq      ((?%1 >> 16) << 32) | (EX86ACCTRAP << 40) | ((EGDTOSCODE & 0FFFFh) << 16) | (?%1 & 0FFFFh)
%endmacro
%macro                  menter  1
?%1                     equ     ($-$$)
%endmacro
%macro                  tsvce   1
e%1                     equ     ($-tsvc)/4
                        dd      %1
%endmacro
%ifdef BUILDBOOT
;=======================================================================================================================
;
;       Boot Sector                                                             @disk: 000000   @mem: 007c00
;
;       The first sector of the diskette is the boot sector. The BIOS will load the boot sector into memory and pass
;       control to the code at the start of the sector. The boot sector code is responsible for loading the operating
;       system into memory. The boot sector contains a disk parameter table describing the geometry and allocation
;       of the diskette. Following the disk parameter table is code to load the operating system kernel into memory.
;
;       The "cpu" directive limits emitted code to those instructions supported by the most primitive processor
;       we expect to ever execute our code. The "vstart" parameter indicates addressability of symbols so as to
;       emulate the DOS .COM program model. Although the BIOS is expected to load the boot sector at address 7c00,
;       we do not make that assumption. The CPU starts in 16-bit addressing mode. A three-byte jump instruction is
;       immediately followed by the disk parameter table.
;
;=======================================================================================================================
                        cpu     8086                                            ;assume minimal CPU
section                 boot    vstart=0100h                                    ;emulate .COM (CS,DS,ES=PSP) addressing
                        bits    16                                              ;16-bit code at power-up
%ifdef BUILDPREP
Boot                    jmp     word Prep                                       ;jump to preparation code
%else
Boot                    jmp     word Boot.10                                    ;jump over parameter table
%endif
;-----------------------------------------------------------------------------------------------------------------------
;
;       Disk Parameter Table
;
;       The disk parameter table informs the BIOS of the floppy disk architecture. Here, we use parameters for the
;       3.5" 1.44MB floppy disk since this format is widely supported by virtual machine hypervisors.
;
;-----------------------------------------------------------------------------------------------------------------------
                        db      "OS      "                                      ;eight-byte label
cwSectorBytes           dw      EBOOTSECTORBYTES                                ;bytes per sector
cbClusterSectors        db      1                                               ;sectors per cluster
cwReservedSectors       dw      1                                               ;reserved sectors
cbFatCount              db      2                                               ;file allocation table copies
cwDirEntries            dw      EBOOTDIRENTRIES                                 ;max directory entries
cwDiskSectors           dw      EBOOTDISKSECTORS                                ;sectors per disk
cbDiskType              db      0F0h                                            ;1.44MB
cwFatSectors            dw      9                                               ;sectors per FAT copy
cbTrackSectors          equ     $                                               ;sectors per track (as byte)
cwTrackSectors          dw      18                                              ;sectors per track (as word)
cwDiskSides             dw      2                                               ;sides per disk
cwSpecialSectors        dw      0                                               ;special sectors
;
;       BIOS typically loads the boot sector at absolute address 7c00 and sets the stack pointer at 512 bytes past
;       the end of the boot sector. But, since BIOS code varies, we don't make any assumptions as to where our boot
;       sector is loaded. For example, the initial CS:IP could be 0:7c00, 700:c00, 7c0:0, etc. To avoid assumptions,
;       we first normalize CS:IP to get the absolute segment address in BX. The comments below show the effect of this
;       code given several possible starting values for CS:IP.
;
                                                                                ;CS:IP   0:7c00 700:c00 7c0:0
Boot.10                 call    word .20                                        ;[ESP] =   7c21     c21    21
.@20                    equ     $-$$                                            ;.@20 = 021h
.20                     pop     ax                                              ;AX =      7c21     c21    21
                        sub     ax,.@20                                         ;AX =      7c00     c00     0
                        mov     cl,4                                            ;shift count
                        shr     ax,cl                                           ;AX =       7c0      c0     0
                        mov     bx,cs                                           ;BX =         0     700   7c0
                        add     bx,ax                                           ;BX =       7c0     7c0   7c0
;
;       Now, since we are assembling our boot code to emulate the addressing of a .COM file, we want the DS and ES
;       registers to be set to where a Program Segment Prefix (PSP) would be, exactly 100h (256) bytes prior to
;       the start of our code. This will correspond to our assembled data address offsets. Note that we instructed
;       the assembler to produce addresses for our symbols that are offset from our code by 100h. See the "vstart"
;       parameter for the "section" directive above. We also set SS to the PSP and SP to the address of our i/o
;       buffer. This leaves 256 bytes of usable stack from 7b0:0 to 7b0:100.
;
;       Note that when a value is loaded into the stack segment register (SS) interrupts are disabled until the
;       completion of the following instruction.
;
                        sub     bx,16                                           ;BX = 07b0
                        mov     ds,bx                                           ;DS = 07b0 = psp
                        mov     es,bx                                           ;ES = 07b0 = psp
                        mov     ss,bx                                           ;SS = 07b0 = psp (ints disabled)
                        mov     sp,EBOOTSTACKTOP                                ;SP = 0100       (ints enabled)
;
;       Our boot addressability is now set up according to the following diagram.
;
;       DS,ES,SS -----> 007b00  +-----------------------------------------------+ DS:0000
;                               |  Boot Stack & Boot PSP (Unused)               |
;                               |  256 = 100h bytes                             |
;       SS:SP --------> 007c00  +-----------------------------------------------+ DS:0100  07b0:0100
;                               |  Boot Sector (vstart=0100h)                   |
;                               |  1 sector = 512 = 200h bytes                  |
;                       007e00  +-----------------------------------------------+ DS:0300
;                               |  File Allocation Table (FAT) I/O Buffer       |
;                               |  9x512-byte sectors = 4,608 = 1200h bytes     |
;                       009000  +-----------------------------------------------+ DS:1500  08f0:0100
;                               |  Directory Sector Buffer & Kernel Load Area   |
;                               |  2 sectors = 1024 = 400h bytes                |
;                       009400  +-----------------------------------------------+ DS:1900
;
;       On entry, DL indicates the drive being booted from.
;
                        mov     [wbDrive],dl                                    ;[wbDrive] = drive being booted from
;
;       Compute directory i/o buffer address.
;
                        mov     ax,[cwFatSectors]                               ;AX = 0009 = FAT sectors
                        mul     word [cwSectorBytes]                            ;DX:AX = 0000:1200 = FAT bytes
                        add     ax,EBOOTFATBASE                                 ;AX = 1500 = end of FAT buffer
                        mov     [wwDirBuffer],ax                                ;[wwDirBuffer] = 1500
;
;       Compute segment where os.com will be loaded.
;
                        shr     ax,cl                                           ;AX = 0150
                        add     ax,bx                                           ;AX = 0150 + 07b0 = 0900
                        sub     ax,16                                           ;AX = 08f0
                        mov     [wwLoadSegment],ax                              ;[wwLoadSegment] = 08f0
;
;       Set the video mode to 80 column, 25 row, text.
;
                        mov     ax,EBIOSFNSETVMODE<<8|EBIOSMODETEXT80           ;set mode function, 80x25 text mode
                        int     EBIOSINTVIDEO                                   ;call BIOS display interrupt
;
;       Write a message to the console so we know we have our addressability established.
;
                        mov     si,czLoadMsg                                    ;loading message
                        call    BootPrint                                       ;display loader message
;
;       Initialize the number of directory sectors to search.
;
                        mov     ax,[cwDirEntries]                               ;AX = 224 = max dir entries
                        mov     [wwEntriesLeft],ax                              ;[wwEntriesLeft] = 224
;
;       Compute number of directory sectors and initialize overhead count.
;
                        mov     cx,ax                                           ;CX = 00e0 = 224 entries
                        mul     word [cwEntryLen]                               ;DX:AX = 224 * 32 = 7168
                        div     word [cwSectorBytes]                            ;AX = 7168 / 512 = 14 = dir sectors
                        mov     [wwOverhead],ax                                 ;[wwOverhead] = 000e
;
;       Compute directory entries per sector.
;
                        xchg    ax,cx                                           ;DX:AX = 0:00e0, CX = 0000e
                        div     cx                                              ;AX = 0010 = entries per dir sector
                        mov     [wwSectorEntries],ax                            ;[wwSectorEntries] = 0010
;
;       Compute first logical directory sector and update overhead count.
;
                        mov     ax,[cwFatSectors]                               ;AX = 0009 = FAT sectors per copy
                        mul     byte [cbFatCount]                               ;AX = 0012 = FAT sectors
                        add     ax,[cwReservedSectors]                          ;AX = 0013 = FAT plus reserved
                        add     ax,[cwSpecialSectors]                           ;AX = 0013 = FAT + reserved + special
                        mov     [wwLogicalSector],ax                            ;[wwLogicalSector] = 0013
                        add     [wwOverhead],ax                                 ;[wwOverhead] = 0021 = res+spec+FAT+dir
;
;       Read directory sector.
;
.30                     mov     al,1                                            ;sector count
                        mov     [wbReadCount],al                                ;[wbReadCount] = 01
                        mov     bx,[wwDirBuffer]                                ;BX = 1500
                        call    ReadSector                                      ;read sector into es:bx
;
;       Setup variables to search this directory sector.
;
                        mov     ax,[wwEntriesLeft]                              ;directory entries to search
                        cmp     ax,[wwSectorEntries]                            ;need to search more sectors?
                        jna     .40                                             ;no, continue
                        mov     ax,[wwSectorEntries]                            ;yes, limit search to sector
.40                     sub     [wwEntriesLeft],ax                              ;update entries left to searh
                        mov     si,cbKernelProgram                              ;program name
                        mov     di,[wwDirBuffer]                                ;DI = 1500
;
;       Loop through directory sectors searching for kernel program.
;
.50                     push    si                                              ;save kernel name address
                        push    di                                              ;save dir i/o buffer address
                        mov     cx,11                                           ;length of 8+3 name
                        cld                                                     ;forward strings
                        repe    cmpsb                                           ;compare entry name
                        pop     di                                              ;restore dir i/o buffer address
                        pop     si                                              ;restore kernel name address
                        je      .60                                             ;exit loop if found
                        add     di,[cwEntryLen]                                 ;point to next dir entry
                        dec     ax                                              ;decrement remaining entries
                        jnz     .50                                             ;next entry
;
;       Repeat search if we are not at the end of the directory.
;
                        inc     word [wwLogicalSector]                          ;increment logical sector
                        cmp     word [wwEntriesLeft],0                          ;done with directory?
                        jne     .30                                             ;no, get next sector
                        mov     si,czNoKernel                                   ;missing kernel message
                        jmp     BootExit                                        ;display message and exit
;
;       If we find the kernel program in the directory, read the FAT.
;
.60                     mov     ax,[cwReservedSectors]                          ;AX = 0001
                        mov     [wwLogicalSector],ax                            ;start past boot sector
                        mov     ax,[cwFatSectors]                               ;AX = 0009
                        mov     [wbReadCount],al                                ;[wbReadCount] = 09
                        mov     bx,EBOOTFATBASE                                 ;BX = 0300
                        call    ReadSector                                      ;read FAT into buffer
;
;       Get the starting cluster of the kernel program and target address.
;
                        mov     ax,[di+26]                                      ;AX = starting cluster of file
                        les     bx,[wwLoadOffset]                               ;ES:BX = kernel load add (08f0:0100)
;
;       Read each program cluster into RAM.
;
.70                     push    ax                                              ;save cluster nbr
                        sub     ax,2                                            ;AX = cluster nbr base 0
                        mov     cl,[cbClusterSectors]                           ;CL = sectors per cluster
                        mov     [wbReadCount],cl                                ;save sectors to read
                        xor     ch,ch                                           ;CX = sectors per cluster
                        mul     cx                                              ;DX:AX = logical cluster sector
                        add     ax,[wwOverhead]                                 ;AX = kernel sector nbr
                        mov     [wwLogicalSector],ax                            ;save logical sector nbr
                        call    ReadSector                                      ;read sectors into ES:BX
;
;       Update buffer pointer for next cluster.
;
                        mov     al,[cbClusterSectors]                           ;AL = sectors per cluster
                        xor     ah,ah                                           ;AX = sectors per cluster
                        mul     word [cwSectorBytes]                            ;DX:AX = cluster bytes
                        add     bx,ax                                           ;BX = next cluster target address
                        pop     ax                                              ;AX = restore cluster nbr
;
;       Compute next cluster number.
;
                        mov     cx,ax                                           ;CX = cluster nbr
                        mov     di,ax                                           ;DI = cluster nbr
                        shr     ax,1                                            ;AX = cluster/2
                        mov     dx,ax                                           ;DX = cluster/2
                        add     ax,dx                                           ;AX = 2*(cluster/2)
                        add     ax,dx                                           ;AX = 3*(cluster/2)
                        and     di,1                                            ;get low bit
                        add     di,ax                                           ;add one if cluster is odd
                        add     di,EBOOTFATBASE                                 ;add FAT buffer address
                        mov     ax,[di]                                         ;get cluster bytes
;
;       Adjust cluster nbr by 4 bits if cluster is odd; test for end of chain.
;
                        test    cl,1                                            ;is cluster odd?
                        jz      .80                                             ;no, skip ahead
                        mov     cl,4                                            ;shift count
                        shr     ax,cl                                           ;shift nybble low
.80                     and     ax,0FFFh                                        ;mask for 24 bits; next cluster nbr
                        cmp     ax,0FFFh                                        ;end of chain?
                        jne     .70                                             ;no, continue
;
;       Transfer control to the operating system program.
;
                        db      0EAh                                            ;jmp seg:offset
wwLoadOffset            dw      0100h                                           ;kernel entry offset
wwLoadSegment           dw      08F0h                                           ;kernel entry segment (computed)
;
;       Read [wbReadCount] disk sectors from [wwLogicalSector] into ES:BX.
;
ReadSector              mov     ax,[cwTrackSectors]                             ;AX = sectors per track
                        mul     word [cwDiskSides]                              ;DX:AX = sectors per cylinder
                        mov     cx,ax                                           ;CX = sectors per cylinder
                        mov     ax,[wwLogicalSector]                            ;DX:AX = logical sector
                        div     cx                                              ;AX = cylinder; DX = cyl sector
                        mov     [wbTrack],al                                    ;[wbTrack] = cylinder
                        mov     ax,dx                                           ;AX = cyl sector
                        div     byte [cbTrackSectors]                           ;AH = sector, AL = head
                        inc     ah                                              ;AH = sector (1,2,3,...)
                        mov     [wbHead],ax                                     ;[wbHead]= head, [wwSectorTrack]= sector
;
;       Try maxtries times to read sector.
;
                        mov     cx,EBOOTMAXTRIES                                ;CX = 0005
.10                     push    bx                                              ;save buffer address
                        push    cx                                              ;save retry count
                        mov     dx,[wwDriveHead]                                ;DH = head, DL = drive
                        mov     cx,[wwSectorTrack]                              ;CH = track, CL = sector
                        mov     ax,[wwReadCountCommand]                         ;AH = fn., AL = sector count
                        int     EBIOSINTDISKETTE                                ;read sector
                        pop     cx                                              ;restore retry count
                        pop     bx                                              ;restore buffer address
                        jnc     BootReturn                                      ;skip ahead if done
                        loop    .10                                             ;retry
;
;       Handle disk error: convert to ASCII and store in error string.
;
                        mov     al,ah                                           ;AL = bios error code
                        xor     ah,ah                                           ;AX = bios error code
                        mov     dl,16                                           ;divisor for base 16
                        div     dl                                              ;AL = hi order, AH = lo order
                        or      ax,03030h                                       ;apply ASCII zone bits
                        cmp     ah,03Ah                                         ;range test ASCII numeral
                        jb      .20                                             ;continue if numeral
                        add     ah,7                                            ;adjust for ASCII 'A'-'F'
.20                     cmp     al,03Ah                                         ;range test ASCII numeral
                        jb      .30                                             ;continue if numeral
                        add     ah,7                                            ;adjust for ASCII 'A'-'F'
.30                     mov     [wzErrorCode],ax                                ;store ASCII error code
                        mov     si,czErrorMsg                                   ;error message address
BootExit                call    BootPrint                                       ;display messge to console
;
;       Wait for a key press.
;
.10                     mov     ah,EBIOSFNKEYSTATUS                             ;BIOS keyboard status function
                        int     EBIOSINTKEYBOARD                                ;get keyboard status
                        jnz     .20                                             ;continue if key pressed
                        sti                                                     ;enable maskable interrupts
                        hlt                                                     ;wait for interrupt
                        jmp     .10                                             ;repeat
;
;       Reset the system.
;
.20                     mov     al,EKEYBCMDRESET                                ;8042 pulse output port pin
                        out     EKEYBPORTSTAT,al                                ;drive B0 low to restart
.30                     sti                                                     ;enable maskable interrupts
                        hlt                                                     ;stop until reset, int, nmi
                        jmp     .30                                             ;loop until restart kicks in
;
;       Display text message.
;
BootPrint               cld                                                     ;forward strings
.10                     lodsb                                                   ;load next byte at DS:SI in AL
                        test    al,al                                           ;end of string?
                        jz      BootReturn                                      ;... yes, exit our loop
                        mov     ah,EBIOSFNTTYOUTPUT                             ;BIOS teletype function
                        int     EBIOSINTVIDEO                                   ;call BIOS display interrupt
                        jmp     .10                                             ;repeat until done
BootReturn              ret                                                     ;return
;-----------------------------------------------------------------------------------------------------------------------
;
;       Constants
;
;-----------------------------------------------------------------------------------------------------------------------
                        align   2
cwEntryLen              dw      32                                              ;length of directory entry
cbKernelProgram         db      "OS      COM"                                   ;kernel program name
czLoadMsg               db      "Loading OS",13,10,0                            ;loading message
czErrorMsg              db      "Disk error "                                   ;error message
wzErrorCode             db      020h,020h,0                                     ;error code and null terminator
czNoKernel              db      "OS missing",0                                  ;missing kernel message
;-----------------------------------------------------------------------------------------------------------------------
;
;       Work Areas
;
;-----------------------------------------------------------------------------------------------------------------------
                        align   2
wwDirBuffer             dw      0                                               ;directory i/o buffer address
wwEntriesLeft           dw      0                                               ;directory entries to search
wwOverhead              dw      0                                               ;overhead sectors
wwSectorEntries         dw      0                                               ;directory entries per sector
wwLogicalSector         dw      0                                               ;current logical sector
wwReadCountCommand      equ     $                                               ;read count and command
wbReadCount             db      0                                               ;sectors to read
cbReadCommand           db      EBIOSFNREADSECTOR                               ;BIOS read disk fn code
wwDriveHead             equ     $                                               ;drive, head (word)
wbDrive                 db      0                                               ;drive
wbHead                  db      0                                               ;head
wwSectorTrack           equ     $                                               ;sector, track (word)
                        db      0                                               ;sector
wbTrack                 db      0                                               ;track
                        times   510-($-$$) db 0h                                ;zero fill to end of sector
                        db      055h,0AAh                                       ;end of sector signature
%endif
%ifdef BUILDPREP
;=======================================================================================================================
;
;       Diskette Preparation Code
;
;       This routine writes the OS boot sector code to a formatted floppy diskette. The diskette parameter table,
;       which is located in the first 30 bytes of the boot sector is first read from the diskette and overlayed onto
;       the OS bootstrap code so that the diskette format parameters are preserved.
;
;=======================================================================================================================
;
;       Query the user to insert a flopppy diskette and press enter or cancel.
;
Prep                    mov     si,czPrepMsg10                                  ;starting message address
                        call    BootPrint                                       ;display message
;
;       Exit if the Escape key is pressed or loop until Enter is pressed.
;
.10                     mov     ah,EBIOSFNKEYSTATUS                             ;BIOS keyboard status function
                        int     EBIOSINTKEYBOARD                                ;get keyboard status
                        jnz     .20                                             ;continue if key pressed
                        sti                                                     ;enable interrupts
                        hlt                                                     ;wait for interrupt
                        jmp     .10                                             ;repeat
.20                     cmp     al,EASCIIRETURN                                 ;Enter key pressed?
                        je      .30                                             ;yes, branch
                        cmp     al,EASCIIESCAPE                                 ;Escape key pressed?
                        jne     .10                                             ;no, repeat
                        jmp     .120                                            ;yes, exit program
;
;       Display writing-sector message and patch the JMP instruction.
;
.30                     mov     si,czPrepMsg12                                  ;writing-sector message address
                        call    BootPrint                                       ;display message
                        mov     bx,Boot+1                                       ;address of JMP instruction operand
                        mov     ax,01Bh                                         ;address past disk parameter table
                        mov     [bx],ax                                         ;update the JMP instruction
;
;       Try to read the boot sector.
;
                        mov     cx,EBOOTMAXTRIES                                ;try up to five times
.40                     push    cx                                              ;save remaining tries
                        mov     bx,wcPrepInBuf                                  ;input buffer address
                        mov     dx,0                                            ;head zero, drive zero
                        mov     cx,1                                            ;track zero, sector one
                        mov     al,1                                            ;one sector
                        mov     ah,EBIOSFNREADSECTOR                            ;read function
                        int     EBIOSINTDISKETTE                                ;attempt the read
                        pop     cx                                              ;restore remaining retries
                        jnc     .50                                             ;skip ahead if successful
                        loop    .40                                             ;try again
                        mov     si,czPrepMsg20                                  ;read-error message address
                        jmp     .70                                             ;branch to error routine
;
;       Copy diskette parms from input buffer to output buffer.
;
.50                     mov     si,wcPrepInBuf                                  ;input buffer address
                        add     si,11                                           ;skip over JMP and system ID
                        mov     di,Boot                                         ;output buffer address
                        add     di,11                                           ;skip over JMP and system ID
                        mov     cx,19                                           ;length of diskette parameters
                        cld                                                     ;forward string copies
                        rep     movsb                                           ;copy diskette parameters
;
;       Try to write boot sector to diskette.
;
                        mov     cx,EBOOTMAXTRIES                                ;try up to five times
.60                     push    cx                                              ;save remaining tries
                        mov     bx,Boot                                         ;output buffer address
                        mov     dx,0                                            ;head zero, drive zero
                        mov     cx,1                                            ;track zero, sector one
                        mov     al,1                                            ;one sector
                        mov     ah,EBIOSFNWRITESECTOR                           ;write function
                        int     EBIOSINTDISKETTE                                ;attempt the write
                        pop     cx                                              ;restore remaining retries
                        jnc     .100                                            ;skip ahead if successful
                        loop    .60                                             ;try again
                        mov     si,czPrepMsg30                                  ;write-error message address
;
;       Convert the error code to ASCII and display the error message.
;
.70                     push    ax                                              ;save error code
                        mov     al,ah                                           ;copy error code
                        mov     ah,0                                            ;AX = error code
                        mov     dl,10h                                          ;hexadecimal divisor
                        idiv    dl                                              ;AL = hi-order, AH = lo-order
                        or      ax,03030h                                       ;add ASCII zone digits
                        cmp     ah,03Ah                                         ;AH ASCII numeral?
                        jb      .80                                             ;yes, continue
                        add     ah,7                                            ;no, make ASCII 'A'-'F'
.80                     cmp     al,03Ah                                         ;ASCII numeral?
                        jb      .90                                             ;yes, continue
                        add     al,7                                            ;no, make ASCII
.90                     mov     [si+17],ax                                      ;put ASCII error code in message
                        call    BootPrint                                       ;write error message
                        pop     ax                                              ;restore error code
;
;       Display the completion message.
;
.100                    mov     si,czPrepMsgOK                                  ;assume successful completion
                        mov     al,ah                                           ;BIOS return code
                        cmp     al,0                                            ;success?
                        je      .110                                            ;yes, continue
                        mov     si,czPrepMsgErr1                                ;disk parameter error message
                        cmp     al,1                                            ;disk parameter error?
                        je      .110                                            ;yes, continue
                        mov     si,czPrepMsgErr2                                ;address mark not found message
                        cmp     al,2                                            ;address mark not found?
                        je      .110                                            ;yes, continue
                        mov     si,czPrepMsgErr3                                ;protected disk message
                        cmp     al,3                                            ;protected disk?
                        je      .110                                            ;yes, continue
                        mov     si,czPrepMsgErr6                                ;diskette removed message
                        cmp     al,6                                            ;diskette removed?
                        je      .110                                            ;yes, continue
                        mov     si,czPrepMsgErr80                               ;drive timed out message
                        cmp     al,80h                                          ;drive timed out?
                        je      .110                                            ;yes, continue
                        mov     si,czPrepMsgErrXX                               ;unknown error message
.110                    call    BootPrint                                       ;display result message
.120                    mov     ax,04C00H                                       ;terminate with zero result code
                        int     021h                                            ;terminate DOS program
                        ret                                                     ;return (should not execute)
;-----------------------------------------------------------------------------------------------------------------------
;
;       Diskette Preparation Messages
;
;-----------------------------------------------------------------------------------------------------------------------
czPrepMsg10             db      13,10,"OS Boot-Diskette Preparation Program"
                        db      13,10,"Copyright (C) 2010-2020 David J. Walling"
                        db      13,10
                        db      13,10,"This program overwrites the boot sector of a diskette with startup code that"
                        db      13,10,"will load the operating system into memory when the computer is restarted."
                        db      13,10,"To proceed, place a formatted diskette into drive A: and press the Enter key."
                        db      13,10,"To exit this program without preparing a diskette, press the Escape key."
                        db      13,10,0
czPrepMsg12             db      13,10,"Writing the boot sector to the diskette ..."
                        db      13,10,0
czPrepMsg20             db      13,10,"The error-code .. was returned from the BIOS while reading from the disk."
                        db      13,10,0
czPrepMsg30             db      13,10,"The error-code .. was returned from the BIOS while writing to the disk."
                        db      13,10,0
czPrepMsgOK             db      13,10,"The boot-sector was written to the diskette. Before booting your computer with"
                        db      13,10,"this diskette, make sure that the file OS.COM is copied onto the diskette."
                        db      13,10,0
czPrepMsgErr1           db      13,10,"(01) Invalid Disk Parameter"
                        db      13,10,"This is an internal error caused by an invalid value being passed to a system"
                        db      13,10,"function. The OSBOOT.COM file may be corrupt. Copy or download the file again"
                        db      13,10,"and retry."
                        db      13,10,0
czPrepMsgErr2           db      13,10,"(02) Address Mark Not Found"
                        db      13,10,"This error indicates a physical problem with the floppy diskette. Please retry"
                        db      13,10,"using another diskette."
                        db      13,10,0
czPrepMsgErr3           db      13,10,"(03) Protected Disk"
                        db      13,10,"This error is usually caused by attempting to write to a write-protected disk."
                        db      13,10,"Check the 'write-protect' setting on the disk or retry using using another disk."
                        db      13,10,0
czPrepMsgErr6           db      13,10,"(06) Diskette Removed"
                        db      13,10,"This error may indicate that the floppy diskette has been removed from the"
                        db      13,10,"diskette drive. On some systems, this code may also occur if the diskette is"
                        db      13,10,"'write protected.' Please verify that the diskette is not write-protected and"
                        db      13,10,"is properly inserted in the diskette drive."
                        db      13,10,0
czPrepMsgErr80          db      13,10,"(80) Drive Timed Out"
                        db      13,10,"This error usually indicates that no diskette is in the diskette drive. Please"
                        db      13,10,"make sure that the diskette is properly seated in the drive and retry."
                        db      13,10,0
czPrepMsgErrXX          db      13,10,"(??) Unknown Error"
                        db      13,10,"The error-code returned by the BIOS is not a recognized error. Please consult"
                        db      13,10,"your computer's technical reference for a description of this error code."
                        db      13,10,0
wcPrepInBuf             equ     $
%endif
%ifdef BUILDDISK
;=======================================================================================================================
;
;       File Allocation Tables
;
;       The disk contains two copies of the File Allocation Table (FAT). On our disk, each FAT copy is 1200h bytes in
;       length. Each FAT entry contains the logical number of the next cluster. The first two entries are reserved. Our
;       OS.COM file here is 5400h bytes in length. The first 400h bytes are the 16-bit loader code. The remaining 5000h
;       bytes are the 32-bit kernel code. Our disk parameter table defines a cluster as containing one sector and each
;       sector having 200h bytes. Therefore, our FAT table must reserve 42 clusters for OS.COM. The clusters used by
;       OS.COM, then, will be cluster 2 through 43. The entry for cluster 43 is set to "0fffh" to indicate that it is
;       the last cluster in the chain.
;
;       Every three bytes encode two FAT entries as follows:
;
;       db      0abh,0cdh,0efh  ;even cluster: 0dabh, odd cluster: 0efch
;
;=======================================================================================================================
;-----------------------------------------------------------------------------------------------------------------------
;
;       FAT copy 1                                                              @disk: 000200   @mem: n/a
;
;-----------------------------------------------------------------------------------------------------------------------
section                 fat1                                                    ;first copy of FAT
                        db      0F0h,0FFh,0FFh, 003h,040h,000h
                        db      005h,060h,000h, 007h,080h,000h
                        db      009h,0A0h,000h, 00Bh,0C0h,000h
                        db      00Dh,0E0h,000h, 00Fh,000h,001h
                        db      011h,020h,001h, 013h,040h,001h
                        db      015h,060h,001h, 017h,080h,001h
                        db      019h,0A0h,001h, 01Bh,0C0h,001h
                        db      01Dh,0E0h,001h, 01Fh,000h,002h
                        db      021h,020h,002h, 023h,040h,002h
                        db      025h,060h,002h, 027h,080h,002h
                        db      029h,0A0h,002h, 02Bh,0F0h,0FFh
                        times   (9*512)-($-$$) db 0                             ;zero fill to end of section
;-----------------------------------------------------------------------------------------------------------------------
;
;       FAT copy 2                                                              @disk: 001400   @mem: n/a
;
;-----------------------------------------------------------------------------------------------------------------------
section                 fat2                                                    ;second copy of FAT
                        db      0F0h,0FFh,0FFh, 003h,040h,000h
                        db      005h,060h,000h, 007h,080h,000h
                        db      009h,0A0h,000h, 00Bh,0C0h,000h
                        db      00Dh,0E0h,000h, 00Fh,000h,001h
                        db      011h,020h,001h, 013h,040h,001h
                        db      015h,060h,001h, 017h,080h,001h
                        db      019h,0A0h,001h, 01Bh,0C0h,001h
                        db      01Dh,0E0h,001h, 01Fh,000h,002h
                        db      021h,020h,002h, 023h,040h,002h
                        db      025h,060h,002h, 027h,080h,002h
                        db      029h,0A0h,002h, 02Bh,0F0h,0FFh
                        times   (9*512)-($-$$) db 0                             ;zero fill to end of section
;-----------------------------------------------------------------------------------------------------------------------
;
;       Diskette Directory                                                      @disk: 002600   @mem: n/a
;
;       The disk contains one copy of the diskette directory. Each directory entry is 32 bytes long. Our directory
;       contains only one entry. Unused entries are set to all nulls. The directory immediately follows the second FAT
;       copy.
;
;-----------------------------------------------------------------------------------------------------------------------
section                 dir                                                     ;diskette directory
                        db      "OS      COM"                                   ;file name (must contain spaces)
                        db      020h                                            ;attribute (archive bit set)
                        times   10 db 0                                         ;unused
                        dw      0h                                              ;time
                        db      01000001b                                       ;mmm = 10 MOD 8 = 2; ddddd = 1
                        db      01001001b                                       ;yyyyyyy = 2016-1980 = 36 = 24h; m/8 = 1
                        dw      2                                               ;first cluster
                        dd      05400h                                          ;file size
                        times   (EBOOTDIRENTRIES*32)-($-$$) db 0h               ;zero fill to end of section
%endif
%ifdef BUILDCOM
;=======================================================================================================================
;
;       OS.COM
;
;       The operating system file is assembled at the start of the data area of the floppy disk image, which
;       immediately follows the directory. This corresponds to logical cluster 2, even though the physical address of
;       this sector on the disk varies depending on the disk type. The os.com file consists of two parts, the OS loader
;       and the OS kernel. The Loader is 16-bit code that receives control directly from the boot sector code after the
;       OS.COM file is loaded into memory. The kernel is 32-bit code that receives control after the Loader has
;       initialized protected-mode tables and 32-bit interrupt handlers and switched the CPU into protected mode.
;
;       Our loader addressability is set up according to the following diagram.
;
;       SS -----------> 007b00  +-----------------------------------------------+ SS:0000
;                               |  Boot Stack & Boot PSP (Unused)               |
;                               |  256 = 100h bytes                             |
;       SS:SP --------> 007c00  +-----------------------------------------------+ SS:0100  07b0:0100
;                               |  Boot Sector (vstart=0100h)                   |
;                               |  1 sector = 512 = 200h bytes                  |
;                       007e00  +-----------------------------------------------+
;                               |  File Allocation Table (FAT) I/O Buffer       |
;                               |  9 x 512-byte sectors = 4,608 = 1200h bytes   |
;                               |                                               |
;       CS,DS,ES -----> 008f00  |  Loader PSP (Unused)                          | DS:0000
;                               |                                               |
;       CS:IP --------> 009000  +-----------------------------------------------+ DS:0100  08f0:0100
;                               |  Loader Code                                  |
;                               |  2 sectors = 1024 = 400h bytes                |
;                       009400  +-----------------------------------------------+ DS:0500
;
;=======================================================================================================================
;-----------------------------------------------------------------------------------------------------------------------
;
;       OS Loader                                                               @disk: 004200   @mem: 009000
;
;       This code is the operating system loader. It resides on the boot disk at the start of the data area, following
;       the directory. The loader occupies several clusters that are mapped in the file allocation tables above.
;       The loader executes 16-bit instructions in real mode. It performs several initialization functions such as
;       determining whether the CPU and other resources are sufficient to run the operating system. If all minimum
;       resources are present, the loader initializes protected mode tables, places the CPU into protected mode and
;       starts the console task. Since the loader was called either from the bootstrap or as a .com file on the boot
;       disk, we can assume that the initial IP is 0x100 and not perform any absolute address fix-ups on our segment
;       registers.
;
;-----------------------------------------------------------------------------------------------------------------------
                        cpu     8086                                            ;assume minimal CPU
section                 loader  vstart=0100h                                    ;use .COM compatible addressing
                        bits    16                                              ;this is 16-bit code
Loader                  push    cs                                              ;use the code segment
                        pop     ds                                              ;...as our data segment
                        push    cs                                              ;use the code segment
                        pop     es                                              ;...as our extra segment
;
;       Write a message to the console so we know we have our addressability established.
;
                        mov     si,czStartingMsg                                ;starting message
                        call    PutTTYString                                    ;display loader message
;
;       Determine the CPU type, generally. Exit if the CPU is not at least an 80386.
;
                        call    GetCPUType                                      ;AL = cpu type
                        mov     si,czCPUErrorMsg                                ;loader error message
                        cmp     al,3                                            ;80386+?
                        jb      LoaderExit                                      ;no, exit with error message
                        cpu     386                                             ;allow 80386 instructions
                        mov     si,czCPUOKMsg                                   ;cpu ok message
                        call    PutTTYString                                    ;display message
;
;       Fixup the GDT descriptor for the current (loader) code segment.
;
                        mov     si,EKRNCODESRCADR                               ;GDT offset
                        mov     ax,cs                                           ;AX:SI = gdt source
                        rol     ax,4                                            ;AX = phys addr bits 11-0,15-12
                        mov     cl,al                                           ;CL = phys addr bits 3-0,15-12
                        and     al,0F0h                                         ;AL = phys addr bits 11-0
                        and     cl,00Fh                                         ;CL = phys addr bits 15-12
                        mov     word [si+EGDTLOADERCODE+2],ax                   ;lo-order loader code (0-15)
                        mov     byte [si+EGDTLOADERCODE+4],cl                   ;lo-order loader code (16-23)
                        mov     si,czGDTOKMsg                                   ;GDT prepared message
                        call    PutTTYString                                    ;display message
;
;       Move the 32-bit kernel to its appropriate memory location.
;
                        push    EKRNCODESEG                                     ;use kernel code segment ...
                        pop     es                                              ;... as target segment
                        xor     di,di                                           ;ES:DI = target address
                        mov     si,EKRNCODESRCADR                               ;DS:SI = source address
                        mov     cx,EKRNCODELEN                                  ;CX = kernel size
                        cld                                                     ;forward strings
                        rep     movsb                                           ;copy kernel image
                        mov     si,czKernelLoadedMsg                            ;kernel moved message
                        call    PutTTYString                                    ;display message
;
;       Switch to protected mode.
;
                        xor     si,si                                           ;ES:SI = gdt addr
                        mov     ss,si                                           ;protected mode ss
                        mov     sp,EKRNCODEBASE                                 ;initial stack immediate before code
                        mov     ah,EBIOSFNINITPROTMODE                          ;initialize protected mode fn.
                        mov     bx,02028h                                       ;BH,BL = IRQ int bases
                        mov     dx,001Fh                                        ;outer delay loop count
.10                     mov     cx,0FFFFh                                       ;inner delay loop count
                        loop    $                                               ;wait out pending interrupts
                        dec     dx                                              ;restore outer loop count
                        jnz     .10                                             ;continue outer loop
                        int     EBIOSINTMISC                                    ;call BIOS to set protected mode
;
;       Enable hardware and maskable interrupts.
;
                        xor     al,al                                           ;enable all registers code
                        out     EPICPORTPRI1,al                                 ;enable all primary 8259A ints
                        out     EPICPORTSEC1,al                                 ;enable all secondary 8259A ints
                        sti                                                     ;enable maskable interrupts
;
;       Load the Task State Segment (TSS) and Local Descriptor Table (LDT) registers and jump to the initial task.
;
                        ltr     [cs:cwLoaderTSS]                                ;load task register
                        lldt    [cs:cwLoaderLDT]                                ;load local descriptor table register
                        jmp     EGDTCONSOLETSS:0                                ;jump to task state segment selector
;-----------------------------------------------------------------------------------------------------------------------
;
;       Routine:        LoaderExit
;
;       Description:    This routine displays the message at DS:SI, waits for a keypress and resets the system.
;
;       In:             DS:SI   string address
;
;-----------------------------------------------------------------------------------------------------------------------
LoaderExit              call    PutTTYString                                    ;display error message
;
;       Now we want to wait for a keypress. We can use a keyboard interrupt function for this (INT 16h, AH=0).
;       However, some hypervisor BIOS implementations have been seen to implement the "wait" as simply a fast
;       iteration of the keyboard status function call (INT 16h, AH=1), causing a max CPU condition. So, instead,
;       we will use the keyboard status call and iterate over a halt (HLT) instruction until a key is pressed.
;       The STI instruction enables maskable interrupts, including the keyboard. The CPU assures that the
;       instruction immediately following STI will be executed before any interrupt is serviced.
;
.30                     mov     ah,EBIOSFNKEYSTATUS                             ;keyboard status function
                        int     EBIOSINTKEYBOARD                                ;call BIOS keyboard interrupt
                        jnz     .40                                             ;exit if key pressed
                        sti                                                     ;enable maskable interrupts
                        hlt                                                     ;wait for interrupt
                        jmp     .30                                             ;repeat until keypress
;
;       Now that a key has been pressed, we signal the system to restart by driving the B0 line on the 8042
;       keyboard controller low (OUT 64h,0feh). The restart may take some microseconds to kick in, so we issue
;       HLT until the system resets.
;
.40                     mov     al,EKEYBCMDRESET                                ;8042 pulse output port pin
                        out     EKEYBPORTSTAT,al                                ;drive B0 low to restart
.50                     sti                                                     ;enable maskable interrupts
                        hlt                                                     ;stop until reset, int, nmi
                        jmp     .50                                             ;loop until restart kicks in
;-----------------------------------------------------------------------------------------------------------------------
;
;       Routine:        GetCPUType
;
;       Description:    The loader needs only to determine that the cpu is at least an 80386 or an equivalent. Note that
;                       the CPUID instruction was not introduced until the SL-enhanced 80486 and Pentium processors, so
;                       to distinguish whether we have at least an 80386, other means must be used.
;
;       Out:            AX      0 = 808x, v20, etc.
;                               1 = 80186
;                               2 = 80286
;                               3 = 80386
;
;-----------------------------------------------------------------------------------------------------------------------
GetCPUType              mov     al,1                                            ;AL = 1
                        mov     cl,32                                           ;shift count
                        shr     al,cl                                           ;try a 32-bit shift
                        or      al,al                                           ;did the shift happen?
                        jz      .10                                             ;yes, cpu is 808x, v20, etc.
                        cpu     186
                        push    sp                                              ;save stack pointer
                        pop     cx                                              ;...into cx
                        cmp     cx,sp                                           ;did sp decrement before push?
                        jne     .10                                             ;yes, cpu is 80186
                        cpu     286
                        inc     ax                                              ;AX = 2
                        sgdt    [cbLoaderGDT]                                   ;store gdt reg in work area
                        mov     cl,[cbLoaderGDTHiByte]                          ;CL = hi-order byte
                        inc     cl                                              ;was hi-byte of GDTR 0xff?
                        jz      .10                                             ;yes, cpu is 80286
                        inc     ax                                              ;AX = 3
.10                     ret                                                     ;return
;-----------------------------------------------------------------------------------------------------------------------
;
;       Routine:        PutTTYString
;
;       Description:    This routine sends a NUL-terminated string of characters to the TTY output device. We use the
;                       TTY output function of the BIOS video interrupt, passing the address of the string in DS:SI
;                       and the BIOS teletype function code in AH. After a return from the BIOS interrupt, we repeat
;                       for the next string character until a NUL is found. Note that we clear the direction flag (DF)
;                       with CLD before the first LODSB. The direction flag is not guaranteed to be preserved between
;                       calls within the OS. However, the "int" instruction does store the EFLAGS register on the
;                       stack and restores it on return. Therefore, clearing the direction flag before subsequent calls
;                       to LODSB is not needed.
;
;       In:             DS:SI   address of string
;
;       Out:            DF      0
;                       ZF      1
;                       AL      0
;
;-----------------------------------------------------------------------------------------------------------------------
PutTTYString            cld                                                     ;forward strings
.10                     lodsb                                                   ;load next byte at DS:SI in AL
                        test    al,al                                           ;end of string?
                        jz      .20                                             ;... yes, exit our loop
                        mov     ah,EBIOSFNTTYOUTPUT                             ;BIOS teletype function
                        int     EBIOSINTVIDEO                                   ;call BIOS display interrupt
                        jmp     .10                                             ;repeat until done
.20                     ret                                                     ;return
;-----------------------------------------------------------------------------------------------------------------------
;
;       Loader Data
;
;       The loader data is updated to include constants defining the initial (Loader) TSS and LDT selectors in the
;       GDT, a work area to build the GDTR, and additional text messages.
;
;-----------------------------------------------------------------------------------------------------------------------
                        align   2
cwLoaderLDT             dw      EGDTLOADERLDT                                   ;loader local descriptor table selector
cwLoaderTSS             dw      EGDTLOADERTSS                                   ;loader task state segment selector
cbLoaderGDT             times   5 db 0                                          ;6-byte GDTR work area
cbLoaderGDTHiByte       db      0                                               ;hi-order byte
czCPUErrorMsg           db      "The operating system requires an i386 or later processor.",13,10
                        db      "Please press any key to restart the computer.",13,10,0
czCPUOKMsg              db      "CPU OK",13,10,0                                ;CPU level ok message
czGDTOKMsg              db      "GDT prepared",13,10,0                          ;global descriptor table ok message
czKernelLoadedMsg       db      "Kernel loaded",13,10,0                         ;kernel loaded message
czStartingMsg           db      "Starting OS",13,10,0                           ;starting message
                        times   1024-($-$$) db 0h                               ;zero fill to end of sector
;=======================================================================================================================
;
;       OS Kernel                                                               @disk: 004600   @mem: 001000
;
;       This code is the operating system kernel. It resides on the boot disk image as part of the OS.COM file,
;       following the 16-bit loader code above. The Kernel executes only 32-bit code in protected mode and contains one
;       task, the Console, which performs a loop accepting user input from external devices (keyboard, etc.), processes
;       commands and displays ouput to video memory. The Kernel also includes a library of system functions accessible
;       through software interrupt 58 (30h). Finally, the Kernel provides CPU and hardware interrupt handlers.
;
;=======================================================================================================================
;=======================================================================================================================
;
;       Kernel Tables
;
;=======================================================================================================================
;-----------------------------------------------------------------------------------------------------------------------
;
;       Global Descriptor Table                                                 @disk: 004600   @mem: 001000
;
;       The Global Descriptor Table (GDT) consists of eight-byte descriptors that define reserved memory areas. The
;       first descriptor must be all nulls.
;
;       6   5         4         3         2         1         0
;       3210987654321098765432109876543210987654321098765432109876543210
;       ----------------------------------------------------------------
;       h......hffffmmmma......ab......................bn..............n
;
;       h......h                                                                hi-order base address (bits 24-31)
;               ffff                                                            flags
;                   mmmm                                                        hi-order limit (bits 16-19)
;                       a......a                                                access
;                               b......................b                        lo-order base address (bits 0-23)
;                                                       n..............n        lo-order limit (bits 0-15)
;
;       00000000                                                                all areas have base addresses below 2^24
;               0...                                                            single-byte size granularity
;               1...                                                            4-kilobyte size granularity
;               .0..                                                            16-bit default for code segments
;               .1..                                                            32-bit default for code segments
;               ..0.                                                            intel-reserved; should be zero
;               ...0                                                            available for operating system use
;                   0000                                                        segment is less than 2^16 in size
;                   1111                                                        segment is greater than 2^24-2 in size
;                       1.......                                                segment is present in memory
;                       .00.....                                                segment is of privilege level 0
;                       ...0....                                                segment is of system or gate type
;                       ...00010                                                local decriptor table (LDT)
;                       ...01001                                                task state segment (TSS) available
;                       ...01011                                                task state segment (TSS) busy
;                       ...10...                                                data segment
;                       ...10011                                                writable data (accessed)
;                       ...11...                                                code segment
;                       ...11011                                                readable non-conforming code (accessed)
;
;-----------------------------------------------------------------------------------------------------------------------
section                 gdt                                                     ;global descriptor table
                        dq      0000000000000000h                               ;00 required null selector
                        dq      00409300100007FFh                               ;08 2KB  writable data  (GDT alias)
                        dq      00409300180007FFh                               ;10 2KB  writable data  (IDT alias)
                        dq      00CF93000000FFFFh                               ;18 4GB  writable data  (kernel)     DS:
                        dq      0040930B80000FFFh                               ;20 4KB  writable data  (CGA)        ES:
                        dq      0040930000000FFFh                               ;28 4KB  writable stack (Loader)     SS:
                        dq      00009B000000FFFFh                               ;30 64KB readable code  (loader)     CS:
                        dq      00009BFF0000FFFFh                               ;38 64KB readable code  (BIOS)
                        dq      004093000400FFFFh                               ;40 64KB writable data  (BIOS)
                        dq      00409B0020001FFFh                               ;48 8KB  readable code  (kernel)
                        dq      004082000F00007Fh                               ;50 80B  writable LDT   (loader)
                        dq      004089000F80007Fh                               ;58 80B  writable TSS   (loader)
                        dq      004082004700007Fh                               ;60 80B  writable LDT   (console)
                        dq      004089004780007Fh                               ;88 80B  writable TSS   (console)
                        times   2048-($-$$) db 0h                               ;zero fill to end of section
;-----------------------------------------------------------------------------------------------------------------------
;
;       Interrupt Descriptor Table                                              @disk: 004e00   @mem: 001800
;
;       The Interrupt Descriptor Table (IDT) consists of one eight-byte entry (descriptor) for each interrupt. The
;       descriptors here are of two kinds, interrupt gates and trap gates. The "mint" and "mtrap" macros define the
;       descriptors, taking only the name of the entry point for the code handling the interrupt.
;
;       6   5         4         3         2         1         0
;       3210987654321098765432109876543210987654321098765432109876543210
;       ----------------------------------------------------------------
;       h..............hPzzStttt00000000S..............Sl..............l
;
;       h...h   high-order offset (bits 16-31)
;       P       present (0=unused interrupt)
;       zz      descriptor privilege level
;       S       storage segment (must be zero for IDT)
;       tttt    type: 0101=task, 1110=int, 1111=trap
;       S...S   handling code selector in GDT
;       l...l   lo-order offset (bits 0-15)
;
;-----------------------------------------------------------------------------------------------------------------------
section                 idt                                                     ;interrupt descriptor table
                        mtrap   dividebyzero                                    ;00 divide by zero
                        mtrap   singlestep                                      ;01 single step
                        mtrap   nmi                                             ;02 non-maskable
                        mtrap   break                                           ;03 break
                        mtrap   into                                            ;04 into
                        mtrap   bounds                                          ;05 bounds
                        mtrap   badopcode                                       ;06 bad op code
                        mtrap   nocoproc                                        ;07 no coprocessor
                        mtrap   doublefault                                     ;08 double-fault
                        mtrap   operand                                         ;09 operand
                        mtrap   badtss                                          ;0a bad TSS
                        mtrap   notpresent                                      ;0b not-present
                        mtrap   stacklimit                                      ;0c stack limit
                        mtrap   protection                                      ;0d general protection fault
                        mtrap   int14                                           ;0e (reserved)
                        mtrap   int15                                           ;0f (reserved)
                        mtrap   coproccalc                                      ;10 (reserved)
                        mtrap   int17                                           ;11 (reserved)
                        mtrap   int18                                           ;12 (reserved)
                        mtrap   int19                                           ;13 (reserved)
                        mtrap   int20                                           ;14 (reserved)
                        mtrap   int21                                           ;15 (reserved)
                        mtrap   int22                                           ;16 (reserved)
                        mtrap   int23                                           ;17 (reserved)
                        mtrap   int24                                           ;18 (reserved)
                        mtrap   int25                                           ;19 (reserved)
                        mtrap   int26                                           ;1a (reserved)
                        mtrap   int27                                           ;1b (reserved)
                        mtrap   int28                                           ;1c (reserved)
                        mtrap   int29                                           ;1d (reserved)
                        mtrap   int30                                           ;1e (reserved)
                        mtrap   int31                                           ;1f (reserved)
                        mint    clocktick                                       ;20 IRQ0 clock tick
                        mint    keyboard                                        ;21 IRQ1 keyboard
                        mint    iochannel                                       ;22 IRQ2 second 8259A cascade
                        mint    com2                                            ;23 IRQ3 com2
                        mint    com1                                            ;24 IRQ4 com1
                        mint    lpt2                                            ;25 IRQ5 lpt2
                        mint    diskette                                        ;26 IRQ6 diskette
                        mint    lpt1                                            ;27 IRQ7 lpt1
                        mint    rtclock                                         ;28 IRQ8 real-time clock
                        mint    retrace                                         ;29 IRQ9 CGA vertical retrace
                        mint    irq10                                           ;2a IRQA (reserved)
                        mint    irq11                                           ;2b IRQB (reserved)
                        mint    ps2mouse                                        ;2c IRQC ps/2 mouse
                        mint    coprocessor                                     ;2d IRQD coprocessor
                        mint    fixeddisk                                       ;2e IRQE fixed disk
                        mint    irq15                                           ;2f IRQF (reserved)
                        mtrap   svc                                             ;30 OS services
                        times   2048-($-$$) db 0h                               ;zero fill to end of section
;=======================================================================================================================
;
;       Interrupt Handlers                                                      @disk: 005600   @mem:  002000
;
;       Interrupt handlers are 32-bit routines that receive control either in response to events or by direct
;       invocation from other kernel code. The interrupt handlers are of three basic types. CPU interrupts occur when a
;       CPU exception is detected. Hardware interrupts occur when an external device (timer, keyboard, disk, etc.)
;       signals the CPU on an interrupt request line (IRQ). Software interrupts occur when directly called by other code
;       using the INT instruction. Each interrupt handler routine is defined by using our "menter" macro, which simply
;       establishes a label defining the offset address of the entry point from the start of the kernel section. This
;       label is referenced in the "mint" and "mtrap" macros found in the IDT to specify the address of the handlers.
;
;=======================================================================================================================
section                 kernel  vstart=0h                                       ;data offsets relative to 0
                        cpu     386                                             ;allow 80386 instructions
                        bits    32                                              ;this is 32-bit code
;=======================================================================================================================
;
;       CPU Interrupt Handlers
;
;       The first 32 entries in the Interrupt Descriptor Table are reserved for use by CPU interrupts. The handling
;       of these interrupts will vary. For now, we will define the entry points but simply return from the interrupt.
;
;=======================================================================================================================
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT0    Divide By Zero
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  dividebyzero                                    ;divide by zero
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT1    Single Step
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  singlestep                                      ;single step
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT2    Non-Maskable Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  nmi                                             ;non-maskable
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT3    Break
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  break                                           ;break
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT4    Into
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  into                                            ;into
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT5    Bounds
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  bounds                                          ;bounds
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT6    Bad Operation Code
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  badopcode                                       ;bad opcode interrupt
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT7    No Coprocessor
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  nocoproc                                        ;no coprocessor interrupt
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT8    Double Fault
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  doublefault                                     ;doublefault interrupt
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT9    Operand
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  operand                                         ;operand interrupt
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT10   Bad Task State Segment
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  badtss                                          ;bad TSS interrupt
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT11   Not Present
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  notpresent                                      ;not present interrupt
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT12   Stack Limit
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  stacklimit                                      ;stack limit interrupt
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT13   General Protection Fault
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  protection                                      ;protection fault interrupt
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT14   Reserved
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  int14                                           ;(reserved)
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT15   Reserved
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  int15                                           ;(reserved)
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT16   Coprocessor Calculation
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  coproccalc                                      ;coprocessor calculation
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT17   Reserved
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  int17                                           ;(reserved)
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT18   Reserved
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  int18                                           ;(reserved)
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT19   Reserved
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  int19                                           ;(reserved)
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT20   Reserved
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  int20                                           ;(reserved)
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT21   Reserved
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  int21                                           ;(reserved)
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT22   Reserved
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  int22                                           ;(reserved)
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT23   Reserved
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  int23                                           ;(reserved)
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT24   Reserved
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  int24                                           ;(reserved)
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT25   Reserved
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  int25                                           ;(reserved)
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT26   Reserved
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  int26                                           ;(reserved)
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT27   Reserved
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  int27                                           ;(reserved)
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT28   Reserved
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  int28                                           ;(reserved)
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT29   Reserved
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  int29                                           ;(reserved)
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT30   Reserved
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  int30                                           ;(reserved)
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT31   Reserved
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  int31                                           ;(reserved)
                        jmp     ReportInterrupt                                 ;report interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       Routine:        ReportInterrupt
;
;       Description:    This routine will be used to respond to processor interrupts that are not otherwise handled.
;                       At this stage, we simply restore the stack and return from the interrupt.
;
;-----------------------------------------------------------------------------------------------------------------------
ReportInterrupt         iretd                                                   ;return
;=======================================================================================================================
;
;       Hardware Device Interupts
;
;       The next 16 interrupts are defined as our hardware interrupts. These interrupts vectors (20h-2Fh) are mapped to
;       the hardware interrupts IRQ0-IRQF by the BIOS when the call to the BIOS is made invoking BIOS function 89h
;       (BX=2028h).
;
;=======================================================================================================================
;-----------------------------------------------------------------------------------------------------------------------
;
;       IRQ0    Clock Tick Interrupt
;
;       PC compatible systems contain or emulate the function of the Intel 8253 Programmable Interval Timer (PIT).
;       Channel 0 of this chip decrements an internal counter to zero and then issues a hardware interrupt. The default
;       rate at which IRQ0 occurs is approximately 18.2 times per second or, more accurately, 1,573,040 times per day.
;
;       Every time IRQ0 occurs, a counter at 40:6c is incremented. When the number of ticks reaches the maximum for one
;       day, the counter is set to zero and the number of days counter at 40:70 is incremented.
;
;       This handler also decrements the floppy drive motor count at 40:40 if it is not zero. When this count reaches
;       zero, the floppy disk motors are turned off.
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  clocktick                                       ;clock tick interrupt
                        push    eax                                             ;save non-volatile regs
                        push    edx                                             ;
                        push    ds                                              ;
;
;       End the interrupt.
;
                        call    PutPrimaryEndOfInt                              ;send EOI to primary PIC
;
;       Update the clock tick count and the elapsed days as needed.
;
                        push    EGDTOSDATA                                      ;load OS data selector ...
                        pop     ds                                              ;... into data segment register
                        mov     eax,[wdClockTicks]                              ;EAX = clock ticks
                        inc     eax                                             ;increment clock ticks
                        cmp     eax,EPITDAYTICKS                                ;clock ticks per day?
                        jb      irq0.10                                         ;no, skip ahead
                        inc     byte [wbClockDays]                              ;increment clock days
                        xor     eax,eax                                         ;reset clock ticks
irq0.10                 mov     dword [wdClockTicks],eax                        ;save clock ticks
;
;       Decrement floppy disk motor timeout.
;
                        cmp     byte [wbFDCMotor],0                             ;floppy motor timeout?
                        je      irq0.20                                         ;yes, skip ahead
                        dec     byte [wbFDCMotor]                               ;decrement motor timeout
                        jnz     irq0.20                                         ;skip ahead if non-zero
;
;       Turn off the floppy disk motor if appropriate.
;
                        sti                                                     ;enable maskable interrupts
irq0.15                 mov     dh,EFDCPORTHI                                   ;FDC controller port hi
                        mov     dl,EFDCPORTLOSTAT                               ;FDC main status register
                        in      al,dx                                           ;FDC main status byte
                        test    al,EFDCSTATBUSY                                 ;test FDC main status for busy
                        jnz     irq0.15                                         ;wait while busy
                        mov     al,EFDCMOTOROFF                                 ;motor-off / enable/ DMA setting
                        mov     byte [wbFDCControl],al                          ;save motor-off setting
                        mov     dh,EFDCPORTHI                                   ;FDC port hi
                        mov     dl,EFDCPORTLOOUT                                ;FDC digital output register
                        out     dx,al                                           ;turn motor off
;
;       Enable maskable interrupts.
;
irq0.20                 sti                                                     ;enable maskable interrupts
;
;       Restore and return.
;
                        pop     ds                                              ;restore modified regs
                        pop     edx                                             ;
                        pop     eax                                             ;
                        iretd                                                   ;return
;-----------------------------------------------------------------------------------------------------------------------
;
;       IRQ1    Keyboard Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  keyboard                                        ;keyboard interrrupt
                        push    eax                                             ;
                        jmp     hwint                                           ;
;-----------------------------------------------------------------------------------------------------------------------
;
;       IRQ2    Secondary 8259A Cascade Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  iochannel                                       ;secondary 8259A cascade
                        push    eax                                             ;save modified regs
                        jmp     hwint                                           ;end interrupt and return
;-----------------------------------------------------------------------------------------------------------------------
;
;       IRQ3    Communication Port 2 Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  com2                                            ;serial port 2 interrupt
                        push    eax                                             ;save modified regs
                        jmp     hwint                                           ;end interrupt and return
;-----------------------------------------------------------------------------------------------------------------------
;
;       IRQ4    Communication Port 1 Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  com1                                            ;serial port 1 interrupt
                        push    eax                                             ;save modified regs
                        jmp     hwint                                           ;end interrupt and return
;-----------------------------------------------------------------------------------------------------------------------
;
;       IRQ5    Parallel Port 2 Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  lpt2                                            ;parallel port 2 interrupt
                        push    eax                                             ;save modified regs
                        jmp     hwint                                           ;end interrupt and return
;-----------------------------------------------------------------------------------------------------------------------
;
;       IRQ6    Diskette Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  diskette                                        ;floppy disk interrupt
                        push    eax                                             ;save non-volatile regs
                        push    ds                                              ;
                        call    PutPrimaryEndOfInt                              ;end the interrupt
                        push    EGDTOSDATA                                      ;load OS data selector ...
                        pop     ds                                              ;... into DS register
                        mov     al,[wbFDCStatus]                                ;AL = FDC calibration status
                        or      al,10000000b                                    ;set IRQ flag
                        mov     [wbFDCStatus],al                                ;update FDC calibration status
                        sti                                                     ;enable maskable interrupts
                        pop     ds                                              ;restore non-volatile regs
                        pop     eax                                             ;
                        iretd                                                   ;return from interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       IRQ7    Parallel Port 1 Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  lpt1                                            ;parallel port 1 interrupt
                        push    eax                                             ;save modified regs
                        jmp     hwint                                           ;end interrupt and return
;-----------------------------------------------------------------------------------------------------------------------
;
;       IRQ8    Real-time Clock Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  rtclock                                         ;real-time clock interrupt
                        push    eax                                             ;save modified regs
                        jmp     hwwint                                          ;end interrupt and return
;-----------------------------------------------------------------------------------------------------------------------
;
;       IRQ9    CGA Vertical Retrace Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  retrace                                         ;CGA vertical retrace interrupt
                        push    eax                                             ;save modified regs
                        jmp     hwwint                                          ;end interrupt and return
;-----------------------------------------------------------------------------------------------------------------------
;
;       IRQ10   Reserved Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  irq10                                           ;reserved
                        push    eax                                             ;save modified regs
                        jmp     hwwint                                          ;end interrupt and return
;-----------------------------------------------------------------------------------------------------------------------
;
;       IRQ11   Reserved Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  irq11                                           ;reserved
                        push    eax                                             ;save modified regs
                        jmp     hwwint                                          ;end interrupt and return
;-----------------------------------------------------------------------------------------------------------------------
;
;       IRQ12   PS/2 Mouse Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  ps2mouse                                        ;PS/2 mouse interrupt
                        push    eax                                             ;save modified regs
                        jmp     hwwint                                          ;end interrupt and return
;-----------------------------------------------------------------------------------------------------------------------
;
;       IRQ13   Coprocessor Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  coprocessor                                     ;coprocessor interrupt
                        push    eax                                             ;save modified regs
                        jmp     hwwint                                          ;end interrupt and return
;-----------------------------------------------------------------------------------------------------------------------
;
;       IRQ14   Fixed Disk Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  fixeddisk                                       ;fixed disk interrupt
                        push    eax                                             ;save modified regs
                        jmp     hwwint                                          ;end interrupt and return
;-----------------------------------------------------------------------------------------------------------------------
;
;       IRQ15   Reserved Hardware Interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  irq15                                           ;reserved
                        push    eax                                             ;save modified regs
                        jmp     hwwint                                          ;end interrupt and return
;-----------------------------------------------------------------------------------------------------------------------
;
;       Exit from hardware interrupt
;
;-----------------------------------------------------------------------------------------------------------------------
hwwint                  call    PutSecondaryEndOfInt                            ;send EOI to secondary PIC
                        jmp     hwint90                                         ;skip ahead
hwint                   call    PutPrimaryEndOfInt                              ;send EOI to primary PIC
hwint90                 sti                                                     ;enable maskable interrupts
                        pop     eax                                             ;restore modified regs
                        iretd                                                   ;return from interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       INT 30h Operating System Software Service Interrupt
;
;       Interrupt 30h is used by our operating system as an entry point for many commonly-used subroutines reusable by
;       any task. These routines include low-level i/o functions that shield applications from having to handle
;       device-specific communications. On entry to this interrupt, AL contains a function number that is used to load
;       the entry address of the specific function from a table.
;
;-----------------------------------------------------------------------------------------------------------------------
                        menter  svc
                        cmp     al,maxtsvc                                      ;is our function out of range?
                        jae     svc90                                           ;yes, skip ahead
                        movzx   eax,al                                          ;function
                        shl     eax,2                                           ;offset into table
                        call    dword [cs:tsvc+eax]                             ;far call to indirect address
svc90                   iretd                                                   ;return from interrupt
;-----------------------------------------------------------------------------------------------------------------------
;
;       Service Request Table
;
;
;       These tsvce macros expand to define an address vector table for the service request interrupt (int 30h).
;
;-----------------------------------------------------------------------------------------------------------------------
tsvc                    tsvce   PlaceCursor                                     ;place the cursor at the current loc
maxtsvc                 equ     ($-tsvc)/4                                      ;function out of range
;-----------------------------------------------------------------------------------------------------------------------
;
;       Service Request Macros
;
;       These macros provide positional parameterization of service request calls.
;
;-----------------------------------------------------------------------------------------------------------------------
%macro                  placeCursor 0
                        mov     al,ePlaceCursor                                 ;function code
                        int     _svc                                            ;invoke OS service
%endmacro
;=======================================================================================================================
;
;       Kernel Function Library
;
;=======================================================================================================================
;=======================================================================================================================
;
;       Input/Output Routines
;
;       These routines read and/or write directly to ports.
;
;       PlaceCursor
;       PutPrimaryEndOfInt
;       PutSecondaryEndOfInt
;
;=======================================================================================================================
;-----------------------------------------------------------------------------------------------------------------------
;
;       Routine:        PlaceCursor
;
;       Description:    This routine positions the cursor on the console.
;
;       In:             DS      OS data selector
;
;-----------------------------------------------------------------------------------------------------------------------
PlaceCursor             push    ecx                                             ;save non-volatile regs
                        mov     al,[wbConsoleRow]                               ;AL = row
                        mov     ah,ECONCOLS                                     ;AH = cols/row
                        mul     ah                                              ;row offset
                        add     al,[wbConsoleColumn]                            ;add column
                        adc     ah,0                                            ;add overflow
                        mov     ecx,eax                                         ;screen offset
                        mov     dl,ECRTPORTLO                                   ;crt controller port lo
                        mov     dh,ECRTPORTHI                                   ;crt controller port hi
                        mov     al,ECRTCURLOCHI                                 ;crt cursor loc reg hi
                        out     dx,al                                           ;select register
                        inc     edx                                             ;data port
                        mov     al,ch                                           ;hi-order cursor loc
                        out     dx,al                                           ;store hi-order loc
                        dec     edx                                             ;register select port
                        mov     al,ECRTCURLOCLO                                 ;crt cursor loc reg lo
                        out     dx,al                                           ;select register
                        inc     edx                                             ;data port
                        mov     al,cl                                           ;lo-order cursor loc
                        out     dx,al                                           ;store lo-order loc
                        pop     ecx                                             ;restore non-volatile regs
                        ret                                                     ;return
;-----------------------------------------------------------------------------------------------------------------------
;
;       Routine:        PutPrimaryEndOfInt
;
;       Description:    This routine sends a non-specific end-of-interrupt signal to the primary PIC.
;
;-----------------------------------------------------------------------------------------------------------------------
PutPrimaryEndOfInt      mov     al,EPICEOI                                      ;non-specific end-of-interrupt
                        out     EPICPORTPRI,al                                  ;send EOI to primary PIC
                        ret                                                     ;return
;-----------------------------------------------------------------------------------------------------------------------
;
;       Routine:        PutSecondaryEndOfInt
;
;       Description:    This routine sends a non-specific end-of-interrupt signal to the secondary PIC.
;
;-----------------------------------------------------------------------------------------------------------------------
PutSecondaryEndOfInt    mov     al,EPICEOI                                      ;non-specific end-of-interrupt
                        out     EPICPORTSEC,al                                  ;send EOI to secondary PIC
                        ret                                                     ;return
;-----------------------------------------------------------------------------------------------------------------------
;
;       End of the Kernel Function Library
;
;-----------------------------------------------------------------------------------------------------------------------
                        times   8192-($-$$) db 0h                               ;zero fill to end of section
;=======================================================================================================================
;
;       Console Task
;
;       The only task defined in the kernel is the console task. This task consists of code, data, stack, and task state
;       segments and a local descriptor table. The console task accepts and echos user keyboard input to the console
;       screen and responds to user commands.
;
;=======================================================================================================================
;-----------------------------------------------------------------------------------------------------------------------
;
;       Console Stack                                                           @disk: 007600   @mem:  004000
;
;       This is the stack for the console task. It supports 448 nested calls.
;
;-----------------------------------------------------------------------------------------------------------------------
section                 constack                                                ;console task stack
                        times   1792-($-$$) db 0h                               ;zero fill to end of section
;-----------------------------------------------------------------------------------------------------------------------
;
;       Console Local Descriptor Table                                          @disk: 007d00   @mem:  004700
;
;       This is the LDT for the console task. It defines the stack, code, data and queue segments as well as data
;       aliases for the TSS LDT. Data aliases allow inspection and altering of the TSS and LDT. This LDT can hold up to
;       16 descriptors. Six are initially defined.
;
;-----------------------------------------------------------------------------------------------------------------------
section                 conldt                                                  ;console local descriptors
                        dq      004093004780007Fh                               ;04 TSS alias
                        dq      004093004700007Fh                               ;0c LDT alias
                        dq      00409300400006FFh                               ;14 stack
                        dq      00CF93000000FFFFh                               ;1c data
                        dq      00409B0050000FFFh                               ;24 code
                        dq      00409300480007FFh                               ;2c message queue
                        times   128-($-$$) db 0h                                ;zero fill to end of section
;-----------------------------------------------------------------------------------------------------------------------
;
;       Console Task State Segment                                              @disk: 007d80   @mem:  004780
;
;       This is the TSS for the console task. All rings share the same stack. DS and ES are set to the console data
;       segment. CS to console code.
;
;-----------------------------------------------------------------------------------------------------------------------
section                 contss                                                  ;console task state segment
                        dd      0                                               ;00 back-link tss
                        dd      0700h                                           ;04 esp ring 0
                        dd      0014h                                           ;08 ss ring 0
                        dd      0700h                                           ;0c esp ring 1
                        dd      0014h                                           ;10 es ring 1
                        dd      0700h                                           ;14 esp ring 2
                        dd      0014h                                           ;18 ss ring 2
                        dd      0                                               ;1c cr ring 3
                        dd      0                                               ;20 eip
                        dd      0200h                                           ;24 eflags
                        dd      0                                               ;28 eax
                        dd      0                                               ;2c ecx
                        dd      0                                               ;30 edx
                        dd      0                                               ;34 ebx
                        dd      0700h                                           ;38 esp ring 3
                        dd      0                                               ;3c ebp
                        dd      0                                               ;40 esi
                        dd      0                                               ;44 edi
                        dd      001Ch                                           ;48 es
                        dd      0024h                                           ;4c cs
                        dd      0014h                                           ;50 ss ring 3
                        dd      001Ch                                           ;54 ds
                        dd      0                                               ;58 fs
                        dd      0                                               ;5c gs
                        dd      EGDTCONSOLELDT                                  ;60 ldt selector in gdt
                        times   128-($-$$) db 0h                                ;zero fill to end of section
;-----------------------------------------------------------------------------------------------------------------------
;
;       Console Message Queue                                                   @disk: 007e00   @mem: 004800
;
;       The console message queue is 2048 bytes of memory organized as a queue of 510 double words (4 bytes each) and
;       two double word values that act as indices. The queue is a FIFO that is fed by the keyboard hardware interrupt
;       handler and consumed by a service routine called from a task. Each queue entry defines an input (keystroke)
;       event.
;
;-----------------------------------------------------------------------------------------------------------------------
section                 conmque                                                 ;console message queue
                        dd      8                                               ;head pointer
                        dd      8                                               ;tail pointer
                        times   510 dd 0                                        ;queue elements
;-----------------------------------------------------------------------------------------------------------------------
;
;       Console Code                                                            @disk: 008600   @mem: 005000
;
;       This is the code for the console task. The task is defined in the GDT in two descriptors, the Local Descriptor
;       Table (LDT) at 0050h and the Task State Segment (TSS) at 0058h. Jumping to or calling a TSS selector causes a
;       task switch, giving control to the code for the task at the CS:IP defined in the TSS for the current ring level.
;       The initial CS:IP in the Console TSS is 24h:0, where 24h is a selector in the LDT. This selector points to the
;       concode section, loaded into memory 5000h by the Loader. The console task is dedicated to accepting user key-
;       board input, echoing to the console screen and responding to user commands.
;
;       When control reaches this section, our addressability is set up according to the following diagram.
;
;       DS,ES --------> 000000  +-----------------------------------------------+ DS,ES:0000
;                               |  Real Mode Interrupt Vectors                  |
;                       000400  +-----------------------------------------------+ DS,ES:0400
;                               |  Reserved BIOS Memory Area                    |
;                       000800  +-----------------------------------------------+ DS,ES:0800
;                               |  Shared Kernel Memory Area                    |
;                       001000  +-----------------------------------------------+               <-- GDTR
;                               |  Global Descriptor Table (GDT)                |
;                       001800  +-----------------------------------------------+               <-- IDTR
;                               |  Interrupt Descriptor Table (IDT)             |
;                       002000  +-----------------------------------------------+
;                               |  Interrupt Handlers                           |
;                               |  Kernel Function Library                      |
;       SS -----------> 004000  +===============================================+ SS:0000
;                               |  Console Task Stack Area                      |
;       SS:SP --------> 004700  +-----------------------------------------------+ SS:0700       <-- LDTR = GDT.SEL 0050h
;                               |  Console Task Local Descriptor Table (LDT)    |
;                       004780  +-----------------------------------------------+               <-- TR  = GDT.SEL 0058h
;                               |  Console Task Task State Segment (TSS)        |
;                       004800  +-----------------------------------------------+
;                               |  Console Task Message Queue                   |
;       CS:IP --------> 005000  +-----------------------------------------------+ CS:0000
;                               |  Console Task Code                            |
;                               |  Console Task Constants                       |
;                       006000  +===============================================+
;
;-----------------------------------------------------------------------------------------------------------------------
;=======================================================================================================================
;
;       Console Task Routines
;
;       ConCode                 Console task entry point
;       ConClearPanel           Clear the panel area of video memory to spaces
;       ConDrawFields           Draw the panel fields to video memory
;       ConDrawField            Draw a panel field to video memory
;       ConPutCursor            Place the cursor at the current index into the current field
;       ConMain                 Handle the main command
;
;=======================================================================================================================
section                 concode vstart=05000h                                   ;labels relative to 5000h
;
;       Initialize console work areas to low values.
;
ConCode                 mov     edi,ECONDATA                                    ;OS console data address
                        xor     al,al                                           ;initialization value
                        mov     ecx,ECONDATALEN                                 ;size of OS console data
                        cld                                                     ;forward strings
                        rep     stosb                                           ;initialize data
;
;       Initialize the Operator Information Area (OIA).
;
                        push    es                                              ;save extra segment
                        push    EGDTCGA                                         ;load CGA video selector...
                        pop     es                                              ;...into extra segment reg
                        mov     edi,ECONROWS*ECONROWBYTES                       ;target offset
                        mov     eax,ECONOIADWORD                                ;OIA attribute and space
                        mov     ecx,ECONROWDWORDS                               ;double-words per row
                        rep     stosd                                           ;reset OIA
                        pop     es                                              ;restore extra segment
;
;       Set the current panel to Main, clear and redraw all fields.
;
                        call    ConMain                                         ;initialize panel
;
;       Place the cursor at the current field index.
;
                        call    ConPutCursor                                    ;place the cursor
;
;       Enter halt loop
;
.10                     sti                                                     ;enable interrupts
                        hlt                                                     ;halt until interrupt
                        jmp     .10                                             ;continue halt loop
;-----------------------------------------------------------------------------------------------------------------------
;
;       Routine:        ConClearPanel
;
;       Description:    This routine clears the console panel video memory. The panel field buffer values
;                       are not disturbed.
;
;-----------------------------------------------------------------------------------------------------------------------
ConClearPanel           push    ecx                                             ;save non-volatile regs
                        push    edi                                             ;
                        push    es                                              ;
;
;       Clear panel rows.
;
                        push    EGDTCGA                                         ;load CGA video selector...
                        pop     es                                              ;...into extra segment reg
                        xor     edi,edi                                         ;target offset
                        mov     eax,ECONCLEARDWORD                              ;initialization value
                        mov     ecx,ECONROWS*ECONROWDWORDS                      ;double-words to clear
                        cld                                                     ;forward strings
                        rep     stosd                                           ;reset screen body
;
;       Restore and return.
;
                        pop     es                                              ;restore non-volatile regs
                        pop     edi                                             ;
                        pop     ecx                                             ;
                        ret                                                     ;return
;-----------------------------------------------------------------------------------------------------------------------
;
;       Routine:        ConDrawFields
;
;       Description:    This routine draws the panel fields. If there is no active input field, the first input
;                       field of the panel is set as the active field.
;
;-----------------------------------------------------------------------------------------------------------------------
ConDrawFields           push    ebx                                             ;save non-volatile regs
;
;       Exit if no panel
;
                        mov     ebx,[wdConsolePanel]                            ;panel definition addr
                        test    ebx,ebx                                         ;have panel?
                        jz      .30                                             ;no, branch
;
;       Loop until end of panel
;
.10                     cmp     dword [ebx],0                                   ;end of panel?
                        je      .30                                             ;yes, branch
;
;       If input field and we have no active field, set as active field
;
                        test    byte [ebx+11],80h                               ;input field?
                        jz      .20                                             ;no, branch
                        cmp     dword [wdConsoleField],0                        ;have active field?
                        jne     .20                                             ;yes, branch
                        mov     [wdConsoleField],ebx                            ;set active field
;
;       Draw the field and loop to the next field.
;
.20                     call    ConDrawField                                    ;draw field
                        lea     ebx,[ebx+12]                                    ;next field addr
                        jmp     .10                                             ;next field
;
;       Restore and return.
;
.30                     pop     ebx                                             ;restore non-volatile regs
                        ret                                                     ;return
;-----------------------------------------------------------------------------------------------------------------------
;
;       Routine:        ConDrawField
;
;       Description:    This routine draws the contents of a panel field.
;
;       In:             DS:EBX  field definition address
;                               [ebx+0]         field buffer address
;                               [ebx+4]         row (0-23)
;                               [ebx+5]         column (0,79)
;                               [ebx+6]         size (0-255)
;                               [ebx+7]         cursor index (0-255)
;                               [ebx+8]         1st selected index (0-255)
;                               [ebx+9]         last selected index (0-255)
;                               [ebx+10]        attribute
;                               [ebx+11]        flags
;                                               80h = input field
;
;-----------------------------------------------------------------------------------------------------------------------
ConDrawField            push    ecx                                             ;save non-volatile regs
                        push    esi                                             ;
                        push    edi                                             ;
                        push    es                                              ;
;
;       Exit if no field or zero size.
;
                        test    ebx,ebx                                         ;have field?
                        jz      .30                                             ;no, exit
                        movzx   ecx,byte [ebx+6]                                ;have size?
                        jecxz   .30                                             ;no, exit
;
;       Address video memory.
;
                        push    EGDTCGA                                         ;load CGA video selector...
                        pop     es                                              ;...into extra segment reg
;
;       Compute the target offset.
;
                        movzx   eax,byte [ebx+4]                                ;row
                        mov     ah,ECONCOLS                                     ;columns per row
                        mul     ah                                              ;row offset
                        add     al,byte [ebx+5]                                 ;add column
                        adc     ah,0                                            ;handle overflow
                        shl     eax,1                                           ;two-bytes per column
                        mov     edi,eax                                         ;target offset
;
;       Display field characters.
;
                        mov     ah,[ebx+10]                                     ;attribute
                        cld                                                     ;forward strings
                        mov     esi,[ebx]                                       ;field buffer addr
                        test    esi,esi                                         ;have field buffer?
                        jz      .20                                             ;no, exit
.10                     lodsb                                                   ;field character
                        test    al,al                                           ;end of value?
                        jz      .20                                             ;yes, branch
                        stosw                                                   ;store character with attribute
                        dec     ecx                                             ;decrement remaining size
                        jecxz   .30                                             ;exit if field full
                        jmp     .10                                             ;next character
;
;       Clear the remaining field.
;
.20                     mov     al,EASCIISPACE                                  ;ASCII space
                        rep     stosw                                           ;store space with attribute
;
;       Restore and return.
;
.30                     pop     es                                              ;restore non-volatile regs
                        pop     edi                                             ;
                        pop     esi                                             ;
                        pop     ecx                                             ;
                        ret                                                     ;return
;-----------------------------------------------------------------------------------------------------------------------
;
;       Routine:        ConPutCursor
;
;       Description:    This routine places the cursor at the current index into the current field.
;
;-----------------------------------------------------------------------------------------------------------------------
ConPutCursor            push    ecx                                             ;save non-volatile regs
                        mov     ecx,[wdConsoleField]                            ;current field?
                        jecxz   .10                                             ;no, branch
                        mov     al,[ecx+4]                                      ;field row
                        mov     [wbConsoleRow],al                               ;set current row
                        mov     al,[ecx+5]                                      ;field column
                        add     al,[ecx+7]                                      ;field offset
                        mov     [wbConsoleColumn],al                            ;set curren tcol
                        placeCursor                                             ;place the cursor
.10                     pop     ecx                                             ;restore non-volatile regs
                        ret                                                     ;return
;-----------------------------------------------------------------------------------------------------------------------
;
;       Routine:        ConMain
;
;       Description:    This routine sets the current panel to the main panel (CON001).
;
;       In:             ES:     OS data segment
;
;-----------------------------------------------------------------------------------------------------------------------
ConMain                 push    ecx                                             ;save non-volatile regs
                        push    edi                                             ;
;
;       Initialize current panel, field.
;
                        mov     eax,czPnlCon001                                 ;main panel addr
                        mov     [wdConsolePanel],eax                            ;set panel addr
                        mov     eax,czPnlConInp                                 ;main panel command field addr
                        mov     [wdConsoleField],eax                            ;set active field
;
;       Clear panel video memory and draw fields
;
                        call    ConClearPanel                                   ;clear panel
                        call    ConDrawFields                                   ;draw fields
;
;       Restore and return.
;
                        pop     edi                                             ;restore non-volatile regs
                        pop     ecx                                             ;
                        ret                                                     ;return
;-----------------------------------------------------------------------------------------------------------------------
;
;       Constants
;
;-----------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------
;
;       Panels
;
;       Notes:          1.      Each field MUST have an address of a constant or an input field.
;                       2.      The constant text or input field MUST be at least the length of the field.
;                       3.      Field constant text or field values MUST be comprised of printable characters.
;
;-----------------------------------------------------------------------------------------------------------------------
                                                                                ;---------------------------------------
                                                                                ;  Main Panel
                                                                                ;---------------------------------------
czPnlCon001             dd      czFldPnlIdCon001                                ;field text
                        db      0,0,6,0,0,0,7,0                                 ;row col siz ndx 1st nth atr flg
                        dd      czFldTitleCon001
                        db      0,33,14,0,0,0,7,0
                        dd      czFldDatTmCon001
                        db      0,63,17,0,0,0,7,0
                        dd      czFldPrmptCon001
                        db      23,0,1,0,0,0,7,0
czPnlConInp             dd      wzConsoleInBuffer
                        db      23,1,79,0,0,0,7,80h
                        dd      0                                               ;end of panel
;-----------------------------------------------------------------------------------------------------------------------
;
;       Strings
;
;-----------------------------------------------------------------------------------------------------------------------
czFldPnlIdCon001        db      "CON001",0                                      ;main console panel id
czFldTitleCon001        db      "OS Version 1.0",0                              ;main console panel title
czFldDatTmCon001        db      "DD-MMM-YYYY HH:MM",0                           ;panel date and time template
czFldPrmptCon001        db      ":",0                                           ;command prompt
                        times   4096-($-$$) db 0h                               ;zero fill to end of section
%endif
%ifdef BUILDDISK
;-----------------------------------------------------------------------------------------------------------------------
;
;       Free Disk Space                                                         @disk: 009600   @mem:  n/a
;
;       Following the convention introduced by DOS, we use the value 'F6' to indicate unused floppy disk storage.
;
;-----------------------------------------------------------------------------------------------------------------------
section                 unused                                                  ;unused disk space
                        times   EBOOTDISKBYTES-09600h db 0F6h                   ;fill to end of disk image
%endif
;=======================================================================================================================
;
;       End of Program Code
;
;=======================================================================================================================
