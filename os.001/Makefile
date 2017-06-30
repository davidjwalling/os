all:    os.dat os.dsk

clean:
	rm -f os.dat os.dat.lst os.dsk os.dsk.lst

os.dat:
	nasm os.asm -f bin -o os.dat -l os.dat.lst -DBUILDBOOT

os.dsk:
	nasm os.asm -f bin -o os.dsk -l os.dsk.lst -DBUILDDISK
