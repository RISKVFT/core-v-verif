###############################################################################
#
# Copyright 2020 Politecnico di Torino
# 
###############################################################################
#
# Common code for simulation Makefiles.  Intended to be included by the
# Makefiles in the "core" and "uvmt_cv32" dirs.
#
###############################################################################
# "Toolchain" to compile 'test-programs' (either C or RISC-V Assember) for the
# CV32E40P.   This toolchain is used by both the core testbench and UVM
# environment.  The assumption here is that you have installed at least one of
# the following toolchains:
#     1. GNU:   https://github.com/riscv/riscv-gnu-toolchain
#               Assumed to be installed at /opt/gnu.
#
#     2. COREV: https://www.embecosm.com/resources/tool-chain-downloads/#corev 
#               Assumed to be installed at /opt/corev.
#
#     3. PULP:  https://github.com/pulp-platform/pulp-riscv-gnu-toolchain 
#               Assumed to be installed at /opt/pulp.
#
# If you do not select one of the above options, compilation will be attempted
# using whatever is found at /opt/riscv using arch=unknown.
#

PULP_SW_TOOLCHAIN   ?= /software/pulp
#PULP_SW_TOOLCHAIN   ?= /opt/pulp
PULP_MARCH          ?= unknown

CV_SW_TOOLCHAIN  ?= /software/pulp/riscv
RISCV            ?= $(CV_SW_TOOLCHAIN)
RISCV_PREFIX     ?= riscv32-unknown-elf-
RISCV_EXE_PREFIX ?= $(RISCV)/bin/$(RISCV_PREFIX)

ifeq ($(call IS_YES,$(GNU)),YES)
RISCV            = $(GNU_SW_TOOLCHAIN)
RISCV_PREFIX     = riscv32-$(GNU_MARCH)-elf-
RISCV_EXE_PREFIX = $(RISCV)/bin/$(RISCV_PREFIX)
endif

ifeq ($(call IS_YES,$(COREV)),YES)
RISCV            = $(COREV_SW_TOOLCHAIN)
RISCV_PREFIX     = riscv32-$(COREV_MARCH)-elf-
RISCV_EXE_PREFIX = $(RISCV)/bin/$(RISCV_PREFIX)
endif

ifeq ($(call IS_YES,$(PULP)),YES)
RISCV            = $(PULP_SW_TOOLCHAIN)
RISCV_PREFIX     = riscv32-$(PULP_MARCH)-elf-
RISCV_EXE_PREFIX = $(RISCV)/bin/$(RISCV_PREFIX)
endif

CFLAGS ?= -Os -g -static -mabi=ilp32 -march=rv32imc -Wall -pedantic

# FIXME:strichmo:Repeating this code until we fully deprecate CUSTOM_PROG, hopefully next PR
ifeq ($(firstword $(subst _, ,$(CUSTOM_PROG))),pulp)
  CFLAGS = -Os -g -D__riscv__=1 -D__LITTLE_ENDIAN__=1 -march=rv32imcxpulpv2 -Wa,-march=rv32imcxpulpv2 -fdata-sections -ffunction-sections -fdiagnostics-color=always
endif

ifeq ($(firstword $(subst _, ,$(TEST))),pulp)
  CFLAGS = -Os -g -D__riscv__=1 -D__LITTLE_ENDIAN__=1 -march=rv32imcxpulpv2 -Wa,-march=rv32imcxpulpv2 -fdata-sections -ffunction-sections -fdiagnostics-color=always
endif

# CORE FIRMWARE vars. All of the C and assembler programs under CORE_TEST_DIR
# are collectively known as "Core Firmware".  Yes, this is confusing because
# one of sub-directories of CORE_TEST_DIR is called "firmware".
#
# Note that the DSIM targets allow for writing the log-files to arbitrary
# locations, so all of these paths are absolute, except those used by Verilator.
# TODO: clean this mess up!
PROJ_ROOT_DIR			     = ./../../../..
CORE_TEST_DIR                        = $(PROJ_ROOT_DIR)/cv32/tests/programs/mibench/general_test
#BSP                                  = $(PROJ_ROOT_DIR)/cv32/bsp
BSP			             = /home/thesis/luca.fiore/Repos/core-v-verif/cv32/bsp
FIRMWARE                             = $(CORE_TEST_DIR)/firmware
VERI_FIRMWARE                        = ../../tests/core/firmware
CUSTOM                               = $(CORE_TEST_DIR)
CUSTOM_DIR                          ?= $(CUSTOM)
CUSTOM_PROG                         ?= my_hello_world
VERI_CUSTOM                          = ../../tests/programs/custom
ASM                                  = $(CORE_TEST_DIR)/asm
ASM_DIR                             ?= $(ASM)
ASM_PROG                            ?= my_hello_world
CV32_RISCV_TESTS_FIRMWARE            = $(CORE_TEST_DIR)/cv32_riscv_tests_firmware
CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE = $(CORE_TEST_DIR)/cv32_riscv_compliance_tests_firmware
RISCV_TESTS                          = $(CORE_TEST_DIR)/riscv_tests
RISCV_COMPLIANCE_TESTS               = $(CORE_TEST_DIR)/riscv_compliance_tests
RISCV_TEST_INCLUDES                  = -I$(CORE_TEST_DIR)/riscv_tests/ \
                                       -I$(CORE_TEST_DIR)/riscv_tests/macros/scalar \
                                       -I$(CORE_TEST_DIR)/riscv_tests/rv64ui \
                                       -I$(CORE_TEST_DIR)/riscv_tests/rv64um
CV32_RISCV_TESTS_FIRMWARE_OBJS       = $(addprefix $(CV32_RISCV_TESTS_FIRMWARE)/, \
                                         start.o print.o sieve.o multest.o stats.o)
CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE_OBJS = $(addprefix $(CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE)/, \
                                              start.o print.o sieve.o multest.o stats.o)
RISCV_TESTS_OBJS         = $(addsuffix .o, \
                             $(basename $(wildcard $(RISCV_TESTS)/rv32ui/*.S)) \
                             $(basename $(wildcard $(RISCV_TESTS)/rv32um/*.S)) \
                             $(basename $(wildcard $(RISCV_TESTS)/rv32uc/*.S)))
FIRMWARE_OBJS            = $(addprefix $(FIRMWARE)/, \
                             start.o print.o sieve.o multest.o stats.o)
FIRMWARE_TEST_OBJS       = $(addsuffix .o, \
                             $(basename $(wildcard $(RISCV_TESTS)/rv32ui/*.S)) \
                             $(basename $(wildcard $(RISCV_TESTS)/rv32um/*.S)) \
                             $(basename $(wildcard $(RISCV_TESTS)/rv32uc/*.S)))
FIRMWARE_SHORT_TEST_OBJS = $(addsuffix .o, \
                             $(basename $(wildcard $(RISCV_TESTS)/rv32ui/*.S)) \
                             $(basename $(wildcard $(RISCV_TESTS)/rv32um/*.S)))
COMPLIANCE_TEST_OBJS     = $(addsuffix .o, \
                             $(basename $(wildcard $(RISCV_COMPLIANCE_TESTS)/*.S)))


# Thales verilator testbench compilation start

SUPPORTED_COMMANDS := vsim-firmware-unit-test questa-unit-test questa-unit-test-gui dsim-unit-test vcs-unit-test
SUPPORTS_MAKE_ARGS := $(filter $(firstword $(MAKECMDGOALS)), $(SUPPORTED_COMMANDS))

ifneq "$(SUPPORTS_MAKE_ARGS)" ""
  UNIT_TEST := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(UNIT_TEST):;@:)
  UNIT_TEST_CMD := 1
else 
 UNIT_TEST_CMD := 0
endif

COMPLIANCE_UNIT_TEST = $(subst _,-,$(UNIT_TEST))

FIRMWARE_UNIT_TEST_OBJS   =  	$(addsuffix .o, \
				$(basename $(wildcard $(RISCV_TESTS)/rv32*/$(UNIT_TEST).S)) \
				$(basename $(wildcard $(RISCV_COMPLIANCE_TESTS)*/$(COMPLIANCE_UNIT_TEST).S)))

###############################################################################
# Read YAML test specifications

# If the gen_corev-dv target is defined then read in a test specification file
YAML2MAKE = $(PROJ_ROOT_DIR)/bin/yaml2make
ifneq ($(filter gen_corev-dv,$(MAKECMDGOALS)),)
ifeq ($(TEST),)
$(error ERROR must specify a TEST variable with gen_corev-dv target)
endif
GEN_FLAGS_MAKE := $(shell $(YAML2MAKE) --test=$(TEST) --yaml=corev-dv.yaml --debug --prefix=GEN)
ifeq ($(GEN_FLAGS_MAKE),)
$(error ERROR Could not find corev-dv.yaml for test: $(TEST))
endif
include $(GEN_FLAGS_MAKE)
endif

# If the test target is defined then read in a test specification file
TEST_YAML_PARSE_TARGETS=test waves cov
ifneq ($(filter $(TEST_YAML_PARSE_TARGETS),$(MAKECMDGOALS)),)
ifeq ($(TEST),)
$(error ERROR must specify a TEST variable)
endif
TEST_FLAGS_MAKE := $(shell $(YAML2MAKE) --test=$(TEST) --yaml=test.yaml --debug --run-index=$(RUN_INDEX) --prefix=TEST)
ifeq ($(TEST_FLAGS_MAKE),)
$(error ERROR Could not find test.yaml for test: $(TEST))
endif
include $(TEST_FLAGS_MAKE)
endif

# If a test target is defined and a CFG is defined that read in build configuration file
# CFG is optional
CFGYAML2MAKE = $(PROJ_ROOT_DIR)/bin/cfgyaml2make
CFG_YAML_PARSE_TARGETS=comp test
ifneq ($(filter $(CFG_YAML_PARSE_TARGETS),$(MAKECMDGOALS)),)
ifneq ($(CFG),)
CFG_FLAGS_MAKE := $(shell $(CFGYAML2MAKE) --yaml=$(CFG).yaml --debug --prefix=CFG)
ifeq ($(CFG_FLAGS_MAKE),)
$(error ERROR Error finding or parsing configuration: $(CFG).yaml)
endif
include $(CFG_FLAGS_MAKE)
endif
endif

#endend
