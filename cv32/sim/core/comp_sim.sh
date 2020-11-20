#!/bin/bash

source ccommon.sh

CORE_V_VERIF="/home/thesis/elia.ribaldone/Desktop/core-v-verif"

isnumber='^[0-9]+$'

vecho() { if [[ $VERBOSE ]]; then echo -e "${red}${1}${reset}";fi }
db_recho() { if [[ $VERBOSE ]]; then echo -e "${red}${bold}${1}${reset}"; fi }
db_becho() { if [[ $VERBOSE ]]; then echo -e "${blue}${bold}${1}${reset}"; fi }
db_gecho() { if [[ $VERBOSE ]]; then echo -e "${green}${bold}${1}${reset}"; fi }
db_lgecho() { if [[ $VERBOSE ]]; then lgecho "$1"; fi }

## General variable
CUR_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
SIM_FT="$CUR_DIR/sim_FT"

## Variable for parametrization
BENCHMARK=0
UNIQUE_FILE=0

COMPILATION=0
SIMULATION=0

# Folder that contain *.c file (and after compilation the *.hex file) of
# unique program to use as architecture firmware
UNIQUE_CHEX_DIR="/home/thesis/elia.ribaldone/Desktop/core-v-verif/cv32/tests/programs/custom_FT/hello-world"
U_LOG_DIR=" "

# Folder that contain the build_all.py program runned to compile all benchmark
BENCH_BUILD_FILE="/home/thesis/elia.ribaldone/Desktop/core-v-verif/cv32/tests/programs/mibench/build_all.py"
# Folder that contain *.hex file of benchmar
BENCH_HEX_DIR="/home/thesis/elia.ribaldone/Desktop/core-v-verif/cv32/tests/programs/mibench/out"
B_TYPE=" "
B_FILE=" "
B_NUM=0
B_LOG_DIR="/home/thesis/elia.ribaldone/Desktop/core-v-verif/cv32/sim/core/bench_log"

# common parameter
CHEX_FILE=" "
VSIM_EXT=""
GUI=""
VERBOSE=1

#TEST_DIR="$CUR_DIR/../../tests/programs/MiBench/"
#TEST_DIR="$CUR_DIR/../../tests/programs/riscv-toolchain-blogpost/out"

# vector of parameter -[a-zA-Z]
par=$(echo "$@" | awk 'BEGIN{RS=" "};{if ($0 ~ /^-[a-zA-Z]*$/) print $0; if ($0 ~ /^-[a-zA-Z]*\n/) print $0}')
echo $par
for p1 in $par; do
	case $p1 in
		-h|--help)
			UsageExit 		
			shift	
			;;
		-g|--gui)
			db_becho "Set Gui"
			GUI=-gui
			shift
			;;
		-q|--quiet)
			VERBOSE=0
			shift
			;;
		-u|--unique-program)
			# BASE:
			#   cf    only compilation "-u cf filename"
			#   sf	  only compilation "-u sf filename"
			#   csf   both "-u csf filename"
			# 
			# OPTIONAL OPTIONS:
			#   fv   only comp, with file vsim setted"-u cfv filename vsimfile" o
			#   vf	             	  		   "-u cvf vsimfile filename"
			#      	 only sim, with file vsim settato "-u sfv filename vsimfile" o
			#				 	 "-u svf vsimfile filename"
			# 	 both with file vsim setted "-u csvf vsimfile filename" o
			#				  	"-u csfv filename vsimfile"
			# OPTIONS MANDATORY FOR THE FIRST RUN
			#   d    directory of c and hex file "-u cvfd vsimfile filename dirname"
			#   l    directory in which save log file of unique elaboration
			#	
			# SCRIPT PARAMETER
			#	COMPILATION
			#	SIMULATION
			# 	CHEX_FILE
			#	VSIM_EXT
			#	UNIQUE_CHEX_DIR

			UNIQUE=1
			shift # delete -u
			arg=$1
			shift # delete args string
			
			# cycle on args string
			for (( i=0; i< ${#arg}; i++ )) ; do
				case ${arg:i:1} in
					c) # case like "-u cf filename" only compilation or both
					  	db_becho "To do: compilation"
						COMPILATION=1;;
					s)# case like "-u sf filename" only simulation or both
					  	db_becho "To do: simulation"
						SIMULATION=1;;
					f)# parameter to give filename of .c file to compile or to 
					  # simulate their name should be the same apart the extention
					  # cmd like"-u csf filename" o "-u csfv filename vsimname"
					  	db_becho "Set filename of *.c file to $1.c"
						CHEX_FILE=$1; shift;;
					v)# parameter to give extension to append to the vsim file 
					  # used to execute simulation in vsim and stored in
					  # core-v-verif/cv32/sim/questa
					  	db_becho "Set vsim extension to _$1"
					  	VSIM_EXT="_$1"; shift;;
					d)# 
						dfSetVar d $1 "UNIQUE_CHEX_DIR" "Set hex/c file directory" \
							"give a correct directory for executable and hex!!"
						shift
						exit 1;;
					l)
						dfSetVar d $1 "U_LOG_DIR" "Set log file directory" \
							"give a correct directory for log file!!" CREATE
						shift
						exit 1;;
						
					*)
						
					
				esac
			done

			# error handler
			if [[ $CHEX_FILE == " " ]]; then
				recho_exit "Error: program file to compile or simulate should be\n \
					alway specified, for example:\n \
					-u cf file_to_compile\n -u sf file_to_simulate\n\
					-u csf file_to_compile&simulate\n\
					-u csfv file_to_comp&sim vsim_script_extension\n"
			fi
			if [[ $COMPILATION -eq 0 && $SIMULATION -eq 0 ]]; then
				recho_exit "Error: select simulation (s) or/and compilation (c) at least\n\
					-u cf file_to_compile\n -u sf file_to_simulate\n\
					-u csf file_to_compile&simulate\n\
					-u csfv file_to_comp&sim vsim_script_extension\n"
			fi
			;;
		-b|--benchmark)
			# BASE:
			#  c a         compilation of all benchmark "-b c a " (all)
			#  c $num                  of first program  "-b c 1" (not implemented)
			#  c $filename	           of hello-world "-b c hello-world" (not implemented)
			#  s a 	       simulazione di tutto il b "-b s a" (uguale a sopra per il resto)
			#  s $num		                 "-b s 3"
			#  s $filename                           "-b s hello-world"
			# MIXING OPTION  
			#  cs 	compilation and simulation of all file "-b cs a"
			#	compilation of all and simulation of 1° and 2° file  "-b cs 2"
			#	compilation of all and simulation of hello-world file "-b cs hello-world"
			# OPTIONAL PARAMETERS:
			#  v	simulation with a specific vsim file extension "-b sv a FT"
			# 				                       "-b csv 2 FT"
			# MANDATORY FILE FOR THE FIRST RUN
			#  d    give as first parameter the absolute filename of build_all file and 
			#	then the dir of *.hex file
			#	"-b d ~/dir/to/buld/all/file/build_all.py ~/dir/to/hex/file"
			#	This option has to be gived alone
			# SCRIPT PARAMETER
			#	BENCHMARK def 0
			#	COMPILATION def 0
			# 	SIMULATION def 0
			#       B_TYPE def " "
			#       B_NUM def 0
			#       B_FILE def " "
			#	VSIM_EXT def " "
			#	BENCH_BUILD_FILE def " "
			#   	BENCH_HEX_DIR def " "
			shift			
			BENCHMARK=1	
			arg=$1
			shift # delete args string
			
			# cycle on args string
			for (( i=0; i< ${#arg}; i++ )) ; do
				case ${arg:i:1} in
					c|s)# compile or simulate
						if [[ ${arg:i:1} == "c" ]]; then
						# case like "-u cf filename" only compilation or both
							db_becho "To do: compilation"
							COMPILATION=1
						else
						# case like "-u sf filename" only simulation or both
							db_becho "To do: simulation"
							SIMULATION=1
						fi
						if [[ $1 == "a" ]]; then 
							db_echo "Bench all"
							B_TYPE="all";
						else 
							if [[ $1 =~ $isnumber ]]; then 
								db_becho "Bench Number: $1"
								B_NUM=$1; B_TYPE="number";
							else 
								db_becho "Bench File: $1"
								B_FILE=$1; B_TYPE="name";
							fi
						fi
						shift
						;;
					v)# parameter to give extension to append to the vsim file 
					  # used to execute simulation in vsim and stored in
					  # core-v-verif/cv32/sim/questa
					  	db_becho "Set vsim file extension, vsim_$1.tcl will be run"
					  	VSIM_EXT="_$1"; shift;;
					d)# set build file, dir of out *.hex file and exit
						dfSetVar d "$1" "BENCH_BUILD_FILE" "Set benchmark build file" \
							"give a correct path/name for build file!!"
						shift

						dfSetVar d "$1" "BENCH_HEX_DIR" "Set benchmark hex file dir"\
							"give a correct directory of hex directory !!" 
						shift
						# if user set d variables can't do nothing else
						exit 1;;
					l)
						dfSetVar d $1 "B_LOG_DIR" "Set log bench file directory" \
							"give a correct directory for log file of benchmark!!"\
							CREATE
						shift
						exit 1;;
					*)			
					;;
				esac
			done

			;;
		--)
			break;;
		*)
			echo "Wrong argument!!!!"
			UsageExit
			;;
	esac
done


if [[ $COMPILATION -eq 0 && $SIMULATION -eq 0 ]]; then
	recho_exit "Error: select simulation (s) or/and compilation (c) at least\n\
	\tFirst of all set unique directory or benchmark build-file & hex-dir\n\
	\tAll path wil be appended to CORE_V_VERIF=$CORE_V_VERIF path:\n\
	\t\t-b d path/to/build_all.py path/to/hex/file \n\
	\t\t-u d path/to/c/dir\n\
	\tThen you could compile and simulate\n\
	\t\t-b c a -> compile all benchmark file using build script passed with 'd' option\n\
	\t\t-b s a -> simulate all benchmark *.hex file\n\
	\t\t-u cf filename -> compile filename file in directory passed wirh 'd' option\n"
fi

if [[ $VSIM_FILE == " " ]]; then
	if ! test -f $CORE_V_VERIF/cv32/sim/questa/$VSIM_FILE; then
		recho_exit "Error: when you give 'v' parameter you should give\
		the correct\n extension of a vsim_EXTENSION.tcl file in \
		core-v-verif/cv32/sim/questa directory!! "
	fi
fi	 


if [[ $UNIQUE -eq 1 ]]; then
	if [[ $UNIQUE_CHEX_DIR == " " ]]; then	
		recho_exit "Error: you should set dir/build_all program \
		used to compile all benchmark and the directory of *.hex files with:\n \
		-b d dir/to/build_all.py dir/to/hexfile \n \ 
		Both path will be appended to CORE_V_VERIF=$CORE_V_VERIF path \n \
		to find real path\n"
	fi
	if [[ $U_LOG_DIR == " " ]]; then
		recho_exit "Error: Set log directory with -u l /path/to/log/dir"
	fi
	if [[ $COMPILATION -eq 1 ]]; then
		db_gecho "Executing Makefile_Compile.mk in $UNIQUE_CHEX_DIR"
		#make -C $SIM_FT compile TEST_FILE="$FULL_FILE_CPATH"
		mon_run "make -C $UNIQUE_CHEX_DIR -f $SIM_FT/Makefile_Compile.mk" \
				$U_LOG_DIR/${CHEX_FILE}_comp.txt 1 $LINENO
		db_gecho "File in unique directory:"
		db_gecho "$(ls $UNIQUE_CHEX_DIR)"
	fi
	if [[ $SIMULATION -eq 1 ]]; then
		#rm -rf $CORE_V_VERIF/cv32/sim/core/sim_FT/work	
		source /software/europractice-release-2019/scripts/init_questa10.7c	
		# full simulation path without extension 
		mon_run "make -C $SIM_FT questa-sim$GUI TEST_FILE=$UNIQUE_CHEX_DIR/$CHEX_FILE FT=$VSIM_EXT" $U_LOG_DIR/${CHEX_FILE}_sim.txt 1 $LINENO
		cat log/${CHEX_FILE}_sim.txt | grep '^#.*$' | grep -ve 'Warning\|Process\|Instance\|Loading\|(C)'
		#make -C $SIM_FT questa-sim$GUI TEST_FILE="$UNIQUE_CHEX_DIR/$CHEX_FILE" FT="$VSIM_EXT" 
	fi
fi


#benchmarking 
if [[ $BENCHMARK -eq 1 ]]; then
	if [[ $B_LOG_DIR == " " ]]; then
		recho_exit "Error: Set log directory with -b l /path/to/log/dir"
	        exit 1
	fi
	if [[ $BENCH_BUILD_FILE == " " || $BENCH_HEX_DIR == " " ]]; then
		recho_exit "Error: you should set dir/build_all program \n
		used to compile all benchmark and the directory of *.hex files with:\n
		-b d dir/to/build_all.py dir/to/hexfile\n
		Both path will be appended to CORE_V_VERIF=$CORE_V_VERIF path\n
		to find real path\n"
	fi
	# compilation of mibench files
	if [[ $COMPILATION -eq 1 ]]; then
		cd $BENCHMARK_DIR 
		mkdir -p log 
		mon_run $BENCH_BUILD_FILE "$B_LOG_DIR/bench_compilation.txt" 1 $LINENO
	fi
		
	if [[ $SIMULATION -eq 1 ]]; then
		# simulation of all file in out directory of mibench
		source /software/europractice-release-2019/scripts/init_questa10.7c
	
		hexfiles=$(cd $BENCH_HEX_DIR; ls *.hex)
		db_gecho "This are the *.hex file in $BENCH_HEX_DIR:"
		db_lgecho "${hexfiles[@]}"
		FDONE=0
			
		if [[ $B_TYPE == "name" ]]; then 
			for hex in $hexfiles; do
				if [[ $hex == $B_FILE.hex ]]; then 
					FDONE=1
					db_gecho "Simulation of $hex"
					f_make $hex "$B_LOG_DIR/bench_sim_$(delExt $hex).txt" 1 $LINENO
				fi
			done
			if [[ $FDONE -eq 0 ]]; then
				recho_exit "Error: $B_FILE.hex file not found in $BENCH_HEX_DIR "		
			fi
		fi
		if [[ $B_TYPE == "all" ]]; then
			for hex in $hexfiles; do
				FDONE=1
				db_gecho "Simulation of $hex"
				f_make $hex "$B_LOG_DIR/bench_sim_$(delExt $hex).txt" 1 $LINENO
			done
			if [[ $FDONE -eq 0 ]]; then
				recho_exit "Error: *.hex file not found in $BENCH_HEX_DIR "		
			fi
		fi
		if [[ $B_TYPE == "number" ]]; then
		 	# saturation of file number
			if [[ $B_NUM > ${#hexfiles[@]} ]]; then 
				B_NUM=${#hexfiles[@]}; 
			fi
			# cycle on files
			for ((i=0; i<$B_NUM; i++)); do
				FDONE=1
				hex=${hexfiles[i]}
				db_gecho "Simulation of $hex"
				f_make $hex "$B_LOG_DIR/bench_sim_$(delExt $hex).txt" 1 $LINENO
			done
			if [[ $FDONE -eq 0 ]]; then
				recho_exit "Error: *.hex file not found in $BENCH_HEX_DIR "		
			fi
		fi

	fi
fi


UsageExit () {
	becho '
Program Usage:
	!!!!!!!!! ALL DIRECTORY will be appended to CORE_V_VERIF path !!!!!!!!
	-h|--help)
		UsageExit

	-g|--gui)
		GUI=-gui --> if -g then use Questasim GUI

	-u|unique-file)
		d   directory setting
			First of all set directory of *.c file to compile with:
				-u d dir/to/c/file
		l  dirrectory of log file
				-u l path/to/log/file
		cf|sf|csf compilation/simulation or both
			Then it is possible to compile and simulate
				-u cf c_file_name_without_extension   -> compile
				-u sf c_file_name_without_extension   -> simulate (if already compiled)
				-u csf c_file_name_without_extension   -> compile & simulate
		v   set vsim file extension
			You could also set the extension of vsim file to run with modelsim, this
			file should be located in core-v-verif/cv32/sim/questa directory:
				-u csfv c_file_name_without_extension vsim_extension -> 
					compile & simulate with vsim_$(vsim_extension).tcl file
			
	-b|--benchmark)
		d  directory setting
			First of all set build file to run in order to compile all benchmark and
			the directory in which all *.hex file will be located after compilation
				-b d path/to/build_all.py path/to/hex/file
		l  dirrectory of log file
				-b l path/to/log/file
		c|s|cs compilation/simulation
			Then is possible to compilate and run all benchmark, a restricted number of
			program in the benchmark or a specific program of benchmark:
				-b cs a  -> compile and simulate all benchmark
				-b cs 2  -> compile all b but simulate only the first two hex file
				-b s hello-world -> go in path/to/hex/file and use hello-world to simulate
		v   set vsim file extension
			You could also set the extension of vsim file to run with modelsim, this
			file should be located in core-v-verif/cv32/sim/questa directory:
				-u csv all vsim_extension ->						
					compile & simulate all b, with vsim_$(vsim_extension).tcl file
	
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
