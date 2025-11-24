# Load Quartus Prime Tcl Project package
package require ::quartus::project

set PROJ_DIR_NAME   "impl"
file mkdir $PROJ_DIR_NAME
set ROOT [pwd]
cd $PROJ_DIR_NAME

set PROJ      [lindex $argv 0]
set REV       [lindex $argv 1]
set TOP       [lindex $argv 2]
set FAMILY    "Agilex 5"
set DEVICE    "A5EC065BB23AE4SR0"
set W         [lindex $argv 3]
set ARCH_PARAM_VAL [lindex $argv 4]

if {$TOP eq "prefix_tree"} {
    set N $ARCH_PARAM_VAL
    set M 0
} else {
    set M $ARCH_PARAM_VAL
    set N 0
}

set SRC_V     [file join $ROOT rtl $TOP.sv]
set SDC_FILE  [file join $ROOT adder.sdc]
set OUTDIR 	  "output_files_$REV"

if {[project_exists $PROJ]} {
    project_open -revision $REV $PROJ
} else {
    project_new -revision $REV $PROJ
}

# 1. Copy from ff_test_altera/ff_generic.tcl
set_global_assignment -name FAMILY $FAMILY
set_global_assignment -name DEVICE $DEVICE
set_global_assignment -name ORIGINAL_QUARTUS_VERSION 25.1.1
set_global_assignment -name PROJECT_CREATION_TIME_DATE "01:10:03  SEPTEMBER 21, 2025"
set_global_assignment -name LAST_QUARTUS_VERSION "25.1.1 Pro Edition"
set_global_assignment -name SYSTEMVERILOG_FILE [file normalize $SRC_V]
set_global_assignment -name SDC_FILE [file normalize $SDC_FILE]
set_global_assignment -name POWER_PRESET_COOLING_SOLUTION "23 MM HEAT SINK WITH 200 LFPM AIRFLOW"
set_global_assignment -name POWER_BOARD_THERMAL_MODEL "NONE (CONSERVATIVE)"
set_global_assignment -name ALLOW_REGISTER_RETIMING ON
set_global_assignment -name ALLOW_REGISTER_MERGING OFF
set_global_assignment -name REMOVE_DUPLICATE_REGISTERS OFF
set_global_assignment -name SYNTHESIS_EFFORT FAST
set_global_assignment -name ALLOW_REGISTER_DUPLICATION OFF
set_global_assignment -name AUTO_SHIFT_REGISTER_RECOGNITION ON
set_global_assignment -name ALLOW_SHIFT_REGISTER_MERGING_ACROSS_HIERARCHIES AUTO
set_global_assignment -name SHIFT_REGISTER_RECOGNITION_ACLR_SIGNAL ON
set_global_assignment -name DISABLE_REGISTER_MERGING_ACROSS_HIERARCHIES OFF
set_global_assignment -name RESYNTHESIS_RETIMING OFF
set_global_assignment -name FITTER_EARLY_RETIMING OFF
set_global_assignment -name PRESERVE_REGISTER OFF
set_global_assignment -name AUTO_DSP_RECOGNITION OFF

# 3. Transform from altera-impl/synth.tcl
set_global_assignment -name TOP_LEVEL_ENTITY $TOP
set_global_assignment -name NUM_PARALLEL_PROCESSORS 4
set_instance_assignment -name VIRTUAL_PIN ON -to clk
set_instance_assignment -name VIRTUAL_PIN ON -to rst
set_instance_assignment -name VIRTUAL_PIN ON -to a
set_instance_assignment -name VIRTUAL_PIN ON -to b
set_instance_assignment -name VIRTUAL_PIN ON -to c_in
set_instance_assignment -name VIRTUAL_PIN ON -to in_valid
set_instance_assignment -name VIRTUAL_PIN ON -to c_out
set_instance_assignment -name VIRTUAL_PIN ON -to sum
set_instance_assignment -name VIRTUAL_PIN ON -to out_valid

set_global_assignment -name PROJECT_OUTPUT_DIRECTORY $OUTDIR

if {$TOP eq "prefix_tree"} {
    set_parameter -name P $N
} else {
	set_parameter -name W $W
    set_parameter -name M $M
}

# Commit assignments
export_assignments
project_close
