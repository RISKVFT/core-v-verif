set CORE_V_VERIF "/home/thesis/marcello.neri/Desktop/core-v-verif"
set SIM_BASE "$env(SIM_BASE)"
set GOLD_NAME "$env(GOLD_NAME)"
set STAGE_NAME "$env(STAGE_NAME)"

#set SIM_BASE "sim:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i"

##################################################################
####### Selezione dei segnali da loggare nel file gold.wlf
#set InSignals [ find signals "sim:/$SIM_BASE/${STAGE_NAME}_i/*" -in ]
#set OutSignals [ find signals "sim:/$SIM_BASE/${STAGE_NAME}_i/*" -out ]


if { "$env(GUI)" == "-gui"}  {
	#foreach sig $InSignals {
		#add wave sim:/$sig
	#}
	#foreach sig $OutSignals {
		#add wave sim:/$sig
	#}
}


##################################################################
####### Simulation run
#log -out sim:/$SIM_BASE/${STAGE_NAME}_i/* -wlf ./dataset/${GOLD_NAME}_out.wlf

#vcd add -dumpports -file ./dataset/${GOLD_NAME}_in.vcd -in sim:/$SIM_BASE/${STAGE_NAME}_i/*

#log [find nets sim:/$SIM_BASE/${STAGE_NAME}_i/* -out]



run 0
run -all


##################################################################
####### Save dataset in gold wlf file 

dataset save sim ./dataset/${GOLD_NAME}_out.wlf

#wlf2vcd ./dataset/${GOLD_NAME}_out.wlf -o ./dataset/${GOLD_NAME}_out.vcd
dataset open ./dataset/${GOLD_NAME}_out.wlf
#puts [pwd]

if { "$env(GUI)" != "-gui"}  {
	quit -f
}
#quit -f
