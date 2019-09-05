# OS Commands
### Add/Allocate
```
a m,500               Allocate 500 bytes
a m,20kb              Allocate 20 kilobytes
a 4mb                 Allocate 4 megabytes using the default type specifier
a o,/home             Add the folder "/home" to the file system root node
a /home/robert/       Add the folder "/home/robert" to the file system root node
a i,readme.md         Add the file "readme.md" in the current folder
a data/index.dat      Add the file "index.dat" in the data folder of the current folder
```
### Copy
```
c readme.md,copy.md   Copy the file "readme.md" to "copy.md"
```
### Delete/Deallocate
```
d 120040              Deallocate the memory block at address 120040
d m,745030            Deallocate the memory block at address 745030
d readme.md           Delete the file named "readme.md" in the current folder
d oldfiles/           Delete the folder "oldfiles" and its contents
```
### Edit
```
e readme.md           Edit the file "readme.md"
```
### Inquire/Info
```
i                     Inquire summary system information
i d                   Inquire summary device information
i d,s                 Inquire summary storage device information
i i,readme.md         Inquire summary file information for "readme.md"
i m                   Inquire summary memory information
i n                   Inquire summary network information
i o,reports           Inquire summary folder information
```
### List
```
l                     List files and folders in the current folder
l /home/              List files and folders in the /home folder
l readme.md           List files and folders matching the name "readme.md"
l d                   List devices
l d,a                 List audio devices
l d,s                 List storage devices
l m                   List memory allocations
l n                   List network resources
l n,c                 List network connection resources
l t                   List tasks
```
Sample Memory Allocation List Panel
```
0         1         2         3         4         5         6         7
01234567890123456789012345678901234567890123456789012345678901234567890123456789
LST001                       Memory Allocation List             DD-MM-YYYY HH:MM
    At       Until      Size   Task
 _  99999999-99999999  ZZZZU   TTTT
 _  00010000-00013FFF    16K~  0014
 
:____________________________________________________
```
### Start
```
s myprogram           Start a task on the executable file "myprogram"
```
### Stop
```
p myprogram           Stop the task named "myprogram"
```
### View
```
v i,readme.md          View the file "readme.md"
v readme.md            View the file "readme.md" (implicit type specifier)
```
