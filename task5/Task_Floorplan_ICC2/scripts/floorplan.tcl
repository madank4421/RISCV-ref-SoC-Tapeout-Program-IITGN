
set DESIGN_NAME      vsdcaravel
set DESIGN_LIBRARY   vsdcaravel_fp_lib

set REF_LIB \
"/home/Synopsys/pdk/SCL_PDK_3/work/run1/icc2_workshop_collaterals/standaloneFlow/work/raven_wrapperNangate/lib.ndm"

if {[file exists $DESIGN_LIBRARY]} {
    file delete -force $DESIGN_LIBRARY
}

create_lib $DESIGN_LIBRARY -ref_libs $REF_LIB

read_verilog -top $DESIGN_NAME ../../../synthesis/output/vsdcaravel_synthesis.v

current_design $DESIGN_NAME

initialize_floorplan \
  -control_type die \
  -boundary {{0 0} {3588 5188}} \
  -core_offset {200 200 200 200}


create_placement_blockage \
  -name IO_BOTTOM \
  -type hard \
  -boundary {{0 0} {3588 100}}

create_placement_blockage \
  -name IO_TOP \
  -type hard \
  -boundary {{0 5088} {3588 5188}}

create_placement_blockage \
  -name IO_LEFT \
  -type hard \
  -boundary {{0 100} {100 5088}}

create_placement_blockage \
  -name IO_RIGHT \
  -type hard \
  -boundary {{3488 100} {3588 5088}}

save_block -force -label floorplan

save_lib

file mkdir ../outputs

write_def ../outputs/vsdcaravel_floorplan.def

file mkdir ../reports

redirect -file ../reports/floorplan_report.txt {
    puts "===== FLOORPLAN GEOMETRY (USER DEFINED) ====="
    puts "Die Area  : 0 0 3588 5188  (microns)"
    puts "Core Area : 200 200 3388 4988  (microns)"

    puts "\n===== TOP LEVEL PORTS ====="
    get_ports
}

puts "INFO: Floorplan created, saved, and DEF written successfully."
