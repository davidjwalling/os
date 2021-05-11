## Setup virtual and physical test environments. 

[Back](../README.md) to Tutorials  
[Next](../001/README.md) Create a simple boot sector.  

### Virtual Test Environment

The Operating System is demonstrated in a virtual environment using Oracle Virtual Box.

### Virtual Box VM Definition

|||
|---|---|
|![System](../../images/09_VirtualBox_System.png)|Base memory is set to 64MB to simulate the physical environment.</br>Select only the Floppy Disk as the Boot Order.|
|![Storage](../../images/10_VirtualBox_Storage.png)|Add a Type I82078 Floppy Disk controller.</br>Add a disk and select the `os.dsk` for the tutorial project under test.|
|![Network](../../images/11_VirtualBox_Network.png)|Enable the network adapter.</br>Select an appropriate interface.</br>Select the PCnet-PCI II (Am79C970A) adapter type.|
|||

### Virtual Box VM Operation

|||
|---|---|
|![Operation](../../images/12_VirtualBox_Operation.png)|Start the Virtual Machine.|
|||


### Physical Test Environment
  
The components of the physical test environment are listed below.  

||||
|---|---|---|
|![Processor](../../images/01_Pentium_MMX_233_Small.jpg)|The processor is an Intel Pentium MMX 233MHz.</br>The motherboard is an Intel 555A Rev 3.2.|![Motherboard](../../images/02_Intel_555A_Small.jpg)|
|![Memory](../../images/03_64MB_EDO_DRAM_Small.jpg)|The memory is 64MB of EDO DRAM.</br>The display adapter is a Number Nine 9FX Motion 771 VGA.|![Display](../../images/04_NumberNine_9FX_Motion771_Small.jpg)|
|![Disk](../../images/05_Mitsumi_D359M3_Front_Small.jpg)|The diskette drive is a Mitsumi D359 M3.</br>The network adapter is an Advanced Micro Devices PCInet PCI Fast AM79C971.|![Network](../../images/06_AM_PCInet_PCI_FAST_AM79C971_Small.jpg)||![Monitor](../../images/07_Dell_U2412M_Small.jpg)|The display monitor is a Dell U2412M.</br>The keyboard is a Dell RT7D20.||
||||

Preparing the boot diskette on the development laptop uses the external diskette drive shown below.  
  
|||
|---|---|
|![Disk](../../images/08_Sabrent_N533_Small.jpg)|The development environment external diskette drive is a Sabrent N533.</br>The diskettes are high-density 3.5" 1.44MB.|
|||

### Physical Environment Operation

|||
|---|---|
|![Operation](../../images/13_Physical_Operation.jpg)|Insert the boot diskette into drive A:.</br>Start the test system.|
|||

[Back](../README.md) Tutorials  
[Next](../001/README.md) Create a simple boot sector.    