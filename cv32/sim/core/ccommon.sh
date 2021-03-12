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
	# Replace a variable in a makefile
        key=$1 # keyword
        file=$2 # file with absolute path
        to_rep=$3 # word to replace
        awk -v old="^$key.*=.*$" -v new="$key ?= $to_rep" \
        '{if ($0 ~ old) \
                        print new; \
                else \
                        print $0}' \
         $file > $file.t
         cp $file.t $file	
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
         cp $file.t $file
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

SetVar () {
	var=$1
	var_value=$2
	repfile "$var" "$CUR_DIR/$(basename $0)" "$var_value"
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
			db_recho "AHhhhh you give me an absolute\
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
	   echo $2
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

function show_time () {
    num=$1
    min=0
    hour=0
    day=0
    if((num>59));then
        ((sec=num%60))
        ((num=num/60))
        if((num>59));then
            ((min=num%60))
            ((num=num/60))
            if((num>23));then
                ((hour=num%24))
                ((day=num/24))
            else
                ((hour=num))
            fi
        else
            ((min=num))
        fi
    else
        ((sec=num))
    fi
    echo "$day"d:"$hour"h:"$min"m:"$sec"s
}


# Usage:
# Source this script
# enable_trapping <- optional to clean up properly if user presses ctrl-c
# setup_scroll_area <- create empty progress bar
# draw_progress_bar 10 <- advance progress bar
# draw_progress_bar 40 <- advance progress bar
# block_progress_bar 45 <- turns the progress bar yellow to indicate some action is requested from the user
# draw_progress_bar 90 <- advance progress bar
# destroy_scroll_area <- remove progress bar

# Constants
CODE_SAVE_CURSOR="\033[s"
CODE_RESTORE_CURSOR="\033[u"
CODE_CURSOR_IN_SCROLL_AREA="\033[1A"
COLOR_FG="\e[30m"
COLOR_BG="\e[42m"
COLOR_BG_BLOCKED="\e[43m"
RESTORE_FG="\e[39m"
RESTORE_BG="\e[49m"
LR='\033[1;31m'
LG='\033[1;32m'
LY='\033[1;33m'
LC='\033[1;36m'
LW='\033[1;37m'

# Variables
PROGRESS_BLOCKED="false"
TRAPPING_ENABLED="false"
TRAP_SET="false"

CURRENT_NR_LINES=0

setup_scroll_area() {
    # If trapping is enabled, we will want to activate it whenever we setup the scroll area and remove it when we break the scroll area
    if [ "$TRAPPING_ENABLED" = "true" ]; then
        trap_on_interrupt
    fi

    lines=$(tput lines)
    CURRENT_NR_LINES=$lines
    let lines=$lines-1
    # Scroll down a bit to avoid visual glitch when the screen area shrinks by one row
    echo -en "\n"

    # Save cursor
    echo -en "$CODE_SAVE_CURSOR"
    # Set scroll region (this will place the cursor in the top left)
    echo -en "\033[0;${lines}r"

    # Restore cursor but ensure its inside the scrolling area
    echo -en "$CODE_RESTORE_CURSOR"
    echo -en "$CODE_CURSOR_IN_SCROLL_AREA"

    # Start empty progress bar
    draw_progress_bar 0
}

destroy_scroll_area() {
    lines=$(tput lines)
    # Save cursor
    echo -en "$CODE_SAVE_CURSOR"
    # Set scroll region (this will place the cursor in the top left)
    echo -en "\033[0;${lines}r"

    # Restore cursor but ensure its inside the scrolling area
    echo -en "$CODE_RESTORE_CURSOR"
    echo -en "$CODE_CURSOR_IN_SCROLL_AREA"

    # We are done so clear the scroll bar
    clear_progress_bar

    # Scroll down a bit to avoid visual glitch when the screen area grows by one row
    echo -en "\n\n"

    # Once the scroll area is cleared, we want to remove any trap previously set. Otherwise, ctrl+c will exit our shell
    if [ "$TRAP_SET" = "true" ]; then
        trap - INT
    fi
}

draw_progress_bar() {
    percentage=$1
    time_left=$2
    cycle_t=$3
    lines=$(tput lines)
    let lines=$lines

    # Check if the window has been resized. If so, reset the scroll area
    if [ "$lines" -ne "$CURRENT_NR_LINES" ]; then
        setup_scroll_area
    fi

    # Save cursor
    echo -en "$CODE_SAVE_CURSOR"

    # Move cursor position to last row
    echo -en "\033[${lines};0f"

    # Clear progress bar
    tput el

    # Draw progress bar
    PROGRESS_BLOCKED="false"
    print_bar_text $percentage $time_left $cycle_t

    # Restore cursor position
    echo -en "$CODE_RESTORE_CURSOR"
}

block_progress_bar() {
    percentage=$1
    time_left=$2
    cycle_t=$3
    lines=$(tput lines)
    let lines=$lines
    # Save cursor
    echo -en "$CODE_SAVE_CURSOR"

    # Move cursor position to last row
    echo -en "\033[${lines};0f"

    # Clear progress bar
    tput el

    # Draw progress bar
    PROGRESS_BLOCKED="true"
    print_bar_text $percentage $time_left $cycle_t

    # Restore cursor position
    echo -en "$CODE_RESTORE_CURSOR"
}

clear_progress_bar() {
    lines=$(tput lines)
    let lines=$lines
    # Save cursor
    echo -en "$CODE_SAVE_CURSOR"

    # Move cursor position to last row
    echo -en "\033[${lines};0f"

    # clear progress bar
    tput el

    # Restore cursor position
    echo -en "$CODE_RESTORE_CURSOR"
}

print_bar_text() {
    local percentage=$1
    local time_left=$2
    local cycle_t=$3
    local cols=$(tput cols)
    let bar_size=$cols-50

    local color="${COLOR_FG}${COLOR_BG}"
    if [ "$PROGRESS_BLOCKED" = "true" ]; then
        color="${COLOR_FG}${COLOR_BG_BLOCKED}"
    fi
    color="${LG}"

    # Prepare progress bar
    local percentage_int=$(echo "scale=0; $percentage/1" | bc -l)
    let complete_size=($bar_size*$percentage_int)/100
    let remainder_size=$bar_size-$complete_size
    progress_bar=$(echo -ne "|"; echo -en "${color}"; printf_new "█" $complete_size; echo -en "${RESTORE_FG}${RESTORE_BG}"; printf_new " " $remainder_size; echo -ne "|");

    # Print progress bar
    t=$(show_time $time_left)
    echo -ne "${LR}Tleft:${LW}${t}${RESTORE_FG}${RESTORE_BG}|$cycle_t|${LC}${percentage}%${RESTORE_FG}${RESTORE_BG} ${progress_bar}"
}

enable_trapping() {
    TRAPPING_ENABLED="true"
}

trap_on_interrupt() {
    # If this function is called, we setup an interrupt handler to cleanup the progress bar
    TRAP_SET="true"
    trap cleanup_on_interrupt INT
}

cleanup_on_interrupt() {
    destroy_scroll_area
    exit
}

printf_new() {
    str=$1
    num=$2
    v=$(printf "%-${num}s" "$str")
    echo -ne "${v// /$str}"
}
check_fio () {
   # check first in others (fio)
   # $1 argomento da controllare in quelli dopo
   # 	in or, se $1 è uguale a anche solo uno ritorna 1
   local first=$1
   shift
   for i in $*; do
		if [[ $i = $first ]]; then
			echo 1
			return 
		fi
   done
   echo 0
}
yesorno () {
   # $1 viene controllato essere un si o un no e viene ritornato
   #	0 -> ne si ne no
   # 	1 -> no
   #    2 -> si
   local answer=$(check_fio $1 yes no n y si no s)
   if test $answer -eq 0; then
   		echo 0 # ne si ne no
		return 
   fi
   local is_yes=$(check_fio $1 yes y si s)
   if test $is_yes -eq 1; then
   		echo 2  # si
		return
   fi
	echo 1 # no
}
ask_yesno () {   
    # $1 stringa da stampare nella domanda
    # $3 ... $n argomenti validi
    local op=0
    local flag=1
    local str1=$1
    shift
    echo -n -e $str1": "
    while test $flag -eq 1; do
        read op
        let flag=0
		local answer=$(yesorno $op)
		case $answer in
			0) # ne si ne no
            	echo -n "Only yes or no is avaiable as answer: " 
				let flag=1;;
			1) # no
				let ANS=0;;
			2) # si
				let ANS=1;;
			*) # error
				echo "errorrrrr";;
        esac
    done
    return $ANS
}

sendMailToAll () {
	stringa="Buon*\nOggi è il : $(date)\nQuesto è il log della simulazione:\n$1"
	if [[ $CORE_V_VERIF =~ "luca" ]]; then
		echo -e "$stringa"  | mail -s 'DalTuoCaroServer' lucafiore1996@gmail.com 
	fi
	if [[ $CORE_V_VERIF =~ "elia" ]]; then
		echo -e "$stringa"  | mail -s 'DalTuoCaroServer' ribaldoneelia@gmail.com
	fi
	if [[ $CORE_V_VERIF =~ "marcello" ]]; then
		echo -e "$stringa"  | mail -s 'DalTuoCaroServerAffiliatoDiRuoRoch' marcellon96@hotmail.it
	fi
}

# This function give the timestamp of a file in microseconds
fileTimestamp () {
	# $1 is the file
	if test -f $1 ; then
		min_inmsec=$(echo "$(stat -c %y $1 | cut -d ":" -f 2 | bc -l )*60*1000" | bc -l)
		sec_inmsec=$(echo "$(stat -c %y $1 | cut -d ":" -f 3 | cut -d " " -f 1 | \
			cut -d "." -f 1 | bc -l)*1000" | bc -l)
		msec_inusec=$(echo "scale=0; $(stat -c %y $1 | cut -d ":" -f 3 | cut -d " " -f 1 | \
			cut -d "." -f 2 | bc -l)/1000" | bc -l)
		timestamp_inmsec=$(echo "$min_inmsec*1000+$sec_inmsec*1000+$msec_inusec" | bc -l)
		echo $timestamp_inmsec
	else
		recho_exit "Error in fileTimestamp, file $1 doesn't exist"
	fi
}


