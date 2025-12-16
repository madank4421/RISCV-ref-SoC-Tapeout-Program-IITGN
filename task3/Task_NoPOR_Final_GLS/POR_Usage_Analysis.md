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



# Power-On Reset (POR) Signal Analysis – VSD RISC-V SoC (SCL-180)

**Date:** December 16, 2025
**Author:** Madan K
**Repository:** vsdRiscvScl180
**Branch:** task3-por-removal

---

## Overview

The VSD RISC-V SoC, built on Caravel and using the SCL-180 process, originally uses a behavioral `dummy_por` module to generate power-on reset signals (`porb_h`, `porb_l`, `por_l`). These signals were intended to manage reset sequencing for I/O pads, core logic, housekeeping, clock control, and management modules.

After studying the RTL and I/O pad characteristics in SCL-180, this analysis identifies which POR signals are actively used, which are legacy or pass-through, and how SCL-180’s pad design impacts the need for internal POR.

---

## POR Signal Sources and Relationships

1. **`porb_h`** – Active low, 3.3V domain, high-level bar signal
2. **`porb_l`** – Active low, 1.8V domain, derived from `porb_h`
3. **`por_l`** – Active high, 1.8V domain, inverted from `porb_l`

`dummy_por` is instantiated in `caravel_core.v` and produces all three signals. While it contains behavioral delay logic for simulation, SCL-180 pads have built-in level shifters and do not require POR for voltage translation.

---

## Observed POR Connections

### Management Core (`mgmt_core.v`)

* **POR ports declared:**

  ```verilog
  input wire porb_h_in,
  output wire porb_h_out,
  input wire por_l_in,
  output wire por_l_out
  ```
* **Logic:** Signals are directly routed from input to output:

  ```verilog
  assign porb_h_out = porb_h_in;
  assign por_l_out = por_l_in;
  ```
* **Conclusion:** No internal logic depends on POR; purely pass-through.

---

### Top-Level SoC (`vsdcaravel.v`)

* `porb_h` and `por_l` signals are connected to `mgmt_core_wrapper` and `caravel_core`.
* `por_l` is connected as `por` to caravel_core for core logic reset.
* **Observation:** Top-level only routes signals; no reset sequencing depends on POR here.

---

### Core Logic (`caravel_core.v`)

* **Instantiation of `dummy_por`:**

  ```verilog
  dummy_por por (
      .porb_h(porb_h),
      .porb_l(porb_l),
      .por_l(por_l)
  );
  ```
* **Connections:**

  * `housekeeping` module: `porb_l` as reset
  * `caravel_clocking` module: `porb_l` as reset
* **Observation:** The only modules receiving active POR signals.

---

### Housekeeping Module (`housekeeping.v`)

* **POR input:** `porb`
* **Uses of POR:**

  * Flash SPI output control: disables outputs during reset
  * SPI module: asynchronous reset
  * Wishbone state machine: async reset on POR
  * Serial configuration state machine: async reset for PLL initialization
* **Conclusion:** POR is required for correct reset sequencing; however, all uses can be replaced by the external reset pin in SCL-180.

---

### Clock Control (`caravel_clocking.v`)

* **POR input:** `porb`
* **Reset combination logic:**

  ```verilog
  assign resetb_async = porb & resetb & (!ext_reset);
  ```
* **Function:** Ensures clock output is disabled until POR is released.
* **Replacement:** Removing POR term still allows external reset to control clock safely in SCL-180.

---

### I/O Modules (`chip_io.v` & `mprj_io.v`)

* **POR signal usage:**

  * `porb_h` drives `mprj_io_enh` (pad enable)
  * Legacy SKY130 pads used `ENABLE_H`
* **Observation:** SCL-180 pads do not have ENABLE pins. POR signal is dead code, has no functional effect.

---

### SPI in Housekeeping (`housekeeping_spi.v`)

* Receives `~porb` as reset
* Active-high reset applied to SPI module
* Can be replaced by external reset without affecting functionality.

---

## Active vs. Pass-Through POR Dependencies

**Active Usage (Requires replacement with external reset):**

| Module             | POR Signal | Usage                                |
| ------------------ | ---------- | ------------------------------------ |
| housekeeping.v     | porb_l     | SPI, flash outputs, Wishbone, serial |
| caravel_clocking.v | porb_l     | Clock reset AND logic                |

**Pass-through / Dead Code (Can be removed):**

| Module                | POR Signal    | Usage                                    |
| --------------------- | ------------- | ---------------------------------------- |
| mgmt_core.v           | porb_h, por_l | Routing only                             |
| chip_io.v / mprj_io.v | porb_h        | Pad enable signals (not used in SCL-180) |

---

## Observations About SCL-180 Pads

* No ENABLE pins exist on SCL-180 I/O pads
* Level-shifting is internally handled
* External reset pin is sufficient for housekeeping, clock, and core reset
* All POR-driven legacy logic for pads is unnecessary

---

## Summary

* **`dummy_por` instantiation**: Only actively drives housekeeping and clocking resets
* **I/O POR connections**: Dead code, can be removed
* **Management core**: Only routes POR signals, can be removed
* **Housekeeping and clocking**: POR functionality can be replaced by external reset without impacting operation

**Conclusion:** The VSD RISC-V SoC can safely operate using only an external reset pin. Internal behavioral POR signals and modules related to pad enable or pass-through routing can be removed, simplifying the design and aligning with SCL-180 pad characteristics.

































































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

