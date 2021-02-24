set CORE_V_VERIF "/home/thesis/marcello.neri/Desktop/core_marcello/core-v-verif"
set SIM_BASE "$env(SIM_BASE)"
set GOLD_NAME "$env(GOLD_NAME_SIM)"
set GOLD_NAME_FILE "$env(GOLD_NAME)"
set STAGE_NAME "$env(STAGE_NAME)"
set ENDSIM "$env(T_ENDSIM)"
set CYCLE "$env(CYCLE)"
set FI "$env(FI)"
set compare_filename "$env(COMPARE_ERROR_FILE)"
set info_filename "$env(INFO_FILE)"
set cycle_filename "$env(CYCLE_FILE)"
set signals_filename "$env(SIGNALS_FI_FILE)"

proc ord_list {listain} {
	set listain_new [ deleteGenblk $listain]
	set lista_sig []
 	set stagename [ lindex $listain_new 0]
	set lista [ lrange $listain 1 end ]
	foreach l1 $lista {
		lappend lista_sig [ splitPath $l1 $stagename ]
    }
    set l_ord_sig [lsort $lista_sig]
    set l_index_sig [lsort -indices $lista_sig]
	set lista_out []
    foreach index_sig $l_index_sig {
            lappend lista_out [lindex $lista $index_sig]
    }
    return $lista_out
}

proc splitPath {stringa stagename} {
        set l2 [ split $stringa / ]
	set val_stage [ expr [ lsearch $l2 $stagename ] + 1 ]
        return  [join [lrange $l2 $val_stage end] /]
}


proc deleteGenblk {stringa} {
        set l2 [ split $stringa / ]
		set stringa_new []
		foreach substring $l2 {
			if { [ string match "genblk*" $substring ] == 0 } {
				lappend stringa_new $substring
			}
		}
        return  [join $stringa_new /]
}


# find real name of stage, if we simulate core we should give to comp_sim.sh
# script the name with cv32e40p (cv32e40p_core) instaead in other cases we
# only give stage name. This "if" set REAL_STAGE_NAME that should be csv32e40p_STAGENAME
if { ${STAGE_NAME} == "cv32e40p_core" } {
	set REAL_STAGE_NAME "cv32e40p_core"
} else {
	set REAL_STAGE_NAME "cv32e40p_${STAGE_NAME}"
}

set flag 0
set n_fault 0
# Find all signals that we use in fault injection
# we use _i to filter out clock and reset 
# signals from pipeline IF/ID
# instr_valid_i, instr_rdata_i, is_compressed_i, illegal_c_insn_i, is_fetch_failed_i, pc_id_i

set arch_used [ lindex [ split $GOLD_NAME "_" ] 1 ]
set stage_used [ lindex [ split $GOLD_NAME "_" ] 2 ]

if { $stage_used == "id" } {
	set sim_fi_sig [ find nets  "sim:/${REAL_STAGE_NAME}/instr_valid_i" ]
	set sim_fi_sig [ concat $sim_fi_sig [ find nets  "sim:/${REAL_STAGE_NAME}/instr_rdata_i" ] ]
	set sim_fi_sig [ concat $sim_fi_sig [ find nets  "sim:/${REAL_STAGE_NAME}/is_compressed_i" ] ]
	set sim_fi_sig [ concat $sim_fi_sig [ find nets  "sim:/${REAL_STAGE_NAME}/illegal_c_insn_i" ] ]
	set sim_fi_sig [ concat $sim_fi_sig [ find nets  "sim:/${REAL_STAGE_NAME}/is_fetch_failed_i" ] ]
	set sim_fi_sig [ concat $sim_fi_sig [ find nets  "sim:/${REAL_STAGE_NAME}/pc_id_i" ] ]
	#set sim_fi_sig [ concat $sim_fi_sig [ find nets -r "sim:/${REAL_STAGE_NAME}/*_q" ] ]
	set sim_fi_sig [ concat $sim_fi_sig [ find nets -r "sim:/${REAL_STAGE_NAME}/*mem" ] ] 
} elseif { $stage_used == "ex" } {
	set sim_fi_sig_complete1 [ concat [ concat  [ find nets  "sim:/${REAL_STAGE_NAME}/*_i" ] [ find nets -r "sim:/${REAL_STAGE_NAME}/*_q" ] ] [ find nets -r "sim:/${REAL_STAGE_NAME}/*mem" ] ] 
	set sim_fi_sig_complete2 [lsearch -inline -all -not -regexp $sim_fi_sig_complete1 voted]
	set sim_fi_sig [lsearch -inline -all -not -regexp $sim_fi_sig_complete2 vector_err]
} else {
	if { $stage_used == "if" } {
		puts "###########################################à IF STAGE ############################################"
		set sim_fi_sig [ concat [ concat [ concat  [ find nets  "sim:/${REAL_STAGE_NAME}/*_i" ] [ find nets -r "sim:/${REAL_STAGE_NAME}/*_q" ] ] [ find nets -r "sim:/${REAL_STAGE_NAME}/*mem" ] ] [ find nets -r "sim:/${REAL_STAGE_NAME}/*_i/*/*_o"] ]
	}  else {
		set sim_fi_sig [ concat [ concat  [ find nets  "sim:/${REAL_STAGE_NAME}/*_i" ] [ find nets -r "sim:/${REAL_STAGE_NAME}/*_q" ] ] [ find nets -r "sim:/${REAL_STAGE_NAME}/*mem" ] ] 
	}
}
set sim_fi_sig_tmp $sim_fi_sig
set sim_fi_sig ""
# Copying each signal N times as the number of bits of that signal in order 
#to respect the probability of the fault
foreach sig_fi_to_copy $sim_fi_sig_tmp {
	set sig_width [lindex [ split [ examine -binary -radixenumnumeric sim:$sig_fi_to_copy] "'" ] 0 ]
	set graffa [string index $sig_width 0]
	set num_of_bits 1
	if { "$graffa" == "\{" } {
		set descr [describe sim:$sig_fi_to_copy]
		set exam [examine sim:$sig_fi_to_copy]
		set array_depth [ expr [llength [split $descr "y"]] -1 ]
		for { set j 0} {$j < $array_depth} {incr j} {
			set array_dim  [ lindex [ split [ lindex $descr [expr {(int($j)*6)+4} ]] "\]" ] 0 ]
			set num_of_bits [ expr $num_of_bits*$array_dim ]
		}
		#set bit_number [lindex [split [lindex [split $exam "'"] 0] "\{" ] end ]
		set sig_width [lindex [split [lindex [split $exam "'"] 0] "\{" ] end ]
	} 
	#else {
		#set sig_width [lindex [ split [ examine -binary -radixenumnumeric sim:$sig_fi_to_copy] "'" ] 0 ]
	#}
	set num_of_bits [ expr $num_of_bits*$sig_width ]
	
	for { set j 0} {$j < $num_of_bits} {incr j} {
		set sim_fi_sig [ concat $sim_fi_sig $sig_fi_to_copy ]
	}
}

if [ file exists "${signals_filename}" ] {
	# If the file exist this function enable the script to continue
	# from where it is stopped !!
	set fp [open "${signals_filename}" "r"]
	set filedata [read $fp]
	close $fp
	set file_lines [llength [ split $filedata "\n" ]]
	set len_sim_fi_sig [llength $sim_fi_sig]

	if { $file_lines > $len_sim_fi_sig } {
		set sim_fi_sig []
		set n_fault 0

		foreach line [ split $filedata "\n" ] {
			if [ string match "All_signals:*" $line ] {
				# Save signals
				lappend sim_fi_sig [lindex [split $line ":"] 1]
				lappend l_bit_ft {}
			} else {
				if [ string match "sig_fault:*" $line ]  {
				        set sig_name [lindex [ split [ lindex [ split $line ":" ]  2 ] "\[" ] 0 ]               
				        set sig_id [lindex [split [lindex [split $line ":" ] 3] " "] 0]
				        set sig_index [lsearch $sim_fi_sig $sig_name ]
				        lset l_bit_ft $sig_index [ concat [ lindex $l_bit_ft $sig_index ] [ list $sig_id ] ]
					incr n_fault
				}
			}

		}

		if { $n_fault >= $CYCLE } {
			puts "################################################################"
			puts "You are tring to simulate a simulation that is already done, if you want to resimulate delete file:"
			puts "${signals_filename}"
			puts "################################################################"
			#exit 
		}
		set fp_cycle [ open "${cycle_filename}" "w" ]
		puts $fp_cycle "$n_fault"
		puts $fp_cycle "2000"
		close $fp_cycle	
	
	} else {
		set flag 1
	}	

} else {
	set flag 1
}

if { $flag == 1 } {
	set len_sim_fi_sig [llength $sim_fi_sig]
	# open file of signal in order to delete previous data
	set fp_sig [ open "${signals_filename}" "w" ]
	foreach sig $sim_fi_sig {
		puts $fp_sig "All_signals:$sig"
	}
	close $fp_sig
	# table of bits where we have applied fault injection because we don't want to do fault injection on the same signal at the same clock cysle two times
	set l_bit_ft {}

	for {set k 0} {$k<$len_sim_fi_sig} {incr k} {
		lappend l_bit_ft {}
	}

}


set fp_info [ open "${info_filename}" "w" ]
puts $fp_info "Number_of_signal:$len_sim_fi_sig"
close $fp_info	



puts "INFO: before cycle CYCLE=$CYCLE"
for {set i $n_fault} {$i<$CYCLE} {incr i} {
		
	# set start time of simulation 
	set start_time [clock milliseconds]
		
	# we log ouput signals of current simulation
	# -r for log all signals
	log -r "sim:/${REAL_STAGE_NAME}/*"

	##################################################################
	####### Open gold simulation 
	if { $i == $n_fault } {	
		dataset open ./dataset/${GOLD_NAME_FILE}-out.wlf

		set GOutSignals [ find nets "${GOLD_NAME}_out:/$SIM_BASE/${STAGE_NAME}_i/*_o" ]
		set GInSignals [ find nets "${GOLD_NAME}_out:/$SIM_BASE/${STAGE_NAME}_i/*_i" ]
	
	}
	


	##################################################################
	####### Clock creation

	set Clock "sim:/${REAL_STAGE_NAME}/clk"
	# first 5ns of clock are at "x" value
	force -freeze $Clock 1'hx 0 -can 5
	run 5 ns
	# The until 60ns clock is at 0
	force -freeze $Clock 0 0 -can {@60}
	run 50 ns
	# Finally clock run until the end of simulation
	force -freeze $Clock 0 0 , 1 5 -r 10 -can ${ENDSIM}

	#################################################################
	##### FAULT INJECTION
	##### TODO: salvare i segnali che vengono dai voter per vedere se il
	########## fault iniettato e' stato corretto  detectato non sentito etc.
	
	# Set end of comparison and start to compare
	
	
	# check if the selected bit has been already used in previous fault injection
	#set fi_instant [expr {int(rand()*($ENDSIM-2*10))} ]	
	set fi_instant "no fault injection"

	if { $FI == 1 } {

	    set find_n 1
		while { $find_n == 1 } {		
			# Find instant time in which inject, this instant
			# will be selected between 0 and ENDSIM/2
			set fi_instant [expr {int(rand()*($ENDSIM-2*10))} ] 	
			
			puts "INFO: cycle $i"
			# index of signal in which inject signal
			set sig_index [ expr {int(rand()*$len_sim_fi_sig)} ]
			puts "INFO: Signal index = $sig_index"
			# Find signal in which inject fault
			set sig_fi [lindex $sim_fi_sig $sig_index]
			puts "INFO: signal name = $sig_fi"
			
			# Print the examine and description command to see all value
			set exam [examine sim:$sig_fi]
			set descr [describe sim:$sig_fi]
			puts "INFO: examine = $exam, descr = $descr"

			# Now if the signal have multiple bit we should cycle
			# otherwise we simple assign it
			set bit_number [lindex [ split [ examine -binary -radixenumnumeric sim:$sig_fi] "'" ] 0 ]
			puts "INFO: Bit number = $bit_number"
			
			set graffa [string index $bit_number 0]
			puts "INFO: Graffa  = $graffa"
		
			# set variable to manage multidim array for non replacement
			set bit_choose_array ""
			
			if { "$graffa" == "\{" } {
				# MATRICE
				set descr [describe sim:$sig_fi]
				set exam [examine sim:$sig_fi]
				set array_depth [ expr [llength [split $descr "y"]] -1 ]
				puts "INFO: In If signal  = $array_depth"
				for { set j 0} {$j < $array_depth} {incr j} {
					set array_dim  [ lindex [ split [ lindex $descr [expr {(int($j)*6)+4} ]] "\]" ] 0 ]
					puts "INFO: array_dim = $array_dim"
					set array_dim_rand [expr {int(rand()*$array_dim)} ]
					append sig_fi "\[$array_dim_rand\]"
					puts "INFO: appended signal $sig_fi"
					
					# for non replacement
					append bit_choose_array "\[$array_dim_rand\]"
				}
				set bit_number [lindex [split [lindex [split $exam "'"] 0] "\{" ] end ]
			} 
			puts "INFO: Signal name  = $sig_fi"
			set bit_choose [expr {int(rand()*$bit_number)} ] 
			puts "INFO: Bit choose = $bit_choose"
			# This is the real bit position since index are reversed for string and binary data
			set bit_choose_real [expr $bit_number-$bit_choose-1 ]
			# find bit to flip in binary string
			set bit_value [string index [lindex [ split [examine -binary -radixenumnumeric sim:$sig_fi] "b" ] 1 ] $bit_choose_real ]
			puts "INFO: row number = $bit_value"
	
		    # for non replacement
			set compare_sig "${bit_choose_array}\[${bit_choose}\]${fi_instant}"
			set find_n 0
			#check find_n
			foreach ll [ lindex $l_bit_ft $sig_index ] {
				if  { $ll == $compare_sig } {
					set find_n 1
					break
				}
			}	
		}
				
		# Append new bit to list of bits where we have applied fault injection
		lset l_bit_ft $sig_index [ concat [ lindex $l_bit_ft $sig_index ] [ list $compare_sig ] ]
		if { $bit_value != 0  && $bit_value != 1 } {
			set bit_force_value 0
		} else {
		 	set bit_force_value [expr ($bit_value+1)%2 ]
		}

		force -deposit "$sig_fi\[$bit_choose\]" $bit_force_value
		set fi_instant_real [ expr { $fi_instant-55 } ]
		run $fi_instant_real ns
		
	}

	
	#################################################################
	###### Begin comparation between gold and current simulation

	compare start ${GOLD_NAME}_out sim
	compare options -maxtotal 1
	compare options -track
	compare clock -rising clock_cmp sim:/${REAL_STAGE_NAME}/clk
	
	# These two line find gold and current simulation ouput signal and order it using ord_list function 
	# If you want to compare all internal signal use -r option
	## bisogna fare in modo che le interfacce tra le varie architetture siano sempre uguali, quindi se 
	##   si comparano master e FT_name bisogna rimuovere dalla comparazione i segnali aggiuntivi per la FT
	set s_sig_list1 [ ord_list " ${REAL_STAGE_NAME} [find nets "sim:/${REAL_STAGE_NAME}/*_o"] " ] 
	set g_sig_list1 [ ord_list " ${STAGE_NAME}_i  [find nets "${GOLD_NAME}_out:/$SIM_BASE/${STAGE_NAME}_i/*_o" ] " ] 
	#set s_sig_list1 [ ord_list "${REAL_STAGE_NAME} [find nets -r "sim:/${REAL_STAGE_NAME}/*"]" ] 
	#set g_sig_list1 [ ord_list "${STAGE_NAME}_i  [find nets -r "${GOLD_NAME}_out:/$SIM_BASE/${STAGE_NAME}_i/*"]" ] 
	set s_sig_list []
	set g_sig_list []
	foreach l1 $s_sig_list1 {
		if { [ llength [split $l1 "#"] ] == 1 } {
			lappend s_sig_list $l1
		}
	}
	foreach l1 $g_sig_list1 {
		if { [ llength [split $l1 "#"] ] == 1 } {
			lappend g_sig_list $l1
		}
	}


	if { $arch_used=="ref" } {
		set index_to_remove [ lsearch -all -regexp $s_sig_list _ft_ ]
		for {set ii [ expr [llength $index_to_remove] -1]} {$ii>-1} {incr ii -1} {
			set index_tmp [ lindex $index_to_remove $ii ]
			set s_sig_list [ lreplace $s_sig_list $index_tmp $index_tmp ]
		}
	}

	if { $arch_used=="ft" && $stage_used=="id" } {
		set index_to_remove [ lsearch -all -regexp $s_sig_list _ft_ ]
		for {set ii [ expr [llength $index_to_remove] -1]} {$ii>-1} {incr ii -1} {
			set index_tmp [ lindex $index_to_remove $ii ]
			set s_sig_list [ lreplace $s_sig_list $index_tmp $index_tmp ]
		}
		set index_to_remove [ lsearch -all -regexp $g_sig_list _ft_ ]
		for {set ii [ expr [llength $index_to_remove] -1]} {$ii>-1} {incr ii -1} {
			set index_tmp [ lindex $index_to_remove $ii ]
			set g_sig_list [ lreplace $g_sig_list $index_tmp $index_tmp ]
		}
	}

	# These cycle set the comparison of all output signals
	foreach s_sig $s_sig_list  g_sig $g_sig_list {
		#puts $fp_sim "[ splitPath $s_sig ${REAL_STAGE_NAME} ]" 
		##puts $fp_gold "[ splitPath $g_sig ${STAGE_NAME}_i ]"
		set s_sig_check [ lindex [ split $s_sig "/" ] end ]
		set g_sig_check [ lindex [ split $g_sig "/" ] end ]
		if { $s_sig_check == $g_sig_check } {
			puts "SIGNAL TO COMPARE: sim:$s_sig      ${GOLD_NAME}_out:$g_sig"
			compare add -clock clock_cmp sim:$s_sig ${GOLD_NAME}_out:$g_sig
		} else {
			puts "Skipped:SIGNAL TO COMPARE: sim:$s_sig      ${GOLD_NAME}_out:$g_sig"
			puts "Skipped: Check the signals, an error may be likely..."
		}
		
	}

	#0 ${ENDSIM}
	
	puts "ENDSIM $ENDSIM"
	puts "INFO: Instant = $fi_instant"
	puts "INFO: Simulation time now = $now"
 	set remaining [expr $ENDSIM-$now]
	puts "INFO: remaining = $remaining"
	
	if { $FI==1 } {
		compare run $fi_instant $remaining

		if { $remaining < 300 } { 
			run $remaining
		} else {
			run 300
		}

		#set error_number [ lindex [ compare info ] 12 ]
		set error_number [string map {" " ""} [lindex [ split [lindex [split [compare info] "\n"] 1 ] "=" ] 1]]

			#puts "INFO: compare_info: [compare info]"
		puts "INFO: number of errors: $error_number"
		if { $error_number == 0 && $remaining >= 300} {
 			set remaining [expr $ENDSIM-$now]
			set clock_period 10
			set num_run_cycles 10 
			set num_clock_for_cycle [expr $remaining/($clock_period*$num_run_cycles)]
			set run_time [expr $num_clock_for_cycle*$clock_period ]
			for {set c 0} {$c < $num_run_cycles} { incr c } {
				run ${run_time}
				set error_number [string map {" " ""} [lindex [ split [lindex [split [compare info] "\n"] 1 ] "=" ] 1]]
				if { $error_number != 0 } {
					break
				}
			}
		} 
		if { $error_number != 0 } {
			# If there is at least an error we open error file, read current number of error
			# and increment it
			puts "Compare error filename: ${compare_filename}"
			set fp_compare [ open "${compare_filename}" "r" ]
			set num_error [ expr [ gets $fp_compare ] +1 ]
			close $fp_compare
			set fp_compare [ open "${compare_filename}" "w+" ]
			puts $fp_compare $num_error
			close $fp_compare	
		}	
		puts "INFO: current time = $now"
		
	} else {
		compare run
		run $remaining
		#compare end
	}
	##############################################################################
	###### Save error if there are

	if { $env(GUI) == "-gui" } {
		add wave *
		if {$error_number != 0} {
			compare savediffs savediff.txt
		}			
		puts [ compare info -signals ]
		compare info -write savecompare.txt 1 50	
		puts "Press a key to continue."		
		set key [ gets stdin ]
	}

	if {$FI > 0 } {
		compare end
		restart -force
		set end_time [clock milliseconds]
	}
	
	# Save current cycle and cycle simulation time in cycle_file in order
	# to cumpute remaining time and percentage of total simulations done
	
	if {$FI > 0} {
		# Print on file informations about faults and errors produced
		set fp_sig [ open "${signals_filename}" "a" ]
		puts $fp_sig "sig_fault: signal_name:$sig_fi\[$bit_choose\] sim_id:$compare_sig  value:$bit_force_value  fi_instant:$fi_instant SIM_ERROR:$error_number time_for_this_simulation:[expr $end_time-$start_time]" 
		close $fp_sig
		
		set fp_cycle [ open "${cycle_filename}" "w" ]
		puts $fp_cycle "$i"
		puts $fp_cycle "[expr $end_time-$start_time]"
		close $fp_cycle	
		puts "--------------------------------------------------------\nOpen file: [file channels]\n.------------------------------" 
	}
}

set fp_cycle [ open "${cycle_filename}" "w" ]
puts $fp_cycle "$i"
close $fp_cycle	

#############################################################################
######## Exit from simulation if we are in batch mode
if { $env(GUI) != "-gui"}  {
	compare end
	quit -f
}



