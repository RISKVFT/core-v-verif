#!/bin/bash
CORE_V_VERIF="/home/thesis/elia.ribaldone/Desktop/core-v-verif"

UsageExit () {
	echo "Help of ..."
	exit 1
}

FileToPath (){
	# $1 path in which find
	# $2 filename to find
	# find the corect path and return it
	var=$(find $1 -name "$2.c")
	l=$(( ${#var}-2 ))
	echo ${var:0:$l}
}

TEMP=`getopt -o hd:t:c:s: --long help,default-test-dir:,test-dir:,compile:,simulation: -- "$@"`
eval set -- "$TEMP"
echo $TEMP
## General variable
CUR_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
SIM_FT="$CUR_DIR/sim_FT"

## Variable for parametrization
COMPILATION=0
COMPILATION_FILE="" # file to compile *.c without extension
SIMULATION=0
SIMULATION_FILE="" # file to simulate *.hex without extension
#TEST_DIR="$CUR_DIR/../../tests/programs/custom_FT"
TEST_DIR="Ciao"


while true; do
	case $1 in
		-h|--help)
			UsageExit 		
			shift	
			;;
		-d|--default-test-dir)
			shift
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
			else
				SIMULATION_FILE=$COMPILATION_FILE
			fi
			shift
			;;
		--)
			break;;
		*)
			echo "Wrong argument!!!!"
			UsageExit
			;;
	esac
done


source /software/europractice-release-2019/scripts/init_questa10.7c

if [[ $COMPILATION -eq 1 ]]; then
	# full compilation path without extension
	echo "$TEST_DIR $COMPILATION_FILE"
	FULL_FILE_CPATH=$(FileToPath $TEST_DIR $COMPILATION_FILE)
	make -C $SIM_FT compile TEST_FILE="$FULL_FILE_CPATH"
fi

if [[ $SIMULATION -eq 1 ]]; then	
	# full simulation path without extension 
	FULL_FILE_SPATH=$(FileToPath $TEST_DIR $SIMULATION_FILE)	
	make -C $SIM_FT questa-sim TEST_FILE="$FULL_FILE_SPATH"
fi
