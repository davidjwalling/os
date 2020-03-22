### Project os.008
Source: [os.008/os.asm](os.asm)

### Features and Topics

### [Virtual](/docs/VIRTUAL.md) Machine Operation
- Update the Virtual Machine configuration to use os.008/os.dsk as the diskette image.
- Start the Virtual Machine.

### [Physical](/docs/PHYSICAL.md) Machine Operation
- Overwrite os.com on the OS boot diskette with os.008/os.com.
- Insert the OS boot diskette into the physical system's floppy disk drive A:.
- Start the system.

### Notes

This project extends the console task by adding code to interpret a command entered by the operator. The command input field is parsed to take its first token. The token is compared to a list of recognized commands. If the command is recognized, its handler routine is called. Here we add only the reset command, "r" and a new routine to process the command.

As our commands are case insensitive we'll add an UpperCase kernel routine to take operator input and convert it to all capitals before comparing to the command list. A simple mask is used to logically "AND" the lower-case ASCII alphabetic bit to zero.

We we take the first token from the operator command it is placed in a separate buffer.

Three new routines are added to the kernel service request table. CompareMemory, UpperCaseString and ResetSystem.

Here are the macros to invoke the new service requests.

The CompareMemory and UpperCaseString routines inaugurate a new Sting Helper Routines section of the kernel routine library.
ResetSystem is added to our existing Input/Output Routines section.

Now in ConHandlerMain, after we have detected the Enter key having been depressed, we insert code to take the first token from operator input, determine if it is a command and run the command's handler.

Here we have introduced three new routines in the console task. ConTakeToken, ConDetermineCommand and ConReset.

Lastly, we have added two tables in the console task, one to address command handlers and a second to list known commands.
