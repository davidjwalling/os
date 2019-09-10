### OS

	Copyright (C) 2010-2019 David J. Walling. MIT License.

	OS demonstrates assembly-language programming, hardware I/O techniques and standard protocol
	implementations in the form of a rudimentary operating system for x86-based PC-compatible systems.
	OS is provided as a learning resource. All code is intended to be fully-functional.

### Subprojects

	OS is a series of subprojects that introduce and demonstrate design and coding concepts.
	Additional subprojects may be added from time to time as the project develops.

	Click on the subproject name below for detailed notes.

<table width="100%">
<tr width="100%"><td><span><a href="docs/OS001.md">os.001</a></span></td><td>A boot sector that displays a message and waits for a key-press</td></tr>
<tr><td><span><a href="docs/OS002.md">os.002</a></span></td><td>A boot sector that loads and runs a program that displays a message and waits for a key</td></tr>
<tr><td><span><a href="docs/OS003.md">os.003</a></span></td><td>Create the osprep.com utility that writes the boot sector to a diskette</td></tr>
<tr><td><span><a href="docs/OS004.md">os.004</a></span></td><td>Expand the loader to enter protected mode and start a task</td></tr>
<tr><td><span><a href="docs/OS005.md">os.005</a></span></td><td>Add a keyboard interrupt handler to display characters and shift-key status</td></tr>
<tr><td><span><a href="docs/OS006.md">os.006</a></span></td><td>Add a message queue to route keyboard events to a task</td></tr>
<tr><td><span><a href="docs/OS007.md">os.007</a></span></td><td>Interpret "exit", "quit" and "shutdown" as commands</td></tr>
<tr><td><span><a href="docs/OS008.md">os.008</a></span></td><td>Add a "int6" command to demonstrate CPU interrupt handling</td></tr>
</table>


os.009		Add "mem" and "memory" commands to display memory and "main" to return to the main panel.
os.010		Add simple memory allocation and deallocation routines and "malloc" and "free" test routines.
os.011		Add memory-size reporting from BIOS and Real-Time Clock (RTC) chip.
os.012		Add "date", "time" and related commands with RTC chip support.
os.013		Add logic to probe for and list PCI devices using the "pciprobe" or "lspci" commands.
os.014		Add code to display ethernet adapter memory i/o address and i/o port.
os.015		Add code to initialize and reset discovered PCI network adapter.
os.016		Add code to receive an Ethernet frame.
os.017		Add a second task manually and IRQ0-driven task switching.
os.018		Add support to load a task from disk.
os.019		Add commands to start, stop and list tasks.
os.020		Add code to configure tasks to run on start-up.

### Assembly

- OS is assembled on this site using NASM (Netwide Asssembler) version 2.14.02.
- The make.bat file is provided to assemble and link on Windows using NASM and ALINK.
- The Makefile file is provided to assemple and link on Linux using NASM and ld.

These directives are recognized in the source code:

- BUILDBOOT	Create os.dat, the operating system boot sector.
- BUILDDISK	Create os.dsk, a 1.44MB 3.5" floppy disk image.
- BUILDCOM	Create os.com, the operating system kernel program.
- BUILDPREP	Create osprep.com, a utility to write the boot sector to a diskette.

### Installation

The project's make file produces the following output:

	os.dat		A 512-byte boot sector image that may be written to a physical floppy disk for physical
			implementations.

	os.dsk		Emulated old-style 3.5" 1.44MB floppy-disk image for use as a boot disk for either physical
			or virtual implementations. This disk image contains a boot sector that searches for and
			loads the os.com kernel image file into memory. Code in os.com places the CPU into protected
			mode and starts the initial 32-bit console task.

	os.com		The operating system kernel image.

	osprep.com	A DOS-compatible program that copies the os.dat boot sector image file to the boot sector of
			a 3.5" 1.44MB floppy disk inserted in logical drive A:.

Virtual Machine Installation:

	Configure a virtual machine instance to boot from a floppy drive disk image and select the os.dsk file as the
	disk image for Floppy Device 0. Select a base memory minimum setting of 4MB or higher.

Physical Machine Installation:

	Method 1:	Transfer os.dat, os.com and osprep.com to a host system configured with a physical floppy
			drive and DOS. Execute the osprep.com to copy os.dat to the diskette. Copy os.com to the
			the diskette. Boot the system with the floppy disk inserted in Drive A:.

	Method 2:	Using an alternate disk utility, transfer the entirety of os.dsk to the physical floppy
			disk, or copy only os.dat to the boot sector. Copy os.com to the diskette. Boot the system
			with the floppy disk inserted in Drive A:.

Network Support:

- OS includes native support for the Intel(R) PRO/1000 MT Desktop (82540EM) network adapter.
- Virtual machine installations may select this adapter type in the network configuration of the VM.
- Configure this VM network adapter using bridged networking to access the host system's network.

### Contributors

	David J. Walling		Email:		david@davidjwalling.com
					Twitter:	@davidjwalling
