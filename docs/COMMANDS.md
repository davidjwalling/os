# OS Commands
## Command List
### A Add/Allocate
- The Add/Allocate command adds a resource to the system. A resource can be an allocated memory space or a data set.  
- The maximum size of a single memory allocation is 2GB.  
- Memory allocation size is specified by a number and an optional unit specifier.  
- The memory allocation unit specifier may be "b" (byte), "kb" (kilobyte), "mb" (megabyte) or "gb" (gigabyte).  
- Data set names may include a path.  
- Data set allocation may include a data set type specifier.  
- Memory and data set allocation is indicated by an allocation type specifier.  
- The allocation type specifier may be "m" (memory), "f" file or "o" (folder).  
- The default allocation type specifier is "m" (memory).
- Unit and type specifiers are case-insensitive.  
- If the type specificer is missing, the parameter is interpreted as a folder if it ends with a slash, a memory allocation size if it ends with a valid unit specifier following a numeric size, or a folder if the parameter begins with an alphabetic character.  
  
Examples:
```
a m,500               Allocate 500 bytes
A m,20kb              Allocate 20 kilobytes
a 4MB                 Allocate 4 megabytes using the default type specifier

a o,/home             Add the folder "/home" to the file system root node
a /home/robert/       Add the folder "/home/robert" to the file system root node

a i,readme.md         Add the file "readme.md" in the current working directory
a data/index.dat      Add the file "index.dat" in the data folder of the current working directory
```
