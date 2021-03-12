set CORE_V_VERIF "/home/thesis/marcello.neri/Desktop/core_marcello/core-v-verif"

#add list -out /tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/ex_stage_i/*
#do $CORE_V_VERIF/cv32/sim/questa/vsim_FT.do
#wlfman item saved.wlf
#write list 
#$CORE_V_VERIF/cv32/sim/core/sim_FT/saved_signals/id_stage_FT.lst
add wave -recursive sim:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/*
#set aluinput [find nets -r sim:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/*]
#foreach i $aluinput {
#	puts "ciaooo $i"
#}
run 0
run 1000ns
set aluinput [find nets -r sim:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/*]
foreach i $aluinput {
	puts "ciaooo $i"
	puts [ examine -time 100 -binary $i ]

}
#quit -f
#wlfman item $CORE_V_VERIF/cv32/sim/core/sim_FT/vsim.wlf > $CORE_V_VERIF/cv32/sim/core/sim_FT/saved_signals/filesignal.txt
