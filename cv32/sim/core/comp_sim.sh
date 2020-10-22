#!/bin/bash

UsageExit () {
	echo "Help of ..."
	exit 1
}

TEMP=`getopt -o hd:t:c:s: --long help,default-test-dir:,test-dir:,compile:,simulation: -- "$@"`
eval set -- "$TEMP"
echo $TEMP
## General variable
CUR_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
SIM_FT="$CUR_DIR/sim_FT"

## Variable for parametrization
COMPILE=0
COMPILE_FILE="" # file to compile *.c without extension
SIMULATION=0
SIMULATION_FILE="" # file to simulate *.hex without extension
TEST_DIR="$CUR_DIR/../../tests/programs/custom_FT"

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
			COMPILE=1
			shift
			COMPILE_FILE=$1
			shift
			;;
		-s|--simulation)
			SIMULATION=1
			shift
			if [[ $COMPILE -ne 1 ]]; then
				SIMULATION_FILE=$1
			else
				SIMULATION_FILE=$COMPILE_FILE
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
# 
source /software/europractice-release-2019/scripts/init_questa10.7c
if [[ $COMPILE -eq 1 ]]; then
	echo "huquin"
	make -C $SIM_FT compile TEST_FILE="$TEST_DIR/$COMPILE_FILE/$COMPILE_FILE"
fi

if [[ $SIMULATION -eq 1 ]]; then
	make -C $SIM_FT questa-sim TEST_FILE="$TEST_DIR/$SIMULATION_FILE/$SIMULATION_FILE"
fi
