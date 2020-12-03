#!/usr/bin/bash

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White
# Ansi color code variables
red="\e[0;91m"
blue="\e[0;94m"
expand_bg="\e[K"
blue_bg="\e[0;104m${expand_bg}"
red_bg="\e[0;101m${expand_bg}"
green_bg="\e[0;102m${expand_bg}"
green="\e[0;92m"
white="\e[0;97m"
bold="\e[1m"
uline="\e[4m"
reset="\e[0m"

recho () { echo -e  ${red}${bold}$1${reset} ; }
becho () { echo -e  ${blue}${bold}$1${reset} ; }
gecho () { echo -e  ${green}${bold}$1${reset} ; }
lgecho () { 
	for i in $(echo $1); do
		echo -e  "\t${green}${bold}$i${reset}" ; 
	done
}
recho_exit () { 
        echo -e  ${red}${bold}$1${reset} ;
        echo "!! -h for help !!"
        exit 1

}
becho_exit () {
        echo -e  ${blue}${bold}$1${reset} ;
        echo "!! -h for help !!"
        exit 1
}
gecho_exit () {
        echo -e  ${green}${bold}$1${reset} ;
        echo "!! -h for help !!"
        exit 1

}
wecho () { echo -e  ${white}${bold}$1${reset} ; }

## Returns errlvl 0 if $1 is a reachable git remote url 
gitRepoExist() {
	git ls-remote "$1" CHECK_GIT_REMOTE_URL_REACHABILITY >/dev/null 2>&1
}
gitRepoBranchExist() {
	REPO=$1
	BRANCH=$2
	git ls-remote --heads ${REPO} ${BRANCH} | grep ${BRANCH} >/dev/null
}

repMakeFile () {
        key=$1 # keyword
        file=$2 # file with absolute path
        to_rep=$3 # word to replace
        awk -v old="^$key.*=.*$" -v new="$key ?= $to_rep" \
        '{if ($0 ~ old) \
                        print new; \
                else \
                        print $0}' \
         $file > $file.t
         mv $file{.t,}	
}
# Replace default TEST_DIR with desired directory 
repfile () {
        key=$1 # keyword
        file=$2 # file with absolute path
        to_rep=$3 # word to replace
        awk -v old="^$key=\".*\"" -v new="$key=\"$to_rep\"" \
        '{if ($0 ~ old) \
                        print new; \
                else \
                        print $0}' \
         $file > $file.t
         mv $file{.t,}
         chmod 777 $file
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

Print(){
        echo -e -n "$Red""[$1] "
        echo -e  "$Green""$2"
        echo -en "\e[0m"
}

Action(){
	echo -e "$Red""$1, press enter when you have done."
        echo -en "\e[0m"
	read n
}

Print_verbose () {
       # stampa $1 solo se $2 = 1
       if [[ $2 = 1 ]]; then
           echo -e "$1"
        fi
}

delExt () {  echo $1 | sed 's/\.[^.]*$//'; }

monitor_file () {
	   # stampa in numero di righe del file in questione 
	   # riscrivendo la riga ogni volta dando l'effetto progressivo
	   file=$1 # name of file to monitor
	   str=$2  # str before line number
	   id=$3 # id of process ($!)
	   var=0
	   var_err=0
	   str=$(for i in $str; do v=$(echo $i | rev | cut -d '/' -f 1 | rev); echo -n "$v ";  done)
	   cols=$(($(tput cols)-20))
	   cmd_c=$(($cols/3))
	   out_c=$(($cols-$cmd_c))
	   while true; do 
		   # calcolo delle righe dell'output file
		   var=$(cat $file | wc -l); 
		   # calcolo delle righe dell'error file
		   var_err=$(cat $(delExt $file)_err.txt | wc -l) 
	           # calcolo delle righe totali
		   res=$(($var+$var_err))
		   # se le righe sono maggiori di 1 stampo il log
		   if [[ $res -ne 0 ]]; then 
			if [[ $var -gt $var_old ]]; then
				lastline=$(tail -n 1 $file)
			fi
			if [[ $var_err -gt 0 ]]; then			
				i_e="[err]"
			else
				i_e="[i]"
			fi
			
			if [[ $var -ne $var_old ]]; then
				printf "%-5s %-${cmd_c}s]:%-5d | %-${out_c}s\r" "$i_e" "${str:0:$cmd_c}" \
					"$res" "${lastline:0:$out_c}"
			fi
			if ! test -d /proc/$id; then
				break
			fi
		   else
			   printf "[i]  %-${cmd_c}s]:%-5d \r" "${str:0:$cmd_c}" "$res"
		   fi
		   var_old=$var
		   var_err_old=$var_err
	   done
	   printf "[i]  %-50s]:%-5d \n" "${str:0:50}" "$res"
}

Setvar () {
	var=$1
	var_value=$2
	repfile "$var" \		
		"$CUR_DIR/$(basename $0)" \
		"$var_value"
}

dfSetVar (){
	df=$1
	if [[ $df != "f" && $df != "d" ]]; then
		recho "Error df_var_set needs f or d as first argument"
		exit 1	
	fi
	dirorfile=$2
	var=$3
	settext=$4
	errtext=$5
	create=$6	
	if test -$df "$CORE_V_VERIF/$dirorfile" || [[ $create == "CREATE" ]]; then
		db_becho "$settext: $CORE_V_VERIF/$dirorfile"
		repfile "$var" \
			"$CUR_DIR/$(basename $0)" \
			"\$CORE_V_VERIF/$dirorfile"
		if [[ $df == "d" ]]; then
			mkdir -p $CORE_V_VERIF/$dirorfile
		fi
	else
		if test -$df $dirorfile ; then
			recho_echo "AHhhhh you give me an absolute\
			path buth I need path from \
			CORE_V_VERIF=$CORE_V_VERIF dir"
		fi
		recho_exit "Error: $df $dirorfile $errtext!!"
	fi
}

monitor_file_error () {
	   # stampa tutte le righe con errore e 
	   # se  ce se sono chiude lo script
	   # $1 è il nome del file con eventuali errori
	   cat $1 | grep -ni "error" --color > error_log.txt
   	   if [[ $(cat error_log.txt | wc -l) -gt 0 ]]; then
		   echo -e $( \
		   echo "[!]  An error has been found!!!!!\n";\
		   echo "[!]  command: $2\n";\
		   echo "[!]  Log file with error: "$1\n;\
	   	   echo "[!]  These are error lines of the log file:\n";\
		   cat error_log.txt ;\
		   echo "\n[!]  These are error lines from the error log file:\n";\
		   cat $(delExt $1)_err.txt ;\
		   echo "\n[!]  More info in file $1\n" ) > error_monitor.txt
		   #exit 1
		   return 0
	   fi
}

## This function is used many times during installation and perform following 
# action:
#	1) execute a command in background ( $1 )
#	2) redirect it's output in a log file ( $2 )
#	3) continuously control log file printing the file line and last
#		line in terminal.
#	4) At the end check the log file in order to find errors, in this case
#		print this error and exit
#	5) $4 option set if the log file should be ovewritten (1) or the 
#		new content chould be appended, is useful if you want that two 
#		or more command share log file.
#	6) $5 is the script line, can be gived using $LINENO varible,
#		this is useful if you want to know where an error occur in 
#		your script since $5 argument is printed.
mon_run (){
	   # $1 è il comando da eseguire
	   # $2 è il file in cui scrivere il log
	   # $3 se è 1 sovrascrivo il file
	   # $4 è l'eventuale numero di riga
	   echo "Comando:|$1|"
	   echo "Line $4: $1" >> trace_command.txt
	   mkdir -p $(dirname $2)
	   touch $2
	   err_file=$(delExt $2)_err.txt
	   touch $err_file
	   chmod 777 $2
	   chmod 777 $err_file
	   if [[ $3 -eq 1 ]]; then
		   $1 > $2 2> $err_file &
	   else
		   	$1 >> $2 2>> $err_file &
	   fi
	   becho "Log file: $2" 
	   monitor_file "$2" "line $4: [$1" $!
	   monitor_file_error $2 "Line $4: $1"
}
f_make () {
        firmware=$1
	export GOLD_NAME="gold_${STAGE_NAME}_${firmware:0:-4}"
	logfile=$2
	override=$3
	lineno=$4
        #mon_run "make -C $SIM_FT questa-sim$GUI \
        #TEST_FILE=\"$BENCH_HEX_DIR/${firmware:0:-4}\" FT=\"$VSIM_EXT\"" "$logfile" "$override" "$lineno"
	echo "---------------$GUI"
	if [[ $SET_BLOCK -eq 0 ]]; then
    		make -C $SIM_FT questa-sim$GUI TEST_FILE="$BENCH_HEX_DIR/${firmware:0:-4}" FT="$VSIM_EXT"
	else 
		make -C $SIM_FT questa-sim-stage$GUI STAGE=$B_STAGE \
			TEST_FILE="$BENCH_HEX_DIR/${firmware:0:-4}" FT="$VSIM_EXT"
	fi
}

get_git_branch (){
	gitd=$1
	git --git-dir=$gitd/.git --work-tree=$gitd status | grep branch | cut -d " " -f 4
}

export_path (){
	   export PATH=$PATH:$1
	   if [[ `grep -c "export PATH=$PATH:$1" ~/.bash_profile` -eq 0 ]] ; then
		   echo "export PATH=$PATH:$1" >> ~/.bash_profile
           fi
}

export_var (){
	   export $1=$2
	   if [[ `grep -c ".bash\_profile" ~/.bashrc` -eq 0 ]] ; then
		   echo -e "if [ -f ~/.bash_profile ]; then\n. ~/.bash_profile\nfi" >> ~/.bashrc
	   fi
	   if [[ `grep -c "export $1=$2" ~/.bash_profile` -eq 0 ]]; then
	   	echo "export $1=$2" >> ~/.bash_profile
	   fi

}
