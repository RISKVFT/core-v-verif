#!/bin/bash

for file in $(ls ./../../tests/programs/custom_FT/out | grep 'hex'); do
	file_compare=${file::-4}
	./comp_sim.sh -qsfiupi atsbcf ft ft ${file_compare} ex_stage cov 1
done

