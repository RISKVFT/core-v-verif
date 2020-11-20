# Copyright 2018 ETH Zurich and University of Bologna.
# Copyright and related rights are licensed under the Solderpad Hardware
# License, Version 0.51 (the "License"); you may not use this file except in
# compliance with the License.  You may obtain a copy of the License at
# http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
# or agreed to in writing, software, hardware and materials distributed under
# this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.

# Author: Robert Balas (balasr@student.ethz.ch)
# Description: TCL scripts to facilitate simulations

set CORE_V_VERIF "/home/thesis/elia.ribaldone/Desktop/core-v-verif"
#add wave -position insertpoint  \
#sim:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/register_file_i/mem

# Definition of error type
#set default

#set signal "/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/register_file_i/mem[5]"

#log -out /tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/ex_stage_i/*
add wave /*
set signal "/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/ex_stage_i/alu_result"
for {set t 0} {$t < 1} {incr t} {
	for {set i 0} {$i < 32} {incr i} {
		set force_signal_element $signal
		append force_signal_element "[$i]"
		puts $force_signal_element
		# This command set value to 1 @ 1000ns and release it a 1100ns
		#force -freeze  sim:$force_signal_element 1 1000 ns -cancel 1100 ns
		#force -freeze  sim:$force_signal_element 1 1000, 0 1050 -r 2000 
		#force -deposit  sim:$force_signal_element 1 1000 ns
	}
}

#ls $CORE_V_VERIF/cv32/sim/core/sim_FT
#set list_ex [view list -new -title list_ex]
#add list -out tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/ex_stage_i/*
#set list_id [view list -new -title list_id]
#add list -window $list_id \
	-out tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/*
run 0ns
run -all
#write list -window $list_ex \
#	$CORE_V_VERIF/cv32/sim/core/sim_FT/saved_signals/ex_stage_FT.lst
#write list $CORE_V_VERIF/cv32/sim/core/sim_FT/saved_signals/id_stage_FT.lst


#ls $CORE_V_VERIF/cv32/sim/core/sim_FT
#ls .
#pwd
