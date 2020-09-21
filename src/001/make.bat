@echo off
if exist os.dat del /Q os.dat
@echo on
nasm os.asm -f bin -o os.dat -l os.dat.lst
@echo off
