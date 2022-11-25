## OS Notes

<table><tr><td>
Intro<br><br>
- OS uses the Netwide Assembler (NASM) variant of the Intel Syntax x86 Assembly Language.<br>
- Examples demonstrate both virtual and physical operating environments.<br>
- Virtualization uses Oracle &reg; VirtualBox 6.1.<br>
- Physical operation is demonstrated on an Intel Pentium MMX 233MHz.<br>
- Networking uses (or emulates) the Am79C971 PCnet &trade;-FAST controller.<br>
</td><td>
<img src="images/13_Physical_Operation.jpg">
</td></tr></table>

<table>
<colgroup><col style="width:60%;"><col style="width:20%;"><col style="width:20%;"></colgroup>
<tr><td>
Intro<br><br>
- OS uses the Netwide Assembler (NASM) variant of the Intel Syntax x86 Assembly Language.<br>
- Examples demonstrate both virtual and physical operating environments.<br>
- Virtualization uses Oracle &reg; VirtualBox 6.1.<br>
- Physical operation is demonstrated on an Intel Pentium MMX 233MHz.<br>
- Networking uses (or emulates) the Am79C971 PCnet &trade;-FAST controller.<br>
<br>
Build<br><br>
nasm os.asm -f bin -o os.dsk -l os.dsk.lst -DBUILDDISK<br>
nasm os.asm -f bin -o os.dat -l os.dat.lst -DBUILDBOOT<br>
nasm os.asm -f bin -o os.com -l os.com.lst -DBUILDCOM<br>
nasm os.asm -f bin -o osprep.com -l osprep.com.lst -DBUILDPREP
</td><td colspan=2>
<img src="images/13_Physical_Operation.jpg">
</td></tr>

<tr><td>
Output<br><br>
<table>
<tr><td>os.dat</td><td>A 512-byte boot sector image that may be written to a physical floppy disk for physical implementations.</td></tr>
<tr><td>os.dsk</td><td>Emulated 3.5" 1.44MB floppy-disk image for use as a boot disk for either physical or virtual implementations. This disk image contains a boot sector that searches for and loads the os.com kernel image file into memory. Code in os.com places the CPU into protected mode and starts the initial 32-bit console task.</td><tr>
<tr><td>os.com</td><td>The operating system kernel.</td></tr>
<tr><td>osprep.com</td><td>A DOS-compatible program that copies the os.dat boot sector image file to the boot sector of a 3.5" 1.44MB floppy disk inserted in logical drive A:.</td></tr>
</table>
</td><td colspan=2>
<img src="images/14_Ubuntu_22.04_Build.png">
</td></tr>

<tr><td>
Virtualization<br><br>
- Set the operating system as "Other/Unknown"<br>
- Specify 64MB of Base Memory<br>
- Set the Boot Order to Floppy only<br>
- The Graphics Controller should be "VBoxVGA"<br> 
- Add a Floppy Controller and set Floppy Device 0: to os.dsk<br>
- Set the Network Adapter to Pcnet-PCI II
</td><td colspan=2>
<img src="images/15_VirtualBox_Settings.png">
</td></tr>

<tr><td>
Virtualized Operation<br><br>
- Start the VM in VirtualBox.<br>
- The title and version will display.<br>
- Use the "net" command to confirm network oepration.
</td><td colspan=2>
<img src="images/16_VirtualBox_Operation.png">
</td></tr>

<tr><td>
Physical Environment<br><br>
- The processor is a 233MHz Intel Pentium MMX CPU.<br>
- The motherboard is a Holco (Shuttle) HOT-555A Rev 3.2 with an Intel 430VX chipset and Award BIOS 1995.<br>
- This is a "Baby AT" motherboard (230mm x 220mm) requiring AT P8 P9 power connectors.
</td><td>
<img src="images/01_Pentium_MMX_233_Small.jpg">
</td><td>
<img src="images/02_Intel_555A_Small.jpg">
</td></tr>

<tr><td>
- The memory is 64MB of EDO DRAM.<br>
- The display adapter is a Number Nine 9FX Motion 771 VGA.
</td><td>
<img src="images/03_64MB_EDO_DRAM_Small.jpg">
</td><td>
<img src="images/04_NumberNine_9FX_Motion771_Small.jpg">
</td></tr>

<tr><td>
- The diskette drive is a Mitsumi D359 M3.<br>
- The development environment external diskette drive is a Sabrent N533.<br>
- The diskettes are high-density 3.5" 1.44MB.
</td><td>
<img src="images/05_Mitsumi_D359M3_Front_Small.jpg">
</td><td>
<img src="images/08_Sabrent_N533_Small.jpg">
</td></tr>

<tr><td>
- The network adapter is an Advanced Micro Devices PCInet PCI Fast AM79C971.<br>
- The display monitor is a Dell U2412M.<br>
- The keyboard is a Dell RT7D20.
</td><td>
<img src="images/06_AM_PCInet_PCI_FAST_AM79C971_Small.jpg">
</td><td>
<img src="images/07_Dell_U2412M_Small.jpg">
</td></tr>
</table>
