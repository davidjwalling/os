@echo off
if exist os.dat del /Q os.dat
@echo on
nasm os.asm -f bin -o os.dat -l os.dat.lst -DBUILDBOOT
@echo off
if exist os.dsk del /Q os.dsk
@echo on
nasm os.asm -f bin -o os.dsk -l os.dsk.lst -DBUILDDISK
