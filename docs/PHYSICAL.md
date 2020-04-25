### OS Target Platform Example
The program samples presented here were tested using the following physical components. Other x86 PC-Compatible components may be substituted.
### Components
- Intel:registered: Pentium:registered: MMX 233 MHz Processor Part# BP80503233 (SL293) 2.8V
- Intel:registered: 555A Rev 3.2 Socket 7 Motherboard
- 64MB EDO DRAM
- 2 x Mitsumi D359M3 Internal 3.5" 1.44 MB Floppy Drive
- Number Nine #9FX Motion 771 SVGA
- AMD:registered: PCInet-PCI FAST Network Adapter
- Dell:registered: U2412M 24 inch LCD monitor
- Dell:registered: RT7D20 104-Key Standard US Layout Windows Keyboard via PS/2 to 5-pin DIN adapter.
### Intel:registered: Pentium:registered: MMX 233 MHz Processor Part# BP80503233 (SL293) 2.8V
<img src="../images/01_Pentium_MMX_233.jpg"/>

### Intel:registered: 555A Rev 3.2 Socket 7 Motherboard
<img src="../images/02_Intel_555A.jpg"/><br>
<img src="../images/03_Intel_555A.jpg"/>

### 64MB EDO DRAM
<img src="../images/04_64MB_EDO_DRAM.jpg"/>

### Mitsumi D359M3 Internal 3.5" 1.44 MB Floppy Drive x 2
<img src="../images/05_Mitsumi_D359M3_Front.jpg"/><br>
<img src="../images/06_Mitsumi_D359M3_Back.jpg"/>

### Number Nine #9FX Motion 771 SVGA
<img src="../images/07_NumberNine_9FX_Motion771.jpg"/>

### AMD PCInet PCI FAST Adapter AM97C971KC
<img src="../images/08_AMD_PCInet_PCI_FAST_AM79C971.jpg"/>

### Dell:registered: U2412M 24 inch LCD monitor  Dell:registered: RT7D20 104-Key Standard US Layout Windows Keyboard  via PS/2 to 5-pin DIN adapter
<img src="../images/09_Dell_U2412M.jpg"/>

### Sabrent N533 External Floppy Disk Drive
<img src="../images/10_Sabrent_N533.jpg"/>

### Windows Explorer Floppy Disk Properties
- After connecting the external Floppy Disk Drive to the development system, right-click on Drive A: shown in Windows Explorer.
- The Floppy Disk Properties windows opens to confirm normal operation.

<img src="../images/11_WindowsExplorer_FloppyDiskProperties.PNG"/>

### HxD Hex Editor - About
- Start the HxD Hex Editor program as Administrator.

<img src="../images/12_HxD_About.PNG"/>

### HxD Hex Editor - Open Device
- Use the Extras|Open Disk ... menu option to open the "open disk" dialog.

<img src="../images/13_HxD_OpenDevice.PNG"/>

### HxD Hex Editor - Select Device
- In the "open disk" dialog, select floppy disk A:.
- IMPORTANT: Uncheck the "open as read only" checkbox.

<img src="../images/14_HxD_SelectDevice.PNG"/>

### HxD Hex Editor - Read/Write Warning
- When a disk is opened without read-only protection a warning is displayed.
- Click "OK" to continue.

<img src="../images/15_HxD_ReadWriteWarning.PNG"/>

### HxD Hex Editor - MS-DOS Boot Sector
- In this example, the diskette we have selected to update already as a DOS boot sector on it.
- We will overwrite this boot sector with the os.dat boot sector image.

<img src="../images/16_HxD_MSDOSBootSector.PNG"/>

### HxD Hex Editor - File Open
- Use the File|Open menu option to open the os.dat file image.

<img src="../images/17_HxD_OSBootSector.PNG"/>

### HxD Hex Editor - Edit | Copy
- Use the Edit|Copy menu option to copy the selected os.dat boot sector.

<img src="../images/18_HxD_EditCopy.PNG"/>

### HxD Hex Editor - Edit | Paste Write
- Use the Edit|Paste Write open to paste the copied os.dat sector into the floppy disk A: tab.

<img src="../images/19_HxD_EditPasteWrite.PNG"/>

### HxD Hex Editor - OS Boot Sector Pasted
- The pasted boot sector appears in red where byte values have changed.
- Use the File|Save menu to save changes to the floppy disk.

<img src="../images/20_HxD_EditPaste.PNG"/>

### HxD Hex Editor - Overwrite Warning
- HxD displays a warning dialog box before writing changes.
- Click "Yes" to confirm and save changes.

<img src="../images/21_HxD_WarningOverwrite.PNG"/>

### HxD Hex Editor - Diskette Changes Saved
<img src="../images/22_HxD_BootSectorUpdated.PNG"/>

### Insert Diskette in Target Platform Floppy Disk Drive and Reboot
- Remove the floppy diskette from the external floppy drive.
- Insert floppy diskette into Drive A: on the target physical system.
- Start the target physical system.

<img src="../images/23_phys_boot.jpg"/>

### Using the ```osprep.com``` Program

<img src="../images/24_osprep1.jpg"/>

<img src="../images/25_osprep2.jpg"/>

<img src="../images/26_osprep3.jpg"/>

<img src="../images/27_osprep4.jpg"/>
