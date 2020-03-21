### Project os.003
Source: [os.003/os.asm](os.asm)

### Features and Topics
- The BUILDPREP directive assembles the ```osprep.com``` program.
- Writing disk sectors using the BIOS.

### [Virtual](../docs/VIRTUAL.md) Machine Operation
- The ```osprep.com``` program is created by make.bat or make with Makefile.
- ```osprep.com``` will not operate on 64-bit operating systems.
- See the Physical Machine Operation below for instructions using ```osprep.com```.

### [Physical](../docs/PHYSICAL.md) Machine Operation
- Project os.003 does not change the boot sector created in Project os.002.
- It is not necessary to update the boot sector of the physical floppy diskette.
- To prepare for physical machine operation using ```osprep.com```, copy ```osprep.com``` to a formatted diskette.
- Insert a bootable DOS diskette into a floppy disk drive.
- Start the system.

<img src="../images/os003_osprep_001.jpg"/>

- Once the system is booted into DOS, insert a diskette containing ```osprep.com```.
- Here we use the DOS "dir" command to list the files on the diskette.
- Confirm that ```osprep.com``` is present on the diskette.

<img src="../images/os003_osprep_002.jpg"/>

- Next, we run the ```osprep.com``` as a DOS program.
- ```Osprep.com``` displays instructional text.
- Per instructions, insert a formatted diskette in drive A: on which we want ```os.dat``` written as the boot sector.

<img src="../images/os003_osprep_003.jpg"/>

- After inserting the target diskette and pressing enter, the boot sector is written to the diskette.
- A confirmation message is displayed after the boot sector is written.
- DOS will prompt to restore the DOS diskette to return to the DOS command prompt.

<img src="../images/os003_osprep_004.jpg"/>

### Notes

Project os.003 introduces code to prepare a floppy diskette boot sector to load OS. The assembly directive BUILDPREP is used to create only the ```osprep.com``` program.

When ```osprep.com``` is created, it runs using .COM addressability. Instead of starting with a JMP instruction to the Boot code, it jumps to the OS preparation code.

The preparation code displays the starting greeting message and waits for the operator to confirm that a formatted diskette is placed in the floppy disk drive. The JMP instruction at the start of the boot sector is fixed to point to the Boot code before it is written to the diskette.

The existing boot sector on the target diskette is read and the disk parameter table is used to overwrite the parameter table in the OS boot sector. This is so that if the target disk parameters are different, they are preserved so that the book diskette is still valid.

If an error occurs during the write of the boot sector, the error message is displayed.

The program checks for well-known errors that can occur writing to a diskette. Disk write error numbers are displayed with accompanying message text.
