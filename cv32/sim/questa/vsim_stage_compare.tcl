set CORE_V_VERIF "/home/thesis/elia.ribaldone/Desktop/core-v-verif/"
set SIM_BASE "$env(SIM_BASE)"
set GOLD_NAME "$env(GOLD_NAME)"
set STAGE_NAME "$env(STAGE_NAME)"
set ENDSIM "$env(T_ENDSIM)"
set CYCLE "$env(CYCLE)"
set FI "$env(FI)"
set compare_filename "$env(COMPARE_ERROR_FILE)"
set info_filename "$env(INFO_FILE)"
set cycle_filename "$env(CYCLE_FILE)"
set signals_filename "$env(SIGNALS_FI_FILE)"

proc ord_list {listain} {
	set lista_sig []
 	set stagename [ lindex $listain 0]
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

# find real name of stage, if we simulate core we should give to comp_sim.sh
# script the name with cv32e40p (cv32e40p_core) instaead in other cases we
# only give stage name. This "if" set REAL_STAGE_NAME that should be csv32e40p_STAGENAME
if { ${STAGE_NAME} == "cv32e40p_core" } {
	set REAL_STAGE_NAME "cv32e40p_core"
} else {
	set REAL_STAGE_NAME "cv32e40p_${STAGE_NAME}"
}

# Find all signals that we use in fault injection
# we use _i to filter out clock and reset 
set sim_fi_sig [ concat [ concat  [ find nets  "sim:/${REAL_STAGE_NAME}/*_i" ] [ find nets -r "sim:/${REAL_STAGE_NAME}/*_q" ] ] [ find nets -r "sim:/${REAL_STAGE_NAME}/*mem" ] ] 

# open file of signal in order to delete previous data
set fp_sig [ open "${signals_filename}" "w" ]
foreach sig $sim_fi_sig {
	puts $fp_sig "All_signals:$sig"
}
close $fp_sig

set len_sim_fi_sig [llength $sim_fi_sig]

set fp_info [ open "${info_filename}" "w" ]
puts $fp_info "Number_of_signal:$len_sim_fi_sig"
close $fp_info	

# table of bits where we have applied fault injection because we don't want to do fault injection on the same signal at the same clock cysle two times
set l_bit_ft {}

for {set k 0} {$k<$len_sim_fi_sig} {incr k} {
	lappend l_bit_ft {}
}


puts "INFO: before cycle CYCLE=$CYCLE"
for {set i 0} {$i<$CYCLE} {incr i} {
		
	# set start time of simulation 
	set start_time [clock milliseconds]
		
	# we log ouput signals of current simulation
	# -r for log all signals
	log "sim:/${REAL_STAGE_NAME}/*_o"

	##################################################################
	####### Open gold simpulation 
	if { $i == 0 } {	
		dataset open ./dataset/${GOLD_NAME}_out.wlf

		set GOutSignals [ find nets  "${GOLD_NAME}_out:/$SIM_BASE/${STAGE_NAME}_i/*_o" ]
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

	#################################################################
	##### FAULT INJECTION
	##### TODO: salvare i segnali che vengono dai voter per vedere se il
	########## fault iniettato e' stato corretto  detectato non sentito etc.
	
	# Set end of comparison and start to compare
	
	
	# check if the selected bit has been already used in previous fault injection
	
	if { $FI == 1 } {

	    set find_n 1
		while { $find_n == 1 } {		
			# Find instant time in which inject, this instant
			# will be selected between 0 and ENDSIM/2
			set fi_instant [expr {int(rand()*($ENDSIM-2*10))} ]	
			run $fi_instant ns
			
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
					set array_dim_rand [expr {int(rand())*$array_dim}]
					append sig_fi "\[$array_dim_rand\]"
					puts "INFO: appeded signal $sig_fi"
					
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
			set compare_sig [ concat $bit_choose_array "\[$bit_choose\]" "_" $fi_instant ]	
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
		
	}
	
	#################################################################
	###### Begin comparation between gold and current simulation

	compare start ${GOLD_NAME}_out sim
	compare options -maxtotal 1
	compare options -track
	
	# These two line find gold and current simulation ouput signal and order it using ord_list function 
	# If you want to compare all internal signal use -r option
	set s_sig_list [ ord_list " ${REAL_STAGE_NAME} [find nets  "sim:/${REAL_STAGE_NAME}/*_o"] " ] 
	set g_sig_list [ ord_list " ${STAGE_NAME}_i  [find nets "${GOLD_NAME}_out:/$SIM_BASE/${STAGE_NAME}_i/*_o" ] " ] 

	# These cyce set the comparison of all output signals
	foreach s_sig $s_sig_list  g_sig $g_sig_list {
		#puts $fp_sim "[ splitPath $s_sig ${REAL_STAGE_NAME} ]" 
		##puts $fp_gold "[ splitPath $g_sig ${STAGE_NAME}_i ]"
		puts "sim:$s_sig      ${GOLD_NAME}_out:$g_sig"
		compare add sim:$s_sig ${GOLD_NAME}_out:$g_sig
	}

	#0 ${ENDSIM}
	
	puts "ENDSIM $ENDSIM"
	puts "INFO: Instant = $fi_instant"
 	set remaining [expr $ENDSIM-$now]
	puts "INFO: remaining = $remaining"
	compare run $fi_instant $remaining 
	
	run 300
	#set error_number [ lindex [ compare info ] 12 ]
	set error_number [string map {" " ""} [lindex [ split [lindex [split [compare info] "\n"] 1 ] "=" ] 1]]

	puts "INFO: compare_info: [compare info]"
	puts "INFO: number of errors: $error_number"
	if { $error_number == 0 } {
		set clock_period 10
		set num_run_cycles [expr $ENDSIM/($clock_period*10)]
		set num_compare [ expr $remaining/($clock_period*$num_run_cycles) ]
		set run_time [expr $num_run_cycles*$clock_period ]
		for {set c 0} {$c < $num_compare} { incr c } {
			run ${run_time}
			set error_number [ lindex [ compare info ] 12 ]
			if { $error_number > 0 } {
				break
			}
		}
	} else {
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
	
	##############################################################################
	###### Save error if there are

	if {$FI > 0} {
		compare end
		restart -force
	}
	
	# Save current cycle and cycle simulation time in cycle_file in order
	# to cumpute remaining time and percentage of total simulations done
	set end_time [clock milliseconds]
	
	if {$FI > 0} {
		# Print on file informations about faults and errors produced
		set fp_sig [ open "${signals_filename}" "a" ]
		puts $fp_sig "sig_fault: signal_name:$sig_fi\[$bit_choose\]  value:[expr ($bit_value+1)%2 ]  fi_instant:$fi_instant SIM_ERROR:$error_number time_for_this_simulation:[expr $end_time-$start_time]" 
		close $fp_sig
	}
	
	set fp_cycle [ open "${cycle_filename}" "w" ]
	puts $fp_cycle "$i"
	puts $fp_cycle "[expr $end_time-$start_time]"
	close $fp_cycle	
	puts "--------------------------------------------------------\nOpen file: [file channels]\n.------------------------------" 
}
set fp_cycle [ open "${cycle_filename}" "w" ]
puts $fp_cycle "$i"
close $fp_cycle	

#############################################################################
######## Exit from simulation if we are in batch mode
if { "$env(GUI)" != "-gui"}  {
	compare end
	quit -f
}


