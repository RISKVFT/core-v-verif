#!/bin/bash

source ccommon.sh

UsageExit () {
	becho '
Program Usage:
	!!!!!!!!! ALL DIRECTORY will be appended to CORE_V_VERIF path !!!!!!!!
	-h|--help)
		UsageExit

	-g|--gui)
		GUI=-gui --> if -g then use Questasim GUI

	-a|--arch)
		ref https://github.com/path/to/repo.git branch_name
			This option is used to set the repo and the branch of the reference arch
			for current fault tolerant arch. This repo will be uploaded using "-a s ref"
		ft https://github.com/path/to/repo.git branch_name
			This option is used to set the repo and the branch of the fault tolerant arch
			for current fault tolerant arch. This repo will be uploaded using "-a s ft"
		s [ft|ref]   (ft as default)
			This option is used to set the desired arch between ref (reference arch) and 
			ft arch, this setting can only be done after providing the repositories and 
			the branches for both architectures using "-a ref repo branch" and "-a ft repo branch"

	-u|--unique-file)
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
	1) set the reference and fault tolerant architectures:
		./comp_sim.sh -a ref https://github.com/openhwgroup/cv32e40p.git master
		./comp_sim.sh -a ft https://github.com/RISKVFT/cv32e40p.git FT_Elia
	   now we could use ref or ft arch using "-a s [ft|ref]"
	2) Compile and simulate an application program for our architecture:
		1) set application *.c/*.S code directory:
			./comp_sim.sh -u d cv32/tests/programs/custom_FT/hello-world
		   The use of relative path is because we use the variable CORE_V_VERIF to
		   have the core-v-verif path.
		2) set log file directory
			./comp_sim.sh -u l cv32/sim/core/log
		   Will be created the log dir and used to save log file
		3) Compile program
			./comp_sim.sh -u c hello-world
		4) Simulation using vsim_gold.tcl script in cv32/sim/questa directory
		   and using gui (-g) and using ref architecture.
			./comp_sim.sh -a ref -u sv hello-world gold -g 
		   The same but with the ref arch
			./comp_sim.sh -a ref -u sv hello-world gold -g 
	3) Compile and simulate a testbench:
		1) Set build program and directory of output *.hex file
			./comp_sim.sh -b d cv32/tests/programs/mibench/build_all.py \
						cv32/tests/programs/mibench/out
		2) Set log dir
			./comp_sim.sh -b l cv32/sim/core/bench_log
		3) Compile all benchmark
			./comp_sim.sh -b c a
		4) Simulate only counters.hex program using reference arch and vsim_gold.tcl script:
			./comp_sim.sh -a ref -b sv counters gold
		5) Simulate my arch and compare using vsim_compare.tcl script:
			./comp_sim.sh -a ft -b sv counters compare
'
	exit 1
}

CORE_V_VERIF="/home/thesis/elia.ribaldone/Desktop/core-v-verif"
COMMONMK="$CORE_V_VERIF/cv32/sim/core/sim_FT/Common.mk"

isnumber='^[0-9]+$'

vecho() { if [[ $VERBOSE ]]; then echo -e "${red}${1}${reset}";fi }
db_recho() { if [[ $VERBOSE ]]; then echo -e "${red}${bold}${1}${reset}"; fi }
db_becho() { if [[ $VERBOSE ]]; then echo -e "${blue}${bold}${1}${reset}"; fi }
db_gecho() { if [[ $VERBOSE ]]; then echo -e "${green}${bold}${1}${reset}"; fi }
db_lgecho() { if [[ $VERBOSE ]]; then lgecho "$1"; fi }

# FUNCTIONS #########################
refGitIsSet () { if [[ $A_REF_REPO == " " && $A_REF_BRANCH == " " ]]; then echo 0; else echo 1; fi ; }
ftGitIsSet () { if [[ $A_FT_REPO == " " && $A_FT_BRANCH == " " ]]; then echo 0; else echo 1; fi ;}
setRepoBranch () {
	ref_or_ft=$1
	if [[ $ref_or_ft != "ref" && $ref_or_ft != "ft" ]];then
		recho_exit "Error, arch can be only ref or ft"
	fi	
	if [[ $ref_or_ft == "ref" ]]; then
		if [[ $(refGitIsSet) -eq 0 ]]; then
			recho_exit "Error, repo and branch of ref arch isn't setted"
		fi
		db_gecho "Setted ref arch repo=$A_REF_REPO branch=$A_REF_BRANCH"
		repMakeFile "CV32E40P_REPO" $COMMONMK "$A_REF_REPO"
		repMakeFile "CV32E40P_BRANCH" $COMMONMK "$A_REF_BRANCH"
	else
		if [[ $(ftGitIsSet) -eq 0 ]]; then
			recho_exit "Error, repo and branch of ft arch isn't setted"
		fi
		db_gecho "Setted ft arch repo=$A_FT_REPO branch=$A_FT_BRANCH"
		repMakeFile "CV32E40P_REPO" $COMMONMK "$A_FT_REPO"
		repMakeFile "CV32E40P_BRANCH" $COMMONMK "$A_FT_BRANCH"
	fi
}
#####################################


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
export GUI=""
VERBOSE=1

# ARCH
A_REF_REPO="https://github.com/openhwgroup/cv32e40p.git"
A_REF_BRANCH="master"
A_FT_REPO="https://github.com/RISKVFT/cv32e40p.git"
A_FT_BRANCH="FT_Elia"

# Set variable are used to correctly end program if only
# this action are done, for example if only git repo 
# is setted the program should ended since all is done
ARCH=0
SET_ARCH=0
SET_DIR=0
SET_LOG=0

#TEST_DIR="$CUR_DIR/../../tests/programs/MiBench/"
#TEST_DIR="$CUR_DIR/../../tests/programs/riscv-toolchain-blogpost/out"

# vector of parameter -[a-zA-Z]
par=$(echo "$@" | awk 'BEGIN{RS=" "};{if ($0 ~ /^-[a-zA-Z\-]*$/) print $0; if ($0 ~ /^-[a-zA-Z\-]*\n/) print $0}')
echo "Argument taken: $par"

for p1 in $par; do
	case $p1 in
		-h|--help)
			UsageExit 		
			shift	
			;;
		-g|--gui)
			db_becho "Set Gui"
			export GUI="-gui"
			shift
			;;
		-q|--quiet)
			VERBOSE=0
			shift
			;;
		-a|-arch)
			ARCH=1
			# This option set the ref git REPO and the derivated ft git REPO and their 
			# relative branch, the ref git REPO can be used in the script to create
			# a fisrt comparison in order to verify correct working of FT arch.
			# BASE   "-a ref|ft REPO BRANCH"
			#   ref     save the ref git REPO and BRANCH 
			#		"-a ref https://github.com/openhwgroup/cv32e40p.git master"
			#   ft     save the dut git REPO and BRANCH
			#		"-a dut https://github.com/RISKVFT/cv32e40p.git FT_Marcello"
			#   s [ft|ref]     set current arch , default is ft
			#		"-a s ref -b s a" -> simula tutto il benchmark utilizzando l'arch ft
			shift # delete -a
			if [[ $1 == "ref" || $1 == "ft" ]];then
				if ! gitRepoExist "$2"; then
					recho_exit "Error: git repo don't exist!!!"
				fi
				if ! gitRepoBranchExist $2 $3; then
					recho_exit "Error: branch of $2 don't exist!!"
				fi
			fi
	
			case $1 in
				ref)
					db_becho "Setted \n	REF_REPO=$2 and \n	REF_BRANCH=$3"
					A_REF_REPO=$2
					repfile "A_REF_REPO" "$CUR_DIR/$(basename $0)" $2
					A_REF_BRANCH=$3
					repfile "A_REF_BRANCH" "$CUR_DIR/$(basename $0)" $3 
					shift 3;;	
				ft)
					db_becho "Setted \n	FT_REPO=$2 and \n	FT_BRANCH=$3"
					A_FT_REPO=$2
					repfile "A_FT_REPO" "$CUR_DIR/$(basename $0)" $2
					A_FT_BRANCH=$3
					repfile "A_FT_BRANCH" "$CUR_DIR/$(basename $0)" $3
					shift 3;;
				s)
					SET_ARCH=1
					setRepoBranch $2
					shift 2;;
				*)
					recho_exit "Error; \"-a\" option needs correct parameter [ref|ft|s] ";;
			esac
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
						SET_DIR=1
						UNIQUE_CHEX_DIR=$1
						dfSetVar d $1 "UNIQUE_CHEX_DIR" "Set hex/c file directory" \
							"give a correct directory for executable and hex!!"
						shift
						exit 1;;
					l)
						SET_LOG=1
						U_LOG_DIR=$1
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
			#	This option has to be given alone
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
						SET_DIR=1
						BENCH_BUILD_FILE=$1
						dfSetVar d "$1" "BENCH_BUILD_FILE" "Set benchmark build file" \
							"give a correct path/name for build file!!"
						shift
						BENCH_HEX_DIR=$1
						dfSetVar d "$1" "BENCH_HEX_DIR" "Set benchmark hex file dir"\
							"give a correct directory of hex directory !!" 
						shift
						# if user set d variables can't do nothing else
						exit 1;;
					l)
						SET_LOG=1
						B_LOG_DIR=$1
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

# CONTROLS !!
if [[ $BENCHMARK -eq 0 && $UNIQUE -eq 0 ]]; then
	if [[ $ARCH -eq 1 ]]; then
		exit 1 # exit since arch is setted and all is already done
	else
		echo "ciao"
		#recho_exit "Error: you sould use at least one option between -u,-b,-a" #se uso --help questo comando non fa stampare nulla
	fi
else
	if [[ $SET_DIR -eq 1 || $SET_LOG -eq 1 ]]; then
		exit 1 # exit since dir or log dir is setted and no other should be done
	else
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
		if [[ $SET_ARCH -eq 0 ]];then
			if [[ $A_FT_REPO == " " || $A_REF_REPO == " " ]]; then
				recho_exit "Error: you should setat least FT repo and branch aof arch using \n\
					 	\t\t-a ft https://github.com/ft_repo ft_branch_name\n"
			else
				if [[ $A_FT_REPO != " " ]]; then
					db_gecho "Setted ft arch (default) repo=$A_FT_REPO branch=$A_FT_BRANCH"
					setRepoBranch ft
				else
					db_gecho "Setted ref arch repo=$A_REF_REPO branch=$A_REF_BRANCH"
					setRepoBranch ref
				fi
			fi
		fi	
	fi
fi

if [[ $VSIM_FILE == " " ]]; then
	if ! test -f $CORE_V_VERIF/cv32/sim/questa/$VSIM_FILE; then
		recho_exit "Error: when you give 'v' parameter you should give\
		the correct\n extension of a vsim_EXTENSION.tcl file in \
		core-v-verif/cv32/sim/questa directory!! "
	fi
fi	 

# EXECUTION
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
	# Controls
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



