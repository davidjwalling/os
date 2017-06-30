all:    os.dat os.dsk os.com

clean:
	rm -f os.dat os.dat.lst os.dsk os.dsk.lst os.com os.com.lst

os.dat:	os.asm
	nasm os.asm -f bin -o os.dat -l os.dat.lst -DBUILDBOOT

os.dsk:	os.asm
	nasm os.asm -f bin -o os.dsk -l os.dsk.lst -DBUILDDISK

os.com:	os.asm
	nasm os.asm -f bin -o os.com -l os.com.lst -DBUILDCOM
