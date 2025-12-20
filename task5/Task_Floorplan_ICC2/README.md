# Task 5: SoC Floorplanning Using ICC2 (Floorplan Only)

Objective
The objective of this task is to create a correct SoC floorplan using ICC2, meeting exact die size and IO pad placement targets, and to develop hands-on familiarity with ICC2 floorplanning commands and concepts

## Toolchain Requirements

The following tools and libraries are required to reproduce this flow:

- Synopsys VCS for RTL and gate-level simulation
- Synopsys ICC2 (Integrated Circuit Compiler II) for synthesis
- SCL-180 standard cell libraries
- SCL-180 IO pad libraries and Verilog models

Floorplan
(brief description)

tHE FLOOR PLAN IS DONE USING THE FOLLOWING SCRIPT FILE:

```tcl

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
```

Then run the icc2 shell with the script file

```
icc2_shell -f floorplan.tcl
```

<task5_3>

The gui can be viewed with the following command.

```
start_gui
```

tHe Dimensions of the die and core can be checked under "floorplan initialization" as shown:

<task5_1>

Also the pins can be placed (without any order) using the following command in the console of gui:

```
place_pins -self
```

<task5_2>
