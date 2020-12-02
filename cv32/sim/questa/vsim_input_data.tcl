set SIM_BASE "$env(SIM_BASE)"
set GOLD_NAME "$env(GOLD_NAME)"
set STAGE_NAME "$env(STAGE_NAME)"

proc ord_list {lista} {
        foreach l1 $lista {
                set l2 [ split $l1 / ]
                lappend lista_sig [lindex $l2 [expr [ llength $l2] -1]]
        }
        set l_ord_sig [lsort $lista_sig]
        set l_index_sig [lsort -indices $lista_sig]
        foreach index_sig $l_index_sig {
                lappend lista_out [lindex $lista $index_sig]
        }
        #foreach l $lista_out {
        #       puts $l
        #}
        return $lista_out

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

set InSignals [ find nets "sim:/cv32e40p_${STAGE_NAME}/*" -in ]
set OutSignals [ find nets "sim:/cv32e40p_${STAGE_NAME}/*" -out ]

foreach sig $OutSignals {
	puts sim:/$sig
	log sim:/$sig
	if { "$env(GUI)" == "-gui"}  {
		add wave sim:/$sig
	}
}

run 0
run -all



##################################################################
####### Save dataset in gold wlf file 

dataset open ${GOLD_NAME}_out.wlf

set GOutSignals [ find nets "${GOLD_NAME}_out:/$SIM_BASE/${STAGE_NAME}_i/*_o" ]

if { "$env(GUI)" == "-gui"}  {
	foreach sig $GOutSignals {
		puts $sig
		add wave ${GOLD_NAME}_out:/$sig
	}
}

# bisogna provare a comparare segnali che hanno dimensioni diverse (parallelismo diverso)
compare start sim ${GOLD_NAME}_out
foreach s_sig [ list_to_sig $OutSignals ] g_sig [ ord_list $GOutSignals ]{
	puts sim:/$s_sig ${GOLD_NAME}_out:/$g_sig
	compare sim:/$s_sig ${GOLD_NAME}_out:/$g_sig
}
compare run
compare savediffs diffs_id_stage.txt
compare saverules rules_id_stage.txt

quit -f
