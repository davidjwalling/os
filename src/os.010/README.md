### Project os.010
Source: [os.010/os.asm](os.asm)

### Features and Topics

### [Virtual](/docs/VIRTUAL.md) Machine Operation
- Update the Virtual Machine configuration to use os.010/os.dsk as the diskette image.
- Start the Virtual Machine.

<img src="/images/os010_VirtualBox_001.PNG" width="640"/><br>
<img src="/images/os010_VirtualBox_002.PNG" width="640"/><br>

### [Physical](/docs/PHYSICAL.md) Machine Operation
- Overwrite os.com on the OS boot diskette with os.010/os.com.
- Insert the OS boot diskette into the physical system's floppy disk drive A:.
- Start the system.

<img src="/images/os010_Boot_001.jpg"/><br>
<img src="/images/os010_Boot_002.jpg"/><br>

### Notes
This projects adds a second panel, the default view panel, that displays the values of memory locations. The view ("v") and go ("g") commands are added. First, we have added a scan-code and an ASCII equate.

In our console variable storage area we have added a variable to track the base address of the memory we are viewing and two arrays of storage for our row command fields and the row display fields.

Two new service routines, HexadecimalToUnsigned and UnsignedToHexadecimal, assist in converting hexadecimal to decimal memory address values.

In ConCode, new code handles the forward and backward tab key.

ConHandlerView handles operator input in the view panel.

We have added some menu options to the main or home panel. So we need to initialize those data areas.

ConView converts any address parameter to update the base memory address, initializes panel storage and draws the panel.

The panel handler offset address contants are updated to include ConHandlerView

The main panel has menu options added.

The panel definition for the memory view panel is added.

The tables and strings now include the go, view commands and memory panel constants.
