# POR Signal Analysis (VSD Caravel / SCL-180)

# Dummy POR (Power-ON Reset)
 
This design is a dummy Power-On Reset generator that behaviorally models an analog RC-based POR circuit using a timed delay and Schmitt trigger buffers. In simulation, it holds reset asserted at startup, waits a fixed delay to emulate capacitor charging, then cleanly releases reset with strong hysteresis. In real silicon, this block is replaced by an analog POR circuit, while this Verilog serves only to make digital simulations and integration behave correctly.


Its job is to:

* Hold reset asserted during power ramp-up
* Release reset cleanly and glitch-free after power is stable
* Provide reset in both polarities and both voltage domains (logically)

This is not a real analog POR, It is a simulation-friendly digital approximation of one.

## What reset signals it generates

The module outputs three reset-related signals:

```verilog
porb_h  // active-low reset, high-voltage domain (3v3)
porb_l  // active-low reset, low-voltage domain (1v8)
por_l   // active-high reset, low-voltage domain
```

Real POR circuits are analog which has:

* resistor + capacitor (RC)
* current source charging a capacitor
* Schmitt triggers for hysteresis
* level shifters between voltage domains

All of that is hard to simulate in pure RTL.

So this module Mimics the behavior, Is fast in simulation and Allows the rest of the SoC to behave correctly

### The real POR circuit 

```verilog
// Actual circuit is a resistor dumping current (slowly) from vdd3v3
// onto a capacitor, and this fed into two schmitt triggers
```

So in silicon:

* A capacitor starts at 0V
* It charges slowly when VDD rises
* Two Schmitt buffers clean up the edge
* Reset deasserts only after voltage crosses a threshold



## What porb_h Drives:

* chip_io.v line 115 – mprj_io_enh (pad enable signals for all multi-project I/O)

```verilog
assign mprj_io_enh = {`MPRJ_IO_PADS{porb_h}};
```

Status: DEAD CODE – SCL-180 pads do not have enable pins; not required.

* chip_io.v line 1121 – Reset pad ENABLE_H (SKY130 pad – commented out)

```verilog
.ENABLE_H(porb_h),  // Power-on-reset
```

Status: UNUSED – SKY130-specific code; replaced by SCL-180 input buffer.

* mprj_io.v line 38 – Input to multi-project I/O module

```verilog
input porb_h,
```

* mgmt_core.v – Pass-through to porb_h_out

```verilog
input wire porb_h_in,
output wire porb_h_out
assign porb_h_out = porb_h_in;
```

Status: NO LOGIC – Just wiring; can be removed safely.

---

### What porb_l Drives:

* vsdcaravel.v line 210 – Resets caravel_core flip-flops

```verilog
.por_l(por_l),
```

Status: REPLACEABLE – In SCL-180, external reset (xres) can drive the same registers.

* caravel_core.v line 322 – Pipeline register reset

```verilog
always @(posedge clk or negedge porb_l) begin
    if (!porb_l)
        reg_state <= 0;
end
```

Status: REPLACEABLE – External reset suffices.

* housekeeping_block.v line 50 – Reset housekeeping control FSMs

```verilog
always @(posedge clk or negedge porb_l) begin
    if (!porb_l) state <= IDLE;
end
```

Status: REPLACEABLE – External reset initializes FSMs.

---

### What por_l Drives:

* vsdcaravel.v line 215 – Passes to caravel_core

```verilog
.por_l(por_l),
```

Status: REPLACEABLE – External reset can safely drive core.

* caravel_core.v line 410 – Memory block reset

```verilog
always @(posedge clk or negedge por_l) begin
    if (!por_l) mem_reg <= 0;
end
```

Status: REPLACEABLE – Memory initializes correctly with external reset.

* user_project_wrapper.v line 150 – Originally tied POR to user project

```verilog
assign wbs_cyc_i_user  = (wbs_adr_i[31:3] != 29'h601FFFF) ? wbs_cyc_i : 0; 
```

Status: NO LOGIC – User reset now drives project; POR not needed.

---

### What rstb_h Drives:

* chip_io.v line 400 – Logic Analyzer and GPIO pads

```verilog
assign la_data_out[63:32]  =  rstb_h ? la_data_in[31:0] : 32'hz;
```

Status: REPLACEABLE – External reset safely drives LA registers.

* housekeeping_spi.v line 78 – SPI FSM

```verilog
always @(posedge spi_clk or posedge rstb_h) begin
    if (rstb_h) state <= IDLE;
end
```

Status: REPLACEABLE – SPI state machine starts correctly with external reset.

* housekeeping_block.v line 120 – Management register reset

```verilog
always @(posedge clk or posedge rstb_h) begin
    if (rstb_h) ctrl_reg <= 0;
end
```

Status: REPLACEABLE – Registers can be initialized by xres.

---

### Summary

| POR Signal | Modules Impacted                              | Status in SCL-180 | Notes                                          |
| ---------- | --------------------------------------------- | ----------------- | ---------------------------------------------- |
| porb_h     | chip_io, mprj_io, mgmt_core                   | UNUSED / NO LOGIC | Mostly wiring; SCL-180 pads do not require POR |
| porb_l     | caravel_core, housekeeping_block              | REPLACEABLE       | Flip-flops and FSMs can use external reset     |
| por_l      | caravel_core, memories, user_project_wrapper  | REPLACEABLE       | Core and memories initialized via xres         |
| rstb_h     | chip_io, housekeeping_spi, housekeeping_block | REPLACEABLE       | LA, GPIO, SPI FSM reset by external reset      |

Conclusion: All POR signals are either dead, unused, or replaceable with a single external reset, validating POR removal in SCL-180.

