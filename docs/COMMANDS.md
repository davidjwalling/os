# OS Commands
### Add/Allocate
```
a 2048                Allocate 2048 bytes (implicit type and units)
a 4mb                 Allocate 4 megabytes using the default type specifier (implicit type)
a m,500               Allocate 500 bytes (implicit units)
a m,20kb              Allocate 20 kilobytes

a i,readme.md         Add the file "readme.md" in the current folder
a data/index.dat      Add the file "index.dat" in the data folder of the current folder (implicit type)

a o,/home             Add the folder "/home" to the file system root node
a /home/taxes/        Add the folder "/home/taxes" to the file system root node (implicit type)
```
### Copy
```
c readme.md,copy.md   Copy the file "readme.md" to "copy.md"
```
### Delete/Deallocate
```
d 120040              Deallocate the memory block at address 120040 (implicit type)
d m,745030            Deallocate the memory block at address 745030

d readme.md           Delete the file named "readme.md" in the current folder (implicit type)
d i,readme.md         Delete the file named "readme.md" in the current folder (explicit type)

d oldfiles/           Delete the folder "oldfiles" and its contents (implicit type)
d o,oldfiles          Delete the folder "oldfiles" (explicit type)
d o,oldfiles/         Delete the folder "oldfiles" (explicit type)
```
### Edit
```
e                     Edit memory at last viewed address or zero (impicit type and address)
e 5000                Edit memory at address 5000 (implicit type)
e m                   Edit memory at last viewed address or zero (implicit address)
e m,5000              Edit memory at address 5000

e readme.md           Edit the file "readme.md" (implicit type)
e i,readme.md         Edit the file "readme.md" (explicit type)

e taxes/              Edit the folder "taxes" (implicit type)
e o,taxes             Edit the folder "taxes" (explicit type)
e o,taxes/            Edit the folder "taxes" (explicit type)
```
### Inquire/Info
```
i                     Inquire summary system information
i d                   Inquire summary device information
i d,n                 Inquire summary network device information
i d,s                 Inquire summary storage device information
i i,readme.md         Inquire summary file information for "readme.md"
i m                   Inquire summary memory information
i n                   Inquire summary network information
i o                   Inquire summary folder information
i o,reports           Inquire summary information for folder "reports"
i o,reports/          Inquire summary information for folder "reports"
i t                   Inquire summary task information
i t,0148              Inquire summary information for task 0148
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
### Move/Rename with Replace
```
m readme,newname      Non-destrucdtive rename file "readme" to "newname"
m readme,newname,r    Destructive rename file "readme" to "newname"
m readme,/            Non-destructive move file "readme" to the root folder
m readme,/,r          Destructive move file "readme" to the root folder

m taxes/,newname      Non-destructive rename folder "taxes" to "newname"
m taxes/,newname,r    Destructive rename folder "taxes" to "newname"
m taxes/,backup/      Non-destructive move folder "taxes" into folder "backup"
m taxes/,backup/,r    Desctructive move folder "taxes" into folder "backup"
```
### Start
```
s myprogram           Start a task on the executable file "myprogram"
myprogram             Start a task on the executable file "myprogram" (implicit command)
```
### Stop
```
p myprogram           Stop the task named "myprogram"
```
### View
```
v readme.md           View the file "readme.md" (implicit type specifier)
v i,readme.md         View the file "readme.md"
v m                   View memory contents at last viewed address or zero
v m,5000              view memory contents at address 5000
```
### Sample Command Resolution
```
a                     Error: Add/Allocate implicit type (m) requires parameters
a -1                  Error: Add/Allocate implicit type (m) requires positive, non-zero size
a 0                   Error: Add/Allocate implicit type (m) requires positive, non-zero size
a 1                   Add/Allocate implicit type (m) and unit (b) allocates minimum block of 256 bytes
a 257                 Add/Allocate implicit type (m) and unit (b) allocates in multiples of 16, or 262 bytes
a 1024b               Add/Allocate implicit type (m) allocates 1024 bytes
a 32k                 Add/Allocate implicit type (m) allocates 32 kilobytes
a 16m                 Add/Allocate implicit type (m) allocates 64 megabytes
a m,                  Error: Add/Allocate explicit type (m) requires parameters
a m,x                 Error: Add/Allocate explicit type (m) requires positive, non-zero size
a m,16k               Add/Allocate allocates 16 kilobytes

a m                   Add/Allocate deduced type (i) creates zero-length file "m" in the current folder
a x                   Add/Allocate deduced type (i) creates zero-length file "x" in the current folder
a readme              Add/Allocate creates zero-length file "readme" in the current folder
a "readme"            Add/Allocate creates zero-length file "readme" in the current folder
a i,readme            Add/Allocate creates zero-length file "readme" in the current folder
a ./readme            Add/Allocate creates zero-length file "readme" in the current folder
a /readme             Add/Allocate creates zero-length file "readme" in the root folder
a new/readme          Add/Allocate creates zero-length file "readme" in folder "new" in the current folder

a new/                Add/Allocate creates folder "new" in the current folder
a /new/               Add/Allocate creates folder "new" in the root folder
a f,new               Add/Allocate creates folder "new" in the current folder
a f,/new/             Add/Allocate creates folder "new" in the root folder
```
