#!/bin/bash

function func () {
	local len=0
	PAR=""
	while [[ $1 != '' ]] && ! [[ $1 =~ ^-[a-zA-Z\-]*$ ]] ; do
		PAR="$PAR $1"
		echo "fnc $1" 
		let len=len+1
		shift	
	done
	ARG=$len
}

par=$(echo "$@" | awk 'BEGIN{RS=" "};{if ($0 ~ /^-[a-zA-Z\-]*$/) print $0; if ($0 ~ /^-[a-zA-Z\-]*\n/) print $0}')
echo "Argument taken: $par"

newpar=""
while [[ $1 != '' ]]; do
	echo "while1 $1"
	echo "###### $@ #########à"
	case $1 in
		-c)
			cc=2
			shift
			;;
		-g|--gui-g)	
			gui=1
			shift
			;;
		-b|--boc-cs)
			shift
			func $@
			BPAR=$PAR
			shift $ARG
			;;
		*)
			echo "error"
			exit
			;;
	esac
done
echo "newpar $newpar"
echo "bpar $BPAR"

