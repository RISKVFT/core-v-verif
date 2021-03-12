set CORE_V_VERIF "/home/elia.ribaldone/Desktop/core-v-verif"
set SIM_BASE "$env(SIM_BASE)"
set GOLD_NAME "$env(GOLD_NAME_DATASET)"
set STAGE_NAME "$env(STAGE_NAME)"

file mkdir dataset

#set OutSignals [ find nets "sim:/$SIM_BASE/${STAGE_NAME}_i/*" -out ]

log -r sim:/$SIM_BASE/${STAGE_NAME}_i/*


run -all
set wlfname [string map {/ _} $GOLD_NAME] 

dataset save sim ./dataset/${wlfname}-out.wlf

quit -sim
if { "$env(GUI)" != "-gui"}  {
	quit -f
}

