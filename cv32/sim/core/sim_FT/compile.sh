#!/bin/bash

UsageExit () {
	echo "Help of ..."
	exit 1
}

CUR_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
echo "dove sto? $CUR_DIR, $1, $2"
SIM_FT="$CUR_DIR"
BSP="./../../../bsp"

# Configure the env for the compilation  
make -C $BSP 
RISCV_EXE_PREFIX=/software/pulp/riscv/bin/riscv32-unknown-elf-

# Compilation of .c argument file
"$RISCV_EXE_PREFIX"gcc $CFLAGS -v -o $1.elf -nostartfiles $1.c -T $BSP/link.ld -L $BSP -lcv-verif

# Tranform .elf in .hex file changing address
"$RISCV_EXE_PREFIX"objcopy -O verilog $1.elf $1.hex \
	--change-section-address  .debugger=0x3FC000 \
	--change-section-address  .debugger_exception=0x3FC800
# Save elf properties
"$RISCV_EXE_PREFIX"readelf -a $1.elf > $1.readelf
"$RISCV_EXE_PREFIX"objdump -D -S $1.elf > $1.objdump

