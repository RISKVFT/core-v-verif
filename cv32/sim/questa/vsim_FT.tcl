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

add wave -position insertpoint  \
sim:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/register_file_i/mem

# Definition of error type
#set default

set signal "/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i/id_stage_i/register_file_i/mem[21]"

for {set i 0} {$i < 32} {incr i} {
	set force_signal_element $signal
  	append force_signal_element "[$i]"
	puts $force_signal_element
	# This command set value to 1 @ 1000ns and release it a 1100ns
	#force -freeze  sim:$force_signal_element 1 1000 ns -cancel 1100 ns
	force -deposit  sim:$force_signal_element 1 1000 ns
}

run -all

