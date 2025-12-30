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



Previous Progress:

floorplan:
<fp.png>



change the constraints file such that the frequency becomes 100 MHz .

<sdc>

Running Placement:

Run the placement ICC2 shell using the following script:

```
code will upload later
```

now run plaCEMENt and routing:

using the script file, run placement and routing

<routing>

<routing2>
  
The zoomed view of routing can be seen in above image.

Let us check the timing results using `report_timing -delay max` and `report_timing -delay min`

<timing_max>

<timing_min>



