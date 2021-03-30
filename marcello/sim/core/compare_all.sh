#!/bin/bash

for file in $(ls ./../../tests/programs/custom_FT/out | grep 'hex'); do
	file_compare=${file::-4}
	echo "INFO: program ${file_compare}"
	./comp_sim.sh -b atsbvf ft ref $file_compare core stage_compare 0 -g
	exit 0
done

