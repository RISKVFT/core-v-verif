#!/usr/bin/python3

import os
import sys
from subprocess import Popen

if not os.path.exists('out'):
    os.mkdir("out")

TOPDIR = os.path.abspath(os.path.dirname(__file__))
CORE_V_VERIF="/home/luca.fiore/Repos/core-v-verif"

# If any folders need prepending to the path for a given configuration, then
# edit the appropriate value in here. If no additional paths need prepending
# for a given configuration, use the empty string ''.
toolchain_paths ='/software/pulp/riscv/bin'
#toolchain_paths ='/home/thesis/luca.fiore/Desktop/riscv/bin'


# The compiler flags for each configuration are given here. Some compilers
# require more flags than others in order to successfully compile for their
# target, but all us `-Os` in order to generate code optimised for size.
toolchain_args = '-Os -g -static -mabi=ilp32 -march=rv32imc -Wall -pedantic'


# The name of the compiler for each configuration.
toolchain_cc = 'riscv32-unknown-elf-gcc'
#toolchain_cc = '/home/thesis/luca.fiore/Desktop/riscv/bin'



def make_env():
    e = os.environ.copy()
    e['PATH'] = '%s:%s' % (toolchain_paths, os.environ['PATH'])
    e['TGT'] = "elf"
    e['OPT'] = toolchain_args
    e['CC'] = toolchain_cc
    e['BSP'] = '%s/cv32/bsp' % CORE_V_VERIF
    #e['LD'] = "-nostartfiles -T ${BSP}/link.ld -L ${BSP} -lcv-verif"
    e['LD'] = "-nostartfiles --specs=nosys.specs -nostdlib -L ${BSP} -lcv-verif -Wl,--start-group -lc -lgcc -lc -lm -Wl,--end-group -L ${BSP} -lcv-verif -T ${BSP}/link.ld"
    return e




env = make_env()
args = ['make']
proc = Popen(args, env=env, cwd=TOPDIR)
retcode = proc.wait()
if retcode != 0:
	raise RuntimeError("Make failed with retcode %s" % ( retcode))

def get_script_path():
	return os.path.dirname(os.path.realpath(sys.argv[0]))


os.chdir(get_script_path()+"/out")

for hexfile in os.listdir("."):	
	if ".elf" in hexfile:
		cmd="{0}objcopy -O verilog {1}.elf {1}.hex \
		--change-section-address  .debugger=0x3FC000\
		 --change-section-address  .debugger_exception=0x3FC800".\
		format(toolchain_paths+"/"+toolchain_cc[0:-3],hexfile[0:-4])
		os.system(cmd)








