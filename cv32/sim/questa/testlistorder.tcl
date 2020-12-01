#!/usr/bin/tclsh

lappend list1 gold_out:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/ciccio6
lappend list1 gold_out:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/ciccio2
lappend list1 gold_out:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/ciccio7
lappend list1 gold_out:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/ciccio
lappend list1 gold_out:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/ciccio1
lappend list1 gold_out:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/ciccio3
lappend list1 gold_out:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/ciccio4
lappend list1 gold_out:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/ciccio5
lappend list1 gold_out:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/ciccio8

lappend list2 gold_out:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/ciccio6
lappend list2 gold_out:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/ciccio7
lappend list2 gold_out:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/ciccio8
lappend list2 gold_out:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/ciccio
lappend list2 gold_out:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/wrapper/ciccio1
lappend list2 gold_out:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/ciccapper/ciccio4
lappend list2 gold_out:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/ciccapper/ciccio5
lappend list2 gold_out:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/wrapper/ciccio2
lappend list2 gold_out:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/wrapper/ciccio3


proc list_to_sig {lista} {
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
	#	puts $l
	#}
	return $lista_out

}

list_to_sig $list1
list_to_sig $list2



