set CORE_V_VERIF "/home/thesis/elia.ribaldone/Desktop/core-v-verif"
set STAGE_NAME "$env(STAGE_NAME)"
set ENDSIM "$env(T_ENDSIM)"
set SWC "$env(SWC)" 
set info_filename "$env(SIM_CYCLE_NUMBER_FILE)"


run 10ns
# find real name of stage, if we simulate core we should give to comp_sim.sh
# script the name with cv32e40p (cv32e40p_core) instaead in other cases we
# only give stage name. This "if" set REAL_STAGE_NAME that should be csv32e40p_STAGENAME
if { ${STAGE_NAME} == "cv32e40p_core" } {
	set REAL_STAGE_NAME "cv32e40p_core"
} else {
	set REAL_STAGE_NAME "cv32e40p_${STAGE_NAME}"
}
puts "INFO] CORE_V_VERIF=$CORE_V_VERIF"
puts "INFO] STAGE_NAME=$STAGE_NAME"
puts "INFO] SWC=$SWC"
puts "INFO] info_filename=$info_filename"

# Find all signals that we use in fault injection
# we use _i to filter out clock and reset 

set test "register_all"

if { "$test" == "in" } {  
        set sim_fi_sig [  find nets  "sim:/${REAL_STAGE_NAME}/*_i" ]
} else {
        if { "$test" == "register_in" } {
                set sim_fi_sig [  find nets  "sim:/${REAL_STAGE_NAME}/*_i" ]
                set sim_fi_sig [ concat $sim_fi_sig [ find nets -r "sim:/${REAL_STAGE_NAME}/*_q" ] ]
                set sim_fi_sig [ concat $sim_fi_sig [ find nets -r "sim:/${REAL_STAGE_NAME}/*mem" ] ]
                set sim_fi_sig [ concat $sim_fi_sig [ find nets -r "sim:/${REAL_STAGE_NAME}/*_i/*_i" ] ]
                set sim_fi_sig [ concat $sim_fi_sig [ find nets -r "sim:/${REAL_STAGE_NAME}/*_i/*_q" ] ] 
                set sim_fi_sig [ concat $sim_fi_sig [ find nets -r "sim:/${REAL_STAGE_NAME}/*_i/*/*_i" ] ]
                set sim_fi_sig [ concat $sim_fi_sig [ find nets -r "sim:/${REAL_STAGE_NAME}/*_i/*/*_q" ] ]
                set sim_fi_sig [ concat $sim_fi_sig [ find nets -r "sim:/${REAL_STAGE_NAME}/prefetch_buffer_i/fetch_fifo_i/*_i" ] ]
                set sim_fi_sig [ concat $sim_fi_sig [ find nets -r "sim:/${REAL_STAGE_NAME}/prefetch_buffer_i/fifo_i/*_q" ] ]
        } else {
                if { "$test" == "register_compressed_decoder" } {
                        set sim_fi_sig [ find nets -r "sim:/${REAL_STAGE_NAME}/compressed_decoder_i/*_i" ]
                        set sim_fi_sig [ concat $sim_fi_sig [ find nets -r "sim:/${REAL_STAGE_NAME}/compressed_decoder_i/*_q" ]]
                        set sim_fi_sig [ concat $sim_fi_sig [ find nets -r "sim:/${REAL_STAGE_NAME}/compressed_decoder_i/*_n" ]]
                        set sim_fi_sig [ concat $sim_fi_sig [ find nets -r "sim:/${REAL_STAGE_NAME}/compressed_decoder_i/*/*" ]]
                        set sim_fi_sig [ concat $sim_fi_sig [ find nets -r "sim:/${REAL_STAGE_NAME}/compressed_decoder_i/*/*/*" ]]
               } else {
                        set sim_fi_sig [  find nets  -r "sim:/${REAL_STAGE_NAME}/*/*" ]
                        set sim_fi_sig [ concat $sim_fi_sig [ find nets -r "sim:/${REAL_STAGE_NAME}/*/*/*" ] ]
                        set sim_fi_sig [ concat $sim_fi_sig [ find nets -r "sim:/${REAL_STAGE_NAME}/*_tr" ] ]
               }
        }
}


puts "INFO: signals: $sim_fi_sig $REAL_STAGE_NAME"

# Find total number of bits in order to find adequate number of simulation
# to have a certain coverage 
set total_bit 0
foreach sig_fi $sim_fi_sig {	
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

	set vector_num 1

	if { "$graffa" == "\{" } {
		# MATRICE
		set descr [describe sim:$sig_fi]
		set exam [examine sim:$sig_fi] 
		set array_depth [ expr [llength [split $descr "y"]] -1 ]
		puts "INFO: In If signal  = $array_depth"
		for { set j 0} {$j < $array_depth} {incr j} {
			set array_dim  [ lindex [ split [ lindex $descr [expr {(int($j)*6)+4} ]] "\]" ] 0 ]

			set vector_num [expr $vector_num*$array_dim]
			puts "INFO: array_dim = $array_dim"
			set array_dim_rand [expr {int(rand())*$array_dim}]
			append sig_fi "\[$array_dim_rand\]"
			puts "INFO: appeded signal $sig_fi"
		}
		set bit_number [lindex [split [lindex [split $exam "'"] 0] "\{" ] end ]
	} 
	set total_bit [expr $total_bit+[expr $vector_num*$bit_number ]]

}

# function to calculate the number of cycle
set P 0.5
set E 0.04
set N [ expr ($total_bit/10)*$ENDSIM ]
set T 1.96
#(1.96 confidence of 95%)
#(2.5758 confidence of 99%)
#   N / (1 + (E^2)*(N-1)/(T^2*P*(P-1)))
set den [expr ( 1 + ($E*$E)*($N-1)/(($T*$T)*$P*(1-$P)) )  ]
set cycle [ expr {int($N/$den)} ]
echo "ENDSIM=$ENDSIM, total_bit:$total_bit, P: $P, E: $E, N: $N, T: $T, den: $den, cycle: $cycle"

# open file of signal in order to delete previous data
set fp_info [ open "${info_filename}" "a" ]
puts $fp_info "$SWC-$STAGE_NAME: n_bits:$total_bit n_cycles:$cycle"
close $fp_info
quit -f
