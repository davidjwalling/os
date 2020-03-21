### Project os.005
Source: [os.005/os.asm](os.asm)

### Features and Topics
- 6845 Cathode Ray Tube (CRT) I/O
- Software Interrupts
- CGA Cursor Placement
- Defining a Screen or Panel as a Series of Fields

### [Virtual](/docs/VIRTUAL.md) Machine Operation
- Update the Virtual Machine configuration to use os.005/os.dsk as the diskette image.
- Start the Virtual Machine.

<img src="/images/os005_VirtualBox_001.PNG" width="640"/>

### [Physical](/docs/PHYSICAL.md) Machine Operation
- Overwrite ```os.com``` on the OS boot diskette with os.005/os.com.
- Insert the OS boot diskette into the physical system's floppy disk drive A:.
- Start the system.

<img src="/images/os005_Boot_001.jpg"/>

### Notes
This project adds code to the console task to add support for "panels". A panel is a set of fields that define text and input elements on the screen. For this project we define one main panel for the console task. The main panel displays a panel identifier, title and placeholder values for the current date and time on the top row, and a command input field preceded by a colon ":" prompt on row 24. The bottom row, row 25, will be reserved for OS indicators. This row is referred to here as the Operator Information Area (OIA).

Our Equates include two new sections, one for the 6845 Cathode Ray Tube (CRT) I/O constants and one for software constants for the Console Task. We add an ASCII equate for the space character.

We also add a constant to reference the Color Graphics Adapter (CGA) video memory area in the Global Descriptor Table (GDT).

At the end of the data structure, defined in that last project, for the low-memory BIOS area, we now begin to declare address locations to store console task variables.

Starting with this project, we introduce Interrupt 30h as a single entry point for several OS kernel-level functions usable by any task. First we define the tsvce macro, which will be used to define a table entry. Each table entry will be given an address label and a service number which will translate into an index offset into the service table. The service table entry values themselves are the addresses of the routine entry points in the OS kernel code segment.

Next we add an entry in the Interrupt Descriptor Table (IDT) for interrupt 30h. We use an mtrap macro for this descriptor. It references a label "svc" that we'll define next.

Now we define three more sections. First we use the "menter" macro to define an Interrupt Handler entry point named "svc", to correspond to our interrupt descriptor table entry defined above. The "svc" entry point checks the interrupt number passed as an argument in AL. If the interrupt number is within a valid range, it is converted to an index offset into the a service request table of service routine addresses. Then, control is passed to the address stored in the table.

The Servce Request Table, "tsvc", will consist of a sequence of "tsvce" macros define above. Here we add one entry to the Service Request Table, for the new routine, PlaceCursor. Note that the "maxtsvc" value checked by "svc" is dynamically generated at the end of the "tsvc" table.

Next, we define a macro, placeCursor, placeCursor for our new PlaceCursor routine. The macro is used in our task code to invoke a "int" instruction to the interrupt service handler "svc" (030h). The macro allows us to prepare registers with values expected by the interrupt service routine. In this case, we put the service routine number (ePlaceCursor), which is computed by the "tscve" macro, into register AL and invoke interrupt _svc (030h).

Finally, we add the code for PlaceCursor itself. This routine uses the 6845 CRT controller I/O ports to place the cursor on the screen using row and column coordinates stored in two of our console task variables.

Now in our console task, we have four discrete steps. First we initialize our console work areas using a store repetition. Secondly, we initialize the Operator Information Area by addressing the video memory directly using the "EGDTCGA" symbolic we created to reference the video memory descriptor in the GDT. Third, we call a routine, ConMain, to initialize console task variables to use a "panel" to display fields on the screen. Lastly, we call a routine "ConPutCursor" to position the cursor at the current location in the active panel field.

The ConMain routine makes use of two routines we see next. ConClearPanel clears the CGA video memory used by panels, the first 24 rows. ConDrawFields steps through the panel definition and draws each field in the panel on the screen. The current active input field is chosen as the first input field found if no active input field is already defined.

The process of drawing the field, for this project, is limited to locating the field's offset address on the screen and drawing the character and attribute for each column position, then filling any remaining screen colums for the field with spaces. In a future project we will add highlighting the current selected text in the input field.

The ConPutCursor routine takes the row and column attributes of the current active field to update the console cursor row and column position. The column is updated to reflect the current offset into the field. The ConMain routine sets the current console panel and active field values, then calls routines to clear the panel and draw the panel fields.

This project defines one panel. In a "Constants" section, we provide the panel definition. Each field in the panel consists of a reference to either a constant null-terminated string or an input field. Then, each field has attributes indicating the field row and column, size, current index, the first and last "selected" column, the column attribute (background color/blink setting) and a flags field where the high-order bit set indicates an input field. Following the panel definition are the constant strings used in the panel.
