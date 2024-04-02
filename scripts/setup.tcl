proc add_files_from { basedir pattern } {
    set file_list [recglob $basedir $pattern]
    if {[string length $file_list] > 0} {
        add_files -force -norecurse $file_list
        foreach single_file $file_list { puts ${single_file}->Added! }
    } else {
        puts ---No_files_found_in_${pattern}---
    }
}

# return all files in basedir which match pattern
proc recglob { basedir pattern } {
    set dirlist [glob -nocomplain -directory $basedir -type d *]
    set found_list [glob -nocomplain -directory $basedir $pattern]
    foreach dir $dirlist {
        set reclist [recglob $dir $pattern]
        set found_list [concat $found_list $reclist]
    }
    return $found_list
}


source ../scripts/chip_part.tcl
set localRoot ./

create_project -force top $localRoot/prj/ -part ${CHIP_PART_DEF}
set_param general.maxThreads 8

# Set project properties
set obj [get_projects top]
set_property "simulator_language" "Mixed" $obj
set_property "target_language" "Verilog" $obj
set_property coreContainer.enable 0 $obj

update_ip_catalog

# RTL: Verilog Verilog_Header VHDL
add_files_from  ../src/rtl/ *.v
add_files_from  ../src/rtl/ *.vhd
add_files_from  ../src/rtl/ *.vh

# Netlist
add_files_from  ../src/netlist/ *.*

# IP
add_files_from  ../src/ip/coe/ *.coe
add_files_from  ../src/ip/ *.xci

# --------  XDC
# add_files -force -fileset constrs_1 -norecurse  [glob ../scripts/sdc/*.xdc]
# set_property used_in_synthesis false [get_files [glob ../scripts/sdc/*_impl.xdc]]
# set_property target_constrs_file ../scripts/sdc/debug_impl.xdc [current_fileset -constrset]

update_compile_order -fileset sources_1


set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files_from  ../src/tb/ *.v
update_compile_order -fileset sim_1

set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE  true [get_runs impl_1]
set_property STEPS.WRITE_BITSTREAM.ARGS.MASK_FILE true [get_runs impl_1]
