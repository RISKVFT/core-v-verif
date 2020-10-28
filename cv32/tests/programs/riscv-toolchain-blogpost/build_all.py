#!/usr/bin/python3

import os
from subprocess import Popen

TOPDIR = os.path.abspath(os.path.dirname(__file__))

# The list of configurations that will be built. Delete any from this list that
# you're not interested in.
configurations = [ 'riscv32gcc']


# If any folders need prepending to the path for a given configuration, then
# edit the appropriate value in here. If no additional paths need prepending
# for a given configuration, use the empty string ''.
toolchain_paths = {
    # RISC-V 32
    'riscv32gcc': '/software/pulp/riscv/bin',

}


# The compiler flags for each configuration are given here. Some compilers
# require more flags than others in order to successfully compile for their
# target, but all us `-Os` in order to generate code optimised for size.
toolchain_args = {
    # RISC-V 32
    # -m32 -march=RV32IC to generate code for RISC-V 32 base integer
    # architecture with the compressed instruction extension
    'riscv32gcc': '-Os -g -static -mabi=ilp32 -march=rv32imc -Wall -pedantic'
}


# The name of the compiler for each configuration.
toolchain_cc = {
    'riscv32gcc': 'riscv32-unknown-elf-gcc'
}



def make_env(config):
    e = os.environ.copy()
    e['PATH'] = '%s:%s' % (toolchain_paths[config], os.environ['PATH'])
    e['TGT'] = config
    e['OPT'] = toolchain_args[config]
    e['CC'] = toolchain_cc[config]
    e['BSP'] = '%s/../../../bsp' % os.getcwd()
    e['LD'] = "-nostartfiles -T ${BSP}/link.ld  -L ${BSP} -lcv-verif"
    return e



for config in configurations:
    env = make_env(config)
    args = ['make']
    proc = Popen(args, env=env, cwd=TOPDIR)
    retcode = proc.wait()
    print("fanccccccccccccccccccc")
    if retcode != 0:
        raise RuntimeError("Make failed with retcode %s" % ( retcode))
