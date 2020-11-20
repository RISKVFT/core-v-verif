set CORE_V_VERIF "/home/thesis/elia.ribaldone/Desktop/core-v-verif"
set SIM_BASE "sim:/tb_top/cv32e40p_tb_wrapper_i/cv32e40p_core_i"

log $SIM_BASE/id_stage_i/instr_rdata_i

run 0
run 100ns

dataset save sim gold.wlf
quit -sim
