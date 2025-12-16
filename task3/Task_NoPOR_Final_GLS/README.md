# Task3 - Removal of On-Chip POR and Final GLS Validation (SCL-180)

The objective of this task is to formally remove the on-chip Power-On Reset (POR) from the VSD Caravel-based RISC-V SoC and prove—using design reasoning, pad analysis, synthesis, and gate-level simulation—that an external reset-only strategy is safe and correct for SCL-180.

## Remove POR from RTL

First let us remove the dummy_por from our design. for that , lets remove (or comment) its instantiattion from the design. it is instantited in caravel_core.v

<fix1>

since the ports of dummy_por shouldnt be left hanging, we are going to use it in such a way it is driven by an external reset resetb.

So, in caravel_core Declare the output ports porb_h, porb_l as inout, so that we can drive those signals in the top module vsdcaravel.v 

<fix2>

Also remeber to do the same in the instantiation of the caravel_core (inside vsdcaravel.v), to avoid signal name mismatch.

<fix3>

Now assign the nets from the port porb_l, porh_l and por_l to resetb. This is done to provide an external reset to all the modules instead of dummy_por's por signal.

<fix4>

## Run the RTL (Functional) simulation

Before running our RTL SImulation , let us make sure the dummy_por is totally removed from our design. let us delete all the dummy_por.v files from our design (both from rtl/ and gl/).

<fix5>

ALso, let us remove all the lines which includes the dummy_por.v 

<fix6>

Now let us Run the Simulation
