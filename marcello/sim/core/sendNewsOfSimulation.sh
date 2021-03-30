#!/bin/bash

source ccommon.sh

VERBOSE=1
vecho() { if [[ $VERBOSE ]]; then echo -e "${red}${1}${reset}";fi }
db_recho() { if [[ $VERBOSE ]]; then echo -e "${red}${bold}${1}${reset}"; fi }
db_becho() { if [[ $VERBOSE ]]; then echo -e "${blue}${bold}${1}${reset}"; fi }
db_gecho() { if [[ $VERBOSE ]]; then echo -e "${green}${bold}${1}${reset}"; fi }
db_lgecho() { if [[ $VERBOSE ]]; then lgecho "$1"; fi }

info_file=$1
string_to_search=$2
cycle=$3
sleep_time=$4

isnumber='^[\.0-9]+$'

if ! test -f $info_file; then
	echo "Error, the first argument should be a file \$1=$1"
	exit
fi
if ! [[ $cycle =~ $isnumber ]]; then
	echo "Error, the third element should be the number of cycle after which end simulation. \$3=$3"
	exit
fi
if ! [[ $sleep_time =~ $isnumber ]]; then
	echo "Error, the fourth element should be the sleep time in seconds \$4=$4"
	exit
fi
db_becho "INFO: A mail each $(show_time $(echo "$sleep_time*60" | bc -l | cut -d "." -f 1))"
db_becho "INFO: info file: $info_file"


flag=1
real_sleep_time=$(echo "$sleep_time*60" | bc -l | cut -d "." -f 1)

while [[ $flag -eq 1 ]]; do
	sleep $real_sleep_time
	current_cycle=$(cat $info_file | grep $string_to_search | cut -d ":" -f 2)
	text=$(cat $info_file)
	if [[ $previous_cycle == $current_cycle ]]; then
		message="Buon* (probabilmente non lo e' perche' forse c'e' un errore)\nLog della simulazione\n\n----------------------------------------------\nNome: ${info_file:5:-4}i\n----------------------------------------------\n\n$text\n\n----------------------------------------------"
		flag=0
		echo "------Errors -------"
	else
		message="Buon*\nOggi e' il : $(date)\nQuesto e' il log della simulazione\n\n----------------------------------------------\nNome: ${info_file:5:-4}\n----------------------------------------------\n\n$text\n\n----------------------------------------------"
	fi
	#echo "messaggio:$message"
	
	previous_cycle=$current_cycle
	echo "-------Ciclo: $current_cycle su $cycle -------"

	if [[ $current_cycle -eq $cycle ]]; then
		flag=0
		logesfiupi="$(./comp_sim.sh -co -esfiupi ${info_file:5:-4} | grep -v "esfiupi\|Argument")"
		#logesfiupi="$(./comp_sim.sh -co -esfiupi ${info_file:5:-4} | grep -v "esfiupi\|Argument" | cat -E | sed 's/\$/\\n/g')"
		message="Buon*\nOggi e' il : $(date)\nQuesto e' il log della simulazione\n\n----------------------------------------------\nNome: ${info_file:5:-4}\n----------------------------------------------\n\n$logesfiupi\n\n----------------------------------------------"
		echo -e "last_message: $message"
		echo "-------Cycle finished -------"
	fi
	echo "-------Send mail -------"
	message="$message\nCi rivedremo fra $sleep_time minuti ...  ma non ancora"
	echo -e "$message"  | mail -s 'DalTuoCaroServer' lucafiore1996@gmail.com
	echo -e "$message"  | mail -s 'DalTuoCaroServer' ribaldoneelia@gmail.com
	echo -e "$message"  | mail -s 'DalTuoCaroServerAffiliatoDiRuoRoch' marcellon96@hotmail.it
done	
rm $info_file
