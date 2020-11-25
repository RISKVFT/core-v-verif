set CORE_V_VERIF "/home/thesis/elia.ribaldone/Desktop/core-v-verif"
set SIM_BASE "sim:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i"

##################################################################
####### Selezione dei segnali da loggare nel file gold.wlf
set CheckSignals "$SIM_BASE/id_stage_i/apu_perf_dep_o $SIM_BASE/id_stage_i/controller_i/apu_stall_o $SIM_BASE/id_stage_i/controller_i/apu_en_i"

log $CheckSignals
if { "$env(GUI)" == "-gui"}  {
	add wave $CheckSignals
}


##################################################################
####### Simulation run

run 0
run 600ns


##################################################################
####### Save dataset in gold wlf file 

dataset save sim gold.wlf


quit -f
