#!/bin/bash

for dir in $(ls); do
	if test -d $dir; then 
		rm -f ./$dir/Makefile
		cp Makefile_inside ./$dir/Makefile
	fi
done
