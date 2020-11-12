#!/bin/bash
CORE_V_VERIF="/home/thesis/elia.ribaldone/Desktop/core-v-verif"

red="\e[0;91m\e[1m"
reset="\e[0m"


UsageExit () {
	echo '
Program Usage:
-h|--help)
	UsageExit
-f|--file-vsim suffix
	FAULT_INJECTION=suffix --> is the name suffix of the .tcl script used in the Makefile--> vsim_$(FT).tcl

-d|--default-test-dir absolute_path
	TEST_DIR=absolute_path --> change permanently default directory absolute path

-t|--test-dir absolute_path
	TEST_DIR=absolute_path --> use new directory absolute path

-c|--compile filename
	COMPILATION=1
	COMPILATION_FILE=filename --> relative name of application without extension.
				      Launch Makefile in sim_FT that runs compile.sh

-s|--simulation [filename]
	Start Questasim simulation: run Makefile in sim_FT that runs simulation.

-g|--gui)
	GUI=-gui --> if -g then use Questasim GUI

-k|--kompile_simulate filename
	Compilation and simulation: insert filename for the application to compile and simulate;
-v|--verbose)
	verbose prints				

Usage example:
1) set default application dir: 
	./comp_sim.sh -d /abs/path/to/test/dir
2) compile only: 
	./comp_sim.sh -c /abs/path/to/test/dir
3) simulate only hello_world.c with GUI: 
	./comp_sim.sh -s hello_world -g
4) compile and simulate hello_world.c: 
	./comp_sim.sh -k hello_world
'
	exit 1
}


vecho() {
	if [[ $VERBOSE ]]; then
		echo -e "${red}${1}${reset}"
	fi 
}

# Replace default TEST_DIR with desired directory 
replace_TEST_DIR () {
	awk -v old="^TEST_DIR=\".*\"" -v new="TEST_DIR=\"$2\"" \
	'{if ($0 ~ old) \
			print new; \
		else \
			print $0}' \
	 $1 > $1.t
	 mv $1{.t,}
	 chmod 777 $1
}

FileToPath (){
	# $1 path in which find
	# $2 filename to find
	# find the corect path and return it
	var=$(find $1 -name "$2.[c\|S]")
	#l=$(( ${#var}-${#3}-1 ))
	#echo ${var:0:$l}
	echo $(dirname $var)
}

TEMP=`getopt -o hf:d:t:c:s:gk:vb --long help,file-vsim,default-test-dir:,test-dir:,compile:,simulation:,gui,kompile_simulate:,verbose,benchmark -- "$@"`
eval set -- "$TEMP"

## General variable
CUR_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
SIM_FT="$CUR_DIR/sim_FT"

## Variable for parametrization
COMPILATION=0
COMPILATION_FILE="" # file to compile *.c without extension
SIMULATION=0
SIMULATION_FILE="" # file to simulate *.hex without extension
TEST_DIR="/home/thesis/luca.fiore/Repos/core-v-verif/cv32/sim/core/../../tests/programs/mibench/general_test"
#TEST_DIR="$CUR_DIR/../../tests/programs/MiBench/"
#TEST_DIR="$CUR_DIR/../../tests/programs/riscv-toolchain-blogpost/out"
BENCHMARK_DIR="$CUR_DIR/../../tests/programs/mibench"
FAULT_INJECTION=""
GUI=""
VERBOSE=0
BENCHMARK=0

while true; do
	case $1 in
		-h|--help)
			UsageExit 		
			shift	
			;;
		-f|--file-vsim)
			shift
			FAULT_INJECTION="_$1"
			shift
			;;
		-d|--default-test-dir)
			shift
			replace_TEST_DIR "$CUR_DIR/$(basename $0)" $1
			TEST_DIR=$1
			shift
			;;
		-t|--test-dir)
			shift
			TEST_DIR=$1
			shift
			;;
		-c|--compile)
			COMPILATION=1
			shift
			COMPILATION_FILE=$1
			shift
			;;
		-s|--simulation)
			SIMULATION=1
			shift
			if [[ $COMPILATION -ne 1 ]]; then
				SIMULATION_FILE=$1
				shift
			else
				SIMULATION_FILE=$COMPILATION_FILE
			fi
			;;
		-k|--kompile_simulate)
			shift
			COMPILATION=1
			SIMULATION=1
			COMPILATION_FILE=$1
			SIMULATION_FILE=$COMPILATION_FILE
			shift			
			;;
		-g|--gui)
			GUI="-gui"
			shift
			;;
		-v|--verbose)
			VERBOSE=1
			shift
			;;
		-b|--benchmark)
			shift			
			BENCHMARK=1	
			;;	
		--)
			break;;
		*)
			echo "Wrong argument!!!!"
			UsageExit
			;;
	esac
done

vecho $TEMP

if [[ $COMPILATION -eq 1 ]]; then
	# full compilation path without extension
	vecho "$TEST_DIR $COMPILATION_FILE"
	# PATH/file to compile without c extension
	FULL_CPATH=$(FileToPath $TEST_DIR $COMPILATION_FILE)
	vecho "path to file: $FULL_CPATH"
	#make -C $SIM_FT compile TEST_FILE="$FULL_FILE_CPATH"
	make -C $FULL_CPATH -f $SIM_FT/Makefile_Compile.mk
fi
if [[ $SIMULATION -eq 1 ]]; then
	source /software/europractice-release-2019/scripts/init_questa10.7c	
	# full simulation path without extension 
	FULL_FILE_SPATH=$(FileToPath $TEST_DIR $SIMULATION_FILE "c")
	make -C $SIM_FT questa-sim$GUI TEST_FILE="$FULL_FILE_SPATH" FT="$FAULT_INJECTION"	
fi

#benchmarking 
if [[ $BENCHMARK -eq 1 ]]; then
	cd $BENCHMARK_DIR 
	./build_all.py
fi







