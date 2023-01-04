## OS Notes
These notes may be better viewed in github with an extension that provides a wider presentation.  
I use https://github.com/xthexder/wide-github.
<table>
<colgroup><col><col width=15%><col width=15%></colgroup>
<tr><td>
Intro<br><br>
- OS is written in the Netwide Assembler (NASM) variant of the Intel Syntax x86 Assembly Language.<br>
- Examples here demonstrate both virtual and physical operating environments.<br>
- Virtualization uses Oracle &reg; VirtualBox 6.1.<br>
- Physical operation is demonstrated on an Intel Pentium MMX 233MHz processor.<br>
- Networking uses (or emulates) the PCnet-II FAST Am79C971 &trade; controller.<br><br>
Build<br><br>
nasm os.asm -f bin -o os.dsk -l os.dsk.lst -DBUILDDISK<br>
nasm os.asm -f bin -o os.dat -l os.dat.lst -DBUILDBOOT<br>
nasm os.asm -f bin -o os.com -l os.com.lst -DBUILDCOM<br>
nasm os.asm -f bin -o osprep.com -l osprep.com.lst -DBUILDPREP</td><td colspan=2>
<img src="images/13_Physical_Operation.jpg"></td></tr>
<tr><td>
Output<br><br>
- os.dat: A 512-byte boot sector image that may be written to a physical floppy disk for physical implementations.<br>
- os.dsk: An Emulated 3.5" 1.44MB floppy-disk image for use as a boot disk for either physical or virtual implementations. This disk image contains a boot sector that searches for and loads the os.com kernel image file into memory. Code in os.com places the CPU into protected mode and starts the initial 32-bit console task.<br>
- os.com: The operating system kernel.<br>
- osprep.com: A DOS-compatible program that copies the os.dat boot sector image file to the boot sector of a 3.5" 1.44MB floppy disk inserted in logical drive A:.</td><td colspan=2>
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
<tr><td>
Commands<br><br>
<table><colgroup><col><col><col></colgroup>
<tr><td>date</td><td>[mm/dd/yyyy]</td><td>display (or set) the date</td></tr>
<tr><td>display<br>d</td><td></td><td>show the display menu</td></tr>
<tr><td>free</td><td>&lt;address&gt;</td><td>free memory at address</td></tr>
<tr><td>lspci<br>p<br>d p</td><td></td><td>display PCI table</td></tr>
<tr><td>m<br>mem<br>d m</td><td>[&lt;address&gt;]</td><td>display memory (at address)</td></tr>
<tr><td>malloc</td><td>&lt;bytes&gt;</td><td>allocate memory</td></tr>
<tr><td>net<br>d n</td><td></td><td>display network information</td></tr>
<tr><td>time</td><td>[hh:mm:ss]</td><td>display (or set) the time</td></tr>
<tr><td>v<br>ver<br>version<br>d v</td><td><td>display program version</td></tr>
</table>
</td><td colspan=2>
<img src="images/17_VirtualBox_Commands.png">
</td></tr>
<tr><td>
Key Memory Addresses<br><br>
<table><colgroup><col><col><col><col><col></colgroup>
<tr><td>00000000</td><td colspan=4>Real mode interrupt table</td></tr>
<tr><td>00000400</td><td colspan=4>BIOS variables</td></tr>
<tr><td>00000800</td><td colspan=4>OS variables</td><tr>
<tr><td>00000800</td><td></td><td>Console Heap Memory Address</td></tr>
<tr><td>00000804</td><td></td><td>Console Heap Memory Size</td></tr>
<tr><td>00000808</td><td></td><td>Console Input Buffer</td></tr>
<tr><td>00000859</td><td></td><td>Console Token Buffer</td></tr>
<tr><td>000008AA</td><td></td><td>Console Output Buffer</td></tr>
<tr><td>000008FB</td><td></td><td>Console Column</td></tr>
<tr><td>000008FC</td><td></td><td>Console Row</td></tr>
<tr><td>000008FD</td><td></td><td>Console Keyboard Data</td></tr>
<tr><td>00000907</td><td></td><td>Console Memory Root</td></tr>
<tr><td>0000091F</td><td></td><td>Console Date Time Buffer</td></tr>
<tr><td>00000929</td><td></td><td>Console PCI Context</td></tr>
<tr><td>0000093D</td><td></td><td>Console Ethernet Context</td></tr>
<tr><td>0000097C</td><td></td><td>Console AM79C970 Init Block</td></tr>
<tr><td>00000994</td><td></td><td>ATA Data</td></tr>
<tr><td>00000B94</td><td></td><td>Disk Sector</td></tr>
<tr><td>00000D94</td><td></td><td>Unused</td></tr>
<tr><td>00001000</td><td colspan=4>Global Descriptor Table</td></tr>
<tr><td>00001800</td><td colspan=4>Interrupt Descriptor Table</td></tr>
<tr><td>00002000</td><td colspan=4>Interrupt Handlers and Kernel Library</td></tr>
<tr><td>00004000</td><td colspan=4>Console Stack</td></tr>
<tr><td>00004700</td><td colspan=4>Console Local Descriptor Table</td></tr>
<tr><td>00004780</td><td colspan=4>Console Task State Segment</td></tr>
<tr><td>00004800</td><td colspan=4>Console Message Queue</td></tr>
<tr><td>00005000</td><td colspan=4>Console Code Segment</td></tr>
<tr><td>000A0000</td><td colspan=4>Read Only Memory</td></tr>
<tr><td>00100000</td><td colspan=4>OS Heap</td></tr>
</table>
</td><td colspan=2></td></tr>
</table>
