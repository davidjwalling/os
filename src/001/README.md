## src/001/

### Assemble the Project
```
C:\os\src\001> make.bat
```
### Boot a VirtualBox virtual machine using os.dsk

Configure the VirtualBox virtual machine with a Floppy controller and floppy disk image.  
<image src="../../images/001_VirtualBox_Storage.PNG"/>

Configure the VirtualBox virtual machine system to boot from the floppy disk.  
<image src="../images/001_VirtualBox_System.PNG"/>

Start the virtual machine  
<image src="../../images/001_VirtualBox_Launch.PNG"/>

### Boot a physical system using os.dat

Attach a floppy disk drive to the build system.
Insert a floppy diskette into the disk drive.  
<image src="../../images/10_Sabrent_N533.jpg"/>

Open os.dat in a hex editor like HxD.  
Copy the boot sector (the first 512 bytes).  
<image src="../../images/001_HxD_EditCopy.PNG"/>

Open a phyisical floppy diskette in the hex editor.  
<image src="../../images/001_HxD_ExtraOpenDisk.PNG"/>  

Make sure the disk is not opened read-only.  
<image src="../../images/001_HxD_SelectDisk.PNG"/>  

Click OK if a warning is displayed.  
<image src="../../images/001_HxD_Warning1.PNG"/>

Paste the os.dat boot sector onto the diskette boot sector.  
Save the updated boot sector to the diskette.  
<image src="../../images/001_HxD_FileSave.PNG"/>  

Click OK if a warning is displayed.  
<image src="../../images/001_HxD_Warning2.PNG"/>

Place the diskette into a physical system floppy drive A:.  
Boot the physical system from the floop diskette.  
<image src="../../images/001_Physical_Boot.jpg"/>
