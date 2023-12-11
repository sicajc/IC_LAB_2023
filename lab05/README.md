# Notes for lab5
1. Do basic analysis of your algorithm first and identify how much Bandwidth are needed for your architecture, then from the bandwidth analyze the Bandwidth Area product by building out the table to improve the overall performance of the system.
2. For configurable system or system with lots of choices, using counter and timing diagram chart counter method is not a good way of designing system, instead use multiple FSM sub controls instead.
3. Deriving Algorithm and optimize and proof from the algorithmic then use it as a verification for your HW is a great way to ease your debug process, I use python ipynb.
4. Note in the for loop, beware of where your @(negedge clk) is, otherwise you might over count stuff.
5. When using SRAM, the mapping of data which keeps consistency yet waste of area is permitted! I made a huge mistake when designing the system at first.
6. When using sub-FSM, give them their own FSM diagram.
7. For debug perpose, remember to check the value of SRAM after writing into it, also check the value correctness as you build your system along the way, incremental implementation is much more efficient.
8. nMemory and nTrace and Verdi is particularly useful in this lab, those are must mastered tools.