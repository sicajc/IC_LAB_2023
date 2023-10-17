fully_connected_result = np.zeros((4,1),dtype='float32')

LARGE_NUMBER = 99999999999999999999999999999
SMALL_NUMBER = -99999999999999999999999999999

min = np.float32(LARGE_NUMBER)
max = np.float32(SMALL_NUMBER)

for i in range(2):
    for j in range(2):
        partial_mult = 0
        for k in range(2):
            partial_mult += max_pooled_result[i,k] * weight[k,j]

        if partial_mult > max:
            max = partial_mult
        if partial_mult < min:
            min = partial_mult

        fully_connected_result[i*2+j] = partial_mult