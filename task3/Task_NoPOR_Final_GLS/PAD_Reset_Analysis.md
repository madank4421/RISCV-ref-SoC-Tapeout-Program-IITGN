# PAD Library Study 

## Does the reset pad require Internal enable?

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

