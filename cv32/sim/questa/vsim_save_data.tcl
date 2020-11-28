set CORE_V_VERIF "/home/thesis/elia.ribaldone/Desktop/core-v-verif"
set SIM_BASE "sim:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i"

##################################################################
####### Selezione dei segnali da loggare nel file gold.wlf
set InSignals [ find signals "$SIM_BASE/id_stage_i/*" -in ]
set OutSignals [ find signals "$SIM_BASE/id_stage_i/*" -out ]


if { "$env(GUI)" == "-gui"}  {
	foreach sig $InSignals {
		add wave sim:/$sig
	}
	foreach sig $OutSignals {
		add wave sim:/$sig
	}
}


##################################################################
####### Simulation run
vcd add -dumpports -file gold_in.vcd -in $SIM_BASE/id_stage_i/*


run 0
run -all


##################################################################
####### Save dataset in gold wlf file 

dataset save $SIM_BASE/id_stage_i/* gold_out.wlf

#puts [pwd]

quit -f
