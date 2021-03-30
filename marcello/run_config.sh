#!/bin/bash

#FT=$1
#sed -i "s/  parameter ID_FAULT_TOLERANCE  =.*$/  parameter ID_FAULT_TOLERANCE  =  ${FT}  \/\/   CODE   CONTROLLER    DECODER  PIPELINE(IF\/ID) REGFILE/" ~/Desktop/core-v-verif/core-v-cores/cv32e40p_ft/rtl/rtl_FT/cv32e40p_core.sv

cd ~/Desktop/core_marcello/core-v-verif/cv32/tests/programs/custom_FT/out 

program=dhrystone.hex

cd ~/Desktop/core_marcello/core-v-verif/cv32/sim/core

for i in {8..14}; do
	sed -i 's/\ \ parameter\ ID_FAULT_TOLERANCE.*/\ \ parameter\ ID_FAULT_TOLERANCE\ =\ '"${i}"'/'  ~/Desktop/core_marcello/core-v-verif/core-v-cores/cv32e40p_ft/rtl/rtl_FT/cv32e40p_id_stage.sv

	echo "______________________________________________"
	echo "INFO: program ${program}"
	echo "INFO: config ${i}"
	echo "______________________________________________"
	./comp_sim.sh -qsfiupi atsbcf ft ft ${program:0:-4} id_stage 663 1 -f
	cp ./sim_FT/sim_out/signals_fault_injection-id_stage-${program:0:-4}-663-1.txt ./sim_FT/sim_out/sim_out_ft_config/signals_fault_injection-id_stage-${program:0:-4}-663-1_CONFIG${i}.txt
done
