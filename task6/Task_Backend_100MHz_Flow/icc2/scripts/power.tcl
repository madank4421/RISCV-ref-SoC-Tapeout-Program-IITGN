# PG pattern : Will describe the physical attributes of metal_layer ,spacing , width , direction .pitch 
# PG strategy : How to use PG pattern in design
# Via : Via is used to connect metal from one metal layer to another  

remove_pg_strategies -all
remove_pg_patterns -all
remove_pg_regions -all
remove_pg_via_master_rules -all
remove_pg_strategy_via_rules -all
remove_routes -net_types {power ground} -ring -stripe -macro_pin_connect -lib_cell_pin_connect

connect_pg_net


set_pg_via_master_rule pgvia_8x10 -via_array_dimension {8 10}


set all_macros [get_cells -hierarchical -filter "is_hard_macro"]




################################################################################
# Build the main power mesh
################################################################################

# Create straps with hori layer M9
# W = 1.104 , P = 13.376 , Offset = 0.856 
# Create straps with vert layer M10
# W = 4.64 ,  P = 19.456 , Offset = 6.08  

create_pg_mesh_pattern P_top_two -layers { \
  { {horizontal_layer: metal9}  {width: 1.104} {spacing: interleaving} {pitch: 13.376} {offset: 0.856} {trim : true} } \
  { {vertical_layer: metal10}   {width: 4.64 } {spacing: interleaving} {pitch: 19.456} {offset: 6.08}  {trim : true} } \
} -via_rule { {intersection: adjacent} {via_master : pgvia_8x10} }

# Lower mesh : Vertical M2, track aligned
create_pg_mesh_pattern P_m2_triple -layers { \
  { {vertical_layer: metal2} {track_alignment : track} {width: 0.44 0.192 0.192} {spacing: 2.724 3.456} {pitch: 9.728} {offset: 1.216} {trim : true} } \
}

## PG Strategy for M9/M10
set_pg_strategy S_default_vddvss -core \
  -pattern { {name: P_top_two} {nets:{VSS VDD}} {offset_start:{0 0}} } \
  -extension { {stop:design_boundary_and_generate_pin} }

## PG Strategy for M2
set_pg_strategy S_m2_vddvss -core \
  -pattern { {name: P_m2_triple} {nets:{VDD VSS VSS}} {offset_start:{0 0}} } \
  -extension { {stop:keep_floating_wire_piecies} }

compile_pg -strategies {S_default_vddvss S_m2_vddvss} 


################################################################################
# Macro rings
################################################################################

create_pg_ring_pattern MACRO_RING_PATTERN \
  -horizontal_layer metal3 \
  -vertical_layer metal4 \
  -horizontal_width 0.52 \
  -vertical_width 0.52

set_pg_strategy MACRO_RING_VDD_STRATEGY \
  -pattern { {name: MACRO_RING_PATTERN} {nets:{VDD VSS}} {offset:{0.5 0.5}} } \
  -macros $all_macros

set_pg_strategy_via_rule S_ring_vias -via_rule { \
  { {{strategies:{MACRO_RING_VDD_STRATEGY}} {layers:{metal3}}} {existing:{strap}} {via_master:{default}} } \
  { {{strategies:{MACRO_RING_VDD_STRATEGY}} {layers:{metal4}}} {existing:{strap}} {via_master:{default}} } \
}

compile_pg -strategies {MACRO_RING_VDD_STRATEGY} -via_rule S_ring_vias


################################################################################
# Macro pin connection  (FIXED HERE)
################################################################################

create_pg_macro_conn_pattern P_HM_pin -pin_conn_type scattered_pin -layers {metal3 metal4}

set_pg_strategy S_HM_top_pins \
  -macros $all_macros \
  -pattern { {pattern:P_HM_pin} {nets:{VSS VDD}} }

compile_pg -strategies {S_HM_top_pins}


################################################################################
# Standard cell rails
################################################################################

create_pg_std_cell_conn_pattern P_std_cell_rail

set_pg_strategy S_std_cell_rail_VSS_VDD -core \
  -pattern { {pattern:P_std_cell_rail} {nets:{VSS VDD}} }

set_pg_strategy_via_rule S_via_stdcellrail -via_rule { \
  {intersection:adjacent} {via_master:default} \
}

compile_pg -strategies {S_std_cell_rail_VSS_VDD} -via_rule {S_via_stdcellrail}

return

check_pg_missing_vias
check_pg_drc -ignore_std_cells
check_pg_connectivity -check_std_cell_pins none
