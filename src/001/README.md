### Project os.001
Source: [os.asm](os.asm)

### Features and Topics
- Assembly Directives
- Hardware, Firmware and Software Symbolic Constants (Equates)
- Boot Sector Principles
- CPU, SECTION, BITS Directives
- VSTART Section Parameter
- COM Addressing Model
- Diskette Parameter Table
- Computed Constants
- Basic Input/Output System (BIOS) Interrupts
- STI, HLT, MOV SS Instruction Behavior

### [Virtual](/docs/VIRTUAL.md) Machine Operation
- Start a VirtualBox VM configured to boot from os.dsk, emulating a 3.5" 1.44MB floppy diskette following these [steps](/docs/VIRTUAL.md).
- The boot (first) sector of the diskette image is loaded to real mode address 0x7C00 and executed.
- The boot sector displays a message, "Starting OS", and waits for a keypress.
- Upon a key press, the system restarts.

### [Physical](/docs/PHYSICAL.md) Machine Operation
- Prepare a physical 3.5" 1.44MB diskette with os.dat as the boot sector following these [steps](/docs/PHYSICAL.md).
- Insert the prepared diskette into a 3.5" floppy disk drive configured as Drive A:.
- Start the system.

### Notes
Program symbolic constants (equates) are defined for hardware, firmware and software domains. Hardware equates include specific devices, such as keyboard controllers. Firmware equates include BIOS constants. Software equates include external standards, such as ASCII, and program-defined values.

The Boot Sector is loaded by the BIOS from the first sector of the boot disk into RAM at real-mode address 0x7C00. The sector length is 512 bytes. A valid boot sector ends with the two-byte signature, 0x55 0xAA. The "cpu" assembler directive allows the code section to include only code that will execute on an Intel 8086 or compatible processor. The "boot" section statement includes a "vstart" parameter instructing the assembler to compose address offsets for labels assuming a 0x100 displacement from the start of the section. This is compatible with the .COM program model. BIOS operations begins in 16-bit real mode. The boot sector, therefore, is written in 16-bit code to accept control directly from the BIOS. The "bits 16" directive instructs the assembler to generate 16-bit code.

By convention, a diskette parameter table is located at the start of the boot sector, immediately after a three-byte JMP instruction. This table is used by the BIOS at boot time to define the characteristics of the boot disk. Where possible, the code uses computed constants, especially when implementing address offsets or aggregated data.

Note that a MOV into SS will disable interrupts until the completion of the following instruction which allows an uninterrupted setting of SP. Also note the precautionary use of STI prior to any use of HLT.
