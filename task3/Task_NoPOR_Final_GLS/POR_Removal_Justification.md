# Why External Reset Is Sufficient in SCL-180 (No POR)

This document provides the technical justification for removing the on-chip Power-On Reset (POR) mechanism from the VSD Caravel-based RISC-V SoC when targeting the SCL-180 PDK. The justification is based entirely on RTL inspection, pad wrapper behavior, and reset distribution logic visible in the design. The conclusion is that an external reset-only strategy is safe, correct, and architecturally aligned with SCL-180, without relying on any hidden or undocumented assumptions.


## POR Is Fundamentally an Analog Problem

A true Power-On Reset is an analog function. It depends on physical phenomena such as supply ramp rate, threshold detection, hysteresis, and timing stability, none of which can be reliably expressed or verified in synthesizable RTL. Any RTL-based POR is therefore, by definition, a behavioral approximation used only for simulation convenience.

This is clearly visible in the design itself: the `dummy_por` module is a behavioral construct used to generate `porb_h`, `porb_l`, and `por_l`, and it does not correspond to a real, synthesizable digital circuit. Its purpose is to model power sequencing during simulation, not to represent an actual hardware macro.

Because POR is an analog concern, its correctness must be guaranteed either by:

* dedicated analog macros, or
* I/O pad behavior that is inherently safe during power-up.

In SCL-180, the latter is true, as demonstrated by the pad wrapper RTL.

---

## Why RTL-Based POR Is Unsafe as a Hardware Requirement

Using an RTL POR as a functional dependency is unsafe for three reasons:

1. It cannot be synthesized into a real POR circuit.
2. Its timing assumptions (delay, release sequence) are artificial.
3. It masks the true hardware behavior of pads and reset paths.

The current design already acknowledges this implicitly: `dummy_por` is treated as a source of reset signals, but those signals do not actually control pad electrical safety in SCL-180. Instead, pad safety is implemented internally through pad mode logic.

Thus, retaining POR as a required architectural element would introduce a false dependency that does not exist in silicon.

---

## What Actually Protects Pads in SCL-180

The critical difference between SCL-180 and SKY130 lies in **how pad safety is enforced during power-up**.

### Evidence from `pc3b03ed_wrapper`

The multi-purpose I/O pad wrapper implements safety using explicit mode and enable logic:

```verilog
assign output_EN_N =
    (~INPUT_DIS && (dm[2:0] == 3'b001)) ||
    OUT_EN_N ||
    (dm[2:0] == 3'b000) ||
    (~INPUT_DIS && (dm[2:0] == 3'b010));

assign pull_down_enb = (dm[2:0] == 3'b000);
```

Key observations:

* There is **no POR input**.
* Output enable depends only on `dm`, `OUT_EN_N`, and `INPUT_DIS`.
* When `dm == 3'b000`, the pad is forced into a safe state with:

  * output disabled
  * internal pull-down enabled

The pad itself is instantiated as:

```
pc3b03ed pad(
    .CIN(IN),
    .OEN(output_EN_N),
    .RENB(pull_down_enb),
    .I(OUT),
    .PAD(PAD)
);
```

This proves that **pad electrical safety at power-up is guaranteed internally by mode logic**, not by POR gating.

As long as the default mode is safe (which it is in the Caravel architecture), pads cannot drive illegal values during power-up.

---

## Reset Pad Behavior in SCL-180

The reset pad is implemented using `pc3d01_wrapper`:

```verilog
module pc3d01_wrapper(output IN, input PAD);
    pc3d01 pad (
        .CIN(IN),
        .PAD(PAD)
    );
endmodule
```

The underlying cell behavior is a buffer behavior.

This means:

* The reset pad is a simple input buffer.
* There is no enable pin.
* There is no POR gating.
* The signal is continuously observable.

This directly answers two critical questions:

* The reset pad does **not** require an internal enable.
* The reset pad does **not** require POR-driven gating.

The pad is always active, and its safety depends entirely on the fact that it is input-only and externally driven.

---

## Asynchronous Nature of the Reset Signal

The reset signal in the design is asynchronous by construction.

This is visible in multiple places, especially in housekeeping logic:

```verilog
always @(posedge wb_clk_i or negedge porb) begin
    if (porb == 1'b0) begin
        ...
    end
end
```

and similarly:

```verilog
always @(posedge csclk or negedge porb) begin
    if (porb == 1'b0) begin
        ...
    end
end
```

These constructs prove that reset is sampled asynchronously with respect to the clock. This behavior does not depend on POR; it depends only on the reset signal itself.

Therefore, replacing `porb` with an external `resetb` preserves the asynchronous reset semantics exactly.

---

## Reset Availability Immediately After VDD

In SCL-180, the reset pad is available immediately after VDD because:

1. The pad is a simple buffer (`pc3d01`).
2. There is no enable or power qualification signal.
3. There is no dependency on internal logic being active.

Once VDD is present, the pad reflects the external reset state directly into the core.

By contrast, in SKY130, reset availability depended on POR because the reset pad itself was gated.

---

## Why POR Was Mandatory in SKY130 but Not Here

The SKY130 reset pad explicitly required POR:

```
.ENABLE_H(porb_h),   // Power-on-reset
```

This line is decisive. It means:

* The reset pad was electrically disabled until POR released.
* Without POR, the pad input was not valid.
* POR was therefore mandatory for correctness.

No equivalent signal exists in SCL-180 pad wrappers.

In SCL-180:

* There is no `ENABLE_H`
* There is no `porb_h` input to pads
* Safety is mode-driven, not POR-driven

Thus, the architectural requirement for POR disappears.

---

## Why POR Still Appears in the RTL

POR signals persist in the RTL because the design was originally derived from a SKY130-centric architecture. They remain as legacy distribution signals routed through modules such as `mgmt_core`, `chip_io`, and `mprj_io`.

However, inspection shows that:

* Many POR paths are pass-through only.
* Some POR-driven logic controls signals that are unused in SCL-180.
* No pad wrapper consumes POR directly.

This proves that POR is no longer functionally essential.

---

## Risks Considered and Mitigations

The primary risks considered were:

* Pads driving during power-up
  Mitigated by pad mode logic (`dm == 000`).

* Reset instability during clock startup
  Mitigated by asynchronous reset design.

* Loss of power sequencing protection
  Mitigated by external reset assertion until supplies stabilize.

* Clock domain hazards
  Addressed by external reset and existing reset synchronization logic.

No risk remains that specifically requires an internal POR.

---

## Final Justification

The removal of POR in the SCL-180 Caravel design is not an omission or limitation of the PDK. It is a direct consequence of a different pad safety philosophy.

In SCL-180:

* Pad electrical safety is guaranteed by pad-internal mode control.
* Reset pads are always active and input-only.
* Reset distribution is asynchronous and independent of POR.
* External reset provides all necessary control for safe bring-up.

Therefore, an external reset-only strategy is both safe and architecturally correct for SCL-180, and retaining an RTL-based POR would add unnecessary complexity without providing real hardware protection.
