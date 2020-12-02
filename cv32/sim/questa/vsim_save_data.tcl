set CORE_V_VERIF "/home/thesis/elia.ribaldone/Desktop/core-v-verif"
set SIM_BASE "$env(SIM_BASE)"
set GOLD_NAME "$env(GOLD_NAME)"
set STAGE_NAME "$env(STAGE_NAME)"

#set SIM_BASE "sim:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i"

##################################################################
####### Selezione dei segnali da loggare nel file gold.wlf
set InSignals [ find signals "sim:/$SIM_BASE/${STAGE_NAME}_i/*" -in ]
set OutSignals [ find signals "sim:/$SIM_BASE/${STAGE_NAME}_i/*" -out ]


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
vcd add -dumpports -file ${GOLD_NAME}_in.vcd -in sim:/$SIM_BASE/${STAGE_NAME}_i/*


run 0
run -all


##################################################################
####### Save dataset in gold wlf file 

dataset save sim:/$SIM_BASE/${STAGE_NAME}_i/*_o ${GOLD_NAME}_out.wlf

#puts [pwd]

quit -f
