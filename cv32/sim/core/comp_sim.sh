#!/bin/bash

source ccommon.sh
echo "argomenti: $@"

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT
trap exit_f EXIT

#######################################################################
## Variable used to configure the closure of the program with ctrl-c
######################################################################
# If setted, when the program is blocked using a ctrl-c the progression bar
# is closed, 
int_close_bar=0
int_remove_work=1
PPID_MAIL=0
PPID_SFIUPI=0

function ctrl_c() {
        echo "** Trapped CTRL-C"
	if [[ $int_close_bar -eq 1 ]]; then
		destroy_scroll_area
	fi
	rm -f log.log
	rm -f time_*
	if [[ $PPID_MAIL -ne 0 ]]; then
		kill $PPID_MAIL	
	fi
	if [[ $PPID_QSFIUPI -ne 0 ]]; then
		kill $PPID_SFIUPI
	fi

}


#######################################################################
## configure the closure of the program each time that finished
######################################################################

function exit_f () {
	# communicate using pipe that the program is terminated
	if [[ $PIPENAME != "" ]]; then
		echo "exit" > $PIPENAME
		if [[ $PIPENAME =~ "info" ]]; then
			delete_pipe $PIPENAME
		fi
	fi	
	rm -f log.log
	rm -f time_*
}	

#######################################################################
## HELP
######################################################################

UsageExit () {
	cat comp_sim_man
	exit 1
}


###################################################################################################################
#  SUPPORT FUNCTION ###############################################################################################
###################################################################################################################

 
vecho() { if [[ $VERBOSE ]]; then echo -e "${red}${1}${reset}";fi }
db_recho() { if [[ $VERBOSE ]]; then echo -e "${red}${bold}${1}${reset}"; fi }
db_becho() { if [[ $VERBOSE ]]; then echo -e "${blue}${bold}${1}${reset}"; fi }
db_gecho() { if [[ $VERBOSE ]]; then echo -e "${green}${bold}${1}${reset}"; fi }
db_lgecho() { if [[ $VERBOSE ]]; then lgecho "$1"; fi }

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

idExists () {
	# Loop in SIM_IDS and check if there is the corresponding id of simulation
	ID=$1
	thereisid=0
	for iid in $SIM_IDS; do
		if [[ "$iid" == "$ID" ]];then
			thereisid=1
		fi
	done
	if [[ $thereisid -eq 0 ]]; then
		echo "0"
		return 
	fi
	echo "1"

}

# This function give the timestamp of a file in microseconds
fileTimestamp () {
	min_inmsec=$(echo "$(stat -c %y $1 | cut -d ":" -f 2 | bc -l )*60*1000" | bc -l)
	sec_inmsec=$(echo "$(stat -c %y $1 | cut -d ":" -f 3 | cut -d " " -f 1 | \
		cut -d "." -f 1 | bc -l)*1000" | bc -l)
	msec_inusec=$(echo "scale=0; $(stat -c %y $1 | cut -d ":" -f 3 | cut -d " " -f 1 | \
		cut -d "." -f 2 | bc -l)/1000" | bc -l)
	timestamp_inmsec=$(echo "$min_inmsec*1000+$sec_inmsec*1000+$msec_inusec" | bc -l)
	echo $timestamp_inmsec
}


executeInTerminal () {
	mate-terminal --window --working-directory="$CUR_DIR" --command="$1; exec $SHELL" --disable-factory &
	ask_yesno "VCD creation is finished (close window before answer yes) (y/n)?"
	while [[ $ANS -eq 0 ]] ; do
		ask_yesno "VCD creation is finished (close window before answer yes) (y/n)?"
	done
}
executeInTerminalEasy () {
	local cmd=$1
	local tname=$2
	mate-terminal --window --working-directory="$CUR_DIR" --command="$cmd"  --disable-factory &
	TERMINAL_PID="$TERMINAL_PID $!_tname"
}
execute_in_terminal() {
	local cmd="$1"
	local tname="$2"
	mate-terminal --window --working-directory="$CUR_DIR" --command="$cmd"  --disable-factory &
	TERMINAL_PID="$TERMINAL_PID $!_$tname"
}
kill_terminal () {
	local tname=$1
	for pid_name in $TERMINAL_PID; do
		echo "$pid_name"
		if [[ $(echo $pid_name | cut -d "_" -f 2-) == $tname ]] ; then
			echo "pid: $(echo $pid_name | cut -d "_" -f 1)"
			kill -9 $(echo $pid_name | cut -d "_" -f 1)
			return
		fi
	done
}
function delete_pipe ()  {
	local pipename=$1
	rm $pipename
	#find /tmp -maxdepth 1 -name pipe_* -delete 
}
function check_pipe () {
	local pipename=$1
	if [[ ! -p $pipename ]]; then
		db_recho "ERROR: The pipe $pipename don't exist!!"
		exit	
	fi
}

function read_pipe () {
	local pipename=$1
	check_pipe $pipename
	read line < $pipename
	echo $line
}

function write_PIPENAME () {
	local pipename=$PIPENAME
	local towrite=$1
	if [[ $pipename != "" ]]; then
		echo $towrite > $PIPENAME
	fi
}

function pulling_pipe () {
	local pipename=$1
	local nametopull=$2
	check_pipe $pipename
	while true ; do
		if read line < $pipename ; then
			if [[ $line == $nametopull ]]; then
				break
			fi
		fi	
	done
}

function kill_terminal_when_it_finished () {
	local pipename=$1
	local wname=$2
	pulling_pipe $pipename "exit"
	kill_terminal $wname
}


verify_upi_vcdwlf () {
	# Verify that vcd (for input signals) and wlf (for output) exist, otherwise create it
	local sw=$1 # name of the software 
	local stg=$2 # name of the stage without cv32e40p if core
	local real_stg=$3

	swc=$(echo $sw | tr '-' '_')
	db_becho "INFO: ./sim_FT/dataset/gold_${ARCH_TO_COMPARE}_${real_stg}_${swc}_in.vcd exists?"
	if [[ ! -f ./sim_FT/dataset/gold_${ARCH_TO_COMPARE}_${real_stg}_${swc}_in.vcd ]]; then
		local pipe_in=/tmp/save_in
		mkfifo $pipe_in
		# Creation of vcd that contain input of stage
		db_becho "PROCESS: Creation of vcd that contains inputs of the stage $stg with program $sw ..."
		execute_in_terminal "./comp_sim.sh -b sbv $sw $stg save_data_in -p $pipe_in" "save_in"
		kill_terminal_when_it_finished "$pipe_in" "save_in"
		delete_pipe "$pipe_in"
	fi
	if [[ ! -f ./sim_FT/dataset/gold_${ARCH_TO_COMPARE}_${real_stg}_${swc}_out.wlf ]]; then
		local pipe_out=/tmp/save_out
		mkfifo $pipe_out
		# Creation of vcd that contain input of stage
		db_becho "PROCESS: Creation of wlf that contains output of the stage $stg with program $sw ..."
		execute_in_terminal "./comp_sim.sh -b sbv $sw $stg save_data_out -g -p $pipe_out" "save_out"
		kill_terminal_when_it_finished "$pipe_out" "save_out"
		delete_pipe "$pipe_out"
	fi

	
}

findEndsim () {
	local sw=$1
	local stg=$2
	local real_stg=$3
	
	verify_upi_vcdwlf $sw $stg $real_stg
	
	db_becho "INFO: vcd input file = ./sim_FT/dataset/gold_${ARCH_TO_COMPARE}_${real_stg}_${swc}_in.vcd"

	endsim="$(( $(tail -n 2 ./sim_FT/dataset/gold_${ARCH_TO_COMPARE}_${real_stg}_${swc}_in.vcd | head -n 1 | tr -d "#") - 1 ))"

	db_becho "INFO: endsim = $endsim"
}

db_gecho_c () {
	if [[ $CLEAROUT == 1 ]]; then
		echo -e "$1"
	else
		db_becho "$1"	
	fi	
}	

function check_id () {
	if [[ $(idExists $1) == "0" ]]; then
		db_recho "Error: ID not found, these are the available IDS: $SIM_IDS"
		exit
	fi
}

sendMailToAll_ifyes () {
	if [[ $1 -eq 1 ]]; then
		sendMailToAll $1
	fi
}

############################################################################################
#  SETTING and MANAGING FUNCTIONS
############################################################################################

function clear_id_from_regular_expression () { 
	# Called by -c option
	# clear id that match a specific regular expression
	# $1 regular expression
	local id_to_delete=$1
	local new_SIM_IDS=""	
	# Backup simulations
	mkdir -p $ERROR_DIR_BACKUP
	cp $ERROR_DIR/* $ERROR_DIR_BACKUP

	# Delete simulation selected
	for id in $SIM_IDS; do
		echo $id
		if [[ $id =~ $id_to_delete ]]; then
			ask_yesno "QUESTION: Do you really want to delete $id simulation(y/n)?"
			if [[ $ANS -eq 1 ]]; then
				files=$(ls $ERROR_DIR | grep "$id")
				for ff in $files; do
					rm $ERROR_DIR/$ff
				done
			else
				echo "INFO: This simulation won't be deleted."
				new_SIM_IDS="$new_SIM_IDS $id"
			fi
		else
			new_SIM_IDS="$new_SIM_IDS $id"
		fi	
	done
	
	SetVar "SIM_IDS" "$new_SIM_IDS"
	exit
}

function set_sim_arch () {
	# Called by -a option
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
			shift 2;;
		refb)
			db_becho "Setted \n	REF_BRANCH=$2"
			A_REF_BRANCH=$2
			repfile "A_REF_BRANCH" "$CUR_DIR/$(basename $0)" $2
			shift 2;;	
		refr)
			db_becho "Setted \n	REF_REPO=$2"
			A_REF_REPO=$2
			repfile "A_REF_REPO" "$CUR_DIR/$(basename $0)" $2
			shift 2;;	
		ft)
			db_becho "Setted \n	FT_REPO=$2 and \n	FT_BRANCH=$3"
			A_FT_REPO=$2
			repfile "A_FT_REPO" "$CUR_DIR/$(basename $0)" $2
			A_FT_BRANCH=$3
			repfile "A_FT_BRANCH" "$CUR_DIR/$(basename $0)" $3
			shift 3;;
		ftr)
			db_becho "Setted \n	FT_REPO=$2"
			A_FT_REPO=$2
			repfile "A_FT_REPO" "$CUR_DIR/$(basename $0)" $2
			shift 2;;
		ftb)
			db_becho "Setted \n	FT_BRANCH=$2"
			A_FT_BRANCH=$2
			repfile "A_FT_BRANCH" "$CUR_DIR/$(basename $0)" $2
			shift 3;;
		s)
			SET_ARCH=1
			setRepoBranch $2
			shift 2;;
		i) # info
			db_becho "Info about archs\nFT branch = $A_FT_BRANCH\nTF repo = $A_FT_REPO\nREF branch = $A_REF_BRANCH\nREF repo = $A_REF_REPO\nSIM BASE = $SIM_BASE\n"	
			exit 1 ;;
		simbase)
			db_echo "Sim base set SIM_BASE=$2"
			export SIM_BASE="$2"
			SetVar "export SIM_BASE" "$2"
			shift 2;;

		*)
			recho_exit "Error; \"-a\" option needs correct parameter [ref|ft|s] ";;
	esac
}

###########################################################################################
#  SIMULATION FUNCTIONS             #######################################################
###########################################################################################

function sim_unique_program () {
	# Called by -u option
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

	arg=$1
	shift # delete args string

	# cycle on args string
	for (( i=0; i< ${#arg}; i++ )) ; do
		case ${arg:i:1} in
			a) # select the architecture to test
				ARCH_TO_USE="$1"
				SetVar "ARCH_TO_USE" "$ARCH_TO_USE"
				export $ARCH_TO_USE
				shift;;
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

	if [[ $VSIM_FILE == " " ]]; then
		if ! test -f $CORE_V_VERIF/cv32/sim/questa/$VSIM_FILE; then
			recho_exit "Error: when you give 'v' parameter you should give\
			the correct\n extension of a vsim_EXTENSION.tcl file in \
			core-v-verif/cv32/sim/questa directory!! "
		fi
	fi	 
	# error handler
	if [[ $CHEX_FILE == " " ]]; then
		recho_exit "Error: program file to compile or simulate should be\n \
			alway specified, for example:\n \
			-u cf file_to_compile\n -u sf file_to_simulate\n\
			-u csf file_to_compile&simulate\n\
			-u csfv file_to_comp&sim vsim_script_extension\n"
	fi
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
		mon_run "make -C $SIM_FT questa-sim$GUI TEST_FILE=$UNIQUE_CHEX_DIR/$CHEX_FILE \
			FT=$VSIM_EXT ARCH=_$ARCH_TO_USE" $U_LOG_DIR/${CHEX_FILE}_sim.txt 1 $LINENO

		cat log/${CHEX_FILE}_sim.txt | grep '^#.*$' | grep -ve 'Warning\|Process\|Instance\|Loading\|(C)'
		
		#make -C $SIM_FT questa-sim$GUI TEST_FILE="$UNIQUE_CHEX_DIR/$CHEX_FILE" FT="$VSIM_EXT" 
	fi

}

function sim_benchmark_programs () {
	# Called by -b option
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
	arg=$1
	shift # delete args string
	
	# cycle on args string
	for (( i=0; i< ${#arg}; i++ )) ; do
		case ${arg:i:1} in
			a) #architecture to test
				ARCH_TO_USE="$1"
				SetVar "ARCH_TO_USE" "$ARCH_TO_USE"
				export $ARCH_TO_USE
				shift;;
			t) #architecture to compare 
				ARCH_TO_COMPARE="$1";
				SetVar "ARCH_TO_COMPARE" "$ARCH_TO_COMPARE"
				export $ARCH_TO_COMPARE
				shift;;
			f) #fi
				export FI=$1
				if [[ $FI -ne 0 && $FI -ne 1 ]]; then
					db_recho "ERROR: -sfiupi f fault_injection_yes_no :"
				        db_recho "	fault_injection_yes_no should bo 0 or 1."
					db_recho "	value $FI is wrong!"
					exit
				fi
				db_becho "FI = $1"
				shift;; 
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
					db_becho "Bench all"
					B_TYPE="all";
					shift
				elif [[ ! -z $1 && -z $B_FILE ]]; then 
					if [[ $1 =~ $isnumber ]]; then 
						db_becho "Bench Number: $1"
						B_NUM=$1; B_TYPE="number";
					else 
						db_becho "Bench File: $1"
						B_FILE=$1; B_TYPE="name";
					fi
					shift
				fi
				;;
			v) # parameter to give extension to append to the vsim file 
			  # used to execute simulation in vsim and stored in
			  # core-v-verif/cv32/sim/questa
				VSIM_EXT="_$1"; 
				if [[ $1 == "cov" ]]; then
					VSIM_EXT="_cycle_to_certain_coverage"
				fi
				db_becho "Set vsim file extension, vsim_$1.tcl will be run"
				shift;;
			d) # set build file, dir of out *.hex file and exit
				SET_DIR=1
				BENCH_BUILD_FILE=$1
				dfSetVar f "$1" "BENCH_BUILD_FILE" "Set benchmark build file" \
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
			b)
				SET_BLOCK=1
				STG=$1
				B_STAGE=cv32e40p_$1 # ex: id_stage
				if [[ $1 =~ "core" ]]; then
					export STAGE_NAME="cv32e40p_$1"
					SetVar "export STAGE_NAME" "cv32e40p_$1"
					export SIM_BASE="tb_top/cv32e40p_tb_wrapper_i"
				else
					export STAGE_NAME="$1"
					SetVar "export STAGE_NAME" "$1"
				fi
				shift;;
			*)			
			;;
		esac
	done
	db_becho "Architecture selected: $ARCH_TO_USE"
	if  [[ $VSIM_EXT == "_cycle_to_certain_coverage" ]]; then
		export SWC="$(echo $B_FILE | tr '-' '_')"
		findEndsim $SWC $STG $STAGE_NAME
		export T_ENDSIM=$endsim
		db_becho "ENDSIM = $T_ENDSIM"
	fi
	if  [[ $VSIM_EXT == "_stage_compare" ]]; then
		SET_UPI=1
		export SWC="$(echo $B_FILE | tr '-' '_')"
		findEndsim $SWC $STG $STAGE_NAME
		export T_ENDSIM=$endsim
		db_becho "ENDSIM = $T_ENDSIM"
		## aggiunti per il momento
		mkdir -p $ERROR_DIR
		ID="$STG-$SWC-$CYCLE-$FI"
		bd_becho "-----------ID:$ID"

		export COMPARE_ERROR_FILE="$ERROR_DIR/$compare_error_file_prefix$ID.txt"
		export INFO_FILE="$ERROR_DIR/$info_file_prefix$ID.txt"
		export CYCLE_FILE="$ERROR_DIR/$cycle_file_prefix$ID.txt"
		export SIGNALS_FI_FILE="$ERROR_DIR/$signals_fi_file_prefix$ID.txt"
		##
	fi
	
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

	if [[ $VSIM_FILE == " " ]]; then
		if ! test -f $CORE_V_VERIF/cv32/sim/questa/$VSIM_FILE; then
			recho_exit "Error: when you give 'v' parameter you should give\
			the correct\n extension of a vsim_EXTENSION.tcl file in \
			core-v-verif/cv32/sim/questa directory!! "
		fi
	fi	 
	
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
}

function manage_stage_fault_injection_upi () {
	# Called by qsfiupi
	
	local pipe_info=/tmp/pipe_info
	mkfifo $pipe_info
	local comando="./comp_sim.sh -sfiupi $@ -p $pipe_info"
	local tname="sfiupi"
	local file_info_mail="/tmp/time_$ID.txt"

	db_becho "PROCESS: Opening a new terminal to run simulations ... "
	# Run 
	echo "INFO: command = $comando"
	execute_in_terminal "$comando" "$tname"

	
	# We save information from pipe in variables
	db_becho "INFO: Reading pipe..."
	
	ID=$(read_pipe $pipe_info| cut -d ":" -f 2)
	db_becho "INFO: ID = $ID"
	
	CYCLE=$(read_pipe $pipe_info|cut -d ":" -f 2)
	db_becho "INFO: CYCLE = $CYCLE"
	
	CYCLE_FILE=$(read_pipe $pipe_info| cut -d ":" -f 2)
	db_becho "INFO: CYCLE_FILE = $CYCLE_FILE"
	
	START_TIME=$(read_pipe $pipe_info| cut -d ":" -f 2)
	db_becho "INFO: CYCLE_FILE = $CYCLE_FILE"
	
	sleep 1

	delete_pipe $pipe_info

	
	# We reset the cycle file, this file is written by tcl script
	# and contain a number correcponding to the  number of
	# simulation finished
	echo "0" > "$CYCLE_FILE"
	echo "2000" >> "$CYCLE_FILE"
	# mean cycle time in ms
	cycle_time_mean=4000
	current_cycle=$(head -n 1 "$CYCLE_FILE")
	cycle_time=$(tail -n 1 "$CYCLE_FILE")
	cycle_time_sum=0
	 
	# If the send variable is setted we sent a mail in periodical mode
	# in order to report news from simulation
	echo -e "Time-left:Unknown sec\nPercentage:0%\nMean cycle time sec:3 sec\ncycle:0" > "time_$ID.txt"
	if [[ $SEND -eq 1 ]]; then
		db_becho "PROCESS: Open a new terminal for mail sender ..."
		touch $file_info_mail
		# time between two mail in order to have a coverage of 20%
		# so about each 20% of simulation a mail is sent
		if [[ $CYCLE -lt 20 ]]; then 
			mail_cycle_time="0.5"
		else
			mail_cycle_time=$(echo "scale=3; $cycle_time_mean*$CYCLE/600000" | bc -l )
		fi
		execute_in_terminal "./sendNewsOfSimulation.sh $file_info_mail cycle: $CYCLE $mail_cycle_time" "mail"
		
		db_becho "INFO: The mail sender will send you a mail each "
		db_becho "		$(show_time $(echo "$mail_cycle_time*60" | bc -l | cut -d "." -f 1))"

	fi

	db_becho "INFO: Monitoring the simulation"
	enable_trapping
	setup_scroll_area

	int_close_bar=1
	var=$(echo "scale=3; 2000/1000" | bc -l)
	
	draw_progress_bar 0 $((2*$CYCLE)) "$var|$var"
	
	while [[ $current_cycle -le $CYCLE ]]; do
	
		current_cycle=$(head -n 1 "$CYCLE_FILE")
		cycle_time=$(tail -n 1 "$CYCLE_FILE")

		# If to avoid 0 in that variable 
		# percentage calculated basing on current cycle
		if [[ ! $current_cycle =~ $isnumber ]]; then
			current_cycle=$current_cycle_old
			if [[ $current_cycle == "" ]]; then
				current_cycle=0
			fi
		fi
		if [[ ! $cycle_time =~ $isnumber ]]; then
			cycle_time=$cycle_time_old
			if [[ $cycle_time == "" ]]; then
				cycle_time=2000
			fi
		fi

		# Evaluation of the probable end time
		if [[ $current_cycle != $current_cycle_old ]]; then
			if [[ $current_cycle -eq 0 ]]; then
				cycle_time_mean=2000
			else
				cycle_time_sum=$( echo "$cycle_time_sum+$cycle_time" | bc -l)
				cycle_time_mean=$( echo "$cycle_time_sum/$current_cycle" | bc -l)
				percentage=$( echo "scale=2; $current_cycle*100/$CYCLE" | bc -l)
				time_left=$( echo "(($CYCLE-$current_cycle)*$cycle_time_mean)/1000" \
						| bc -l | cut -d "." -f 1)
				cycle_time_mean_sec=$(echo "scale=2; $cycle_time_mean/1000" | bc -l)
				cycle_time_sec="m:$cycle_time_mean_sec|tcy:$(echo "scale=2; $cycle_time/1000" | bc -l)|cy:$current_cycle"

				# send info to mail process
				echo -e "Time-left: $(show_time $time_left)" > "$file_info_mail"
				echo -e "Percentage: $percentage%" >> "$file_info_mail"
				echo -e "Mean cycle time sec: $cycle_time_mean_sec sec" >> "$file_info_mail"
				echo -e "cycle:$current_cycle" >> "$file_info_mail" 
				
				#draw progress bar
				draw_progress_bar $percentage $time_left $cycle_time_sec
			fi
			
		fi
			
		# Termination condition
		if [[ $current_cycle -eq $CYCLE ]]; then
			break
		fi

		current_cycle_old=$current_cycle
		cycle_time_old=$cycle_time
		
		sleep 1
	done

	# Clear cycle file
	echo "0" > "$CYCLE_FILE"
	
	destroy_scroll_area
	
	sleep 2
	elaborate_simulation_output "$ID"

	kill_terminal "mail"
	exit 
}

function sim_stage_fault_injection_upi () {
	
	if [[ $1 == "-h" ]]; then
		echo "c (0-1000000)[cycle number], f (0/1)[injection], s [software_name], b [stage_name]"
		exit
	fi
	# c [0-100000000] cycle number
	# f [0/1] fault  injection
	# s software
	# b stage
	arg=$1
	shift # delete args string
	
	export CYCLE=1
	export FI=0
	CALC_CYCLE_ON=0
	# cycle on args string
	for (( i=0; i< ${#arg}; i++ )) ; do
		case ${arg:i:1} in
			a) #architecture to test
				ARCH_TO_USE="$1"
				SetVar "ARCH_TO_USE" "$ARCH_TO_USE"
				export $ARCH_TO_USE
				shift;;
			t) #architecture to compare 
				ARCH_TO_COMPARE="$1";
				SetVar "ARCH_TO_COMPARE" "$ARCH_TO_COMPARE"
				export $ARCH_TO_COMPARE
				shift;;
			c)# cycle
				# metti solo gli export e' via			
				export CYCLE=$1
				if [[ $CYCLE == "cov" ]]; then
					CALC_CYCLE_ON=1
				fi
				if ! [[ $CYCLE =~ $isnumber ]]; then
					db_recho "ERROR: -sfiupi c number_of_cycle :"
					db_recho "	number of cycle should be an integer number."
				        db_recho "      value $CYCLE is wrong!"
					exit
				fi
				db_becho "CYCLE = $1"
				shift
			;;
			f) #fi
				export FI=$1
				if [[ $FI -ne 0 && $FI -ne 1 ]]; then
					db_recho "ERROR: -sfiupi f fault_injection_yes_no :"
				        db_recho "	fault_injection_yes_no should bo 0 or 1."
					db_recho "	value $FI is wrong!"
					exit
				fi
				db_becho "FI = $1"
				shift
			;; 
			s)
				SW=$1
				hexfiles=$(cd $BENCH_HEX_DIR; ls *.hex)
				flag=0
				for file in $hexfiles; do
					if [[ "$SW.hex" == "$file" ]]; then
						flag=1
						break
					fi
				done
				if [[ $flag -eq 0 ]]; then
					db_recho "ERROR: -sfiupi s software:"
					db_recho "	software should be an hex file located in:$BENCH_HEX_DIR "
					db_recho "	This directory can be setted with "
					db_recho "      \'-b d ~/dir/build_all.py ~/dir/to/hex/file\' command."
					db_recho "	$SW hex file there isn't in $BENCH_HEX_DIR!!"
					exit
				fi
				SWC="$(echo $1 | tr '-' '_')"
				shift	
			;;
			b)
				STG=$1
				if [[ $STG =~ "core" ]]; then
					REAL_STG="cv32e40p_$STG"
				else
					REAL_STG=$STG
				fi

				shift
			;;
		esac
	done
	if [[ $FI -eq 0 ]]; then
		export CYCLE=1
		echo "Fault injection is equal to 0 so you can't cycle, CYCLE=0"
	else
		if  [[ $CALC_CYCLE_ON -eq 1 ]]; then
			CYCLE="cov"	
			if [[ -f "$SIM_CYCLE_NUMBER_FILE" ]]; then
				line=$(cat "$SIM_CYCLE_NUMBER_FILE" | grep "$SWC$REAL_STG:")
				if [[ $line != "" ]]; then
					CYCLE=$(echo $line | rev | cut -d ":" -f 1 | rev)
				fi
			fi
			if [[ $CYCLE == "cov" ]]; then
				# execute the tcl script in order to find correct number of cycle
				./comp_sim.sh -b sbv $SW $STG "cov" -upi
				line=$(cat "$SIM_CYCLE_NUMBER_FILE" | grep "$SWC$REAL_STG:")
				if [[ $line != "" ]]; then
					CYCLE=$(echo $line | rev | cut -d ":" -f 1 | rev)
				fi
				db_becho "CYCLE = $CYCLE"
				exit
			fi
			
		fi
	fi

	# Set error file used to save number of error of the simulation
	# each simulation, if at least an error is found in the output signals
	# the number in this file in increased by one.
	mkdir -p $ERROR_DIR
	ID="$STG-$SWC-$CYCLE-$FI"

	write_PIPENAME "ID:$ID"
	db_becho "INFO: send ID through pipe"

	if [[ $(idExists $ID) == "0" ]]; then
		db_becho "INFO: Saving IDs for next simulation"
		SetVar "SIM_IDS" "$STG-$SWC-$CYCLE-$FI $SIM_IDS"
		SIM_IDS="$STG-$SWC-$CYCLE-$FI $SIM_IDS"
	fi
	export COMPARE_ERROR_FILE="$ERROR_DIR/$compare_error_file_prefix$ID.txt"
	export INFO_FILE="$ERROR_DIR/$info_file_prefix$ID.txt"
	export CYCLE_FILE="$ERROR_DIR/$cycle_file_prefix$ID.txt"
	export SIGNALS_FI_FILE="$ERROR_DIR/$signals_fi_file_prefix$ID.txt"
	echo 0 > "$COMPARE_ERROR_FILE"
	echo "" > "$INFO_FILE"

	############# RUN SIMULATION #############################
	if [[ $SWC == "all" ]]; then
		hexfile=$(ls $BENCH_HEX_DIR/*.hex)
		for i in $hexfile;do
			############ Save parameter in a log file for -qsfiupi ##########
			write_PIPENAME "cycle:$CYCLE"
			write_PIPENAME "cycle_file:$CYCLE_FILE"

			timeone=$(date +%s)
			write_PIPENAME "start_time:$timeone"

			SW=$(echo $i | rev | cut -d "/" -f 1 | rev | cut -d "." -f 1)
			SWC="$(echo $SW | tr '-' '_')"

			findEndsim $SWC $STG $REAL_STG
			export T_ENDSIM=$endsim


			db_becho "Simulation end time $T_ENDSIM"
			sim_benchmark_programs svb $SW stage_compare $STG -upi
			timetwo=$(date +%s)
			sim_total_time=$(($timetwo-$timeone))
			echo "Total_sim_time:$sim_total_time" >> "$INFO_FILE"
			echo "SImulation ID:$ID"
		done	
	else
		############ Save parameter in a log file for -qsfiupi ##########
		write_PIPENAME "cycle:$CYCLE"
		db_becho "INFO: send CYCLE through pipe"
		write_PIPENAME "cycle_file:$CYCLE_FILE"
		db_becho "INFO: send CYCLE_FILE through pipe"
		timeone=$(date +%s)
		write_PIPENAME "start_time:$timeone"

		
		findEndsim $SWC $STG $REAL_STG
		export T_ENDSIM=$endsim
		
		db_becho "Simulation end time $T_ENDSIM"

		sim_benchmark_programs atsvb $ARCH_TO_USE $ARCH_TO_COMPARE $SW stage_compare $STG -upi
		
		timetwo=$(date +%s)
		sim_total_time=$(($timetwo-$timeone))
		echo "Total_sim_time:$sim_total_time" >> "$INFO_FILE"
		echo "SImulation ID:$ID"
		#./comp_sim.sh -esfiupi "$ID"
	fi
	exit
}

#######################################################################################
#  ELABORATION FUNCTION #########################################################
######################################################################################

function signals_elaboration () {
	local id=$1
	local file_sig="$ERROR_DIR/signals_fault_injection_$id.txt"
	local signals=$(grep All_signals $file_sig | cut -d ":" -f 2)

	# TODO: add percentage of fault tolerance for each signal
	MEAN_ERROR=""
	for sig in $signals; do
		local l_errors=$(grep $sig $file_sig | grep sig_fault | tr -s " " |\
		       	cut -d " " -f 5 | cut -d ":" -f 2)
		local err_n=$(echo $l_errors | wc -w )
		if [[ $err_n -gt 0 ]]; then
			local tot_errors=0
			for err in $l_errors; do
				let tot_errors=tot_errors+$err
			done
			local mean_error=$( echo "scale=2; $tot_errors/$err_n" | bc -l)
			MEAN_ERROR="$MEAN_ERROR mean:$mean_error#$sig"
		fi
	done
}

function elaborate_simulation_output () {
	# elaborate sfiupi output
	# $1 is the id of simulation ex: id_stage-fibonacci-10-1  -> is_stage simulato 
	# col software fibonacci in 10 cicli con fault injection
	############ CONTROLS  #################################
	local id=$1
	check_id $id

	#cat signals_fault_injection_id_stage-fibonacci-16600-1.txt | grep sig_fault | \
	#o	sort -k 5.12,5.16 -n | tr -s " " | cut -d " " -f 5 | cut -d ":" -f 2

	############ TAKE DATA #################################
	local stg=$(echo $id | cut -d "-" -f 1)
	local swc=$(echo $id | cut -d "-" -f 2)
	local tot_cycle=$(echo $id | cut -d "-" -f 3)
	local fi=$(echo $id | cut -d "-" -f 4)
	local err_file="$ERROR_DIR/$compare_error_file_prefix$id.txt"
	local info_file="$ERROR_DIR/$info_file_prefix$id.txt"
	### Take data from files 
	local error=$(cat "$err_file")
	local sim_total_time=$(cat "$info_file" | grep Total_sim_time | cut -d ":" -f 2)
	local n_of_signal=$(cat "$info_file" | grep Number_of_signal | cut -d ":" -f 2)


	############ ELABORATE DATA in info and error files ##############################
	
	local time_for_cycle=$(echo "scale=3; $sim_total_time/$tot_cycle" | bc -l)
	local sim_show_time=$(show_time $sim_total_time)

	if [[ $fi > 0 ]]; then 
		local fault_tolerance=$(echo "100*(1-$error/$tot_cycle)" | bc -l )
		signals_elaboration $id
		local signals_mean=$(echo $MEAN_ERROR | tr " " "\n" | \
			sort -k 1.6,1.20 -n -r)
	fi

	# CLEAROUT variable said when to print an putput clean from color, used for send mail
	db_gecho_c "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	db_gecho_c "Total simulation time ${sim_show_time}"
	db_gecho_c "Software : $swc"
	db_gecho_c "Stage : $stg"
	db_gecho_c "Time for cycle ${time_for_cycle}s"
	if [[ $fi> 0 ]]; then 
		db_gecho_c "Total errors in $tot_cycle simulations are $error"
		db_gecho_c "Total number of signals that could be used" 
		db_gecho_c "	for fault injection : $n_of_signal"
		db_gecho_c "Fault tolerance ${fault_tolerance:0:6}%"
		for sig_mean in $signals_mean; do
			db_gecho_c "$(echo $sig_mean )"  #| sed -e 's/\#/ sig\:/g')"
		done
	fi	
	db_gecho_c "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

###########################################################################################
#  SETTING VARIABLES                #######################################################
###########################################################################################

## General variable
CORE_V_VERIF="/home/thesis/elia.ribaldone/Desktop/core-v-verif"
COMMONMK="$CORE_V_VERIF/cv32/sim/core/sim_FT/Common.mk"

isnumber='^[0-9]+$'

CUR_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
SIM_FT="$CUR_DIR/sim_FT"

ARCH_TO_USE="ft"
ARCH_TO_COMPARE="ref"
export $ARCH_TO_USE
export $ARCH_TO_COMPARE

# Folder that contain *.c file (and after compilation the *.hex file) of
# unique program to use as architecture firmware
UNIQUE_CHEX_DIR="$CORE_V_VERIF/cv32/tests/programs/custom_FT/general_tests/hello-world"
U_LOG_DIR="$CORE_V_VERIF/cv32/sim/core/u_log"
mkdir -p $U_LOG_DIR

# Folder that contain the build_all.py program runned to compile all benchmark
BENCH_BUILD_FILE="$CORE_V_VERIF/cv32/tests/programs/custom_FT/build_all.py"
#BENCH_BUILD_FILE="$CORE_V_VERIF/cv32/tests/programs/custom_FT/coremark/build-coremark.sh"
# Folder that contain *.hex file of benchmar
BENCH_HEX_DIR="$CORE_V_VERIF/cv32/tests/programs/custom_FT/out"
B_TYPE=""
B_FILE=""
B_NUM=0
B_LOG_DIR="$CORE_V_VERIF/cv32/sim/core/bench_log"
mkdir -p $B_LOG_DIR
# common parameter
CHEX_FILE=" "
VSIM_EXT=""
export GUI=""
export SIM_BASE="tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i"
export STAGE_NAME="if_stage"

VERBOSE=1

# ARCH
A_REF_REPO="https://github.com/RISKVFT/cv32e40p.git"
A_REF_BRANCH="master"
A_REF_REPO_NAME="cv32e40p_ref"
A_FT_REPO="https://github.com/RISKVFT/cv32e40p.git"
A_FT_BRANCH="master"
A_FT_REPO_NAME="cv32e40p_ft"

# Set variable are used to correctly end program if only
# this action are done, for example if only git repo 
# is setted the program should ended since all is done
ARCH=0
SET_ARCH=0
SET_DIR=0
SET_LOG=0
SET_BLOCK=0
SET_UPI=0
#TEST_DIR="$CUR_DIR/../../tests/programs/MiBench/"
#TEST_DIR="$CUR_DIR/../../tests/programs/riscv-toolchain-blogpost/out"
CLEAROUT=0
TERMINAL_PID=""
export CYCLE=1

# Error variale
ERROR_DIR="$CORE_V_VERIF/cv32/sim/core/sim_FT/sim_out"
ERROR_DIR_BACKUP="$CORE_V_VERIF/cv32/sim/core/sim_FT/.sim_out_backup"
SIM_IDS=""
compare_error_file_prefix="cnt_error_"
info_file_prefix="info_"
cycle_file_prefix="cycle_"
signals_fi_file_prefix="signals_fault_injection_"
export SIM_CYCLE_NUMBER_FILE="$ERROR_DIR/cycles_number_coverage.txt"

SEND=0
PIPENAME=""

###########################################################################################
#  CLONE of cv32e40p  repository    #######################################################
###########################################################################################

# Verify that the ref and ft architecture exist otherwise clone it
function verify_branch(){
	local ft_repo=$CORE_V_VERIF/core-v-cores/$A_FT_REPO_NAME
	local ref_repo=$CORE_V_VERIF/core-v-cores/$A_REF_REPO_NAME
	local gitref="git --git-dir $ref_repo/.git"
	local gitft="git --git-dir $ft_repo/.git"
	
	cd $CORE_V_VERIF/core-v-cores/
	if test -d  $ref_repo ; then
		local current_branch=$($gitref branch | grep \* | cut -d " " -f 2)

		# Verify if the current branch is equal to the setted branch
		if [[ $current_branch != $A_REF_BRANCH ]]; then
			# Verify if user want to change branch
			ask_yesno "Are you sure to change REF branch from\
					$current_branch to $A_REF_BRANCH?? (y/n)"
			if [[ $ANS -eq 1 ]];then
				# Checkout of setted branch if current branch is different
				$gitref checkout $A_REF_BRANCH 
				make -C $ref_repo deps
			fi
		else
			# If the current branch is correct we pull from git 
			$gitref pull $A_REF_REPO
		fi
	else
		# Clone repository if it doesn't exists
		git clone -b $A_REF_BRANCH $A_REF_REPO $A_REF_REPO_NAME 
		make -C $ref_repo deps
	fi

	if test -d  $ft_repo; then
		local current_branch=$($gitft branch | grep \* | cut -d " " -f 2)

		# Verify if the current branch is equal to the setted branch
		if [[ $current_branch != $A_FT_BRANCH ]]; then
			# Verify if user want to change branch
			ask_yesno "Are you sure to change FT branch from\
					$current_branch to $A_FT_BRANCH?? (y/n)"
			if [[ $ANS -eq 1 ]];then
				# Checkout of setted branch if current branch is different
				$gitft checkout $A_FT_BRANCH 
				make -C $ft_repo deps
			fi
		else
			# If the current branch is correct we pull from git 
			$gitft pull $A_FT_REPO
		fi
	else
		git clone -b $A_FT_BRANCH $A_FT_REPO $A_FT_REPO_NAME
		make -C $ft_repo deps
	fi

	# return to previous dir
	cd -
}


###########################################################################################
#  ARGUMENT HANDLER AND ELABORATION #######################################################
###########################################################################################


function find_args () {
        local len=0
        ARGS=""
        while [[ $1 != '' ]] && ! [[ $1 =~ ^-[a-zA-Z\-]*$ ]] ; do
		echo "arg: $1"
                ARGS="$ARGS $1"
                let len=len+1
                shift
        done
        N_ARGS=$len
}

function elab_par ( ) {
	ELABPAR="$ELABPAR $1"
}

## Variable for parametrization
BENCHMARK=0
UNIQUE_FILE=0
COMPILATION=0
SIMULATION=0
SFIUPI=0
QSFIUPI=0
ESFIUPI=0

ELABPAR=""
while [[ $1 != "" ]]; do
	echo "p1 : $1"
	case $1 in	
		########################################################################
		# SETTING options
		########################################################################
		-g|--gui)
			db_becho "INFO: -g -> setted GUI for sim"
			export GUI="-gui"
			shift
			;;
		-co|--clear-output)
			db_becho "INFO: -co -> some output will be cleared from colors"
			CLEAROUT=1
			shift
			;;
		-s|--send)
			db_becho "INFO: -send -> qsfiupi simulation will use mail"
			SEND=1
			shift
			;;
		-q|--quiet)
			db_becho "INFO: -q -> the script will not be verbose"
			VERBOSE=0
			shift
			;;
		-p|--pipe)
			shift
			PIPENAME=$1
			shift 
			;;
		-upi|--use-previous-input)
			# This option enable the use of .vcd file as input of simulation
			# the .vcd file should be previously create using a tcl script in simulation
			# and will be located in ./dataset/ 
			db_becho "INFO: -upi -> simulation will use previous input"
			SET_UPI=1
			shift
			;;
		-ci|--clear-id)
			elab_par $1
			shift
			# Clear data associated  to a simulation
			# you could use regular expression
			AR_ci_id="$1"
			shift
			;;
		-rsb|--restore-simulation-backup)
			shift
			# Restore previous backup of simulations 
			cp $ERROR_DIR_BACKUP/* $ERROR_DIR
			;;
		-a|-arch)
			ARCH=1
			elab_par $1
			shift # delete -a			
			find_args $@ 
			AR_a_args=$ARGS
			shift $N_ARGS
			;;

		########################################################################
		# INFO option
		########################################################################
		-asi|--available-sim-info)
			db_gecho "These are the simulation ids currently available:"
			for i in $SIM_IDS; do
				db_gecho "		$i"
			done
			exit
			;;
		-h|--help)
			UsageExit 		
			shift	
			;;
		
	
		########################################################################
		# SIMULATION option
		########################################################################
		-u|--unique-program) # simulate a single program also not in benchmark
			UNIQUE=1
			elab_par $1
			shift # delete -u
			find_args $@ 
			AR_u_args=$ARGS
			shift $N_ARGS	
			;;
		-b|--benchmark) # simulate one,many, all benchmark programs 
			BENCHMARK=1	
			elab_par $1
			shift			
			find_args $@ 
			AR_b_args=$ARGS
			shift $N_ARGS
			;;
		-sfiupi|--stage_fault_injection_upi) # simulate benchmarch programs with fault injection
			SFIUPI=1
			elab_par $1
			shift			
			find_args $@ 
			AR_sfiupi_args=$ARGS
			shift $N_ARGS
			;; 
		-ssa|--save_stage_all) # create the input .vcd and ouput .wlf for upi simulation
			shift
			# Save in and out of a stage 
			if [[ $2 =~ "core" ]]; then
				local real_stg="cv32e40p_$2"
			else
				local real_stg=$2
			fi
			verify_branch
			verify_upi_vcdwlf $1 $2 $real_stg
			exit 1
			;;
		-qsfiupi) # manage sfiupi simulation using a new terminal and a progression bar, send mail also
			QSFIUPI=1
			elab_par $1
			shift			
			find_args $@ 
			AR_qsfiupi_args=$ARGS
			echo "qsfiupi args; $AR_qsfiupi_args"
			shift $N_ARGS
			;;
		
		########################################################################
		# ELABORATION option
		########################################################################
		-esfiupi) # elaborate previous simulation created with qsfiupi o sfiupi, use for fault injection
			ESFIUPI=1
			elab_par $1
			shift
			find_args $@ 
			AR_esfiupi_args=$ARGS
			shift $N_ARGS
			;;


		########################################################################
		# OPTION ERROR handle
		########################################################################
		*)
			echo "Wrong argument!!!!"
			UsageExit
			;;
	esac
done
echo "elabpar : $ELABPAR"

#####################################################################################################
# CONTROLS 
####################################################################################################

verify_branch



#####################################################################################################
# EXECUTION of simulation 
####################################################################################################

for par in $ELABPAR;do
	case $par in 
		-ci|--clear-id)
			# AR_ci_id
			clear_id_from_regular_expression $AR_ci_id
			;;
		-a|-arch)
			# AR_a_args
			set_sim_arch $AR_a_args
			;;
		-u|--unique-program)
			# AR_u_args
			sim_unique_program $AR_u_args
			;;
		-b|--benchmark)
			# AR_b_args
			sim_benchmark_programs $AR_b_args
			;;
		-qsfiupi)
			# AR_qsfiupi_args
			manage_stage_fault_injection_upi $AR_qsfiupi_args
			;;
		-sfiupi|--stage_fault_injection_upi)
			# AR_sfiupi_args
			sim_stage_fault_injection_upi $AR_sfiupi_args
			;;
		-esfiupi)
			# AR_esfiupi_args
			elaborate_simulation_output $AR_esfiupi_args
			;;
		*)
			db_recho "ERROR: something goes wrong in the script!! in the for of elaboration"
			exit
			;;
	esac
done



