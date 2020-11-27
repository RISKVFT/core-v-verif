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
###############################################################################
# Variables to determine the the command to clone external repositories.
# For each repo there are a set of variables:
#      *_REPO:   URL to the repository in GitHub.
#      *_BRANCH: Name of the branch you wish to clone;
#                Set to 'master' to pull the master branch.
#      *_HASH:   Value of the specific hash you wish to clone;
#                Set to 'head' to pull the head of the branch you want.
#      *_TAG:    Not yet supported (TODO).
#                

CV32E40P_REPO ?= https://github.com/RISKVFT/cv32e40p.git
#CV32E40P_REPO   ?= https://github.com/RISKVFT/cv32e40p.git
CV32E40P_BRANCH ?= master
#CV32E40P_BRANCH ?= FT_Marcello
#2020-10-08
CV32E40P_HASH   ?= head

FPNEW_REPO      ?= https://github.com/pulp-platform/fpnew.git
FPNEW_BRANCH    ?= master
#2020-09-23
FPNEW_HASH      ?= a0c021c360abcc94e434d41974a52bdcbf14d156

RISCVDV_REPO    ?= https://github.com/google/riscv-dv
#RISCVDV_REPO    ?= https://github.com/MikeOpenHWGroup/riscv-dv
RISCVDV_BRANCH  ?= master
# May 2 version of riscv-dv.  Later versions have had known randomization errors
#RISCVDV_HASH    ?= c37c5f3f57ac61991aa5abd614badb367c5d025d
# July 8 version.  Randomization errors have significantly improved.
#                  Generation of riscv_pmp_test fails (we do not care for CV32E40P).
RISCVDV_HASH    ?= 10fd4fa8b7d0808732ecf656c213866cae37045a

COMPLIANCE_REPO   ?= https://github.com/riscv/riscv-compliance
COMPLIANCE_BRANCH ?= master
# 2020-08-19
COMPLIANCE_HASH   ?= c21a2e86afa3f7d4292a2dd26b759f3f29cde497

# Generate command to clone the CV32E40P RTL
ifeq ($(CV32E40P_BRANCH), master)
  TMP = git clone $(CV32E40P_REPO) --recurse $(CV32E40P_PKG)
else
  #ifeq (, $(wildcard $(PROJ_ROOT_DIR)/core-v-cores/cv32e40p)) # If the directory doesn't esist
  	TMP = git clone -b $(CV32E40P_BRANCH) --single-branch $(CV32E40P_REPO) --recurse $(CV32E40P_PKG)
  #else
  	#TMP = git --git-dir=$(CV32E40P_PKG)/.git --work-tree=$(CV32E40P_PKG) checkout $(CV32E40P_BRANCH)  
  #endif
endif

ifeq ($(CV32E40P_HASH), head)
  CLONE_CV32E40P_CMD = $(TMP)
else
  CLONE_CV32E40P_CMD = $(TMP); cd $(CV32E40P_PKG); git checkout $(CV32E40P_HASH)
endif
a=$(shell echo $(CV32E40P_BRANCH))
$(info "$a -----------------------------------------------------------------------------------------------------------------------_")

# Generate command to clone the FPNEW RTL
ifeq ($(FPNEW_BRANCH), master)
  TMP2 = git clone $(FPNEW_REPO) --recurse $(FPNEW_PKG)
else
  TMP2 = git clone -b $(FPNEW_BRANCH) --single-branch $(FPNEW_REPO) --recurse $(FPNEW_PKG)
endif

ifeq ($(FPNEW_HASH), head)
  CLONE_FPNEW_CMD = $(TMP2)
else
  CLONE_FPNEW_CMD = $(TMP2); cd $(FPNEW_PKG); git checkout $(FPNEW_HASH)
endif
# RTL repo vars end

# Generate command to clone RISCV-DV (Google's random instruction generator)
ifeq ($(RISCVDV_BRANCH), master)
  TMP3 = git clone $(RISCVDV_REPO) --recurse $(RISCVDV_PKG)
else
  TMP3 = git clone -b $(RISCVDV_BRANCH) --single-branch $(RISCVDV_REPO) --recurse $(RISCVDV_PKG)
endif

ifeq ($(RISCVDV_HASH), head)
  CLONE_RISCVDV_CMD = $(TMP3)
else
  CLONE_RISCVDV_CMD = $(TMP3); cd $(RISCVDV_PKG); git checkout $(RISCVDV_HASH)
endif
# RISCV-DV repo var end

# Generate command to clone the RISCV Compliance Test-suite
ifeq ($(COMPLIANCE_BRANCH), master)
  TMP4 = git clone $(COMPLIANCE_REPO) --recurse $(COMPLIANCE_PKG)
else
  TMP4 = git clone -b $(COMPLIANCE_BRANCH) --single-branch $(COMPLIANCE_REPO) --recurse $(COMPLIANCE_PKG)
endif

ifeq ($(COMPLIANCE_HASH), head)
  CLONE_COMPLIANCE_CMD = $(TMP4)
else
  CLONE_COMPLIANCE_CMD = $(TMP4); cd $(COMPLIANCE_PKG); git checkout $(COMPLIANCE_HASH)
endif

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
GNU_SW_TOOLCHAIN    ?= /opt/gnu
GNU_MARCH           ?= unknown
COREV_SW_TOOLCHAIN  ?= /opt/corev
COREV_MARCH         ?= corev
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
CORE_TEST_DIR                        = $(PROJ_ROOT_DIR)/cv32/tests/programs/mibench/general_test
BSP                                  = $(PROJ_ROOT_DIR)/cv32/bsp
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

# Thales verilator testbench compilation end

###############################################################################
# The sanity rule runs whatever is currently deemed to be the minimal test that
# must be able to run (and pass!) prior to generating a pull-request.
sanity: hello-world

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
