### OS

Copyright :copyright: 2010-2020 David J. Walling. MIT License.

- A simple operating system for x86-based PC-compatible systems.
- Operates on 32-bit Intel:registered: or AMD:registered: x86 from the 80386 up through present-day processors.
- Does not require coprocessors or other external firmware or engines beyond the chipset.
- Presented in a series of subprojects that progressively demonstrate concepts.
- Clear assembly-language, hardware I/O and protocol examples.

Click on the subproject name below for details.

<table>
<tr><td><a href="/src/os.001">os.001</a></td><td>Load and run a boot sector that displays a message and waits for a key-press.</td></tr>
<tr><td><a href="/src/os.002">os.002</a></td><td>Extend the boot sector to load and run a program that displays a message and waits for a key.</td></tr>
<tr><td><a href="/src/os.003">os.003</a></td><td>Create the osprep.com utility that writes the boot sector to a diskette.</td></tr>
<tr><td><a href="/docs/OS004.md">os.004</a></td><td>Expand the loader to enter protected mode and start a task.</td></tr>
<tr><td><a href="/docs/OS005.md">os.005</a></td><td>Add a panel definition to the console task main screen.</td></tr>
<tr><td><a href="/docs/OS006.md">os.006</a></td><td>Add a keyboard interrupt handler to display characters and shift-key status.</td></tr>
<tr><td><a href="/docs/OS007.md">os.007</a></td><td>Add a message queue to route keyboard events to a task.</td></tr>
<tr><td><a href="/docs/OS008.md">os.008</a></td><td>Accept the reset command ("r") to restart the system.</td></tr>
<tr><td><a href="/docs/OS009.md">os.009</a></td><td>Add the "int6" command to demonstrate CPU interrupt handling.</td></tr>
<tr><td><a href="/docs/OS010.md">os.010</a></td><td>Add a memory display panel.</td></tr>
<!--
<tr><td><a href="docs/OS010.md">os.010</a></td><td>Add memory allocation and deallocation routines</td></tr>
<tr><td><a href="docs/OS011.md">os.011</a></td><td>Display memory sizes reported by BIOS and Real-Time Clock (RTC)</td></tr>
<tr><td><a href="docs/OS012.md">os.012</a></td><td>Add "date", "time" and related commands with RTC chip support</td></tr>
<tr><td><a href="docs/OS013.md">os.013</a></td><td>Probe and display PCI devices</td></tr>
<tr><td><a href="docs/OS014.md">os.014</a></td><td>Display Ethernet adapter memory I/O address and port</td></tr>
<tr><td><a href="docs/OS015.md">os.015</a></td><td>Initialize and reset discovered PCI network adapter</td></tr>
<tr><td><a href="docs/OS016.md">os.016</a></td><td>Receive an Ethernet frame from the network</td></tr>
<tr><td><a href="docs/OS017.md">os.017</a></td><td>Add a second task and IRQ0-driven task switching</td></tr>
<tr><td><a href="docs/OS018.md">os.018</a></td><td>Load and run a task (program) from disk</td></tr>
<tr><td><a href="docs/OS019.md">os.019</a></td><td>Start, stop and list tasks</td></tr>
<tr><td><a href="docs/OS020.md">os.020</a></td><td>Configure tasks to run at start-up</td></tr>
-->
</table>

### Assembly

- Samples assembled using NASM (Netwide Asssembler) version 2.14.02.
- make.bat assembles and links on Windows using NASM and ALINK.
- Makefile assembles and links on Linux using NASM and ld.

### Directives

<table>
<tr><td>BUILDBOOT</td><td>Create os.dat, the operating system boot sector.</td></tr>
<tr><td>BUILDDISK</td><td>Create os.dsk, a 1.44MB 3.5" floppy disk image.</td></tr>
<tr><td>BUILDCOM</td><td>Create os.com, the operating system kernel program.</td></tr>
<tr><td>BUILDPREP</td><td>Create osprep.com, a utility to write the boot sector to a diskette.</td></tr>
</table>

### Output

<table>
<tr><td>os.dat</td><td>A 512-byte boot sector image that may be written to a physical floppy disk for physical implementations.</td></tr>
<tr><td>os.dsk</td><td>A 1.44MB floppy-disk image for use as a boot disk for either physical or virtual implementations. This disk image contains a boot sector that searches for and loads the os.com kernel image file into memory. Code in os.com places the CPU into protected mode and starts the initial 32-bit console task.</td></tr>
<tr><td>os.com</td><td>The operating system kernel image loaded and run by the boot sector. OS.COM can also be run from a DOS command line.</td></tr>
<tr><td>osprep.com</td><td>A DOS-compatible program that copies the os.dat boot sector image file to the boot sector of a 3.5" 1.44MB floppy disk inserted in logical drive A:.</td></tr>
</table>

### Installation

<table>
<tr><td><a href="/docs/VIRTUAL.md">Virtual</a></td><td>Configure a virtual machine instance to boot from a floppy drive disk image and select the os.dsk file as the disk image for Floppy Device 0. Select a base memory minimum setting of 4MB or higher.</td></tr>
<tr><td><a href="/docs/PHYSICAL.md">Physical</a></td><td>For projects os.001 and os.002, copy os.dat to the boot sector of a formatted floppy diskette. Here we use the HxD utility program to do this. In project os.003, we introduce a utility osprep.com to perform this. Starting with project os.002, copy the os loader program, os.com, to the diskette. Insert the diskette into the target physical system's diskette drive A:. Restart the target physical system.</td></tr>
</table>

### Network Support

- OS includes native support for the Intel :registered: PRO/1000 MT Desktop (82540EM) network adapter.
- Virtual machine installations may select this adapter type in the network configuration of the VM.
- Configure this VM network adapter using bridged networking to access the host system's network.

### Operation

[Operating System Commands](/docs/COMMANDS.md)

### Contributors

<table>
<tr><td>David J. Walling</td><td>Email: david@davidjwalling.com</td><td>Twitter: @davidjwalling</td></tr>
</table>
