#!/bin/bash

BASEDIR=$PWD
CM_FOLDER=coremark

#change this value to reach at leat 10 secs of simulation --- 1800

ITERATIONS=$1
if [[ -z  $ITERATIONS ]]; then
	ITERATIONS=1800
fi

echo "Number of iterations: ${ITERATIONS}"

cd $BASEDIR/$CM_FOLDER

# run the compile
echo "Start compilation"

make PORT_DIR=../riscv32 ITERATIONS=${ITERATIONS} compile
mv coremark.elf ../../out/coremark_${ITERATIONS}.elf
