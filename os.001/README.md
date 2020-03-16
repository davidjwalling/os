### Project os.001
Source: [os.001/os.asm](../os.001/os.asm)

### Features and Topics
- Documentation Standards
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

### [Virtual](VIRTUAL.md) Machine Operation
- Start a VirtualBox VM configured to boot from os.dsk, emulating a 3.5" 1.44MB floppy diskette following these [steps](VIRTUAL.md).
- The boot (first) sector of the diskette image is loaded to real mode address 0x7C00 and executed.
- The boot sector displays a message, "Starting OS", and waits for a keypress.
- Upon a key press, the system restarts.

<img src="../images/os001_VirtualBox_001.PNG" width="640"/>

### [Physical](PHYSICAL.md) Machine Operation
- Prepare a physical 3.5" 1.44MB diskette with os.dat as the boot sector following these [steps](PHYSICAL.md).
- Insert the prepared diskette into a 3.5" floppy disk drive configured as Drive A:.
- Start the system.

<img src="../images/os001_Boot_001.jpg"/>

### Notes
The sample programs begin with a "flowerbox". That is, a sequence of commented lines with a visible border on, at least, the top and bottom rows and the leftmost column. Omitting a vertical right border avoids excessive padding characters to enforce alignment. In these samples, flowerboxes are "major" or "minor". Major flowerboxes use double dashes (or equals signs) for upper and lower borders. Minor flowerboxes uses dashes for upper and lower borders. Major flowerboxes begin the program and major code parts. Minor flowerboxes describe code or data immediately following. The program flowerbox is a major flowerbox that includes the file name, project name, a description of the program, the date of revision, instructions to assemble the program, the version of the assembler used and a copyright notice. Flowerbox contents are column-aligned to improve readability and quick location of information.

Assembly directives recognized in the source code are described in a minor flowerbox. Directives may cascade, as where defining BUILDDISK will automatically define BUILDBOOT.

Extensive coding conventions are described in a minor flowerbox. Many conventions support improved readability, such as alignment, naming, and case usage. Other conventions promote efficient operation and maintainability, such as register use, parameter passing and routine entry and exit.

Program symbolic constants (equates) are defined in a consolidated major part, segmented into hardware, firmware and software domains. Hardware equates include specific devices, such as keyboard controllers. Firmware equates include BIOS constants. Software equates include external standards, such as ASCII, and program-defined values.

The Boot Sector is the first major code part. This code is loaded by the BIOS from the first sector of the boot disk into RAM at real-mode address 0x7C00. The sector length is 512 bytes. A valid boot sector ends with the two-byte signature, 0x55 0xAA. The "cpu" assembler directive allows the code section to include only code that will execute on an Intel 8086 or compatible processor. The OS should verify the CPU type before attempting to execute instructions reserved to later processors. The "boot" section includes a "vstart" parameter instructing the assembler to compose address offsets for labels assuming a 0x100 displacement from the start of the section. This is compatible with the .COM program model. BIOS operations begins in 16-bit real mode. The boot sector, therefore, is written in 16-bit code to accept control directly from the BIOS. The "bits 16" directive instructs the assembler to generate 16-bit code.

By convention, a diskette parameter table is located at the start of the boot sector, immediately after a three-byte JMP instruction. This table is used by the BIOS at boot time to define the characteristics of the boot disk. Where possible, the code uses computed constants, especially when implementing address offsets or aggregated data. Source lines illustrating constant computation include 246, 282, 353 and 365.

Note that a MOV into SS will disable interrupts until the completion of the following instruction which, usually, will allow an uninterrupted setting of SP. Also note the precautionary use of STI prior to any use of HLT.Note also that a MOV into SS will disable interrupts until the completion of the following instruction which, usually, will allow an uninterrupted setting of SP.
