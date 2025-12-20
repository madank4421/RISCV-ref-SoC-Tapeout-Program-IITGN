############################################################
# Task 5 – SoC Floorplanning Using ICC2 (Floorplan + Save)
# Author  : Divya Darshan VR (VSD)
# Design  : vsdcaravel
# Tool    : Synopsys ICC2 2022.12
############################################################

# ---------------------------------------------------------
# Basic Setup
# ---------------------------------------------------------
set DESIGN_NAME      vsdcaravel
set DESIGN_LIBRARY   vsdcaravel_fp_lib

# ---------------------------------------------------------
# Reference Library (NDM with technology)
# ---------------------------------------------------------
set REF_LIB \
"/home/Synopsys/pdk/SCL_PDK_3/work/run1/icc2_workshop_collaterals/standaloneFlow/work/raven_wrapperNangate/lib.ndm"

# ---------------------------------------------------------
# Clean old library (fresh start)
# ---------------------------------------------------------
if {[file exists $DESIGN_LIBRARY]} {
    file delete -force $DESIGN_LIBRARY
}

# ---------------------------------------------------------
# Create ICC2 Design Library
# ---------------------------------------------------------
create_lib $DESIGN_LIBRARY -ref_libs $REF_LIB

# ---------------------------------------------------------
# Read synthesized netlist
# (Unresolved references are OK at floorplan stage)
# ---------------------------------------------------------
read_verilog -top $DESIGN_NAME ../../../synthesis/output/vsdcaravel_synthesis.v

# Set current design explicitly
current_design $DESIGN_NAME

# ---------------------------------------------------------
# Floorplan Definition (MANDATORY)
# Die Size   : 3588 × 5188 microns
# Core Margin: 200 microns on all sides
# ---------------------------------------------------------
initialize_floorplan \
  -control_type die \
  -boundary {{0 0} {3588 5188}} \
  -core_offset {200 200 200 200}

# ---------------------------------------------------------
# IO Regions using placement blockages
# (Conceptual IO planning only)
# ---------------------------------------------------------

# Bottom
create_placement_blockage \
  -name IO_BOTTOM \
  -type hard \
  -boundary {{0 0} {3588 100}}

# Top
create_placement_blockage \
  -name IO_TOP \
  -type hard \
  -boundary {{0 5088} {3588 5188}}

# Left
create_placement_blockage \
  -name IO_LEFT \
  -type hard \
  -boundary {{0 100} {100 5088}}

# Right
create_placement_blockage \
  -name IO_RIGHT \
  -type hard \
  -boundary {{3488 100} {3588 5088}}

# ---------------------------------------------------------
# SAVE FLOORPLAN (CRITICAL FOR TASK-6)
# ---------------------------------------------------------

# Save block snapshot
save_block -force -label floorplan


# Save library
save_lib

# ---------------------------------------------------------
# WRITE FLOORPLAN DEF (NO ROUTING, NO PLACEMENT)
# ---------------------------------------------------------
file mkdir ../outputs

write_def ../outputs/vsdcaravel_floorplan.def

# ---------------------------------------------------------
# BASIC REPORT
# ---------------------------------------------------------
file mkdir ../reports

redirect -file ../reports/floorplan_report.txt {
    puts "===== FLOORPLAN GEOMETRY (USER DEFINED) ====="
    puts "Die Area  : 0 0 3588 5188  (microns)"
    puts "Core Area : 200 200 3388 4988  (microns)"

    puts "\n===== TOP LEVEL PORTS ====="
    get_ports
}

puts "INFO: Floorplan created, saved, and DEF written successfully."
