set CORE_V_VERIF "/home/thesis/elia.ribaldone/Desktop/core-v-verif"
set SIM_BASE "sim:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i"
set GOLD_BASE "gold:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i"

##################################################################
####### Selezione dei segnali da comparare con gold.wlf

log $SIM_BASE/id_stage_i/apu_perf_dep_o
log $SIM_BASE/id_stage_i/controller_i/apu_stall_o
log $SIM_BASE/id_stage_i/controller_i/apu_en_i

##################################################################
####### Simulation run
set signal "$SIM_BASE/id_stage_i/controller_i/apu_stall_o"
force -freeze $signal 1 100 ns -cancel 400 ns

run 0
run 600ns


##################################################################
####### Load gold.wlf and compare signals

dataset open gold.wlf
if { "$env(GUI)" == "-gui"}  {
	add wave $SIM_BASE/id_stage_i/apu_perf_dep_o
	add wave $SIM_BASE/id_stage_i/controller_i/apu_stall_o
	add wave $GOLD_BASE/id_stage_i/apu_perf_dep_o
	add wave $GOLD_BASE/id_stage_i/controller_i/apu_stall_o
}
# bisogna provare a comparare segnali che hanno dimensioni diverse (parallelismo diverso)
compare start gold sim
compare add $SIM_BASE/id_stage_i/apu_perf_dep_o $GOLD_BASE/id_stage_i/apu_perf_dep_o
compare add $SIM_BASE/id_stage_i/controller_i/apu_en_i $GOLD_BASE/id_stage_i/controller_i/apu_en_i
compare run
compare savediffs diffs.txt
compare saverules rules.txt
printenv

if { "$env(GUI)" != "-gui" } {
	quit -f
}
