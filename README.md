## OS

	Copyright (C) 2010-2019 David J. Walling

## Synopsis

OS demonstrates assembly-language programming, hardware I/O techniques and standard protocol implementations in the form of a rudimentary operating system for x86-based PC-compatible systems.

## Motivation

OS is provided as a learning resource. All code is intended to be fully-functional.

## Subprojects

OS is presented in a progressive series of subprojects that incrementally introduce and demonstrate concepts. Additional subprojects may be added from time to time as the project progresses.

### Part I. Boot to Protected Mode

[os.001](docs/OS001.md)	A simple boot sector that displays a message.  
os.002]		A boot sector that loads and runs a program that displays a message.  
os.003]		Creates `osprep.com`, a utility to write the boot sector to a diskette.  
os.004]		Expands the loader to enter protected mode and start a task.  

### Part II. Interrupts, Messages and Commands

os.005		Add keyboard interrupt handler to display characters and shift status in information area.  
os.006		Add a message queue handler to send keyboard messages to a task.  
os.007		Add support for "shutdown", "quit" and "exit" commands.  
os.008		Add an "int6" command to demonstrate CPU interrupt handling.  

### Part III. Memory and Clock

os.009		Add "mem" and "memory" commands to display memory and "main" to return to the main panel.  
os.010		Add simple memory allocation and deallocation routines and "malloc" and "free" test routines.  
os.011		Add memory-size reporting from BIOS and Real-Time Clock (RTC) chip.  
os.012		Add "date", "time" and related commands with RTC chip support.  

### Part IV. Network Adapter, Part I

os.013		Add logic to probe for and list PCI devices using the "pciprobe" or "lspci" commands.  
os.014		Add code to display ethernet adapter memory i/o address and i/o port.  
os.015		Add code to initialize and reset discovered PCI network adapter.  
os.016		Add code to receive an Ethernet frame.  

### Part V. Tasks

os.017		Add a second task manually and IRQ0-driven task switching.  
os.018		Add support to load a task from disk.  
os.019		Add commands to start, stop and list tasks.  
os.020		Add code to configure tasks to run on start-up.  

## Assembly

Assembling the source code requires NASM (the Netwide Assembler) or a compatible assembler.

	The recommended version of NASM is 2.14.02, compiled 26 Dec 2018.

Compilation on Windows:

	Use the make.bat file to remove and recreate all project components.

Compilation on Linux:

	Use the make utility to process the project's Makefile to refresh all project components.

Assembly Directives:

	BUILDBOOT	Create os.dat, the operating system boot sector.
	BUILDDISK	Create os.dsk, a 1.44MB 3.5" floppy disk image.
	BUILDCOM	Create os.com, the operating system kernel program.
	BUILDPREP	Create osprep.com, a utility to write the boot sector to a diskette.

## Installation

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

	OS includes native support for the Intel(R) PRO/1000 MT Desktop (82540EM) network adapter. Virtual machine
	installations may select this adapter type in the network configuration of the VM. Configure this VM network
	adapter using bridged networking to access the host system's network.

## Contributors

	David J. Walling		Email:		david@davidjwalling.com
					Twitter:	@davidjwalling

## License

	OS is licensed under the terms of the MIT License.
