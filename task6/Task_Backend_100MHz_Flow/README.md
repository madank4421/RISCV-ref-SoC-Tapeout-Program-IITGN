Task 6: Backend Flow Bring-Up with 100 MHz Performance Target

Objective
The objective of this task is to set up and validate a complete backend flow capable of supporting a 100 MHz design target (use same design which you used for floorplan), using industry-standard tools and handoffs.
This task focuses on:
•	Correct tool flow setup
•	Correct file formats and paths
•	Clean handoff between tools
•	Basic timing validation


tools:
ICC2 (Placement + Routing)
Star-RC (SPEF Extraction)
PrimeTime (Post-Route STA @ 100MHz)


change the constraints file such that the frequency becomes 100 MHz .

<sdc>

Running Placement:

Run the placement ICC2 shell using the following script:

```
code will upload later
```

now run plaCEMENt and routing:

using the pnr.tcl script file, run placement and routing

```
icc2_shell -f pnr.tcl
```

<routing>

<routing2>
  
The zoomed view of routing can be seen in above image.
