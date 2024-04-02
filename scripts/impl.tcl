# get the directory where this script resides
set thisDir [file dirname [info script]]
# source common utilities
# source -notrace $thisDir/utils.tcl

# Create project
open_project ./prj/top.xpr
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]

set_param general.maxThreads 8

reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

# write_hwdef -file top.hwdef
# write_sysdef -bitfile top.bit -hwdef top.hwdef -file top.sysdef

# If successful, "touch" a file so the make utility will know it's done 
# touch {.impl.done}
