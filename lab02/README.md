# Tips and tricks of lab2
1. Do not process the data right away after reading in the data, the input of the last stage would destroy your circuit's slack. Process it after storing it into the register.
2. Cycles can be stolen during the data read in phase, area can be saved if you do so by building a multicycle machine architecture.
3. Resource sharing must be performed by extracting components out 1 by 1, compiler would help extracting common terms, if those variables are of the same length.
4. First test the circuit with maximum data bit width s.t. you can ensure that the circuit is not overflow.
5. Changing signed arithmetic units into unsigned ones when you know the value is always positive can greatly reduce the area of those arithmetic units.
6. Distributing data calculation into multiple cycles is a great technique for reducing area. I.e. if there are cycles to spare.