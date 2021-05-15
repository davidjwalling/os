;=======================================================================================================================
;
;       File:           os.asm
;
;       Project:        002
;
;       Description:    This sample program adds code to load the operating system kernel program from the disk image.
;                       The boot sector searches the disk for the loader program, loads it into memory and runs it.
;                       The loader program in this sample simply displays a greeting.
;
;       Revised:        1 Jan 2021
;
;       Assembly:       nasm os.asm -f bin -o os.dat -l os.dat.lst -DBUILDBOOT
;                       nasm os.asm -f bin -o os.dsk -l os.dsk.lst -DBUILDDISK
;                       nasm os.asm -f bin -o os.com -l os.com.lst -DBUILDCOM
;
;       Assembler:      Netwide Assembler (NASM) 2.15.05, 28 Aug 2020
;
;       Notice:         Copyright (c) 2010 David J. Walling. All rights reserved.
;
;=======================================================================================================================
;-----------------------------------------------------------------------------------------------------------------------
;
;       Assembly Directives
;
;       Use one of the following as an assembly directive (-D) with NASM.
;
;       BUILDBOOT       Creates os.dat, a 512-byte boot sector as a stand-alone file.
;       BUILDDISK       Creates os.dsk, a 1.44MB (3.5") floppy disk image file.
;       BUILDCOM        Creates os.com, the OS loader and kernel as a standalone DOS program.
;
;-----------------------------------------------------------------------------------------------------------------------
%ifdef BUILDDISK                                                                ;if we are building a disk image ...
%define BUILDBOOT                                                               ;... also build the boot sector
%define BUILDCOM                                                                ;... and the OS kernel
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
;                       may be used as the sole parameter if a test for zero is performed. EBX and EBP may be used as
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
;                       routine begin at .10 and increment by 10.
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
;                       value is to be tested for null upon return using, for example, the jecxz instruction.
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
;       EKEYB...        8042 or "PS/2 Controller" (Keyboard Controller) values
;
;       Firmware-Defined Values
;
;       EBIOS...        Basic Input/Output System (BIOS) values
;
;       Operating System Values
;
;       EBOOT...        Boot sector and loader values
;
;=======================================================================================================================
;-----------------------------------------------------------------------------------------------------------------------
;
;       Hardware-Defined Values
;
;-----------------------------------------------------------------------------------------------------------------------
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
EBIOSINTKEYBOARD        equ     016h                                            ;keyboard services interrupt
EBIOSFNKEYSTATUS        equ     001h                                            ;keyboard status function
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
;       we expect to ever execute the code. The "vstart" parameter indicates addressability of symbols so as to
;       emulate the DOS .COM program model. Although the BIOS is expected to load the boot sector at address 7c00,
;       we do not make that assumption. The CPU starts in 16-bit addressing mode. A three-byte jump instruction is
;       immediately followed by the disk parameter table.
;
;=======================================================================================================================
                        cpu     8086                                            ;assume minimal CPU
section                 boot    vstart=0100h                                    ;emulate .COM (CS,DS,ES=PSP) addressing
                        bits    16                                              ;16-bit code at power-up
Boot                    jmp     word Boot.10                                    ;jump over parameter table
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
;       the end of the boot sector. But, since BIOS code varies, we don't make any assumptions as to where the boot
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
;       Now, since we are assembling the boot code to emulate the addressing of a .COM file, we want the DS and ES
;       registers to be set to where a Program Segment Prefix (PSP) would be, exactly 100h (256) bytes prior to
;       the start of the code. This will correspond to the assembled data address offsets. Note that we instructed
;       the assembler to produce addresses for the symbols that are offset from the code by 100h. See the "vstart"
;       parameter for the "section" directive above. We also set SS to the PSP and SP to the address of the i/o
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
;       Boot addressability is now set up according to the following diagram.
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
;       Write a message to the console so we know we have addressability established.
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
                        jz      BootReturn                                      ;... yes, exit loop
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
%ifdef BUILDDISK
;=======================================================================================================================
;
;       File Allocation Tables
;
;       The disk contains two copies of the File Allocation Table (FAT). On the disk, each FAT copy is 1200h bytes in
;       length. Each FAT entry contains the logical number of the next cluster. The first two entries are reserved. Our
;       OS.COM file here is 400h bytes in length. These 400h bytes contain familiar code that displays a message to the
;       screen. The disk parameter table defines a cluster as containing one sector and each sector having 200h bytes.
;       Therefore, the FAT table must reserve only two clusters for OS.COM. The clusters used by OS.COM, then, will be
;       clusters 2 and 3. The entry value for cluster 3 is set to "0fffh" to indicate that it is the last cluster in the
;       chain.
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
                        db      0F0h,0FFh,0FFh, 003h,0F0h,0FFh
                        times   (9*512)-($-$$) db 0                             ;zero fill to end of section
;-----------------------------------------------------------------------------------------------------------------------
;
;       FAT copy 2                                                              @disk: 001400   @mem: n/a
;
;-----------------------------------------------------------------------------------------------------------------------
section                 fat2                                                    ;second copy of FAT
                        db      0F0h,0FFh,0FFh, 003h,0F0h,0FFh
                        times   (9*512)-($-$$) db 0                             ;zero fill to end of section
;-----------------------------------------------------------------------------------------------------------------------
;
;       Diskette Directory                                                      @disk: 002600   @mem: n/a
;
;       The disk contains one copy of the diskette directory. Each directory entry is 32 bytes long. The directory
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
                        dd      1024                                            ;file size
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
;       Loader addressability is set up according to the following diagram.
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
;       disk, we can assume that the initial IP is 0x100 and not perform any absolute address fix-ups on the segment
;       registers.
;
;-----------------------------------------------------------------------------------------------------------------------
                        cpu     8086                                            ;assume minimal CPU
section                 loader  vstart=0100h                                    ;use .COM compatible addressing
                        bits    16                                              ;this is 16-bit code
Loader                  push    cs                                              ;use the code segment
                        pop     ds                                              ;...as the data segment
                        push    cs                                              ;use the code segment
                        pop     es                                              ;...as the extra segment
;
;       Write a message to the console so we know we have addressability established.
;
                        mov     si,czStartingMsg                                ;starting message
                        call    PutTTYString                                    ;display loader message
;
;       Now we want to wait for a keypress. We can use a keyboard interrupt function for this (INT 16h, AH=0).
;       However, some hypervisor BIOS implementations have been seen to implement the "wait" as simply a fast
;       iteration of the keyboard status function call (INT 16h, AH=1), causing a max CPU condition. So, instead,
;       we will use the keyboard status call and iterate over a halt (HLT) instruction until a key is pressed.
;       The STI instruction enables maskable interrupts, including the keyboard. The CPU assures that the
;       instruction immediately following STI will be executed before any interrupt is serviced.
;
.10                     mov     ah,EBIOSFNKEYSTATUS                             ;keyboard status function
                        int     EBIOSINTKEYBOARD                                ;call BIOS keyboard interrupt
                        jnz     .20                                             ;exit if key pressed
                        sti                                                     ;enable maskable interrupts
                        hlt                                                     ;wait for interrupt
                        jmp     .10                                             ;repeat until keypress
;
;       Now that a key has been pressed, we signal the system to restart by driving the B0 line on the 8042
;       keyboard controller low (OUT 64h,0feh). The restart may take some microseconds to kick in, so we issue
;       HLT until the system resets.
;
.20                     mov     al,EKEYBCMDRESET                                ;8042 pulse output port pin
                        out     EKEYBPORTSTAT,al                                ;drive B0 low to restart
.30                     sti                                                     ;enable maskable interrupts
                        hlt                                                     ;stop until reset, int, nmi
                        jmp     .30                                             ;loop until restart kicks in
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
                        jz      .20                                             ;... yes, exit loop
                        mov     ah,EBIOSFNTTYOUTPUT                             ;BIOS teletype function
                        int     EBIOSINTVIDEO                                   ;call BIOS display interrupt
                        jmp     .10                                             ;repeat until done
.20                     ret                                                     ;return
;-----------------------------------------------------------------------------------------------------------------------
;
;       Loader Data
;
;       The only "data" is the string displayed when the system starts. It ends with ASCII carriage-return (13) and
;       line-feed (10) values. The remainder of the boot sector is filled with NUL. The boot sector finally ends with
;       the required two-byte signature checked by the BIOS. Note that recent versions of NASM will issue a warning if
;       the calculated address for the end-of-sector signature produces a negative value for "1024-($-$$)". This will
;       indicate if we have added too much data and exceeded the length of the sector. Note also that since we are at
;       the end of a "file" (os.com) and not the boot sector, there is no end-of-sector marker (0x55 0xaa) here.
;
;-----------------------------------------------------------------------------------------------------------------------
czStartingMsg           db      "Starting OS",13,10,0                           ;starting message
                        times   1024-($-$$) db 0h                               ;zero fill to end of sector
%endif
%ifdef BUILDDISK
;-----------------------------------------------------------------------------------------------------------------------
;
;       Free Disk Space                                                         @disk: 004600   @mem:  n/a
;
;       Following the convention introduced by DOS, we use the value 'F6' to indicate unused floppy disk storage.
;
;-----------------------------------------------------------------------------------------------------------------------
section                 unused                                                  ;unused disk space
                        times   EBOOTDISKBYTES-04600h db 0F6h                   ;fill to end of disk image
%endif
;=======================================================================================================================
;
;       End of Program Code
;
;=======================================================================================================================
