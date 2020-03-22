### Project os.009
Source: [os.009/os.asm](os.asm)

### Features and Topics
- CPU interrupt reporting

### [Virtual](/docs/VIRTUAL.md) Machine Operation
- Update the Virtual Machine configuration to use os.009/os.dsk as the diskette image.
- Start the Virtual Machine.

### [Physical](/docs/PHYSICAL.md) Machine Operation
- Overwrite os.com on the OS boot diskette with os.009/os.com.
- Insert the OS boot diskette into the physical system's floppy disk drive A:.
- Start the system.

### Notes

Project os.009 provides a ReportInterrupt function to capture register values at the time of a CPU interrupt and display them to the screen. For now the OS does not recover from CPU interrupts. We begin by defining some extended ASCII border values that will provide textual graphic border to our register values display.

Next, we've updated the 32 CPU interrupt handlers to store an interrupt number and a message offset address on the stack before jumping to the ReportInterrupt routine.

Next, we update the ReportInterrupt routine to format and display a message showing the value of the registers at the tiem of the interrupt.

The DrawTextDialogBox routine is called to draw the ASCII text border.

Two new kernel routines are added to help convert 16 and 32-bit binary values to hexadecimal ASCII character representations.

The SetConsolString routine is added to call SetConsoleChar in series for a character string.

Finally, in the console task, the ConInt6 routine is added to issue a known bad opcode (udp2) to trigger the CPU interrupt 6. This command name and its offset address are added to the command tables.
