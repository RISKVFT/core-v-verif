#!/bin/sh

# Replace default TEST_DIR with desired directory 
replace_CORE_V_VERIF () {
        awk -v old="^CORE_V_VERIF=\".*\"" -v new="CORE_V_VERIF=\"$2\"" \
        '{if ($0 ~ old) \
                        print new; \
                else \
                        print $0}' \
         $1 > $1.t
         mv $1{.t,}

		awk -v old="^CORE_V_VERIF=/.*" -v new="CORE_V_VERIF=$2" \
        '{if ($0 ~ old) \
                        print new; \
                else \
                        print $0}' \
         $1 > $1.t
         mv $1{.t,}

		awk -v old="^set CORE_V_VERIF .*" -v new="set CORE_V_VERIF \"$2\"" \
        '{if ($0 ~ old) \
                        print new; \
                else \
                        print $0}' \
         $1 > $1.t
         mv $1{.t,}
}

bash_script="./cv32/sim/core/comp_sim.sh ./cv32/sim/core/comp_sim_prova.sh "
bash_script="$bash_script ./cv32/sim/core/sim_FT/Makefile_Compile.mk"
bash_script="$bash_script ./cv32/tests/programs/custom_FT/build_all.py"
bash_script="$bash_script $(ls ./cv32/sim/questa/*.tcl)"
core_v_verif=$(pwd)

for file in $bash_script; do
	echo "$file"
	replace_CORE_V_VERIF $file $core_v_verif 
	# change permission only to bash script
	if [[ $file =~ .*.sh || $file =~ .*.py ]]; then
		chmod 777 $file
	fi
done
