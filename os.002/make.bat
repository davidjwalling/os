@echo off
if exist os.dat del /Q os.dat
@echo on
nasm os.asm -f bin -o os.dat -l os.dat.lst -DBUILDBOOT -w-label-redef-late
@echo off
if exist os.dsk del /Q os.dsk
@echo on
nasm os.asm -f bin -o os.dsk -l os.dsk.lst -DBUILDDISK -w-label-redef-late
@echo off
if exist os.com del /Q os.com
@echo on
nasm os.asm -f bin -o os.com -l os.com.lst -DBUILDCOM -w-label-redef-late
