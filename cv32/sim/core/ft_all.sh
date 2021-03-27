#!/bin/bash

if [[ $# -ne 2 ]]; then
	echo "wrong number of arguments."
	echo "Usage: ./save_data_all.sh <stage_name> <ref/ft>"
	exit 1;
else
	stage=$1
	arch=$2

	for file in $(ls ./../../tests/programs/custom_FT/out | grep 'hex'); do
		file_compare=${file::-4}
		./comp_sim.sh -qsfiupi atsbcf $arch $arch ${file_compare} $stage cov 1
	done

fi
