set SIM_BASE "sim:"
set GOLD_BASE "gold_out:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i"

gold_out:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/ciccio
gold_out:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/wrapper/cicciopasticcio

sim:/cv32e40p_core_i/id_stage_i/ciccio
sim:/cv32e40p_core_i/id_stage_i/wrapper/cicciopasticcio

ciccio
wrapper/cicciopasticcio

gold_out: tb_top cv32e40p_tb_wrapper_i cv32e40p_core_i safgdasfgb

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

set InSignals [ find nets "$SIM_BASE/cv32e40p_id_stage/*" -in ]
set OutSignals [ find nets "$SIM_BASE/cv32e40p_id_stage/*" -out ]

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

dataset open gold_out.wlf

set GOutSignals [ find nets "$GOLD_BASE/id_stage_i/*_o" ]

if { "$env(GUI)" == "-gui"}  {
	foreach sig $GOutSignals {
		puts $sig
		add wave gold_out:/$sig
	}
}

# bisogna provare a comparare segnali che hanno dimensioni diverse (parallelismo diverso)
compare start sim gold_out
foreach s_sig [ list_to_sig $OutSignals ] g_sig [ ord_list $GOutSignals ]{
	puts $s_sig $g_sig
	compare $s_sig $g_sig
}
compare run
compare savediffs diffs_id_stage.txt
compare saverules rules_id_stage.txt

quit -f
