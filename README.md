### OS

Copyright :copyright: 2010-2019 David J. Walling. MIT License.

- A simple operating system for x86-based PC-compatible systems.
- A series of subprojects that demonstrate design and coding concepts.
- Assembly-language, hardware I/O and protocol examples.
- Fully-functional code as a learning resource.

<span><i>No Windows. No Linux. No Mac. No "Management Engine". No Problem.</i></span>

Click on the subproject name below for details.

<table>
<tr><td><a href="docs/OS001.md">os.001</a></td><td>A boot sector that displays a message and waits for a key-press</td></tr>
<tr><td><a href="docs/OS002.md">os.002</a></td><td>A boot sector that loads and runs a program that displays a message and waits for a key</td></tr>
<tr><td><a href="docs/OS003.md">os.003</a></td><td>Create the osprep.com utility that writes the boot sector to a diskette</td></tr>
<tr><td><a href="docs/OS004.md">os.004</a></td><td>Expand the loader to enter protected mode and start a task</td></tr>
<tr><td><a href="docs/OS005.md">os.005</a></td><td>Add a keyboard interrupt handler to display characters and shift-key status</td></tr>
<tr><td><a href="docs/OS006.md">os.006</a></td><td>Add a message queue to route keyboard events to a task</td></tr>
<tr><td><a href="docs/OS007.md">os.007</a></td><td>Interpret "exit", "quit" and "shutdown" as commands</td></tr>
<tr><td><a href="docs/OS008.md">os.008</a></td><td>Add a "int6" command to demonstrate CPU interrupt handling</td></tr>
<tr><td><a href="docs/OS009.md">os.009</a></td><td>Add a memory display panel</td></tr>
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

<table cols=3>
<tr><td colspan=2><a href="docs/VIRTUAL.md">Virtual</a></td><td>Configure a virtual machine instance to boot from a floppy drive disk image and select the os.dsk file as the disk image for Floppy Device 0. Select a base memory minimum setting of 4MB or higher.</td></tr>
<tr><td><a href="docs/PHYSICAL.md">Physical</a></td><td>A</td><td>Transfer os.dat, os.com and osprep.com to a host system configured with a physical floppy drive and DOS. Execute the osprep.com to copy os.dat to the diskette. Copy os.com to the the diskette. Boot the system with the floppy disk inserted in Drive A:.</td></tr>
<tr><td></td><td>B</td><td>Using an alternate disk utility, transfer the entirety of os.dsk to the physical floppy disk, or copy only os.dat to the boot sector. Copy os.com to the diskette. Boot the system with the floppy disk inserted in Drive A:.</td></tr>
</table>

### Network Support:

- OS includes native support for the Intel(R) PRO/1000 MT Desktop (82540EM) network adapter.
- Virtual machine installations may select this adapter type in the network configuration of the VM.
- Configure this VM network adapter using bridged networking to access the host system's network.

### Contributors

<table>
<tr><td>David J. Walling</td><td>Email: david@davidjwalling.com</td><td>Twitter: @davidjwalling</td></tr>
</table>
