BASEDIR=/home/thesis/luca.fiore/Repos/core-v-verif/cv32/tests/programs/mibench/general_test
#BASEDIR=$(realpath $(pwd))	



#all:
	#cd illegal && $(MAKE);
	#cd hello-world && $(MAKE);
.ONESHELL:
list: $(BASEDIR)/*
	for dir in $^; do \
	echo $$dir; \
	if test -d $$dir; then \	
	echo "\e[0;91m$$dir\e[0m"; \
	cd $$dir && $(MAKE); \
	fi \
	done


#	echo "ciccopasticcio1 ";
#	@for dir in $(shell ls ${BASEDIR}); do \
#	echo $$dir; \
#	if test -d $$dir; then \	
#	echo -e "\e[0;91m$$dir\e[0m" \
#	cd $$dir && $(MAKE); \
#	fi \
#	done







