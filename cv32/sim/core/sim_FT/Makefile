###############################################################################
#
# 
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     https://solderpad.org/licenses/
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 
###############################################################################
#
# Makefile for the CV32E40P "core" testbench.  Substantially modified from the
# Makefile original for the RI5CY testbench.
#
###############################################################################
# 
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.
#
#
###############################################################################

# "Constants"
TEST_FILE=hello-world
MAKE           = make
MAKE_DIR      = $(PWD)
MAKE_PATH     := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
COREV_PROJ     = cv32
PROJ_ROOT_DIR  = $(abspath $(MAKE_PATH)/../../../..)
DATE           = $(shell date +%F)
WAVES         = 0

#a=$(shell echo $(MAKE_PATH) )
#$(info $(a))

# Compile compile flags for all simulators
SV_CMP_FLAGS = 
# vsim configuration
VVERSION  = "10.7c"

VLIB      = vlib
VWORK     = work

VLOG          = vlog
VLOG_FLAGS    = -pedanticerrors -suppress 2577 -suppress 2583
VLOG_LOG      = vloggy

VOPT          = vopt
VOPT_FLAGS    = -debugdb -fsmdebug -pedanticerrors +acc #=mnprft

VSIM              = vsim
VSIM_HOME         = /usr/pack/modelsim-$(VVERSION)-kgf/questasim
VSIM_FLAGS       ?= -nowlfcollapse -quiet # user defined
ALL_VSIM_FLAGS    = $(VSIM_FLAGS)
VSIM_DEBUG_FLAGS  = -debugdb
VSIM_GUI_FLAGS    = -gui -debugdb
VSIM_SCRIPT_DIR	  = ../../questa
VSIM_SCRIPT       = $(VSIM_SCRIPT_DIR)/vsim$(FT).tcl #cambiare con ../tools/vsim/vsim.tcl oppure creare la cartella ../questa e copiare il contenuto di vsim

SIMV                    = ./simv





# TB source files for the CV32E core
TBSRC_HOME  := $(PROJ_ROOT_DIR)/$(COREV_PROJ)/tb
TBSRC_TOP   := $(TBSRC_HOME)/core/tb_top.sv
TBSRC_CORE  := $(TBSRC_HOME)/core
TBSRC_PKG   := $(TBSRC_CORE)/tb_riscv/include/perturbation_defines.sv
TBSRC       := $(TBSRC_CORE)/tb_top.sv \
               $(TBSRC_CORE)/cv32e40p_tb_wrapper.sv \
               $(TBSRC_CORE)/mm_ram.sv \
               $(TBSRC_CORE)/dp_ram.sv \
               $(TBSRC_CORE)/tb_riscv/riscv_random_stall.sv \
               $(TBSRC_CORE)/tb_riscv/riscv_rvalid_stall.sv \
               $(TBSRC_CORE)/tb_riscv/riscv_gnt_stall.sv \
               $(TBSRC_CORE)/tb_riscv/riscv_random_interrupt_generator.sv

RTLSRC_VLOG_TB_TOP	:= $(basename $(notdir $(TBSRC_TOP)))
RTLSRC_VOPT_TB_TOP	:= $(addsuffix _vopt, $(RTLSRC_VLOG_TB_TOP))

TBSRC_VERI  := $(TBSRC_CORE)/tb_top_verilator.sv \
               $(TBSRC_CORE)/cv32e40p_tb_wrapper.sv \
               $(TBSRC_CORE)/mm_ram.sv \
               $(TBSRC_CORE)/dp_ram.sv
SIM_LIBS    := \$(PROJ_ROOT_DIR)/lib/sim_libs

# RTL source files for the CV32E core
# DESIGN_RTL_DIR is used by CV32E40P_MANIFEST file
CV32E40P_PKG         := $(PROJ_ROOT_DIR)/core-v-cores/cv32e40p$(ARCH)
CV32E40P_RTLSRC_INCDIR  := $(CV32E40P_PKG)/rtl/include
CV32E40P_RTLSRC_PKG  := $(CV32E40P_PKG)/rtl/fpnew/src/fpnew_pkg.sv \
				$(addprefix $(CV32E40P_RTLSRC_INCDIR)/,\
				cv32e40p_apu_core_package.sv cv32e40p_defines.sv \
				cv32e40p_tracer_defines.sv)
CV32E40P_RTLSRC  := $(filter-out $(CV32E40P_PKG)/rtl/cv32e40p_register_file_latch.sv, \
                $(wildcard $(CV32E40P_PKG)/rtl/*.sv))
FPNEW_PKG            := $(CV32E40P_PKG)/rtl/fpnew
# FIXME: temporarily using a local manifest for the core.
#        This is BAD PRACTICE and will be fixed with
#        https://github.com/openhwgroup/cv32e40p/pull/421 is resolved.
CV32E40P_MANIFEST    := $(CV32E40P_PKG)/cv32e40p_manifest.flist
#CV32E40P_MANIFEST    := cv32e40p_temp_manifest.flist
export DESIGN_RTL_DIR = $(CV32E40P_PKG)/rtl


### Creation of variables for benchmark tasks
STAGE ?= cv32e40p_id_stage
SV_STAGE := $(PROJ_ROOT_DIR)/core-v-cores/cv32e40p$(ARCH)/rtl/$(STAGE).sv
VLOG_SV_STAGE := $(basename $(notdir $(SV_STAGE)))
VOPT_SV_STAGE := $(addsuffix _vopt, $(VLOG_SV_STAGE))
DPILIB_VSIM_OPT := +dumpports+nocollapse

# Default "custom test-program"
CUSTOM_PROG  ?= requested_csr_por
SILENT_COMP ?= ""
SILENT_SIM ?= ""

# Shorthand rules for convience
cv32e40p_pkg: $(CV32E40P_PKG)

tbsrc_pkg: $(TBSRC_PKG)

tbsrc: $(TBSRC)

###############################################################################

SIMULATOR ?= questa

.PHONY: hello-world
hello-world: $(SIMULATOR)-hello-world

.PHONY: cv32_riscv_tests
cv32_riscv_tests: $(SIMULATOR)-cv32_riscv_tests

.PHONY: cv32_riscv_tests-gui
cv32_riscv_tests-gui: $(SIMULATOR)-cv32_riscv_tests-gui

.PHONY: cv32_riscv_compliance_tests
cv32_riscv_compliance_tests: $(SIMULATOR)-cv32_riscv_compliance_tests

.PHONY: cv32_riscv_compliance_tests-gui
cv32_riscv_compliance_tests-gui: $(SIMULATOR)-cv32_riscv_compliance_tests-gui

.PHONY: firmware
firmware: $(SIMULATOR)-firmware

.PHONY: firmware-gui
firmware-gui: $(SIMULATOR)-firmware-gui

.PHONY: unit-test
unit-test: $(SIMULATOR)-unit-test

.PHONY: unit-test-gui
unit-test-gui: $(SIMULATOR)-unit-test-gui

###############################################################################
# Common Makefile:
#    - Core Firmware and the RISCV GCC Toolchain (SDK)
#    - Variables for RTL dependencies
include $(PROJ_ROOT_DIR)/cv32/sim/core/sim_FT/Common.mk


# assume verilator if no target chosen
.DEFAULT_GOAL := sanity-questa-run

all: clean_all sanity-veri-run dsim-sanity

###############################################################################
###############################################################################
# Mentor Questasim


.lib-rtl:
	$(VLIB) $(VWORK)
	touch .lib-rtl


#a=$(shell echo "-$(CV32E40P_PKG)-$(TBSRC_PKG)-$(TBSRC)-" )
#$(info $(a))
.build-rtl: .lib-rtl $(CV32E40P_PKG) $(TBSRC_PKG) $(TBSRC)
	$(VLOG) -O0 \
		-work $(VWORK) \
		$(VLOG_FLAGS) \
		-f $(CV32E40P_MANIFEST) \
		$(TBSRC_PKG) $(TBSRC) 
		

checkout-arch: 
	$(CV32E40P_CHECKOUT_CMD)

vsim-all:  .opt-rtl 
	

.opt-rtl: .build-rtl
	$(VOPT) -work $(VWORK) $(VOPT_FLAGS) $(RTLSRC_VLOG_TB_TOP) -o $(RTLSRC_VOPT_TB_TOP)
	touch .opt-rtl
	
# run tb and exit
.PHONY: vsim-run
vsim-run: ALL_VSIM_FLAGS += -c  
vsim-run: vsim-all
	$(VSIM) -work $(VWORK) $(DPILIB_VSIM_OPT) $(ALL_VSIM_FLAGS)\
	$(RTLSRC_VOPT_TB_TOP) -do 'source $(VSIM_SCRIPT); exit -f'


# run tb and drop into interactive shell
.PHONY: vsim-run-sh
vsim-run-sh: ALL_VSIM_FLAGS += -c
vsim-run-sh: vsim-all
	$(VSIM) -work $(VWORK) $(DPILIB_VSIM_OPT) $(ALL_VSIM_FLAGS) \
	$(RTLSRC_VOPT_TB_TOP) -do $(VSIM_SCRIPT)

# run tb with simulator gui
.PHONY: vsim-run-gui
vsim-run-gui: ALL_VSIM_FLAGS += $(VSIM_GUI_FLAGS) 
vsim-run-gui: vsim-all
	$(VSIM) -work $(VWORK) $(DPILIB_VSIM_OPT) $(ALL_VSIM_FLAGS) \
	$(RTLSRC_VOPT_TB_TOP) -do $(VSIM_SCRIPT)



.PHONY: questa-hello-world
questa-hello-world: vsim-all $(CUSTOM)/hello-world/hello-world.hex
questa-hello-world: ALL_VSIM_FLAGS += +firmware=$(CUSTOM)/hello-world/hello-world.hex
questa-hello-world: vsim-run-gui &

###############################################

# General target smulation without GUI
.PHONY: questa-sim
questa-sim: checkout-arch
questa-sim: vsim-all $(TEST_FILE).hex
questa-sim: ALL_VSIM_FLAGS += +firmware=$(TEST_FILE).hex
questa-sim: ALL_VSIM_FLAGS += +dumpports+nocollapse
questa-sim: vsim-run-sh

# General target smulation with GUI
.PHONY: questa-sim-gui
questa-sim-gui: vsim-all $(TEST_FILE).hex
questa-sim-gui: ALL_VSIM_FLAGS += +firmware=$(TEST_FILE).hex
questa-sim-gui: ALL_VSIM_FLAGS += +dumpports+nocollapse
questa-sim-gui: vsim-run-gui &

# $(VSIM_GUI_FLAGS) 

.PHONY: questa-sim-stage-gui
questa-sim-stage-gui: ALL_VSIM_FLAGS += $(VSIM_GUI_FLAGS)
questa-sim-stage-gui: ALL_VSIM_FLAGS += -vcdstim ./dataset/$(GOLD_NAME)_in.vcd -debugDB
questa-sim-stage-gui: ALL_VSIM_FLAGS += +dumpports+nocollapse
questa-sim-stage-gui:
				$(VLIB) $(VWORK)
				touch .lib-rtl
				$(VLOG) -O0 -work $(VWORK)  $(VLOG_FLAGS) -f $(CV32E40P_MANIFEST)
				$(VOPT) -work $(VWORK) $(VOPT_FLAGS) $(VLOG_SV_STAGE) -o $(VOPT_SV_STAGE)
				touch .opt-rtl
				$(VSIM) -work $(VWORK) $(ALL_VSIM_FLAGS) $(VOPT_SV_STAGE) -do $(VSIM_SCRIPT)

.PHONY: questa-sim-stage
questa-sim-stage: ALL_VSIM_FLAGS += -c
questa-sim-stage: ALL_VSIM_FLAGS += -vcdstim ./dataset/$(GOLD_NAME)_in.vcd -debugDB
questa-sim-stage: ALL_VSIM_FLAGS += +dumpports+nocollapse
questa-sim-stage:
				$(VLIB) $(VWORK) $(SILENT_COMP)
				touch .lib-rtl
				$(VLOG) -O0 -work $(VWORK)  $(VLOG_FLAGS) -f $(CV32E40P_MANIFEST) $(SILENT_COMP)
				$(VOPT) -work $(VWORK) $(VOPT_FLAGS) $(VLOG_SV_STAGE) -o $(VOPT_SV_STAGE) $(SILENT_COMP)
				touch .opt-rtl
				$(VSIM) -work $(VWORK) $(ALL_VSIM_FLAGS) $(VOPT_SV_STAGE) -do $(VSIM_SCRIPT) $(SILENT_SIM)

	
###############################################

.PHONY: questa-cv32_riscv_tests
questa-cv32_riscv_tests: vsim-all $(CV32_RISCV_TESTS_FIRMWARE)/cv32_riscv_tests_firmware.hex
questa-cv32_riscv_tests: ALL_VSIM_FLAGS += +firmware=$(CV32_RISCV_TESTS_FIRMWARE)/cv32_riscv_tests_firmware.hex
questa-cv32_riscv_tests: vsim-run

.PHONY: questa-cv32_riscv_tests-gui
questa-cv32_riscv_tests-gui: vsim-all $(CV32_RISCV_TESTS_FIRMWARE)/cv32_riscv_tests_firmware.hex
questa-cv32_riscv_tests-gui: ALL_VSIM_FLAGS += +firmware=$(CV32_RISCV_TESTS_FIRMWARE)/cv32_riscv_tests_firmware.hex
questa-cv32_riscv_tests-gui: vsim-run-gui

.PHONY: questa-cv32_riscv_compliance_tests
questa-cv32_riscv_compliance_tests: vsim-all $(CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE)/cv32_riscv_compliance_tests_firmware.hex
questa-cv32_riscv_compliance_tests: ALL_VSIM_FLAGS += +firmware=$(CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE)/cv32_riscv_compliance_tests_firmware.hex
questa-cv32_riscv_compliance_tests: vsim-run

.PHONY: questa-cv32_riscv_compliance_tests-gui
questa-cv32_riscv_compliance_tests-gui: vsim-all $(CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE)/cv32_riscv_compliance_tests_firmware.hex
questa-cv32_riscv_compliance_tests-gui: ALL_VSIM_FLAGS += +firmware=$(CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE)/cv32_riscv_compliance_tests_firmware.hex
questa-cv32_riscv_compliance_tests-gui: vsim-run-gui

.PHONY: questa-firmware
questa-firmware: vsim-all $(FIRMWARE)/firmware.hex
questa-firmware: ALL_VSIM_FLAGS += +firmware=$(FIRMWARE)/firmware.hex
questa-firmware: vsim-run

.PHONY: questa-firmware-gui
questa-firmware-gui: vsim-all $(FIRMWARE)/firmware.hex
questa-firmware-gui: ALL_VSIM_FLAGS += +firmware=$(FIRMWARE)/firmware.hex
questa-firmware-gui: vsim-run-gui

.PHONY: questa-unit-test 
questa-unit-test:  firmware-unit-test-clean 
questa-unit-test:  $(FIRMWARE)/firmware_unit_test.hex 
questa-unit-test: ALL_VSIM_FLAGS += "+firmware=$(FIRMWARE)/firmware_unit_test.hex"
questa-unit-test: vsim-run

.PHONY: questa-unit-test-gui 
questa-unit-test-gui:  firmware-unit-test-clean 
questa-unit-test-gui:  $(FIRMWARE)/firmware_unit_test.hex 
questa-unit-test-gui: ALL_VSIM_FLAGS += "+firmware=$(FIRMWARE)/firmware_unit_test.hex"
questa-unit-test-gui: vsim-run-gui

questa-clean:
	if [ -d $(VWORK) ]; then rm -r $(VWORK); fi
	rm -f transcript vsim.wlf vsim.dbg trace_core*.log \
	.build-rtl .opt-rtl .lib-rtl *.vcd objdump

###############################################################################

clone_cv32e40p_rtl:
	$(CLONE_CV32E40P_CMD)

clone_fpnew_rtl: clone_cv32e40p_rtl
	$(CLONE_FPNEW_CMD)

$(CV32E40P_PKG):
	$(CLONE_CV32E40P_CMD)
	$(CLONE_FPNEW_CMD)


###############################################################################
# general targets
.PHONY: tc-clean
	
# clean up toolchain generated files (CORE_TEST_DIR defined in ../Common.mk)
tc-clean:
	find $(CORE_TEST_DIR) -name *.o       -exec rm {} \;
	find $(CORE_TEST_DIR) -name *.hex     -exec rm {} \;
	find $(CORE_TEST_DIR) -name *.elf     -exec rm {} \;
	find $(CORE_TEST_DIR) -name *.readelf -exec rm {} \;
	find $(CORE_TEST_DIR) -name *.objdump -exec rm {} \;
	find $(CORE_TEST_DIR) -name *.map     -exec rm {} \;

.PHONY: clean clean_all distclean
clean: questa-clean tc-clean verilate-clean vcs-clean firmware-clean custom-clean dsim-clean xrun-clean vcs-clean clean-bsp

distclean: clean
	rm -rf riscv-fesvr riscv-isa-sim $(CV32E40P_PKG) work

clean_all: distclean
#endend
