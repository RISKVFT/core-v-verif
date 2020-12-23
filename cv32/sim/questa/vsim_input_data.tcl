set SIM_BASE "$env(SIM_BASE)"
set GOLD_NAME "$env(GOLD_NAME)"
set STAGE_NAME "$env(STAGE_NAME)"

proc ord_list {listain} {
	set lista_sig []
 	set stagename [ lindex $listain 0]
	set lista [ lrange $listain 1 end ]
	foreach l1 $lista {
		lappend lista_sig [ splitPath $l1 $stagename ]
                #set l2 [ split $l1 / ]
                #lappend lista_sig [lindex $l2 [expr [ llength $l2] -1]]
        }
        set l_ord_sig [lsort $lista_sig]
        set l_index_sig [lsort -indices $lista_sig]
	set lista_out []
        foreach index_sig $l_index_sig {
                lappend lista_out [lindex $lista $index_sig]
        }
        #foreach l $lista_out {
        #       puts $l
        #}
        return $lista_out

}
proc splitPath {stringa stagename} {
	puts "ciccio si spera sia caduto sullo stagename: $stagename"
	puts "ciccio si spera sia caduto sulla stringa: $stringa"
        set l2 [ split $stringa / ]
	set val_stage [ expr [ lsearch $l2 $stagename ] + 1 ]
        #return [lindex $l2 [expr [ llength $l2] -1]]
	puts "luca si spera sia caduto sulla stringa: $l2"
	puts "luca si spera sia caduto sulla stringa: [join [lrange $l2 $val_stage end] /]"
        return  [join [lrange $l2 $val_stage end] /]
}

proc reopenStdout {file} {
	close stdout
	open $file w        ;# The standard channels are special
}
proc compare_sig {} {
	set OutSignals [ find nets "sim:/cv32e40p_id_stage/*" -out ]
	set GOutSignals [ find nets "gold_out:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/*" ]
	reopenStdout f1.txt
	puts [ list_to_sig $OutSignals ]
	reopenStdout f2.txt
	puts [ list_to_sig $GOutSignals]
}
##################################################################
####### Selezione dei segnali da loggare nel file gold.wlf

#vsim top -vcdstim /top/p=proc.vcd -vcdstim /top/c=cache.vcd
#
if { ${STAGE_NAME} == "cv32e40p_core" } {
	set REAL_STAGE_NAME "cv32e40p_core"
} else {
	set REAL_STAGE_NAME "cv32e40p_${STAGE_NAME}"
}

set InSignals [ find nets "sim:/${REAL_STAGE_NAME}/*_i" ]
set OutSignals [ find nets "sim:/${REAL_STAGE_NAME}/*_o" ]

log -r sim:/${REAL_STAGE_NAME}/*

set Clock "sim:/${REAL_STAGE_NAME}/clk"
#	puts sim:$sig
#	log sim:$sig
#	if { "$env(GUI)" == "-gui"}  {
#		add wave sim:/$sig
#	}
#}
#


##################################################################
####### fault injection

#force -freeze [lindex $OutSignals 1] 0


force -freeze $Clock 1'hx 0 -can 5
run 5 ns
force -freeze $Clock 0 0 -can {@60}
run 50 ns
force -freeze $Clock 0 0 , 1 5 -r 10 -can {@156030 ns}
run -all

##################################################################
####### Save dataset in gold wlf file 

dataset open ./dataset/${GOLD_NAME}_out.wlf

set GOutSignals [ find nets  "${GOLD_NAME}_out:/$SIM_BASE/${STAGE_NAME}_i/*_o" ]
set GInSignals [ find nets "${GOLD_NAME}_out:/$SIM_BASE/${STAGE_NAME}_i/*_i" ]

if { "$env(GUI)" != "-gui"}  {
	foreach sig $GOutSignals {
		puts $sig
		add wave ${GOLD_NAME}_out:$sig
	}
	foreach sig $GInSignals {
		puts $sig
		add wave ${GOLD_NAME}_out:$sig
	}
}
#add wave -position insertpoint  \
#sim:/cv32e40p_core/PULP_XPULP \
#sim:/cv32e40p_core/PULP_CLUSTER \
#sim:/cv32e40p_core/FPU \
#sim:/cv32e40p_core/PULP_ZFINX \
#sim:/cv32e40p_core/NUM_MHPMCOUNTERS \
#sim:/cv32e40p_core/PULP_SECURE \
#sim:/cv32e40p_core/N_PMP_ENTRIES \
#sim:/cv32e40p_core/USE_PMP \
#sim:/cv32e40p_core/A_EXTENSION \
#sim:/cv32e40p_core/DEBUG_TRIGGER_EN \
#sim:/cv32e40p_core/PULP_OBI \
#sim:/cv32e40p_core/N_HWLP \
#sim:/cv32e40p_core/N_HWLP_BITS \
#sim:/cv32e40p_core/APU

compare start ${GOLD_NAME}_out sim
#set s_sig_list_in [ ord_list $InSignals ]
#set g_sig_list_in [ ord_list $GInSignals ]
set fp_sim [ open "signal_sim.txt" w ]
set fp_gold [ open "signal_gold.txt" w ]
#puts "ciccio è caduto 1 : [ llength $s_sig_list_in ]"
#puts "ciccio è caduto 2 : [ llength $g_sig_list_in ]"
#foreach s_sig $s_sig_list_in  g_sig $g_sig_list_in {
#	puts "$s_sig $g_sig"
#	#compare add sim:$s_sig ${GOLD_NAME}_out:$g_sig
#}
# bisogna provare a comparare segnali che hanno dimensioni diverse (parallelismo diverso)
#puts "ciccio__:[llength $OutSignals]"
#puts "ciccio__:[llength $GOutSignals]"
#set s_sig_list [ ord_list $OutSignals ]
#set g_sig_list [ ord_list $GOutSignals ]
set s_sig_list [ ord_list " ${REAL_STAGE_NAME} [find nets -r "sim:/${REAL_STAGE_NAME}/*" ] " ] 
# $OutSignals ]
set g_sig_list [ ord_list " ${STAGE_NAME}_i  [find nets -r "${GOLD_NAME}_out:/$SIM_BASE/${STAGE_NAME}_i/*" ] " ] 
# $GOutSignals ]
foreach s_sig $s_sig_list  g_sig $g_sig_list {
	#puts $fp_sim "[ splitPath $s_sig ${REAL_STAGE_NAME} ]" 
 	##puts $fp_gold "[ splitPath $g_sig ${STAGE_NAME}_i ]"
	puts "sim:$s_sig      ${GOLD_NAME}_out:$g_sig"
	compare add sim:$s_sig ${GOLD_NAME}_out:$g_sig
}

close $fp_sim
close $fp_gold

set compare_filename_tmp [ split ${GOLD_NAME} _ ]
set compare_filename [join [lrange $compare_filename_tmp 1 end] _]

puts ${compare_filename}

compare run {0 ns} {156029 ns}

set comp_info [ lindex [ compare info ] 12 ]

if { "$comp_info" == "0" } {
	set fp_compare [ open "${compare_filename}.txt" "r" ]
	set num_error [ expr [ gets $fp_compare ] +1 ]
	close $fp_compare
	set fp_compare [ open "${compare_filename}.txt" "w+" ]
	puts $fp_compare $num_error
	close $fp_compare	
}



#compare savediffs diffs_${compare_filename}.txt
#compare saverules rules_${compare_filename}.txt

if { "$env(GUI)" != "-gui"}  {
	compare end
	quit -f
}
