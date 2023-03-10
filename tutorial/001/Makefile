all:    os.dat os.dsk

clean:
	rm -f os.dat os.dat.lst os.dsk os.dsk.lst

os.dat: os.asm
	nasm os.asm -f bin -o os.dat -l os.dat.lst -DBUILDBOOT

os.dsk:	os.asm
	nasm os.asm -f bin -o os.dsk -l os.dsk.lst -DBUILDDISK
