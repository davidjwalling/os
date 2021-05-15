## Operating System

- A simple protected-mode operating system for x86-based PC-compatible systems.
- Operates on 32-bit Intel or AMD x86 from the 80386 up through present-day processors.
- Does not require coprocessors or other external firmware or engines beyond the chipset.
- Clear assembly-language, hardware I/O and protocol examples.

## Tutorial

- The [tutorial](src/README.md) presents step-by-step instructions for setting up both virtual and physical test environments and explains operating sytem logic in progressive sample programs.
  
## Assembly

- Samples assembled using NASM (Netwide Asssembler) version 2.15.05.
- make.bat assembles and links on Windows using NASM.
- Makefile assembles and links on Linux using NASM.

## Directives

- BUILDBOOT Create `os.dat`, the operating system boot sector.
- BUILDDISK Create `os.dsk`, a 1.44MB 3.5" floppy disk image.
- BUILDCOM Create `os.com`, the operating system kernel program.
- BUILDPREP Create `osprep.com`, a utility to write the boot sector to a diskette.

## Output

- `os.dat` A 512-byte boot sector image that may be written to a physical floppy disk for physical implementations.
- `os.dsk` A 1.44MB floppy-disk image for use as a boot disk for either physical or virtual implementations. This disk image contains a boot sector that searches for and loads the `os.com` kernel image file into memory. Code in `os.com` places the CPU into protected mode and starts the initial 32-bit console task.
- `os.com` The operating system kernel image loaded and run by the boot sector. `os.com` can also be run from a DOS command line.
- `osprep.com` A DOS-compatible program that copies the os.dat boot sector image file to the boot sector of a 3.5" 1.44MB floppy disk inserted in logical drive A:.

## Network Support

- OS includes native support for the AMD PCInet-PCI FAST AM79C971KC network adapter.
- Virtual machine installations may select this adapter type in the network configuration of the VM.
- Configure this VM network adapter using bridged networking to access the host system's network.

Copyright 2010-2021 David J. Walling. All rights reserved.  
david@davidjwalling.com  