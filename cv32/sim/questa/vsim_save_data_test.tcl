set CORE_V_VERIF "/home/thesis/elia.ribaldone/Desktop/core-v-verif"
set SIM_BASE "$env(SIM_BASE)"
set GOLD_NAME "$env(GOLD_NAME)"
set STAGE_NAME "$env(STAGE_NAME)"

file mkdir dataset

#set InSignals [ find nets "sim:/$SIM_BASE/${STAGE_NAME}_i/*" -in ]

add wave sim:/$SIM_BASE/${STAGE_NAME}_i/*
#log -in sim:/$SIM_BASE/${STAGE_NAME}_i/*
#foreach 

run -all

#vcd dumpports -vcdstim -file ./dataset/${GOLD_NAME}_in.vcd -in sim:/$SIM_BASE/${STAGE_NAME}_i/*

# run -all

#if { "$env(GUI)" != "-gui"}  {
#	quit -f
#}

