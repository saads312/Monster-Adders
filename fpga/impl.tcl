package require ::quartus::project

set PROJ_DIR_NAME "impl"
file mkdir $PROJ_DIR_NAME
set ROOT [pwd]
cd $PROJ_DIR_NAME

set PROJ      "impl"
set REV       [lindex $argv 0]

if {[project_exists $PROJ]} {
		project_open -revision $REV $PROJ
} else {
		project_new -revision $REV $PROJ
}

execute_module -tool map
exec quartus_eda --simulation	--tool=modelsim $PROJ -c $REV --format=verilog --output_directory simulation/synth
execute_module -tool fit
exec quartus_eda --simulation --tool=modelsim $PROJ -c $REV --format=verilog --output_directory simulation/impl
execute_module -tool sta
execute_module -tool pow

project_close
