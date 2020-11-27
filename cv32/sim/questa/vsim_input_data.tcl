set CORE_V_VERIF "/home/thesis/marcello.neri/Desktop/core-v-verif"
set SIM_BASE "sim:"
set GOLD_BASE "gold_out:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i"

##################################################################
####### Selezione dei segnali da loggare nel file gold.wlf

#vsim top -vcdstim /top/p=proc.vcd -vcdstim /top/c=cache.vcd



log $SIM_BASE/cv32e40p_id_stage/apu_perf_dep_o

if { "$env(GUI)" == "-gui"}  {
	add wave $SIM_BASE/id_stage_i/apu_perf_dep_o
}

run 0
run -all



##################################################################
####### Save dataset in gold wlf file 
vcd2wlf gold_out.vcd gold_out.wlf

dataset open gold_out.wlf


if { "$env(GUI)" == "-gui"}  {
	add wave $GOLD_BASE/id_stage_i/apu_perf_dep_o
}

# bisogna provare a comparare segnali che hanno dimensioni diverse (parallelismo diverso)
compare start sim gold_out
compare add $SIM_BASE/cv32e40p_id_stage/apu_perf_dep_o $GOLD_BASE/id_stage_i/apu_perf_dep_o
compare run
compare savediffs diffs_id_stage.txt
compare saverules rules_id_stage.txt

quit -f
