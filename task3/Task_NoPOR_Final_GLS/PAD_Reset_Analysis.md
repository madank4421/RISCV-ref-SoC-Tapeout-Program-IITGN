# PAD Library Study 

## 1. Does the reset pad require Internal enable?

No, the reset pad does not require an internal enable.

**Justification with evidence from RTL:**

The reset pad in SCL-180 is instantiated as resetb_pad inside `chip_io.v` (line 1141):

```verilog
pc3d21 resetb_pad (
       .PAD(resetb),
       .CIN(resetb_core_h)
);
```

The `pc3d21` is a buffer with a 0.01 ns delay.

**Analysis:**

* There is **no `OEN`, `RENB`, or other control signals** in the module.
* The buffer directly drives the output `CIN` from the pad `PAD`.
* No logic exists to **enable/disable** the output internally.

**Conclusion:**

* **Internal enable:** **Not required**.
* **Evidence:** The module has only an input pad and an output buffer, with no enable control signals. The buffer drives `CIN` immediately from `PAD`.

But in sky130 we can see the reset pad as:

```
sky130_fd_io__top_xres4v2 resetb_pad (
		`MGMT_ABUTMENT_PINS
		`ifndef	TOP_ROUTING
		    .PAD(resetb),
		`endif
		.TIE_WEAK_HI_H(xresloop),   // Loop-back connection to pad through pad_a_esd_h
		.TIE_HI_ESD(),
		.TIE_LO_ESD(xres_vss_loop),
		.PAD_A_ESD_H(xresloop),
		.XRES_H_N(resetb_core_h),
		.DISABLE_PULLUP_H(xres_vss_loop), // 0 = enable pull-up on reset pad
		.ENABLE_H(porb_h),	 	  // Power-on-reset
   		.EN_VDDIO_SIG_H(xres_vss_loop),	  // No idea.
   		.INP_SEL_H(xres_vss_loop),	  // 1 = use filt_in_h else filter the pad input
   		.FILT_IN_H(xres_vss_loop),	  // Alternate input for glitch filter
   		.PULLUP_H(xres_vss_loop),	  // Pullup connection for alternate filter input
		.ENABLE_VDDIO(vccd_const_one[6])
    	);
```

The internal enable for POR exists and is given by .ENABLE_H(porb_h). The POR circuitry is internally enabled via porb_h. So this pad is POR-driven.

This is why the SCL-180 reset pad can operate **without internal enable**, unlike other pads in some PDKs (e.g., SKY130), which use enable signals to gate the reset during power-up.










## 2. Does the SCL-180 reset pad require POR-driven gating?

**Answer:** **No, it does not require POR-driven gating.**

**Justification using SCL-180 RTL:**

The SCL-180 reset pad is instantiated as:

```verilog
pc3d21 resetb_pad (
       .PAD(resetb),
       .CIN(resetb_core_h)
);
```

The RTL of `pc3d21` is extremely simple. From the instantiation it can be noted that it is a buffer:

```verilog
pc3d21 (PAD,CIN);
```

**Key observations:**

1. The module consists of **only a single buffer** connecting `PAD` to `CIN`.
2. There is **no `ENABLE` signal**, **no POR input**, and **no internal gating logic**.
3. The pad output is always driven directly by the pad input.

Hence, there is **no mechanism to gate the pad output during power-on**, so a POR-driven gating circuit is **not required**. The pad simply passes the external reset signal (`resetb`) to the core (`resetb_core_h`) unconditionally.

---

### Comparison with SKY130 reset pad

SKY130 uses a more complex pad:

```verilog
sky130_fd_io__top_xres4v2 resetb_pad (
    .PAD(resetb),
    .XRES_H_N(resetb_core_h),
    .ENABLE_H(porb_h),      // Power-on-reset controlled
    ...
);
```

**Differences:**

| Feature                     | SCL-180 pc3d21 | SKY130 top_xres4v2                         |
| --------------------------- | -------------- | ------------------------------------------ |
| POR gating                  | ❌ Not present  | ✅ Controlled via `ENABLE_H(porb_h)`        |
| Internal logic              | Simple buffer  | Complex ESd + POR + filter + pull-up logic |
| Internal enable             | ❌ None         | ✅ Present (`ENABLE_H`)                     |
| Filtering/glitch protection | ❌ None         | ✅ `FILT_IN_H`, `INP_SEL_H`                 |

Conclusion from comparison:

* In SKY130, POR gating is **necessary** because the pad includes internal logic that may float or require controlled activation during power-up.
* In SCL-180, the reset pad is **just a direct buffer**; the core will see the external reset immediately. No POR gating or additional enable is required.


### Final Answer:

* **Internal enable:** Not required.
* **POR-driven gating:** Not required.
* **Evidence:** SCL-180 `pc3d21` RTL shows a single buffer with no enable or POR control, unlike SKY130 which explicitly uses `ENABLE_H(porb_h)`.


## 3. Is the reset pin Asynchronous?

Yes. In the VSDCaravel / SCL-180 design, the reset pin is asynchronous.

### Observation from the RTL

The reset pad in your design is:

```verilog
pc3d21 resetb_pad (
    .PAD(resetb),
    .CIN(resetb_core_h)
);
```

**Key points:**

* The `CIN` (core reset input) **follows the PAD directly** through a buffer.
* There is **no clock signal anywhere in the reset path**.
* No synchronizer flip-flops or logic exist in this path.

---

### What makes a reset asynchronous

A reset is **asynchronous** if it can change the state of the system immediately **without waiting for a clock edge**.

* In your design, `resetb_core_h` is driven **directly by `resetb` PAD**.
* Therefore, the core sees the reset immediately whenever the PAD changes, independent of the clock.

This is exactly the definition of **asynchronous reset**.

---

### Comparison with synchronous reset

* **Synchronous reset**: Reset signal is sampled by a flip-flop **at a clock edge**, e.g., `always @(posedge clk) if (rst) ...`.
* **Asynchronous reset**: Reset is **applied immediately**, independent of the clock, as in your `pc3d21` buffer connection.

---

### Supporting evidence from SKY130 (optional)

In SKY130:

```verilog
.XRES_H_N(resetb_core_h),
.ENABLE_H(porb_h)
```

* `XRES_H_N` is also **directly driven** from the pad through internal circuitry.
* If the enable were used, POR could control it, but still, the reset is **applied asynchronously**, independent of the clock.

---

**Conclusion:**

* **VSDCaravel reset pin is asynchronous.**
* **Justification:** The reset signal passes directly from the pad to the core through a buffer (`pc3d21`), with no clock-dependent logic or synchronizer.



## 4. Is the reset pin Available immediately after VDD?


Yes. In the VSDCaravel design targeting SCL-180, the reset pin is available immediately after VDD comes up.

The reset pin in the design is implemented using simple SCL-180 input pad cells such as `pc3d21`, `pc3d01`, or equivalent, which are nothing more than a direct buffer from the external PAD pin to the internal core signal (`CIN`). There are no enable pins, no power-on-reset inputs, no gating logic, no latch, and no clock dependency inside the pad model.

As soon as VDD and GND are valid, the buffer becomes electrically active and propagates the pad value to the core. There is no dependency on any internal control signal such as `porb_h`, `por_l`, or any other sequencing signal. Therefore, the reset signal is visible to the digital core immediately after power is applied.

From the RTL perspective, this means:

* The reset pin does not wait for any internal POR to release it.
* The pad does not require a separate enable to become functional.
* The reset signal does not depend on clock availability.

This is fundamentally different from a gated or POR-controlled reset pad.

Contrast with SKY130:

In the SKY130 flow, the reset pad (`sky130_fd_io__top_xres4v2`) includes explicit POR-related and enable-related controls:

```verilog
.ENABLE_H(porb_h),      // Power-on-reset
.DISABLE_PULLUP_H(...)
.INP_SEL_H(...)
.FILT_IN_H(...)
```

In SKY130, the reset pad input path is explicitly gated by `porb_h`. Until the internal POR deasserts, the reset pad is not guaranteed to propagate correctly to the core. This makes POR a functional requirement in that technology.

In SCL-180, none of these control or gating signals exist in the reset pad instantiation. The reset pad is a passive input buffer that becomes operational as soon as the power rails are valid.

Final conclusion:

In the VSDCaravel SCL-180 implementation, the reset pin is available immediately after VDD because:

* The reset pad is a simple buffer-based input cell.
* There is no POR-driven gating or internal enable.
* The reset signal propagates directly from the pad to the core without waiting for any internal sequencing.

This makes an external reset-only strategy architecturally safe in SCL-180 and removes the necessity for an on-chip POR.
