#!/bin/bash

if [[ $# -ne 2 ]]; then
	echo "wrong number of arguments."
	echo "Usage: ./save_data_all.sh <stage_name> <in/out> <ref/ft>"
	exit 1;
else
	stage=$1
	direction=$2
	arch=$3
	for file in $(ls ./../../tests/programs/custom_FT/out | grep 'hex'); do
		file_save=${file::-4}
		if [[ $direction ==  "in" ]]; then
			echo ""		
			./comp_sim.sh -b atsbv $arch $arch $file_save $stage save_data_in
		else
			if [[ $direction ==  "out" ]]; then
				echo ""
				./comp_sim.sh -b atsbv $arch $arch $file_save $stage save_data_out -g
			else 
				if [[ $direction ==  "inout" ]]; then 
					echo $file_save $stage
					./comp_sim.sh -b atsbv $arch $arch $file_save $stage save_data_in
					./comp_sim.sh -b atsbv $arch $arch $file_save $stage save_data_out -g
				else
					echo "wrong direction: only 'in', 'out' or 'inout'."
					echo "Usage: ./save_data_all.sh <stage_name> <in/out> <ref/ft>"
					exit 1;
				fi
			fi
		fi
		echo ""
	done
fi
