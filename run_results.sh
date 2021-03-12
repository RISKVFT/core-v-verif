#!/bin/bash

cd ~/Desktop/core_marcello/core-v-verif/cv32/sim/core/sim_FT/sim_out/sim_out_ref

programs=$(ls)

cd ~/Desktop/core_marcello/core-v-verif/cv32/sim/core

for program in $programs; do
		echo "INFO: program ${program}"
		./comp_sim.sh -esfiupi ${program:24:-4}
		#./comp_sim.sh -b asbv ref ${program:0:-4} id_stage save_data_out -g
done

