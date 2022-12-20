## os

- Simple, protected-mode operating system for x86-based PC-compatible systems.
- Memory, keyboard, display, clock, and network adapter I/O.
- Operates in protected mode on x86 and x86-64 processors.
- Clear assembly-language, hardware I/O and protocol examples.

Build
```
nasm os.asm -f bin -o os.dsk -l os.dsk.lst -DBUILDDISK
nasm os.asm -f bin -o os.dat -l os.dat.lst -DBUILDBOOT
nasm os.asm -f bin -o os.com -l os.com.lst -DBUILDCOM
nasm os.asm -f bin -o osprep.com -l osprep.com.lst -DBUILDPREP
```
Network Support

- Includes native support for the AMD PCInet-PCI FAST AM79C971 network adapter.
- Virtual machine installations may select this adapter type in the network configuration of the VM.
- Configure this VM network adapter using bridged networking to access the host system's network.

[Notes](NOTES.md)

Copyright 2010 David J. Walling. [MIT License](LICENSE).
