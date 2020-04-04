### OS Target Platform Example
The program samples presented here were tested using the following physical components. Other x86 PC-Compatible components may be substituted.
### Components
- Intel:registered: Pentium:registered: MMX 233 MHz Processor Part# BP80503233 (SL293) 2.8V
- Intel:registered: 555A Rev 3.2 Socket 7 Motherboard
- 64MB EDO DRAM
- 2 x Mitsumi D359M3 Internal 3.5" 1.44 MB Floppy Drive
- Number Nine #9FX Motion 771 SVGA
- Intel Pro/1000 MT Desktop Adapter
- Dell:registered: U2412M 24 inch LCD monitor
- Dell:registered: RT7D20 104-Key Standard US Layout Windows Keyboard via PS/2 to 5-pin DIN adapter.
### Intel:registered: Pentium:registered: MMX 233 MHz Processor Part# BP80503233 (SL293) 2.8V
<img src="../images/os001_Pentium_001.jpg"/>

### Intel:registered: 555A Rev 3.2 Socket 7 Motherboard
<img src="../images/os001_Intel555A_001.jpg"/><br>
<img src="../images/os001_Intel555A_002.jpg"/>

### 64MB EDO DRAM
<img src="../images/os001_64MB_EDO_DRAM_001.jpg"/>

### Mitsumi D359M3 Internal 3.5" 1.44 MB Floppy Drive x 2
<img src="../images/os001_MitsumiD359M3_Front_001.jpg"/><br>
<img src="../images/os001_MitsumiD359M3_Back_001.jpg"/>

### Number Nine #9FX Motion 771 SVGA
<img src="../images/os001_NumberNine_9FX_Motion771_001.jpg"/>

### Dell:registered: U2412M 24 inch LCD monitor  Dell:registered: RT7D20 104-Key Standard US Layout Windows Keyboard  via PS/2 to 5-pin DIN adapter
<img src="../images/os001_DellMonitor_U2412M_001.jpg"/>

### BIOS Boot with no Media - No Network Adapter
<img src="../images/os001_BIOS_002.jpg"/>

### Intel Pro/1000 MT Desktop Adapter
<img src="../images/intel_82540_001.jpg"/>

### BIOS Boot with no Media - With Network Adapter
- Note Intel:registered: Boot Agent searches for LAN boot.

<img src="../images/boot_pci_devices_001.jpg"/>

### Sabrent N533 External Floppy Disk Drive
<img src="../images/os001_SabrentN533_001.jpg"/>

### Windows Explorer Floppy Disk Properties
- After connecting the external Floppy Disk Drive to the development system, right-click on Drive A: shown in Windows Explorer.
- The Floppy Disk Properties windows opens to confirm normal operation.

<img src="../images/os001_WindowsExplorer_FloppyDiskProperties_001.PNG"/>

### HxD Hex Editor - About
- Start the HxD Hex Editor program as Administrator.

<img src="../images/os001_HxD_001_About.PNG"/>

### HxD Hex Editor - Open Device
- Use the Extras|Open Disk ... menu option to open the "open disk" dialog.

<img src="../images/os001_HxD_002_OpenDevice.PNG"/>

### HxD Hex Editor - Select Device
- In the "open disk" dialog, select floppy disk A:.
- IMPORTANT: Uncheck the "open as read only" checkbox.

<img src="../images/os001_HxD_003_SelectDevice.PNG"/>

### HxD Hex Editor - Read/Write Warning
- When a disk is opened without read-only protection a warning is displayed.
- Click "OK" to continue.

<img src="../images/os001_HxD_004_ReadWriteWarning.PNG"/>

### HxD Hex Editor - MS-DOS Boot Sector
- In this example, the diskette we have selected to update already as a DOS boot sector on it.
- We will overwrite this boot sector with the os.dat boot sector image.

<img src="../images/os001_HxD_005_MSDOSBootSector.PNG"/>

### HxD Hex Editor - File Open
- Use the File|Open menu option to open the os.dat file image.

<img src="../images/os001_HxD_008_OSBootSector.PNG"/>

### HxD Hex Editor - Edit | Copy
- Use the Edit|Copy menu option to copy the selected os.dat boot sector.

<img src="../images/os001_HxD_009_EditCopy.PNG"/>

### HxD Hex Editor - Edit | Paste Write
- Use the Edit|Paste Write open to paste the copied os.dat sector into the floppy disk A: tab.

<img src="../images/os001_HxD_010_EditPasteWrite.PNG"/>

### HxD Hex Editor - OS Boot Sector Pasted
- The pasted boot sector appears in red where byte values have changed.
- Use the File|Save menu to save changes to the floppy disk.

<img src="../images/os001_HxD_012_EditPaste.PNG"/>

### HxD Hex Editor - Overwrite Warning
- HxD displays a warning dialog box before writing changes.
- Click "Yes" to confirm and save changes.

<img src="../images/os001_HxD_011_WarningOverwrite.PNG"/>

### HxD Hex Editor - Diskette Changes Saved
<img src="../images/os001_HxD_013_BootSectorUpdated.PNG"/>

### Insert Diskette in Target Platform Floppy Disk Drive and Reboot
- Remove the floppy diskette from the external floppy drive.
- Insert floppy diskette into Drive A: on the target physical system.
- Start the target physical system.

<img src="../images/os022_VirtualBox_001.png"/>

### Using the ```osprep.com``` Program

<img src="../images/os003_osprep_001.jpg"/>

<img src="../images/os003_osprep_002.jpg"/>

<img src="../images/os003_osprep_003.jpg"/>

<img src="../images/os003_osprep_004.jpg"/>
