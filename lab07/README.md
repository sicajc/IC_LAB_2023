# Design flow
1. Create Xor shift algorithm in python or matlab.
2. Create Handshaking synchronizer, test it.
3. Check using JG CDC. Learn how to use it.
4. Create A-FIFO, test A-FIFO


# Handshake synchronizer
[Handshake syn tutorial1](https://www.youtube.com/watch?v=qDnWYp1nG9I&t=506s)

[Handshake syn tutorial2](https://www.youtube.com/watch?v=DLdzmNkSfG8&t=242s)

# ASY-FIFO
[Asynchrnous FIFO](https://www.youtube.com/watch?v=dCj5HAnaCd8)

[Asynchrnous FIFO2](https://www.youtube.com/watch?v=mGREY8u9ELs)

# Lab07 tips
1. FIFO is a useful tool for managing asychronous data, created using SRAM, one can manage the data stream in an asynchrnous way.
2. Asynchrnous FIFO is not an easy design to understand, the concept of 3 cycle design principal is important for keeping the data from becoming unstable.
3. Fuck you JG, convergence error can be solved if you give a feedback handshake control between the block, also seperating out the controls of each block with registers.
4. Clicking on the Why signal on the error waveform can help you trace your code.
