# get the directory where this script resides
set thisDir [file dirname [info script]]
# source common utilities
# source -notrace $thisDir/utils.tcl

# Create project
open_project ./prj/top.xpr
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]

set_param general.maxThreads 8

reset_run synth_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1

# If successful, "touch" a file so the make utility will know it's done 
# touch {.synth.done}
