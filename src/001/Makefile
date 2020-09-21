all:    os.dat

clean:
	rm -f os.dat os.dat.lst

os.dat:	os.asm
	nasm os.asm -f bin -o os.dat -l os.dat.lst