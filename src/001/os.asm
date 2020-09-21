EKEYBPORTSTAT           equ     064h                                            ;status port
EKEYBCMDRESET           equ     0FEh                                            ;reset bit 0 to restart system
EBIOSINTVIDEO           equ     010h                                            ;video services interrupt
EBIOSFNSETVMODE         equ     000h                                            ;video set mode function
EBIOSMODETEXT80         equ     003h                                            ;video mode 80x25 text
EBIOSFNTTYOUTPUT        equ     00Eh                                            ;video TTY output function
EBIOSINTKEYBOARD        equ     016h                                            ;keyboard services interrupt
EBIOSFNKEYSTATUS        equ     001h                                            ;keyboard status function
EBOOTSTACKTOP           equ     0100h                                           ;boot sector stack top relative to DS
EBOOTSECTORBYTES        equ     512                                             ;bytes per sector
EBOOTDIRENTRIES         equ     224                                             ;directory entries (1.44MB 3.5" FD)
EBOOTDISKSECTORS        equ     2880                                            ;sectors per disk (1.44MB 3.5" FD)
                        cpu     8086                                            ;assume minimal CPU
section                 boot    vstart=0100h                                    ;emulate .COM (CS,DS,ES=PSP) addressing
                        bits    16                                              ;16-bit code at power-up
Boot                    jmp     word .10                                        ;jump over parameter table
                        db      "OS      "                                      ;eight-byte label
                        dw      EBOOTSECTORBYTES                                ;bytes per sector
                        db      1                                               ;sectors per cluster
                        dw      1                                               ;reserved sectors
                        db      2                                               ;file allocation table copies
                        dw      EBOOTDIRENTRIES                                 ;max directory entries
                        dw      EBOOTDISKSECTORS                                ;sectors per disk
                        db      0F0h                                            ;1.44MB
                        dw      9                                               ;sectors per FAT copy
                        dw      18                                              ;sectors per track (as word)
                        dw      2                                               ;sides per disk
                        dw      0                                               ;special sectors
                                                                                ;CS:IP   0:7c00 700:c00 7c0:0
.10                     call    word .20                                        ;[ESP] =   7c21     c21    21
.@20                    equ     $-$$                                            ;.@20 = 021h
.20                     pop     ax                                              ;AX =      7c21     c21    21
                        sub     ax,.@20                                         ;AX =      7c00     c00     0
                        mov     cl,4                                            ;shift count
                        shr     ax,cl                                           ;AX =       7c0      c0     0
                        mov     bx,cs                                           ;BX =         0     700   7c0
                        add     bx,ax                                           ;BX =       7c0     7c0   7c0
                        sub     bx,16                                           ;BX = 07b0
                        mov     ds,bx                                           ;DS = 07b0 = psp
                        mov     es,bx                                           ;ES = 07b0 = psp
                        mov     ss,bx                                           ;SS = 07b0 = psp (ints disabled)
                        mov     sp,EBOOTSTACKTOP                                ;SP = 0100       (ints enabled)
                        mov     ax,EBIOSFNSETVMODE<<8|EBIOSMODETEXT80           ;set mode function, 80x25 text mode
                        int     EBIOSINTVIDEO                                   ;call BIOS display interrupt
                        mov     si,czStartingMsg                                ;starting message
                        call    PutTTYString                                    ;display loader message
.30                     mov     ah,EBIOSFNKEYSTATUS                             ;keyboard status function
                        int     EBIOSINTKEYBOARD                                ;call BIOS keyboard interrupt
                        jnz     .40                                             ;exit if key pressed
                        sti                                                     ;enable maskable interrupts
                        hlt                                                     ;wait for interrupt
                        jmp     .30                                             ;repeat until keypress
.40                     mov     al,EKEYBCMDRESET                                ;8042 pulse output port pin
                        out     EKEYBPORTSTAT,al                                ;drive B0 low to restart
.50                     sti                                                     ;enable maskable interrupts
                        hlt                                                     ;stop until reset, int, nmi
                        jmp     .50                                             ;loop until restart kicks in
PutTTYString            cld                                                     ;forward strings
.10                     lodsb                                                   ;load next byte at DS:SI in AL
                        test    al,al                                           ;end of string?
                        jz      .20                                             ;... yes, exit our loop
                        mov     ah,EBIOSFNTTYOUTPUT                             ;BIOS teletype function
                        int     EBIOSINTVIDEO                                   ;call BIOS display interrupt
                        jmp     .10                                             ;repeat until done
.20                     ret                                                     ;return
czStartingMsg           db      "Starting OS",13,10,0                           ;starting message
                        times   510-($-$$) db 0h                                ;zero fill to end of sector
                        db      055h,0AAh                                       ;end of sector signature