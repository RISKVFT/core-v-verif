set CORE_V_VERIF "/home/thesis/elia.ribaldone/Desktop/core-v-verif"
set SIM_BASE "sim:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i"

##################################################################
####### Selezione dei segnali da loggare nel file gold.wlf

log $SIM_BASE/id_stage_i/apu_perf_dep_o
log $SIM_BASE/id_stage_i/controller_i/apu_stall_o
log $SIM_BASE/id_stage_i/controller_i/apu_en_i


##################################################################
####### Simulation run

run 0
run 600ns


##################################################################
####### Save dataset in gold wlf file 

dataset save sim gold.wlf


quit -f
