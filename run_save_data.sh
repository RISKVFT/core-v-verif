#!/bin/bash

cd ~/Desktop/core_marcello/core-v-verif/cv32/tests/programs/custom_FT/out

programs=$(ls *.hex )

cd ~/Desktop/core_marcello/core-v-verif/cv32/sim/core

for program in $programs; do
	if [[ "$program" != "coremark_1" ]]; then
		echo "INFO: program ${program}"
		./comp_sim.sh -b asbv ref ${program:0:-4} id_stage save_data_in
		#./comp_sim.sh -b asbv ref ${program:0:-4} id_stage save_data_out -g
	fi
done
for program in $programs; do
	if [[ "$program" != "coremark_1" ]]; then
		echo "INFO: program ${program}"
		#./comp_sim.sh -b asbv ref ${program:0:-4} id_stage save_data_in
		./comp_sim.sh -b asbv ref ${program:0:-4} id_stage save_data_out -g
	fi
done
