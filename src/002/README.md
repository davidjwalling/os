## src/002/

### Assemble the Project
```
C:\os\src\002> make.bat
```
### Boot a VirtualBox virtual machine using os.dsk

Configure the VirtualBox virtual machine with a Floppy controller and floppy disk image.  
Configure the VirtualBox virtual machine system to boot from the floppy disk.  
Start the virtual machine.  
<image src="../../images/002_VirtualBox_Launch.PNG"/>

### Boot a physical system using os.dat

Attach a floppy disk drive to the build system.  
Insert a floppy diskette into the disk drive.  
Open os.dat in a hex editor like HxD.  
Copy the boot sector (the first 512 bytes).  
Open a phyisical floppy diskette in the hex editor.  
Make sure the disk is not opened read-only.  
Click OK if a warning is displayed.  
Paste the os.dat boot sector onto the diskette boot sector.  
Save the updated boot sector to the diskette.  
Click OK if a warning is displayed.  
Copy os.com to the floppy diskette.
```
C:\os\src\002> copy os.com a:\
```
Place the diskette into a physical system floppy drive A:.  
Boot the physical system from the floop diskette.  
<image src="../../images/002_Physical_Boot.jpg"/>
