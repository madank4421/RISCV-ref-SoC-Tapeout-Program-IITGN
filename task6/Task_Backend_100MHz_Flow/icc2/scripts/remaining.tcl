####################################
# Timing estimation
####################################
estimate_timing
redirect -file $REPORTS_DIR_TIMING_ESTIMATION/${DESIGN_NAME}.post_estimated_timing.rpt     {report_timing -corner estimated_corner -mode [all_modes]}
redirect -file $REPORTS_DIR_TIMING_ESTIMATION/${DESIGN_NAME}.post_estimated_timing.qor     {report_qor    -corner estimated_corner}
redirect -file $REPORTS_DIR_TIMING_ESTIMATION/${DESIGN_NAME}.post_estimated_timing.qor.sum {report_qor    -summary}

save_block -hier -force   -label ${TIMING_ESTIMATION_LABEL_NAME}
save_lib -all


set path_dir [file normalize ${WORK_DIR_WRITE_DATA}]
set write_block_data_script ./write_block_data.tcl
source ${write_block_data_script}

####################################
# Place, CTS, Route
####################################
set_host_options -max_cores 8

# i got error here
remove_corners [get_corners estimated_corner] 
set_app_options -name place.coarse.continue_on_missing_scandef -value true
place_opt
clock_opt
route_auto -max_detail_route_iterations 5
set FILLER_CELLS [get_object_name [sort_collection -descending [get_lib_cells NangateOpenCellLibrary/FILL*] area]]
create_stdcell_fillers -lib_cells $FILLER_CELLS

save_block -hier -force   -label post_route
save_lib -all
