#!/bin/bash

#FT=$1
#sed -i "s/  parameter ID_FAULT_TOLERANCE  =.*$/  parameter ID_FAULT_TOLERANCE  =  ${FT}  \/\/   CODE   CONTROLLER    DECODER  PIPELINE(IF\/ID) REGFILE/" ~/Desktop/core-v-verif/core-v-cores/cv32e40p_ft/rtl/rtl_FT/cv32e40p_core.sv

cd ~/Desktop/core_marcello/core-v-verif/cv32/tests/programs/custom_FT/out 

programs=$(ls *.hex )

cd ~/Desktop/core_marcello/core-v-verif/cv32/sim/core

i=1
for program in $programs; do
	
	echo "$program"
	
	if [[ "${program:0:-4}" == "riscv_arithmetic_basic_test_1" || "${program:0:-4}" == "riscv_ebreak_test_0" || "${program:0:-4}" == "coremark_1" ]]; then
		echo "______________________________________________"
		echo "INFO: $i/18"
		echo "INFO: program ${program}"
		echo "______________________________________________"
		./comp_sim.sh -qsfiupi atsbcf ref ref ${program:0:-4} id_stage 663 1 -f
		cp signals_*_id_stage-${program:0:-4}-663-1 .sim_FT/sim_out/sim_out_ref/
	fi
	i=$(( $i+1 ))
done
