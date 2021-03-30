#!/bin/bash

replace_TEST_DIR () {
	awk -v old="^TEST_DIR=\".*\"" -v new="TEST_DIR=\"Ciao\"" \
	'{if ($0 ~ old) \
			print new; \
		else \
			print $0}' \
	 $1 > $1.t
	 mv $1{.t,}
}

replace_TEST_DIR comp_sim_prova.sh
