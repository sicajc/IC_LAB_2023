import numpy as np
def toDec(hexstr,BIT):
    msb4bits = hexstr[0]
    n = int(msb4bits, 16)
    if n >= 8:
        p = -1*pow(2,BIT-1)
        addend = int(str(n-8) + hexstr[1:], 16)
        return str( p + addend)
    else:
        return str(int(hexstr, 16))

with open('output_1.txt', 'r') as file:
  file_in = file.readlines()


map_rf = np.zeros((64,64))
map1_rf = np.zeros((64,64))

for i in range(64):
    read_in_row = np.array([int(val) for val in file_in[1 + i].split()])
    for j in range(len(read_in_row)):
        map_rf[i][j] = read_in_row[j]

for i in range(64):
    read_in_row = np.array([int(val) for val in file_in[66 + i].split()])
    for j in range(len(read_in_row)):
        map1_rf[i][j] = read_in_row[j]
