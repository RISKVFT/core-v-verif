#!/bin/bash

source ccommon.sh
echo "argomenti: $@"

rm -f comp_sim_tmp.sh
cp comp_sim.sh comp_sim_tmp.sh

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT
trap exit_f EXIT
#######################################################################
# pipes
name=$(echo $USER | tr '.' '_')
name=$(echo ${name}_again)
pipe_in="/tmp/save_in_$name"
pipe_out="/tmp/save_out_$name"
ALL_SW_PIPE="/tmp/pipe_info_all_$name"
pipe_info="/tmp/pipe_info_$name"
file_info_mail="/tmp/time_$ID_$name.txt"
pipe_cov_simulation="/tmp/pipe_simulation_$name"



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
	# and delete pipe
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
	man ./comp_sim_man
	exit 1
}

#############################################################################################################
#############################################################################################################
#  SUPPORT FUNCTION #########################################################################################
#############################################################################################################

############################################################################
# Color printer function
# Parmeters:
#	VERBOSE -> (1/0) if it is 1 the function print $1
#	CLEAROUT -> (1/0) if it is 0 the output is colored, otherwise is without color
#
vecho () { 
	if [[ $VERBOSE ]]; then 
		if [[ $CLEAROUT == 1 ]]; then 
			echo -e "$1";
		else 
			echo -e "${red}${1}${reset}"; 
		fi
	fi 
}
db_recho () { 
	if [[ $VERBOSE ]]; then 
		if [[ $CLEAROUT == 1 ]]; then 
			echo -e "$1"; 
		else 
			echo -e "${red}${bold}${1}${reset}" 
		fi
	fi 
}
db_becho () { 
	if [[ $VERBOSE ]]; then 
		if [[ $CLEAROUT == 1 ]]; then 
			echo -e "$1"; 
		else 
			echo -e "${blue}${bold}${1}${reset}" 
		fi 
	fi
}
db_gecho () { 
	if [[ $VERBOSE ]]; then 
		if [[ $CLEAROUT == 1 ]]; then 
			echo -e "$1"; 
		else 
			echo -e "${green}${bold}${1}${reset}"
		fi
	fi
}
db_lgecho () { 
	if [[ $VERBOSE ]]; then
		lgecho "$1" 
	fi
}

refGitIsSet () { 
	if [[ $A_REF_REPO == " " && $A_REF_BRANCH == " " ]]; then 
		echo 0
	else 
		echo 1 
	fi 
}
ftGitIsSet () { 
	if [[ $A_FT_REPO == " " && $A_FT_BRANCH == " " ]]; then 
		echo 0
	else
		echo 1
	fi 
}
############################################################################
# Check if the architecture is ref or ft, otherwise print an error and exit
# Arguments:
#	$1 -> arch
#
function checkArch() {
	if [[ $1 == 'ref' || $1 == 'ft' ]]; then
		return
	else
		recho_exit "[ERR] Error, the architecture can't be $1, should be \"ref\" or \"ft\""
	fi
}

##############################################################################
# Loop in SIM_IDS and check if there is the corresponding id of simulation
# Arguments: 
#	$1 -> Id of the simulation
# Parameters:
#	SIM_IDS -> list of current simulation ids
#
idExists () {
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

#############################################################################
# Execute a command in another terminal saving the new terminal pid
# in TERMINAL_PID variable, in this way we can terminate it with kill_terminal
# Arguments:
#	$1 -> command to execute
#	$2 -> name of the new terminal, used for track the terminal
# Variables:
#	CUR_DIR -> The new terminal will execute the command in this directory
#	TERMINAL_PID -> In this variable are stored pid_terminalname
#
execute_in_terminal() {
	local cmd="$1"
	local tname="$2"
	mate-terminal --window --working-directory="$CUR_DIR" --command="$cmd"  --disable-factory &
	TERMINAL_PID="$TERMINAL_PID $!_$tname"
}

#############################################################################
# This function kill a specific terminal opened by execute_in_terminal function
# using TERMINAL_PID information and the name of the terminal given as argument
# Arguments: 
#	$1 -> Name of terminal to kill
#
kill_terminal () {
	local tname=$1
	local new_terminal_pid=""
	for pid_name in $TERMINAL_PID; do
		echo "$pid_name"
		if [[ $(echo $pid_name | cut -d "_" -f 2-) == $tname ]] ; then
			echo "pid: $(echo $pid_name | cut -d "_" -f 1)"
			kill -9 $(echo $pid_name | cut -d "_" -f 1)
		else
			new_terminal_pid="$new_terminal_pid $pid_name"
		fi
	done
	TERMINAL_PID="$new_terminal_pid"
}

##############################################################################
# This function delete a pipe given as argument
# Argument:
#	$1 -> pipename
#
function delete_pipe ()  {
	local pipename=$1
	rm $pipename
	#find /tmp -maxdepth 1 -name pipe_* -delete 
}

##############################################################################
# Check if a pipe exists or not
# Arguments: 
#	$1 -> pipename
#
function check_pipe () {
	local pipename=$1
	if [[ ! -p $pipename ]]; then
		db_recho "ERROR: The pipe $pipename doesn't exist!!"
		exit	
	fi
}

##############################################################################
# Read a pipe, this function block program execution until something is written
# in the pipe
# Arguments:
#	$1 -> Pipename
# Return:
#	It prints data readed from the pipe
#
function read_pipe () {
	local pipename=$1
	check_pipe $pipename
	read line < $pipename
	echo $line
}

##############################################################################
# This function write in the PIPENAME pipe that is the pipe setted using -p option
# in the script.
# Arguments
#	$1 -> data to print in the PIPENAME pipe
#
function write_PIPENAME () {
	local pipename=$PIPENAME
	local towrite=$1
	if [[ $pipename != "" ]]; then
		echo $towrite > $PIPENAME
	fi
}

##############################################################################
# Read the pipe $1 until the data readed is $2.
# Arguments:
#	$1 -> pipename
#	$2 -> name checked every time that the pipe is written, when
#		in the pipe is found $2 the function exit
#
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

#########################################################################à###
# This function wait until a pipe return "exit" and then kill the a terminal
# Arguments:
#	$1 -> pipename to wait
#	$2 -> name of the terminal to kill (we used TERMINAL_PID to find
#		pid of the terminal and then kill it).
#
function kill_terminal_when_it_finished () {
	local pipename=$1
	local wname=$2
	pulling_pipe $pipename "exit"
	kill_terminal $wname
}

#############################################################################
# This function verify that  the ARCH_TO_COMPARE architecture has been already 
# simulated with a specific software and stage so that the corrisponding 
# vcd file (for input ) and wlf file (for output) has been created.
# If this file there isn't we run the two simulations to create them.
# Arguments:
#	$1 -> name of the software with "-" but without the extension
#	$2 -> name of the stage during simulation (instance name)
#	$3 -> name of the stage definition
# Variables:
#	ARCH_TO_COMPARE -> This is the architecture used, the vcd and wlf should be related 
#			to this architecture
#
verify_upi_vcdwlf () {
	# Verify that vcd (for input signals) and wlf (for output) exist, otherwise create it
	local sw=$1 # name of the software 
	local stg=$2 # name of the stage without cv32e40p if core
	local real_stg=$3

	swc=$(echo $sw | tr '-' '_')
	db_becho "INFO: ./sim_FT/dataset/gold-${ARCH_TO_COMPARE}-${real_stg}-${swc}-in.vcd exists?"
	if [[ ! -f ./sim_FT/dataset/gold-${ARCH_TO_COMPARE}-${real_stg}-${swc}-in.vcd ]]; then
		mkfifo $pipe_in
		# Creation of vcd that contain input of stage
		db_becho "PROCESS: Creation of vcd that contains inputs of the stage $stg with program $sw ..."
		execute_in_terminal "./comp_sim.sh -b atsbv $ARCH_TO_COMPARE $ARCH_TO_COMPARE $sw $stg save_data_in -p $pipe_in" "save_in"
		kill_terminal_when_it_finished "$pipe_in" "save_in"
		delete_pipe "$pipe_in"
	fi
	if [[ ! -f ./sim_FT/dataset/gold-${ARCH_TO_COMPARE}-${real_stg}-${swc}-out.wlf ]]; then
		mkfifo $pipe_out
		# Creation of vcd that contain input of stage
		db_becho "PROCESS: Creation of wlf that contains output of the stage $stg with program $sw ..."
		execute_in_terminal "./comp_sim.sh -b atsbv $ARCH_TO_COMPARE $ARCH_TO_COMPARE $sw $stg save_data_out -g -p $pipe_out" "save_out"
		kill_terminal_when_it_finished "$pipe_out" "save_out"
		delete_pipe "$pipe_out"
	fi

	
}

#####################################################################################################
# This function find how long the simulation should it last using *in.vcd file of ARCH_TO_COMPARE 
# architecture.
# Arguments:
#	$1 -> name of the software with "-" but without the extension
#       $2 -> name of the stage during simulation (instance name)
#       $3 -> name of the stage definition
# Variables:
#	ARCH_TO_COMPARE -> This is the architecture used, the vcd and wlf should be related 
#			to this architecture
# Returns: 
#	endsim -> in this variable is stored the ns of simulation
#
findEndsim () {
	local sw=$1
	local real_stg=$2
	
	swc=$(echo $sw | tr '-' '_')
	db_becho "INFO: vcd input file = ./sim_FT/dataset/gold-${ARCH_TO_COMPARE}-${real_stg}-${swc}-in.vcd"

	endsim="$(( $(tail -n 2 ./sim_FT/dataset/gold-${ARCH_TO_COMPARE}-${real_stg}-${swc}-in.vcd | head -n 1 | tr -d "#") - 1 ))"

	db_becho "INFO: endsim = $endsim"
}

###########################################################################################
# This function check if an id exist in SIM_IDS and simply exit if the id doesn't exists
# Arguments:
#	$1 -> Id value
#	
function check_id () {
	if [[ $(idExists $1) == "0" ]]; then
		db_recho "Error: ID not found, these are the available IDS: $SIM_IDS"
		exit
	fi
}

################################################################################à
# This function send a mail to elia, marcello or luca looking at root name
# Arguments:
#	$1 -> mail text
#
sendMailToAll_ifyes () {
	if [[ $1 -eq 1 ]]; then
		sendMailToAll $1
	fi
}

############################################################################################
# This function execute the makefile with correct configuration
# the arguments used are:
#	$1 -> firmware   Is the name of the firmware (with .hex estension) to simulate in 
#			the architecture, it should be in BENCH_HEX_DIR dir.
# These instead are the variable used for makefile and vsim setting
#	SET_UPI -> (1/0) If it is 1 we use questa-sim-stage rule and so we set -vcdstim while 
# 			we run vsim, in this way the file ${GOLD_NAME}_in.vcd will be used 
# 			as input stimulus for the simulation
#	ARCH_TO_COMPARE -> Is the name of the gold architecture, or if we use FI will be the 
#				same architecture, this variable is used to find the correct 
#				vcd input file to use as stimulus
#	STAGE_NAME -> Is the name of the block as it is defined in simulation, to see this name
#			you should go in the core definition and see as each stage is defined,
#			in cv32e40p the core for example is defined as "cv32e40p_core" in the 
#			wrapper and the file .sv is "cv32e40p_core.sv" so 
#			STAGE_NAME will be "cv32e40p_core" and B_STAGE will be the same. But the if stage 
#			for example is intanced as "if_stage" in the core while the 
#			file is "cv32e40p_if_stage.sv" so STAGE_NAME will be "if_stage" while B_STAGE 
#			will be "cv32e40p_if_stage"
#	B_STAGE -> see STAGE_NAME
#	VSIM_EXT -> This is the extension of the tcl file used for the simulation, the complete tcl file name
#		will be "vsim$(VSIM_FT).tcl" and it should be located in core-v-verif/cv32/sim/questa
#	ARCH_TO_USE ->  (ft, ref) This is the architecture to use for simulation, this arch will be used to
#			identify the correct directory of the architecture 
#			( core-v-verif/core-v-cores/cv32e40p$(ARCH_TO_USE) )
#	BENCH_HEX_DIR -> This is the directory in which there is the firmware given with $1 argument
#	GUI -> (-gui/) If this variable is equal to gui the -gui the gui will be opened for vsim simulation
#	GOLD_NAME -> is the base name of the golden files (wlf and vcd) used as stimulus, this paramter
#		is used in vsim_save_data_*.tcl script to know how to call the output wlf and vcd files, 
#		it is also used in vsim_stage_compare in order to open the correct ouput file and in 
#		the makefile to give the correct input vcd ( when SET_UPI=1)
#	
f_make () {
        firmware=$1
	firmware_converted="$(echo $firmware | tr '-' '_')"

	export FT="$VSIM_EXT"
	export ARCH="_$ARCH_TO_USE"
	export TEST_FILE="$BENCH_HEX_DIR/${firmware:0:-4}"
	
	if [[ $VSIM_EXT == "_save_data_*" ]]; then
		echo "****** save_data ********" 
		export ARCH="_$ARCH_TO_COMPARE"
	fi

	if [[ $SET_UPI -eq 0 ]]; then
		# If we don't use the previous input GOLD_NAME is only used by save_data_in and 
		# save_data_out and so the name of the vcd and wlf are related to used architecture
		export GOLD_NAME="gold-${ARCH_TO_USE}-${STAGE_NAME}-${firmware_converted:0:-4}"
		export GOLD_NAME_DATASET="gold-${ARCH_TO_COMPARE}-${STAGE_NAME}-${firmware_converted:0:-4}"
		db_gecho "[INFO] FT=$FT ARCH=$ARCH TEST_FILE=$TEST_FILE GOLD_NAME=$GOLD_NAME"
    		make -C $SIM_FT questa-sim$GUI 
	else 
		# If we are using previous input we compare the used architecture with the 
		# ARCH_TO_COMPARE architecture, so we use the vcd of this arch
		export GOLD_NAME="gold-${ARCH_TO_COMPARE}-${STAGE_NAME}-${firmware_converted:0:-4}"
		export GOLD_NAME_SIM="$(echo $GOLD_NAME | tr '-' '_')"
		db_gecho "[INFO]: STAGE:  $B_STAGE"
		db_gecho "[INFO] FT=$FT ARCH=$ARCH TEST_FILE=$TEST_FILE GOLD_NAME=$GOLD_NAME"
		make -C $SIM_FT questa-sim-stage$GUI STAGE=$B_STAGE 
	fi
}


############################################################################################
#  SETTING and MANAGING FUNCTIONS
############################################################################################

############################################################################################à
clear_id_from_regular_expression_help () {
echo -e "
# This function create a backup of simulation file in ERROR_DIR and then delete files selected 
# Arguments:
#	 \$1 -> regular expression used to find file to delete
# Variabili:
#	ERROR_DIR_BACKUP -> complete path of the backup directory to  use 
#	ERROR_DIR -> Directory in which are located simulation files
#	SIM_IDS -> List of IDS of all simulation done up to now
#"
}
function clear_id_from_regular_expression () { 
	# Called by -c option
	# $1 regular expression
	
	if [[ $(check_fio $arg -h -H h -help --help) == 1 ]]; then
		clear_id_from_regular_expression_help
		exit 1;
	fi
	
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

##############################################################################################
set_sim_arch_help () {
echo -e "
# Called by -a option
# With this function you can set ref and ft repo and branch. 
# Arguments:
#	\$1 -> (refr, refb, ftr, ftb, i, simbase) this argument define what architecture you are setting
#		or give you info about current setting:
#		refr -> set the REPO of the reference architecture e.g. https://github.com/RISKVFT/cv32e40p.git
#		refb -> set the BRANCH of the reference architecture  e.g. master
#		ftr -> set the REPO of the fault tolerant arch
#		ftb -> set the BRANCH of the fault tolerant arch
# 		i -> give info about current arch setting
#		simbase -> you can set the base of the simulation 
#	\$2 -> the argument processed according to \$1
# Variables setted by the function:
#	A_REF_REPO -> the name of the repo of the reference arch
#	A_REF_BRANCH -> the name of the branch of the reference arch
#	A_FT_REPO -> The name of the fault tolerant repo
#	A_FT_BRANCH -> the name of the ft branch
#	SIM_BASE -> this variable
# Variables used:
#	CUR_DIR -> directory of this script
# "
}
function set_sim_arch () {
	
	if [[ $(check_fio $1 -h -H h -help --help) == 1 ]]; then
		set_sim_arch_help
		exit 1;
	fi
	
	case $1 in
		refb)
			if ! gitRepoBranchExist $A_REF_REPO $2; then
				recho_exit "Error: branch of $2 doesn't exist!!"
			fi
			db_becho "Setted \n	REF_BRANCH=$2"
			A_REF_BRANCH=$2
			repfile "A_REF_BRANCH" "$CUR_DIR/$(basename $0)" $2
			shift 2;;	
		refr)
			if ! gitRepoExist "$2"; then
				recho_exit "Error: git repo doesn't exist!!!"
			fi
			db_becho "Setted \n	REF_REPO=$2"
			A_REF_REPO=$2
			repfile "A_REF_REPO" "$CUR_DIR/$(basename $0)" $2
			shift 2;;	
		ftr)
			if ! gitRepoExist "$2"; then
				recho_exit "Error: git repo doesn't exist!!!"
			fi
			db_becho "Setted \n	FT_REPO=$2"
			A_FT_REPO=$2
			repfile "A_FT_REPO" "$CUR_DIR/$(basename $0)" $2
			shift 2;;
		ftb)
			if ! gitRepoBranchExist $A_FT_REPO $2; then
				recho_exit "Error: branch of $2 doesn't exist!!"
			fi
			db_becho "Setted \n	FT_BRANCH=$2"
			A_FT_BRANCH=$2
			repfile "A_FT_BRANCH" "$CUR_DIR/$(basename $0)" $2
			shift 3;;
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


#########################################################################################
sim_unique_program_help () {
echo -e "
# Called with -u option
# This function can:
# 	- compile a \$(name).c file in a directory called \$(name)  (d option)
#	- simulate the \$(name).c file in \$(name) directory (d option) with a specified architecture (a option) 
# The option work in this way:
#       comp_sim -u [c][s][a][v][d][l] [a_arg][v_arg][d_arg][l_arg]
# The order of the 
# Option:
#	c -> set compilation
#	s -> set simulation
#	a [ref|ft] -> (ref, ft) set ARCH_TO_USE with the corrisponding argument 
#       v tcl_extension -> set VSIM_EXT that is appended to "vsim_" in order to find tcl script
#			located in core-v-verif/cv32/sim/questa
#	d hex_dir -> set UNIQUE_CHEX_DIR variable that is the path (from CORE_V_VERIF) of the
#		directory where there is the file to compile or simulate. The name of this
#		file should be the same of the directory
#	l log_dir -> Set the log dir
# Parmeterus:
#	ARCH_TO_USE
# 	CHEX_FILE
#	VSIM_EXT
#	UNIQUE_CHEX_DIR
# 	CORE_V_VERIF
# 	U_LOG_DIR
#  	"
}
function sim_unique_program () {
	arg=$1
	shift # delete args string
	
	if [[ $(check_fio $arg -h -H h -help --help) == 1 ]]; then
		sim_unique_program_help
		exit 1;
	fi

	# cycle on args string
	for (( i=0; i< ${#arg}; i++ )) ; do
		case ${arg:i:1} in
			a) # select the architecture to test
				checkArch "$1"
				ARCH_TO_USE="$1"
				SetVar "ARCH_TO_USE" "$ARCH_TO_USE"
				export $ARCH_TO_USE
				shift;;
			c) # case like "-u cf filename" only compilation or both
				db_becho "To do: compilation"
				COMPILATION=1;;
			s) # case like "-u sf filename" only simulation or both
				db_becho "To do: simulation"
				SIMULATION=1;;
			f) # TO_DO --> 
                           # parameter to give filename of .c file to compile or to 
			   # simulate their name should be the same apart the extention
			   # cmd like"-u csf filename" o "-u csfv filename vsimname"
			   	recho_exit "[ERR] f option isn't implemented"
				db_becho "Set filename of *.c file to $1.c"
				CHEX_FILE=$1; shift;;
			v) # parameter to give extension to append to the vsim file 
			   # used to execute simulation in vsim and stored in
			   # core-v-verif/cv32/sim/questa
				db_becho "Set vsim extension to _$1"
				VSIM_EXT="_$1"; shift;;
			d) # 
				SET_DIR=1
				UNIQUE_CHEX_DIR=${CORE_V_VERIF}/$1
				dirorfile=$1
				db_gecho "[INFO] Set directory of execution at UNIQUE_CHEX_DIR=$UNIQUE_CHEX_DIR"
				dfSetVar d $dirorfile "UNIQUE_CHEX_DIR" "Set hex/c file directory" \
					"give a correct directory for executable and hex!!"
				shift;;
			l)
				SET_LOG=1
				U_LOG_DIR=$1
				db_gecho "[INFO] Set log dir at U_LOG_DIR=$U_LOG_DIR"
				dfSetVar d $1 "U_LOG_DIR" "Set log file directory" \
					"give a correct directory for log file!!" CREATE
				shift;;
				
			*)
				
			
		esac
	done
	# Check tcl file extension
	if [[ $VSIM_EXT == " " ]]; then
		if ! test -f $CORE_V_VERIF/cv32/sim/questa/$VSIM_EXT; then
			recho_exit "Error: when you give 'v' parameter you should give\
			the correct\n extension of a vsim_EXTENSION.tcl file in \
			core-v-verif/cv32/sim/questa directory!! "
		fi
	fi	 
	# Check dircetory of execution, the .c file should have the same name 
	if [[ $UNIQUE_CHEX_DIR == " "  ]]; then	
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

###########################################################################################
sim_benchmark_programs_help () {
 echo -e "
# Called by -b option
# This function compile and simulate program that are in a benchmark, for compilation 
# require an executable script (d option) and the directory of the *.hex that the script
# will create.
# Synopsis:
#	comp_sim.sh -b [c][s][a][t][v][d][l][b] [s_arg][a_arg][t_arg][v_args][d_args][l_args][b_arg]
# Options:
#	a [ref|ft] -> set ARCH_TO_USE with the corrisponding argument
#	t [ref|ft] -> set ARCH_TO_COMPARE with the corrisponding argument
#	c -> Compile your benchmark programs using the executable script given using 'd' option,
#		the script should compile all programs you need and place the *.hex files in the directory 
#		setted uding 'd' option. 
#	s [a|number|name] -> Can simulate in different way;
#		s a -> Simulate all executable file in the BENCH_HEX_DIR dir (setted with 'd' option)
#		s 3 -> simulate the first 3 *.hex in the BENCH_HEX_DIR dir
#		s hello_world -> Simulate hello_world.hex if it is present in the BENCH_HEX_DIR dir.
#	v [tcl_extention_name|cov] -> This option set the tcl to use for simulation , final tcl file will be 
#		vsim_\"tcl_extension_name\".tcl and should be located in /cv32/core/questa directory.
#		If we run \"v cov\" the function set VSIM_EXT as _cycle_to_certain_coverage, this means that
#		will be calculated the number of cycle for a certain coverage. See vsim_cycle_to_certain_coverage.tcl
#		for further info.
#	d [build_file] [hex_out_dir] -> This option set th build executable file used to compile all 
#	 	benchmark, and  the directory where all *.hex file will be (final directory will be
#		\$CORE_V_VERIF/hex_out_dir)
#	l [dir] -> Set log dir (final directory will be \$CORE_V_VERIF/dir)
#	b [block_name] -> set the stage name to simulate (final name will be cv32e40p_"block_name")
# Variable:
#	ARCH_TO_USE -> Architecture to simulate, setted with \"a\" option
#	ARCH_TO_COMPARE -> Architecture to compare, setted with \"t\" option
#	COMPILATION -> If 1 compile
#	SIMULATION -> if 1 simulate
#	B_TYPE -> Type of benchmark, all -> simulate all etc, setted with c and s option
#	VSIM_EXT -> Extension of tcl file
#	BENCH_BUILD_FILE -> File used from compile option to compilate all.
#	BENCH_HEX_DIR -> Directory of all hex file
# 	B_STAGE -> is the name of the stage plus cv32e40p, cv32e40p_\$stage_name
#	STAGE_NAME -> Is the name of the stage used in simulation, so for the core
#		is not appended the cv32e40p prefix.
#	COMPARE_ERROR_FILE -> Used by tcl script to know where to save log
#	INFO_FILE -> info file for tcl script
#	CYCLE_FILE -> file used to communicate current cycle
#
"
}
function sim_benchmark_programs () {
	echo "args: $@"
	arg=$1
	shift # delete args string

	if [[ $(check_fio $arg -h -H h -help --help) == 1 ]]; then
		sim_benchmark_programs_help
		exit 1;
	fi
	
	# cycle on args string
	for (( i=0; i< ${#arg}; i++ )) ; do
		case ${arg:i:1} in
			a) #architecture to test
				checkArch "$1"
				ARCH_TO_USE="$1"
				SetVar "ARCH_TO_USE" "$ARCH_TO_USE"
				export $ARCH_TO_USE
				shift;;
			t) #architecture to compare 
				checkArch "$1"
				ARCH_TO_COMPARE="$1";
				SetVar "ARCH_TO_COMPARE" "$ARCH_TO_COMPARE"
				export $ARCH_TO_COMPARE
				shift;;
			c|s) # compile or simulate
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
			d) # set build file, dir oBENCH_HEX_DIR/SET_BLOCKf out *.hex file and exit
				SET_DIR=1
				BENCH_BUILD_FILE="$CORE_V_VERIF/$1"
				dirorfile=$1
				dfSetVar f "$dirorfile" "BENCH_BUILD_FILE" "Set benchmark build file" \
					"give a correct path/name for build file!!"
				shift
				BENCH_HEX_DIR="$CORE_V_VERIF/$1"
				dirorfile=$1
				dfSetVar d "$dirorfile" "BENCH_HEX_DIR" "Set benchmark hex file dir"\
					"give a correct directory of hex directory !!" 
				shift
				# if user set d variables can't do nothing else
				exit 1;;
			l)
				SET_LOG=1
				B_LOG_DIR="$CORE_V_VERIF/$1"
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

	if [[ $VSIM_EXT == " " ]]; then
		if ! test -f $CORE_V_VERIF/cv32/sim/questa/$VSIM_EXT; then
			recho_exit "Error: when you give 'v' parameter you should give\
			the correct\n extension of a vsim_EXTENSION.tcl file in \
			core-v-verif/cv32/sim/questa directory!! "
		fi
	fi	 
	
	if  [[ $VSIM_EXT == "_cycle_to_certain_coverage" ]]; then
		export SWC="$(echo $B_FILE | tr '-' '_')"
		findEndsim $SWC $STAGE_NAME
		export T_ENDSIM=$endsim
		db_becho "ENDSIM = $T_ENDSIM"
	fi
	
	# To use stage compare we should use sfiupi since many variable should set and monitored
	if  [[ $VSIM_EXT == "_stage_compare" && $SSFIUPI == 0 ]]; then
		recho_exit "[ERR] Use sfiupi or qsfiupi to simulate with vsim_stage_compare.tcl script!!"
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
		cd -
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
					f_make $hex
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
				f_make $hex 
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
				f_make $hex 
			done
			if [[ $FDONE -eq 0 ]]; then
				recho_exit "Error: *.hex file not found in $BENCH_HEX_DIR "		
			fi
		fi

	fi
}

########################################################################################################
manage_stage_fault_injection_upi_help () {
echo "
# Called by -qsfiupi
# This function call -sfiupi option and monitor simulation status using progress bar.
# See -sfiupi for options.
"
}
function manage_stage_fault_injection_upi () {
	# Called by qsfiupi

	FORCE_OVW=""
	if [[ $OVWRITE_SIM == 1 ]]; then
		FORCE_OVW="-f"
	fi
	
	if [[ $(check_fio $1 -h -H h -help --help) == 1 ]]; then
		manage_stage_fault_injection_upi_help
		db_becho "\n\nSFIUPI help :"
		sim_stage_fault_injection_upi_help
		exit 1;
	fi
	
	mkfifo $pipe_info
	local comando="./comp_sim.sh -sfiupi $@ -p $pipe_info $FORCE_OVW"
	local tname="sfiupi"

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

	# If user want to run multiple programs the progress bar will be in
	# the second terminal and in this terminal will be only displayed the
	# name of the program already simulated
	if [[ $CYCLE == "all" ]]; then
		sleep 2
		while true; do
			software=$(read_pipe $ALL_SW_PIPE)		
			if [[ $software == "END" ]]; then
				db_gecho "[Info] All software simulated!!!"
				exit 1;
			fi
			db_gecho "[INFO] $software software is in simulation ..."
			sleep 2
		done
	fi

	
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
	SIM_IDS=$(ls $CORE_V_VERIF/cv32/sim/core/sim_FT/sim_out  | cut -d - -f 2,3,4,5 | sed 's/.txt//g' | sort -u)
	elaborate_simulation_output "$ID"

	kill_terminal "mail"
	exit 
}

#############################################################################################################à
sim_stage_fault_injection_upi_help () {
echo -e "
# This function  use the vsim_stage_compare.tcl script (in cv32/sim/questa) to simulate an architecture
# (setted with \"a\" option) and compare the output with the golden architecture (Setted with \"t\" option), this
# simulation is done for a specific software (setted with \"s\" option), this software should be the name of an 
# *.hex file in the directory of the benchmark output.
# This comparison can be used with fault injection, in this case usually the golden architecture is setted
# equal to the architecture to test, the simulation flow is:
#	- Creation of vcd in and wlf out using \"-b sbv software stage save_data_in\" 
#		and \"-b sbv software stage save_data_out\"
#	- fault injection repeated for a certain number of cycle (10 cycle in this case):	
#		\"-sfiupi atcfsb ref ref 10 1 software stage\"
# 
# If we want to test fault injection with a certain coverage we can set cycle to \"cov\" like this:
#	        \"-sfiupi atcfsb ref ref cov 1 software stage\"
# In this case the function run  the script vsim_cycle_to_certain_coverage.tcl, this script calculate the
# number of cycle of fault injection starting from total number of bits where we can inject the fault.
# Then the script simulate using this number of cycle.
#
# Another feature is the possibility to run all software that are in the hex dir, this directory can be set
# using -b option and it is the directory where are stored all *hex of benchmark software. Therfore we can run
# all software setting \"s\" option equal to \"all\" in this way:
#	\"-sfiupi atcfsb ref ref 10 1 all stage\"  -> simulation with fault injection of all software
#
# General form:
#	comp_sim -sfiupi [a][t][c][f][s][b] args
# Options:
#	a [ref|ft]-> Set ARCH_TO_USE with the corrisponding argument, this is the architecture used 
#			in current simulation.
#	t [ref|ft] -> Set ARCH_TO_COMPARE with the corrisponding argument, the vcd (for input) and wlf
#		(for ouput) of this architecture are used respectively as vcdstim input and output 
#		comparison for ARCH_TO_USE architecture. 
#	c [number|cov] -> set number of fault injection cycle to do, for each cycle a fault is injected in
#		a different signal and the output are compared. If we use \"cov\" the program find the number
#		of cycle that corresponds to a certain coverage using vsim_cycle_to_certain_coverage.tcl script.
#	f [0|1] -> This option is effective if we use vsim_stage_compare.tcl script, this option set 
#		the FI variable that is used by vsim_stage_compare.tcl, if FI is 1 the script make
#		fault injection for CYCLE cycle ()
#	s [software|all] -> Set the name of the software to use for simulation, this software should be in 
#	 	the BENCH_HEX_DIR directory, this dir can be set using \"-b d\" option and is the output dir
#		of the benchmark builder. If we set s option to \"all\" the program will simulate one by one all
#		software that are in BENCH_HEX_DIR directory.
#	b [stage_name] -> this is the stage name that we want to test, set it to core to simulate entire core.
# Variables:
#	All variable setted also by -b option, since -sfiupi use -b to simulate
#	CYCLE -> number of cycle
#	T_ENDSIM -> ns of simulation
#"
}
function sim_stage_fault_injection_upi () {
	
	arg=$1
	shift # delete args string
	
	if [[ $(check_fio $arg -h -H h -help --help) == 1 ]]; then
		sim_stage_fault_injection_upi_help
		exit 1;
	fi
	
	export CYCLE=1
	export FI=0
	CALC_CYCLE_ON=0
	SET_UPI=1
	SSFIUPI=1
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
			c) # cycle
				# metti solo gli export e' via			
				export CYCLE=$1
				if [[ $CYCLE == "cov" ]]; then
					CALC_CYCLE_ON=1
				elif ! [[ $CYCLE =~ $isnumber ]]; then
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
				if [[ $flag -eq 0  && $SW != "all" ]]; then
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
	

	# If we don't use fault injection is useless do cycle.
	#if [[ $FI -eq 0 ]]; then
	#	export CYCLE=1
	#	echo "Fault injection is equal to 0 so you can't cycle, CYCLE=1"
	#fi

	# If CYCLE is setted to "cov" we should calculate the number of cycle 
        # needed for a certain coverage and set it before the simulation	
	if  [[ $CALC_CYCLE_ON -eq 1 ]]; then
		db_becho "Entered"
		CYCLE="cov"	
		if [[ -f "$SIM_CYCLE_NUMBER_FILE" ]]; then
			line=$(cat "$SIM_CYCLE_NUMBER_FILE" | grep "$SWC-$REAL_STG:")
			db_becho "Entered line=$line"
			if [[ $line != "" ]]; then
				CYCLE=$(echo $line | rev | cut -d ":" -f 1 | rev)
			fi
		fi
		db_becho "Entered CYCLE=$CYCLE"
		# If CYCLE don't change means that the cycle for this stage
		# are not already calculated and stored in SIM_CYCLE_NUMBER_FILE file.
		# In this case we should calculate it
		if [[ $CYCLE == "cov" ]]; then
			# execute the tcl script in order to find correct number of cycle
			./comp_sim.sh -b sbv $SW $STG "cov" -upi
			line=$(cat "$SIM_CYCLE_NUMBER_FILE" | grep "$SWC-$REAL_STG:")
			if [[ $line != "" ]]; then
				CYCLE=$(echo $line | rev | cut -d ":" -f 1 | rev)
			fi
			db_becho "CYCLE = $CYCLE"
		fi
		
	fi

	
	# If we want to repeat a benchmark
	FORCE_OVW=""
	if [[ $OVWRITE_SIM == 1 ]]; then
		db_becho "INFO: removing *${STG}-${SWC}-${CYCLE}-${FI}.txt files..."
		rm -f ./sim_FT/sim_out/*${STG}-${SWC}-${CYCLE}-${FI}.txt
		FORCE_OVW="-f"
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

	# Verifica dei file vcd di input e wlf di output
	db_becho "[INFO] real_stg: $REAL_STG"
	db_becho "[INFO] stg: $STG"
	
	############# RUN SIMULATION #############################
	if [[ $SWC == "all" ]]; then
		hexfile=$(cd $BENCH_HEX_DIR; ls *.hex)

		write_PIPENAME "cycle:all"
		db_becho "INFO: send CYCLE through pipe"
		write_PIPENAME "cycle_file:$CYCLE_FILE"
		db_becho "INFO: send CYCLE_FILE through pipe"
		timeone=$(date +%s)
		write_PIPENAME "start_time:$timeone"
		
		sleep 2

		delete_pipe $PIPENAME
		mkfifo $ALL_SW_PIPE
		PIPENAME=$ALL_SW_PIPE
		mkfifo $pipe_cov_simulation
		db_becho "Software: $hexfile"
		for i in $hexfile;do	
			software=$(echo $i | cut -d "." -f 1) 
			db_becho "RUN: -sfiupi atsbfc $ARCH_TO_USE $ARCH_TO_COMPARE $software $STG $FI $CYCLE"
			write_PIPENAME "$software"
			db_becho "[INFO]: Write software in pipe"
			execute_in_terminal "./comp_sim.sh -sfiupi atsbfc $ARCH_TO_USE $ARCH_TO_COMPARE $software $STG $FI $CYCLE -p $pipe_cov_simulation $FORCE_OVW" "simulation"
			db_becho "[INFO]: we are waiting comp_sim running in background"
			kill_terminal_when_it_finished $pipe_cov_simulation "simulation"
			db_becho "[INFO]: Killed terminal"
		done	
		sleep 1
		write_PIPENAME "END"
	else
		verify_upi_vcdwlf $SW $STG $REAL_STG
		############ Save parameter in a log file for -qsfiupi ##########
		write_PIPENAME "cycle:$CYCLE"
		db_becho "INFO: send CYCLE through pipe"
		write_PIPENAME "cycle_file:$CYCLE_FILE"
		db_becho "INFO: send CYCLE_FILE through pipe"
		timeone=$(date +%s)
		write_PIPENAME "start_time:$timeone"

		
		findEndsim $SWC $REAL_STG
		export T_ENDSIM=$endsim
		
		db_becho "Simulation end time $T_ENDSIM"

		if [[ $CYCLE -ne 0 ]]; then
			sim_benchmark_programs atsvb $ARCH_TO_USE $ARCH_TO_COMPARE $SW stage_compare $STG
		else
			rm $ERROR_DIR/*0-0*
		fi
		
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


#######################################################################################
# This function elaborate the ERROR_DIR/signals_fault_injection_$id.txt files created 
# during a fault injection by vsim_stage_compare.tcl script.
# Elaboration are stored in variables:
# 	MEAN_ERROR -> if a fault injection create errors, there will be a certain amounnt of 
#	errors in other signals, in signals_fault_injection_$id file is stored the amount
#	of these errors for each fault injection. MEAN_ERROR is a sequence of string like
#	mean:$(mean_number_of_error)#$(signal_where_fault_is_injected)
#	where the mean_number_of_error is calculated over all fault injection.
#
function signals_elaboration () {
	local id=$1
	local file_sig="$ERROR_DIR/$signals_fi_file_prefix$id.txt"
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
		else
			MEAN_ERROR="$MEAN_ERROR mean:0#$dig"
		fi
	done
}


#################################################################################################
elaborate_simulation_output_help () {
echo -e "
# Called by -esfiupi
# This function elaborate the ouput file of a sfiupi simulation. The file in ERROR_DIR directory
# are used to find and print:
# 	- Simulation identity : software, stage
# 	- Total simulation time in dd:hh:mm 
#	- Time spent for a single simulation cycle
# If we simulate with fault injection are also printed:
#	- The absolute number of fault injected that create an error
#	- Number of singnal that has been used for fault injecton
#	- Percentage of fault tolerance
#
"
}
function elaborate_simulation_output () {
	
	if [[ $(check_fio $1 -h -H h -help --help) == 1 ]]; then
		sim_stage_fault_injection_upi_help
		exit 1;
	fi
	
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
	db_gecho "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	db_gecho "Total simulation time ${sim_show_time}"
	db_gecho "Software : $swc"
	db_gecho "Stage : $stg"
	db_gecho "Time for cycle ${time_for_cycle}s"
	if [[ $fi> 0 ]]; then 
		db_gecho "Total errors in $tot_cycle simulations are $error"
		db_gecho "Total number of signals that could be used" 
		db_gecho "	for fault injection : $n_of_signal"
		db_gecho "Fault tolerance ${fault_tolerance:0:6}%"
		for sig_mean in $signals_mean; do
			db_gecho "$(echo $sig_mean )"  #| sed -e 's/\#/ sig\:/g')"
		done
	fi	
	db_gecho "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

function signals_total_elaboration () {
        local id=$1
        local file_sig="$ERROR_DIR/$signals_fi_file_prefix$id.txt"
        STE_SIGNALS=$(grep All_signals $file_sig | sort -u | cut -d ":" -f 2)
        local signals=$STE_SIGNALS

        # TODO: add percentage of fault tolerance for each signal
        for sig in $signals; do
                local l_errors=$(grep $sig $file_sig | grep sig_fault | tr -s " " |\
                        cut -d " " -f 6 | cut -d ":" -f 2)
                local tot_sim_n=$(echo $l_errors | wc -w )
                local no_err_n=$(echo $l_errors | tr " " "\n" | grep ^0$ | wc -l )
                if [[ $tot_sim_n -gt 0 ]]; then
                        local tot_gen_errors=0
                        for err in $l_errors; do
                                let tot_gen_errors=tot_gen_errors+$err
                        done
                        local mean_gen_errors=$( echo "scale=2; $tot_gen_errors/$tot_sim_n" | bc -l)
                        local percentage_errors=$(echo "scale=3; ($tot_sim_n-$no_err_n)/$tot_sim_n " | bc -l)
                        err_n=$(echo "scale=3; $tot_sim_n-$no_err_n" | bc -l)
                        ERROR_ELAB="$ERROR_ELAB $sig#mean_gen_err:$mean_gen_errors#perc_err:$percentage_errors#err:$err_n#sim:$tot_sim_n"
                else
                        ERROR_ELAB="$ERROR_ELAB $sig#mean_gen_err:0#perc_err:0#err:0#sim:0"
                fi
        done
}

elaborate_all_sim_output_help() { 
echo -e "
# Called by -aesfiupi
# This function elaborate all output caming from a simulation with:
#	- Same stage
#	- Same cycle number
# In this way we could mix many simulation with different software in
# an unique static.
# General form:
#	comp_sim.sh -aesfiupi [h] stage_name cycle_number
# Option:
#	h -> call this man
#
"
}
function elaborate_all_sim_output () {

	if [[ $(check_fio $1 -h -H h -help --help) == 1 ]]; then
		elaborate_all_sim_output_help
		exit 1;
	fi

        local stage=$1
        local cycle=$2

        local ids=$(echo $SIM_IDS | grep "$stage-.*-$cycle-1")
        db_gecho "[INFO] ids elaborated: $ids"
        ERROR_ELAB=""
        for id in $ids; do
                signals_total_elaboration $id
        done
        #signals_total_elaboration if_stage-csr_instructions-384-1
        #echo $ERROR_ELAB
        #echo $STE_SIGNALS
        db_gecho "[INFO] Elaboration ..."
        TOT_SIM_ERR_ELAB=""
        for sig in $STE_SIGNALS; do
                sig_elab=$(echo $ERROR_ELAB | tr " " "\n" | grep $sig)
                db_becho "[INFO] elaboration of $sig"
                local tot_sim=0
                local tot_err=0
                for se in $sig_elab; do
                        tot_sim=$(echo "$(echo $se | tr "#" "\n" | grep sim | cut -d ":" -f 2)+$tot_sim" | bc -l)
                        tot_err=$(echo "$(echo $se | tr "#" "\n" | grep ^err: | cut -d ":" -f 2)+$tot_err" | bc -l)
                done
                local percentage_errors=$(echo "scale=3; $tot_err/$tot_sim" | bc -l)
                TOT_SIM_ERR_ELAB="$TOT_SIM_ERR_ELAB $sig#[perc_err:$percentage_errors#[err:$tot_err#[sim:$tot_sim"
                #db_gecho $TOT_SIM_ERR_ELAB | tr " " "\n"
        done
        SIM_ERR_ELAB_ORD=$(echo $TOT_SIM_ERR_ELAB | tr " " "\n" | tr "#" " " | sed 's/:\./:0\./g' | sort -k 2.12,2.17 -n -r | tr " " "#")

        echo "" > $ERROR_DIR/elab-$stage-all-$cycle-1.txt
        printf "%-90s %5s %5s %5s\n" "Signal_name" "err %" "err_n" "sim_n"\
                >> $ERROR_DIR/elab-$stage-all-$cycle-1.txt
        printf "%-90s %5s %5s %5s\n" "Signal_name" "err %" "err_n" "sim_n"
        for line in $SIM_ERR_ELAB_ORD; do
                arr=($(echo $line | tr "#" " "  | tr ":" "\n" | tr " " "\n" | grep -v "\["))
                printf "%-90s %5s %5s %5s\n" ${arr[0]} ${arr[1]} ${arr[2]} ${arr[3]} \
                        >> $ERROR_DIR/elab-$stage-all-$cycle-1.txt
                printf "%-90s %5s %5s %5s\n" ${arr[0]} ${arr[1]} ${arr[2]} ${arr[3]}
        done
}



###########################################################################################
#  SETTING VARIABLES      #################################################################
###########################################################################################

########################################################################
# FIXED variable       #################################################
########################################################################

CORE_V_VERIF="/home/thesis/marcello.neri/Desktop/core_marcello/core-v-verif_again"

##########################
# Directly setted by cmd line
VERBOSE=1
CLEAROUT=0
##########################

function set_core_v_verif() {
	if [[ "$CORE_V_VERIF" =~ "$USER" ]]; then
		db_gecho "Variables for CORE_V_VERIF already setted!"
	else
		cd ./../../../ 
		CORE_V_VERIF=$(pwd)
		./set_core_v_verif.sh
		cd $CORE_V_VERIF/cv32/sim/core
	fi
}
set_core_v_verif

COMMONMK="$CORE_V_VERIF/cv32/sim/core/sim_FT/Common.mk"

isnumber='^[0-9]+$'

CUR_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
SIM_FT="$CUR_DIR/sim_FT"

ERROR_DIR="$CORE_V_VERIF/cv32/sim/core/sim_FT/sim_out"
ERROR_DIR_BACKUP="$CORE_V_VERIF/cv32/sim/core/sim_FT/.sim_out_backup"
compare_error_file_prefix="cnt_error-"
info_file_prefix="info-"
cycle_file_prefix="cycle-"
signals_fi_file_prefix="signals_fault_injection-"
export SIM_CYCLE_NUMBER_FILE="$ERROR_DIR/cycles_number_coverage.txt"

##########################
# Used by function
#
# Set variable are used to correctly end program if only
# this action are done, for example if only git repo 
# is setted the program should ended since all is done
OVWRITE_SIM=0
ARCH=0
SET_ARCH=0
SET_DIR=0
SET_LOG=0
SET_BLOCK=0
SET_UPI=0
#TEST_DIR="$CUR_DIR/../../tests/programs/MiBench/"
#TEST_DIR="$CUR_DIR/../../tests/programs/riscv-toolchain-blogpost/out"
TERMINAL_PID=""

# Error variale

SEND=0
PIPENAME=""
SSFIUPI=0


########################################################################
# USER DEFINED variable      ###########################################
########################################################################
##########################
# Setted by -u option
#
# Folder that contain *.c file (and after compilation the *.hex file) of
# unique program to use as architecture firmware
UNIQUE_CHEX_DIR="$CORE_V_VERIF/cv32/tests/programs/custom_FT/general_test/fibonacci"
U_LOG_DIR="$CORE_V_VERIF/cv32/sim/core/u_log"
mkdir -p $U_LOG_DIR
VSIM_EXT=""

##########################
# Setted by -b option
#
# Folder that contain the build_all.py program runned to compile all benchmark
BENCH_BUILD_FILE="$CORE_V_VERIF//cv32/tests/programs/custom_FT/build_all.py"
#BENCH_BUILD_FILE="$CORE_V_VERIF/cv32/tests/programs/custom_FT/coremark/build-coremark.sh"
# Folder that contain *.hex file of benchmar
BENCH_HEX_DIR="$CORE_V_VERIF//cv32/tests/programs/custom_FT/out"
B_TYPE=""
B_FILE=""
B_NUM=0
B_LOG_DIR="$CORE_V_VERIF/cv32/sim/core/bench_log"
mkdir -p $B_LOG_DIR

export CYCLE=1

##########################
# Setted by -b and -u option
#
CHEX_FILE=" "
export GUI=""
export SIM_BASE="tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i"
export STAGE_NAME="id_stage"

ARCH_TO_USE="ft"
ARCH_TO_COMPARE="ft"
export $ARCH_TO_USE
export $ARCH_TO_COMPARE


##########################
# Setted by -a option
# 
A_REF_REPO="https://github.com/RISKVFT/cv32e40p.git"
A_REF_BRANCH="master"
A_REF_REPO_NAME="cv32e40p_ref"
A_FT_REPO="https://github.com/RISKVFT/cv32e40p.git"
A_FT_BRANCH="FT_Marcello"
A_FT_REPO_NAME="cv32e40p_ft"
AESFIUPI=0


###########################################################################################
#  Find all IDS                     #######################################################
###########################################################################################

SIM_IDS="cycles_number_coverage
id_stage-coremark_1-663-1
id_stage-counters-663-1
id_stage-csr_instructions-663-1
id_stage-cv32e40p_csr_access_test-663-1
id_stage-dhrystone-663-1
id_stage-fibonacci-663-1
id_stage-generic_exception_test-663-1
id_stage-hello_world-200-1
id_stage-hello_world-663-1
id_stage-illegal-663-1
id_stage-interrupt_bootstrap-663-1
id_stage-interrupt_test-663-1
id_stage-misalign-663-1
id_stage-modeled_csr_por-663-1
id_stage-perf_counters_instructions-663-1
id_stage-requested_csr_por-663-1
id_stage-riscv_arithmetic_basic_test_0-663-1
id_stage-riscv_arithmetic_basic_test_1-663-1
id_stage-riscv_ebreak_test_0-663-1
sim_out_ft
sim_out_ref"
SIM_IDS_SUP=$(ls $CORE_V_VERIF/cv32/sim/core/sim_FT/sim_out  | cut -d - -f 2,3,4,5 | sed 's/.txt//g' | sort -u)
SIM_IDS=$SIM_IDS_SUP
SetVar "SIM_IDS" "$SIM_IDS_SUP"

###########################################################################################
#  CLONE of cv32e40p  repository    #######################################################
###########################################################################################

# Verify that the ref and ft architecture exist otherwise clone it and set correct branch
function verify_branch () {
	local ft_repo=$CORE_V_VERIF/core-v-cores/$A_FT_REPO_NAME
	local ref_repo=$CORE_V_VERIF/core-v-cores/$A_REF_REPO_NAME
	local gitref="git --git-dir $ref_repo/.git"
        local gitft="git --git-dir $ft_repo/.git"
	local current_branch=""
	
	#######################################################
	# Verify that repo and branch are setted
	#######################################################
	stringa=""
	if [[ $A_REF_REPO == "" ]]; then
		stringa="$stringa ref repo "
	fi
	if [[ $A_REF_BRANCH == "" ]]; then
		stringa="$stringa, ref branch "
	fi
	if [[ $A_FT_REPO == "" ]]; then
		stringa="$stringa, ft repo "
	fi
	if [[ $A_FT_BRANCH == "" ]]; then
		stringa="$stringa, ft branch "
	fi		
	if [[ $stringa != "" ]]; then 
		db_gecho "[INFO] $stringa aren't setted!!."
		ask_yesno "[QUESTION] Do you want to terminate in order to set them (with -a option) (y/n)?"
		if [[ $ANS -eq 1  ]]; then
			exit 1
		fi
	fi

	#######################################################
	# Verify REF branch
	#######################################################
	cd $CORE_V_VERIF/core-v-cores/
	if test -d  $ref_repo ; then
		current_branch=$($gitref branch | grep \* | cut -d " " -f 2)
	fi

	if [[ $current_branch != "" ]]; then
		# Verify if the current branch is equal to the setted branch
		if [[ $current_branch != $A_REF_BRANCH ]]; then
			# Verify if user want to change branch
			ask_yesno "Are you sure to change REF branch from\
					$current_branch to $A_REF_BRANCH?? (y/n)"
			if [[ $ANS -eq 1 ]]; then
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

	current_branch=""
	
	#######################################################
	# Verify FT branch
	#######################################################
	cd $CORE_V_VERIF/core-v-cores/

	if test -d  $ft_repo ; then
		current_branch=$($gitft branch | grep \* | cut -d " " -f 2)
	fi

        echo "Current branch: $current_branch"

	if [[ $current_branch != "" ]]; then
		# Verify if the current branch is equal to the setted branch
		if [[ $current_branch != $A_FT_BRANCH ]]; then
			# Verify if user want to change branch
			ask_yesno "Are you sure to change FT branch from\
					$current_branch to $A_FT_BRANCH?? (y/n)"
			if [[ $ANS -eq 1 ]]; then
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
	cd $CORE_V_VERIF/cv32/sim/core
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

function elab_par () {
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
		-sfiupi|--stage_fault_injection_upi) # simulate benchmark programs with fault injection
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
		-f) # to use when vsim_stage_compare is run in order to overwrite a simulation
			OVWRITE_SIM=1
			shift			
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

		-aesfiupi)
                        AESFIUPI=1
                        elab_par $1
                        shift
                        find_args $@
                        AR_aesfiupi_args=$ARGS
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
			verify_branch
			sim_unique_program $AR_u_args
			;;
		-b|--benchmark)
			# AR_b_args
			verify_branch
			sim_benchmark_programs $AR_b_args
			;;
		-qsfiupi)
			# AR_qsfiupi_args
			verify_branch
			manage_stage_fault_injection_upi $AR_qsfiupi_args
			;;
		-sfiupi|--stage_fault_injection_upi)
			# AR_sfiupi_args
			verify_branch
			sim_stage_fault_injection_upi $AR_sfiupi_args
			;;
		-esfiupi)
			# AR_esfiupi_args
			elaborate_simulation_output $AR_esfiupi_args
			;;
		-aesfiupi)
                        # AR_aesfiupi_args
                        elaborate_all_sim_output $AR_aesfiupi_args
                        ;;

		*)
			db_recho "ERROR: something goes wrong in the script!! in the for of elaboration"
			exit
			;;
	esac
done


