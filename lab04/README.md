# Lab04 Pipelining
1. Pattern generation using numpy array and read in the file using newline python reader is a fast way of debugging.
2. Can create an easy interactive jupyter notebook debugger by first reading in the pattern and then perform the data wrangling process.
3. Input.txt can be generated with a seperate generator.py
4. Output.txt known as golden, is generated by feeding the input.txt into the golden model of the algorithm.
5. PATTERN.v is actually the easiest to write, just follow the template then you may code it out in no time.
6. When generating output.txt, must first manually insert some EXTREME cases patterns, otherwise, corner cases might not be found right away!


# Debugger idea
1. Read in the Input.txt
2. Given a certain pattern number
3. Generate all the needed infos for that pattern, for this lab it is convolution results, activation results, max pooling results, fully connected results and l1 distances.
4. Display them onto the jupyter notebook screen for immediate pattern comparison.


# Design
1. Stealing cycles while the machine is reading in the data. This can be done be integrating several state machines into the design. In this design there are two controllers. Pipeline controller and Multicycle controller.
2. Valid signals can be used for propogation and indicate whether the signal is ok to write into the destination registers.
3. Line buffers and shift registers can be used to save area and critical path.
4. Cutting mantissa out of IEE754 is a good idea when precision is not constrainted..
5. Ultilizing the pipelined datapath units can significantly reduce the critical path.
6. For any pipeline design, datapath must be drawn! For better visualization and debug.
7. For protocals and complex controllers, using ASMD charts.

# Adavance convolution algorithm
1. Instead of using the sliding kernals, using sliding images and accumulate the convoluted value into the correct location during process is a great way to reduce run time.

# Tips when generating patterns
1. Use with open() as f and 1D array is a better way to quickly produce a workable pattern.
2. Verilog bits to floating point

# [Bits to floating point](https://blog.csdn.net/w40306030072/article/details/43021399)
1. There are function to directly transform verilog bits representation of floating point into real value.