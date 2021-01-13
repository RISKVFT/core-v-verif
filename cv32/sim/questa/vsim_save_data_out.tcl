set CORE_V_VERIF "/home/thesis/marcello.neri/Desktop/core-v-verif"
set SIM_BASE "$env(SIM_BASE)"
set GOLD_NAME "$env(GOLD_NAME)"
set STAGE_NAME "$env(STAGE_NAME)"

file mkdir dataset

#set OutSignals [ find nets "sim:/$SIM_BASE/${STAGE_NAME}_i/*" -out ]

log -r sim:/$SIM_BASE/${STAGE_NAME}_i/*


run -all
dataset save sim ./dataset/${GOLD_NAME}_out.wlf

quit -sim
if { "$env(GUI)" != "-gui"}  {
	quit -f
}

