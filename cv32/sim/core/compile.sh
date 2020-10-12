#!/bin/bash

make -C ./../../bsp
RISCV_EXE_PREFIX=/opt/riscv/bin/riscv32-unknown-elf-

"$RISCV_EXE_PREFIX"gcc $CFLAGS -v -o $1.elf -nostartfiles $1.c -T ./../../bsp/link.ld -L ./../../bsp -lcv-verif

"$RISCV_EXE_PREFIX"objcopy -O verilog $1.elf $1.hex \
	--change-section-address  .debugger=0x3FC000 \
	--change-section-address  .debugger_exception=0x3FC800
"$RISCV_EXE_PREFIX"readelf -a $1.elf > $1.readelf
"$RISCV_EXE_PREFIX"objdump -D -S $1.elf > $1.objdump



#/opt/riscv/bin/riscv32-unknown-elf-gcc -Os -g -static -mabi=ilp32 -march=rv32imc -Wall -pedantic -v -o $1.elf -nostartfiles $1.c -T ./../../link.ld -L ./../../ -lcv-verif
