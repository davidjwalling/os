## CustomOS

	Copyright (C) 2010-2017 David J. Walling. All Rights Reserved.

## Synopsis

CustomOS is a project intended to demonstrate assembly-language programming, hardware I/O techniques and standard
protocol implementations in the form of a rudimentary operating system for i386-based (32-bit) platforms.

## Motivation

CustomOS is intended as a learning resource, although all code is intended to be fully-functional.

## Progressive Sub-Projects

CustomOS is provided as a progressive series of sub-projects that incrementally introduce and demonstrate concepts.

	os.001		A simple boot sector that displays a message.
	os.002		A boot sector that loads and runs a kernel that displays a message.

## Compilation

Local compilation of the source code requires NASM (the Netwide Assembler) or a compatible assembler.

	2017-06-30	Recommended version of NASM is 2.13.01.

Compilation on Windows:

	Use the make.bat file to remove and recreate all project components.

Compilation on Linux:

	Use the make utility to process the project's Makefile to refresh all project components.

Assembly Directives:

	BUILDBOOT	Create os.dat, the operating system boot sector.
	BUILDDISK	Create os.dsk, a 1.44MB 3.5" floppy disk image.
	BUILDCOM	Create os.com, the operating system kernel program.

## Installation

The project's make file produces the following output:

	os.dsk		Emulated old-style 3.5" 1.44MB floppy-disk image for use as a boot disk for either physical
			or virtual implementations. This disk image contains a boot sector that searches for and
			loads the os.com kernel image file into memory. Code in os.com places the CPU into protected
			mode and starts the initial 32-bit console task.

	os.dat		A 512-byte boot sector image that may be written to a physical floppy disk for physical
			implementations.

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

	CustomOS includes native support for the Intel(R) PRO/1000 MT Server (82545EM) network adapter. Virtual
	Machine installations may select this adapter type in the network configuration of the VM. Configure this
	VM network adapter using bridged networking to access the host system's network.

## Contributors

	David J. Walling		Email:		david@davidjwalling.com
					Twitter:	@davidjwalling

## License

	CustomOS is licensed under the terms of the MIT License.
