clear -all 
set DW_SIM "/usr/cad/synopsys/synthesis/cur/dw/sim_ver/"
#set_resilient_compilation on

set_proofgrid_max_local_jobs 10
#check_sec -analyze -sv -both -f dw.f -ignore_translate_off
check_sec -analyze -sv -both ../EXERCISE/01_RTL/GATED_OR.v
check_sec -analyze -sv -both ../EXERCISE/01_RTL/SNN.v -y ${DW_SIM} +libext+.v +incdir+${DW_SIM}
check_sec -elaborate -both  -top SNN  -disable_auto_bbox
check_sec -setup


clock clk -both_edge 
reset ~rst_n

check_sec -gen
check_sec -interface

assume cg_en==0
assume SNN_imp.cg_en==1
check_sec -waive -waive_signals cg_en
check_sec -waive -waive_signals SNN_imp.cg_en

check_sec -interface


set_sec_autoprove_strategy design_style
set_sec_autoprove_design_style_type clock_gating


check_sec -prove -bg
