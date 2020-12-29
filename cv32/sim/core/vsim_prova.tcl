puts "INFO: cycle $i"

	# we log ouput signals of current simulation
	# -r for log all signals
	log "sim:/${REAL_STAGE_NAME}/*_o"
	
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
	########à## fault inietato è stato corretto  detectato non sentito etc.
	
	if { $FI == 1 } {
		# index of signal in which inject signal
		set sig_index [ expr {int(rand()*$len_sim_fi_sig)} ]
		puts "INFO: Signal index = $sig_index"
		# Find signal in which inject fault
		#set sig_fi [lindex $sim_fi_sig $sig_index]
		set sig_fi "/cv32e40p_id_stage/HWLOOP_REGS/hwloop_regs_i/hwlp_end_q"
		puts "INFO: signal name = $sig_fi"
		# Find instant time in which inject, this instant
		# will be selected between 0 and ENDSIM/2
		set fi_instant [expr {int(rand()*($ENDSIM-2*10))} ]	
		puts "INFO: Instant = $fi_instant"

		# Now if the signal have multiple bit we should cycle
		# otherwise we simple assign it
		set bit_number [lindex [ split [ examine sim:$sig_fi] "'" ] 0 ]
		puts "INFO: Bit number = $bit_number"
		
		set graffa [string index $bit_number 0]
		if { "$graffa" == "{" } {
			# MATRICE
			set descr [describe sim:$sig_fi]
			set exam [examine sim:$sig_fi]
			set array_depth [ expr [llength [split $descr "y"]] -1 ]
			for { set i 0} {$i < $array_depth} {incr i} {
				set array_dim  [ lindex $descr [expr $i*6+4 ]]
				set array_dim_rand [expr {int(rand()*$array_dim)}]
				append $sig_fi "\[$array_dim_rand\]"
			}
			set bit_number [lindex [split [lindex [split $exam "'"] 0] "{" ] end ]
		} 
		puts "INFO: Signal name  = $sig_fi"
		set bit_choose [expr {int(rand()*$bit_number)}] 
		puts "INFO: Bit choose = $bit_choose"
		# find bit to flip in binary string
		set bit_value [string index [lindex [ split [examine -binary sim:$sig_fi] "b" ] 1 ] $bit_choose ]
		puts "INFO: row number = $row_number"
		
		force -deposit "$sig_fi\[$bit_number\]" [expr ($bit_value+1)%2 ] $fi_instant
	}

	run -all


	##################################################################
	####### Open gold simpulation 

	dataset open ./dataset/${GOLD_NAME}_out.wlf

	set GOutSignals [ find nets  "${GOLD_NAME}_out:/$SIM_BASE/${STAGE_NAME}_i/*_o" ]
	set GInSignals [ find nets "${GOLD_NAME}_out:/$SIM_BASE/${STAGE_NAME}_i/*_i" ]

	#################################################################
	###### Begin comparation between gold and current simulation

	compare start ${GOLD_NAME}_out sim

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

	# Set end of comparison and start to compare
	puts "Simulation tcl time $ENDSIM"
	compare run 0 ${ENDSIM}

	##############################################################################
	###### Save error if there are

	set compare_filename "$env(COMPARE_ERROR_FILE)"
	puts "Compare error filename: ${compare_filename}"

	# Find error number
	set comp_info [ lindex [ compare info ] 12 ]

	# If there is at least an error we open error file, read current number of error
	# and increment it
	if { "$comp_info" != "0" } {
		set fp_compare [ open "${compare_filename}" "r" ]
		set num_error [ expr [ gets $fp_compare ] +1 ]
		close $fp_compare
		set fp_compare [ open "${compare_filename}" "w+" ]
		puts $fp_compare $num_error
		close $fp_compare	
	}

	if {$FI > 0} {
		compare end
		restart -force
	}
