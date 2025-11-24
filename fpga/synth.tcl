# Load Quartus Prime Tcl Project package
package require ::quartus::project

set PROJ_DIR_NAME "impl"
file mkdir $PROJ_DIR_NAME
set ROOT [pwd]
cd $PROJ_DIR_NAME

set PROJ      "impl"          ;# Vivado: create_project -name synth
set REV       [lindex $argv 0]

project_open -revision $REV $PROJ
execute_module -tool map
project_close
