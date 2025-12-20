# Task4: Full Management SoC DV Validation on SCL-180 (POR-Free Design)

Objective
The objective of this task is to prove that our POR-free RTL is production-ready by:
1.	Running all Management SoC (mgmt_soc) DV tests originally written for Caravel
2.	Using a new SCL-180 netlist generated via DC_TOPO
3.	Running the same tests twice:
o	Phase-A: Using RTL SRAM models
o	Phase-B: Using DC_TOPO synthesized SRAM
4.	Demonstrating that behavior is identical across:
o	RTL simulation
o	GLS with RTL SRAM
o	GLS with synthesized SRAM


Toolchain Requirements
•	Synopsys VCS (functional + GLS)
•	Synopsys DC_TOPO
•	SCL-180 standard cell libraries
•	SCL-180 IO models



RTL Preparation 
## Removal of POR from RTL

The original design includes a dummy_por module, which generates internal power-on reset signals. Since the target flow relies entirely on an external reset pad, this module is no longer required.

The dummy_por instantiation is removed from caravel_core.v by commenting out or deleting the instance.

![Alt text](images/fix1.png)

Once the POR generator is removed, its output signals must not remain floating. The signals porb_h and porb_l are therefore repurposed to be driven externally. In caravel_core, these signals are modified from output ports to inout ports so that they can be driven from the top-level module.

![Alt text](images/fix2.png)

The same port-direction changes are reflected in the instantiation of caravel_core inside vsdcaravel.v to maintain port consistency and avoid elaboration mismatches.

![Alt text](images/fix3.png)

At the top level, the POR-related nets porb_h, porb_l, and por_l are explicitly tied to the external reset signal resetb. This ensures that all internal logic that previously depended on the POR now responds directly to the external reset pad.

![Alt text](images/fix4.png)

With these changes, the entire SoC reset behavior is controlled exclusively by the external reset pin.


Synthesis with DC 

Synthesis of the POR-free vsdcaravel SoC is performed using Synopsys Design Compiler. The synthesis is run from the synthesis/work_folder directory using a TCL script located in the synthesis directory. This script reads the required standard cell and IO pad libraries, applies constraints, blackboxes selected modules, and generates reports.

The libraries used include SCL180 IO pad libraries and standard cell libraries in liberty DB format. The top module for synthesis is vsdcaravel, and the synthesized netlist is written to the synthesis/output directory.

Memory modules (RAM128, RAM256) and power-on-reset logic (dummy_por) are intentionally treated as blackboxes during synthesis to avoid implementation-specific dependencies. Corresponding blackbox module definitions are placed in the stubs directory.

![Alt text](images/task4_1.png)

An example blackbox definition for the dummy_por module is shown below.

![Alt text](images/task4_2.png)

Used this synth.tcl file for synthesis:

```tcl
read_db "/home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/iopad/cio250/4M1L/liberty/tsl18cio250_min.db"

read_db "/home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/stdcell/fs120/4M1IL/liberty/lib_flow_ff/tsl18fs120_scl_ff.db"


set target_library "/home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/iopad/cio250/4M1L/liberty/tsl18cio250_min.db /home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/stdcell/fs120/4M1IL/liberty/lib_flow_ff/tsl18fs120_scl_ff.db"

set link_library {"* /home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/iopad/cio250/4M1L/liberty/tsl18cio250_min.db /home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/stdcell/fs120/4M1IL/liberty/lib_flow_ff/tsl18fs120_scl_ff.db"}

set_app_var target_library $target_library
set_app_var link_library $link_library



set root_dir "/home/madank/work/vsdRiscvScl180"
set io_lib "/home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/iopad/cio250/4M1L/verilog/tsl18cio250/zero"
set verilog_files  "$root_dir/rtl"
set top_module "vsdcaravel" ;
set output_file "$root_dir/synthesis/output/vsdcaravel_synthesis.v"
set report_dir "$root_dir/synthesis/report"

read_file $verilog_files/defines.v

set blackboxes_dir "/home/madank/work/vsdRiscvScl180/stubs"

set blackbox_files [glob -nocomplain ${blackboxes_dir}/*.v]

read_file $blackbox_files -format verilog


# read all rtl files
set all_rtl_files [glob -nocomplain ${verilog_files}/*.v]


# all rtl files except the blackbox ones
set files_to_read [list]

foreach file $all_rtl_files {
	set indicator 0
	foreach bb_file $blackbox_files {
		if {[string equal $file $bb_file]} {
		    set indicator 1
		    break
		}
	}
	if{!indicator}{
		lappend files_to_read $file
	}
}

read_file $files_to_read -define USE_POWER_PINS -format verilog

elaborate $top_module


# Mark RAM128 as blackbox
if {[sizeof_collection [get_designs -quiet RAM128]] > 0} {
    set_attribute [get_designs RAM128] is_black_box true -quiet
    set_dont_touch [get_designs RAM128]
}

# Mark RAM256 as blackbox
if {[sizeof_collection [get_designs -quiet RAM256]] > 0} {
    set_attribute [get_designs RAM256] is_black_box true -quiet
    set_dont_touch [get_designs RAM256]
}


# Mark dummy_por as blackbox
if {[sizeof_collection [get_designs -quiet dummy_por]] > 0} {
    set_attribute [get_designs dummy_por] is_black_box true -quiet
    set_dont_touch [get_designs dummy_por]
}


# Handle any other POR-related modules (case insensitive)
foreach_in_collection por_design [get_designs -quiet "*por*"] {
    set design_name [get_object_name $por_design]
    if {![string equal $design_name "dummy_por"]} {
        set_dont_touch $por_design
        set_attribute $por_design is_black_box true -quiet
    }
}


# Protect all instances of RAM128, RAM256, and dummy_por
foreach blackbox_ref {"RAM128" "RAM256" "dummy_por"} {
    set instances [get_cells -quiet -hierarchical -filter "ref_name == $blackbox_ref"]
    if {[sizeof_collection $instances] > 0} {
        set_dont_touch $instances
        set inst_count [sizeof_collection $instances]
    }
}


link

uniquify

read_sdc "$root_dir/synthesis/vsdcaravel.sdc"

compile

write -format verilog -hierarchy -output $output_file
write -format ddc -hierarchy -output "$root_dir/synthesis/output/vsdcaravel_synthesis.ddc"
write_sdc "$root_dir/synthesis/output/vsdcaravel_synthesis.sdc"


report_area > "$report_dir/area.rpt"
report_power > "$report_dir/power.rpt"
report_timing -max_paths 10 > "$report_dir/timing.rpt"
report_constraint -all_violators > "$report_dir/constraints.rpt"
report_qor > "$report_dir/qor.rpt"
```

Synthesis is launched using dc_shell.

```
dc_shell -f ../synth.tcl
```

![Alt text](images/task4_3.png)

![Alt text](images/task4_4.png)

The synthesized netlist is generated successfully and stored in the synthesis/output directory.

![Alt text](images/task4_5.png)

Inspection of the netlist confirms that the memory and POR modules are correctly preserved as blackboxes.

To perform GLS with the RTL Models of the SRAM, we can include the RAM128.v and RAM256.v models in the vsdcaravel_netlist.v



Management SoC DV – Run-1 (RTL SRAM)

Housekeeping SPI 

functiional simulation

Functional simulation focuses on the housekeeping_spi module present in the vsdcaravel SoC. The corresponding testbench is located in the dv/hkspi directory. Simulation is performed using Synopsys VCS with functional defines enabled.

```
cd dv/hkspi/
```

The Synopsys environment is initialized before invoking VCS.

```
csh
source /home/madank/toolRC_iitgntapeout
```

The following command compiles the RTL and testbench and creates the simulation executable.

```
vcs -full64 -sverilog -timescale=1ns/1ps -debug_access+all \
    +incdir+../ +incdir+../../rtl +incdir+../../rtl/scl180_wrapper \
    +incdir+/home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/iopad/cio250/6M1L/verilog/tsl18cio250/zero \
    +define+FUNCTIONAL +define+SIM \
    hkspi_tb.v -o simv
```

The simulation is executed and a VCD file is generated for waveform viewing.

```
./simv -no_save +define+DUMP_VCD=1 | tee sim_log.txt
```

![Alt text](images/task4_6.png)

All test cases pass successfully. The values read from registers 0 to 18 match the expected results, confirming correct functional behavior of the design.

Waveforms are viewed using GTKWave.

```
gtkwave hkspi.vcd hkspi_tb.v
```

![Alt text](images/task4_7.png)

![Alt text](images/task4_8.png)




Gate-level Simulation

Gate-level simulation is performed using the synthesized netlist to validate post-synthesis functional correctness. VCS is again used for this purpose, and simulation is run from the gls directory.

```
vcs -full64 -sverilog -timescale=1ns/1ps \
    -debug_access+all \
    +define+FUNCTIONAL+SIM+GL \
    +notimingchecks \
    hkspi_tb.v \
    +incdir+../synthesis/output \
    +incdir+/home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/iopad/cio250/4M1L/verilog/tsl18cio250/zero \
    +incdir+/home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/stdcell/fs120/4M1IL/verilog/vcs_sim_model \
    -o simv
```

Some compilation and simulation errors may occur during this stage. The specific issues encountered and their resolutions are documented [HERE](#errors-during-gate-level-simulation).

![Alt text](images/task4_9.png)

The simulation is executed and a VCD file is generated.

```
./simv -no_save +define+DUMP_VCD=1 | tee sim_log.txt
```

![Alt text](images/task4_10.png)

The output initially fails, producing unknown values. This behavior is expected because memory and POR modules were blackboxed during synthesis, resulting in undefined behavior during simulation.

To validate correct functionality, the blackbox definitions are removed and the original RTL implementations of these modules are included during gate-level simulation. The simulation is then recompiled and executed.

![Alt text](images/task4_11.png)

```
./simv -no_save +define+DUMP_VCD=1 | tee sim_log.txt
```

![Alt text](images/task4_12.png)

With the functional RTL of the memory and POR modules included, the gate-level simulation produces correct results that match the functional simulation.

Waveforms are again inspected using GTKWave.

```
gtkwave hkspi.vcd hkspi_tb.v
```

![Alt text](images/task4_13.png)

![Alt text](images/task4_14.png)

