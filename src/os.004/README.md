### Project os.004
Source: [os.004/os.asm](os.asm)

### Features and Topics
- x86 Protected Mode Operation
- NEC 765 Floppy Disk Controller (FDC) I/O
- 8259 Peripheral Interrupt Controller (PIC) I/O
- 8253 Programmable Interval Timer (PIT) I/O
- Protected Mode Global Descriptor Table (GDT)
- Protected Mode Interrupt Descriptor Table (IDT)
- Protected Mode Local Descriptor Table (LDT)
- Protected Mode Task State Segments (TSS)
- BIOS Reserved Memory Areas
- CPU Type Detection
- Entering a Protected Mode Task and the Task Register
- Hardware Interrupt Request (IRQ) Handlers
- Handling the Clock Timer Interrupt

### [Virtual](/docs/VIRTUAL.md) Machine Operation
- Update the Virtual Machine configuration to use os.004/os.dsk as the diskette image.
- Start the Virtual Machine.

<img src="/images/os004_VirtualBox_001.PNG" width="640"/>

### [Physical](/docs/PHYSICAL.md) Machine Operation
- Overwrite ```os.com``` on the OS boot diskette with os.004/os.com.
- Insert the OS boot diskette into the physical system's floppy disk drive A:.
- Start the system.

<img src="/images/os004_Boot_001.jpg"/>

### Notes
This project introduces code that interfaces with several devices, the NEC 765 floppy disk controller (FDC), the 8042 Keyboard controller, the 8259 peripheral interrupt controller (PIC) and the 8253 programmable interrupt timer (PIT).

This project places the processor into Protected Mode. In this mode, segments are defined in descriptor tables. For each table entry, an access flags word describes the nature of segment (code, data, interrupt, trap, task, gate, etc.).

To enter protected mode, this program uses BIOS interrupt 89h, function 15h.

Several symbolic constants are defined to identify memory areas defined in the Global Descriptor Table (GDT). Also some kernel constants are defined that specify addresses, offsets and lengths.

The OS will reference a few predefined low memory addresses that are set by the BIOS. Here we define a structure that maps the BIOS data area.

The mint, mtrap, menter and tsvce macros assist in building tables and entry points for interrupts.

The size of the OS loader program, ```os.com```, which now includes the OS kernel image itself, is now significantly larger than in project os.003. Here we update the FAT tables to indicate the size and location on disk of the loader program.

Since the OS will run in protected mode and use instructions introduced with the 80386 processor, we add code to the loader to check the CPU type. If the CPU type passes, the global descriptor table (GDT) is updated so that the current code segment of the loader is properly defined. This will allow us to perform a long JMP to a task state segment (TSS) without generating an exception.

Now the OS kernel image, global and interrupt descriptor tables, interrupt handlers and the Console Task is now relocated to its desired location in memory, immediately following OS working storage. The CPU is placed in protected mode, system interrupts are enabled and a long JMP to the Console Task State Segment is made to make the Console Task the currently running task.

If the OS could not be successfully started, the loader exit displays the appropriate error message, waits for the operator to press a key and restarts the system.

For this project, determing the CPU simply checks that the processor is at least an 80386.

The OS loader data segment defines some work areas and message constants.

The OS kernel begins here, consisting of the Global Descriptor Table (GDT), the Interrupt Descriptor Table (IDT), Interrupt Handlers and the Console Task.

The Global Descriptor Table (GDT) defines the location, size and attributes of memory locations that may be accessed by any task.

The Interrupt Descriptor Table (IDT) defines the location and type of interrupt handling routines for processor, hardware and software interrupts and traps. The mint, mtrap macros assist in defining these descriptor entries.

Interrupt handling code begins here and will be developed over the course of several subprojects.

Following the interrupt handlers are reusable routines gathered into a kernel function library. For this project, only two reusable routines are defined, which send end-of-interrupt codes to the primary and secondary 8259 Peripheral Interrupt Controllers (PIC).

The Console Task starts when the OS Loader jumps to the Task State Segment (TSS) for the task. In the Local Descriptor Table (LDT) for the task are definitions for each memory area of the task: code, stack, data, a message queue (used in later projects), the LDT and the TSS. For this project the Console Task simply enters a HLT state until the system is reset.
