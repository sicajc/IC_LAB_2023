# %%
import numpy as np

PATTERN_TO_DEBUG = 0

def toDec(hexstr,BIT):
    msb4bits = hexstr[0]
    n = int(msb4bits, 16)
    if n >= 8:
        p = -1*pow(2,BIT-1)
        addend = int(str(n-8) + hexstr[1:], 16)
        return str( p + addend)
    else:
        return str(int(hexstr, 16))

def int2hex(num,bit_width):
    if num<0:
        num = (1 << bit_width) + num
    hex_string = hex(num)[2:]
    return '{:0>{width}}'.format(hex_string,width = (bit_width+3)//4)

NEGATE = {'1': '0', '0': '1'}
def negate(value):
    return ''.join(NEGATE[x] for x in value)

def twocomplement(n, size_in_bits):
    # print(n)
    number = int(n)
    if number < 0:
        return negate(bin(abs(number) - 1)[2:]).rjust(size_in_bits, '1')
    else:
        return bin(number)[2:].rjust(size_in_bits, '0')

NEGATE = {'1': '0', '0': '1'}
def negate(value):
    return ''.join(NEGATE[x] for x in value)

def reverseRow(data, index):

    cols = len(data[index])
    for i in range(cols // 2):
        temp = data[index][i]
        data[index][i] = data[index][cols - i - 1]
        data[index][cols - i - 1] = temp

    return data

# Rotate Matrix by 180 degrees
def rotateMatrix(data):

    rows = len(data)
    cols = len(data[0])

    if (rows % 2):
        # If N is odd reverse the middle
        # row in the matrix
        data = reverseRow(data, len(data) // 2)

        # Swap the value of matrix [i][j] with
        # [rows - i - 1][cols - j - 1] for half
        # the rows size.
        for i in range(rows // 2):
            for j in range(cols):
                temp = data[i][j]
                data[i][j] = data[rows - i - 1][cols - j - 1]
                data[rows - i - 1][cols - j - 1] = temp
        return data

def twocomplement(n, size_in_bits):
    # print(n)
    number = int(n)
    if number < 0:
        return negate(bin(abs(number) - 1)[2:]).rjust(size_in_bits, '1')
    else:
        return bin(number)[2:].rjust(size_in_bits, '0')


# %%
with open('input.txt', 'r') as file:
  file_in = file.readlines()

NUM = int(file_in[0])

# print(file_in)
for i in range(NUM):
  img_16 = []
  kernal_16 = []
  matrix_idx = []
  mode = []

  # MATRIX SIZE
  matrix_in_idx = int(file_in[1 + 65 * i + 0])

  if matrix_in_idx == 0:
     matrix_size = 8
  elif matrix_in_idx == 1:
     matrix_size = 16
  else:
     matrix_size = 32

  for j in range(16):
    img_in = np.array([int(toDec(val,8)) for val in file_in[1 + 65 * i + (1+j)].split()])
    img_16.append(np.reshape(img_in,(matrix_size,matrix_size)))

  for k in range(16):
    kernal_in = np.array([int(toDec(val,8)) for val in file_in[1 + 65 * i + (17+k)].split()])
    kernal_16.append(np.reshape(kernal_in,(5,5)))


  for idx in range(16):
    mode.append(int(file_in[1 + 65 * i + (33+idx*2)])) #0 2 4
    matrix_idx.append(np.array([int(val) for val in file_in[1 + 65 * i + (34+idx*2)].split()]))# 1 3 5

  if i == PATTERN_TO_DEBUG:
    break

# %%
mode[0]

# %%
matrix_idx[6]

# %%
img_16[0]

# %%
kernal_16[0]

# %%
matrix_idx[0]

# %%
matrix_size

# %% [markdown]
# ## Convolution

# %%
img = img_16[13]
kernal = kernal_16[9]

convoluted_results = np.zeros((matrix_size-4,matrix_size-4))
for i in range(matrix_size-4):
    for j in range(matrix_size-4):
        conv = 0
        for k in range(5):
            for l in range(5):
                conv += kernal[k,l] * img[i+k,j+l]

        convoluted_results[i,j] = conv

# %%
convoluted_results

# %% [markdown]
# ## Maxpooling

# %%
convoluted_img_width = len(convoluted_results)

# %%
max_pooling_results = np.zeros((convoluted_img_width//2,convoluted_img_width//2))

for i in range(0,convoluted_img_width,2):
    for j in range(0,convoluted_img_width,2):
        max_pooling_results[i//2,j//2] = max(convoluted_results[i,j],convoluted_results[i+1,j],\
                                                convoluted_results[i+1,j+1],convoluted_results[i,j+1])

# %%
max_pooling_results

# %% [markdown]
# ### Merged Convolution and max pooling

# %%
img_16[0]

# %%
kernal_16[0]

# %%
img = img_16[0]
kernal = kernal_16[0]

# %%
max_pooling_results = np.zeros((convoluted_img_width//2,convoluted_img_width//2))
for img_yptr in range(0,matrix_size-4,2):
    for img_xptr in range(0,matrix_size-4,2):
        # print(img_yptr)

        temp_max = -999999
        # 4 times convolution to quickly get values needed for max pooling
        for mp_window_y in range(2):
            for mp_window_x in range(2):
                conv = 0
                idx_x = img_xptr+mp_window_x
                idx_y = img_yptr+mp_window_y
                for k_yptr in range(5):

                    temp = 0
                    # Uses High level modeling for fast MAC, img_x_cord[x] and kernal_x_cord[x]
                    for k_xptr in range(5): # Unrolling the x_ptr
                        conv += kernal[k_yptr,k_xptr] * img[idx_y+k_yptr,idx_x+k_xptr]
                        temp += kernal[k_yptr,k_xptr] * img[idx_y+k_yptr,idx_x+k_xptr]

                    # print(temp)
                    print(conv)

                if (mp_window_y == 0 and mp_window_x == 0) or conv > temp_max:
                    temp_max = conv

        max_pooling_results[img_yptr//2,img_xptr//2] = temp_max

# %%
max_pooling_results

# %%
max_pooling_results = np.zeros((convoluted_img_width//2,convoluted_img_width//2))
for img_yptr in range(0,matrix_size-4,2):
    for img_xptr in range(0,matrix_size-4,2):
        temp_max = -999999
        # 4 times convolution to quickly get values needed for max pooling
        for mp_window_y in range(2):
            for mp_window_x in range(2):
                conv = 0
                idx_y = img_yptr+mp_window_y
                idx_x = img_xptr+mp_window_x
                for k_yptr in range(5):
                    conv += kernal[k_yptr,0] * img[idx_y+k_yptr,idx_x+0]
                    conv += kernal[k_yptr,1] * img[idx_y+k_yptr,idx_x+1]
                    conv += kernal[k_yptr,2] * img[idx_y+k_yptr,idx_x+2]
                    conv += kernal[k_yptr,3] * img[idx_y+k_yptr,idx_x+3]
                    conv += kernal[k_yptr,4] * img[idx_y+k_yptr,idx_x+4]

                if (mp_window_y == 0 and mp_window_x == 0) or conv > temp_max:
                    temp_max = conv

        max_pooling_results[img_yptr//2,img_xptr//2] = temp_max

# %%
max_pooling_results

# %% [markdown]
# ### Transposed convolution

# %%
trans_convoluted_results = np.zeros((matrix_size+4,matrix_size+4))
for i in range(matrix_size):
    for j in range(matrix_size):
        for k in range(5):
            for l in range(5):
                conv = kernal[k,l] * img[i,j]
                trans_convoluted_results[i+k,j+l] += conv

# %%
trans_convoluted_results

# %% [markdown]
# ## Transpoed convolution with zero-padding

# %%
img = img_16[0]

# %%
img

# %%
kernal = kernal_16[0]

# %%
kernal

# %%
new_trans_convoluted_results = np.zeros((matrix_size+4,matrix_size+4))
# Note the matrix is flipped
lower_bound0 = matrix_size + 4
lower_bound1 = matrix_size + 5
lower_bound2 = matrix_size + 6
lower_bound3 = matrix_size + 7

for img_ytr in range(matrix_size+4):
    for img_xptr in range(matrix_size+4):
        conv = 0
        for k_yptr in range(5):
            # Uses High level always@* , need idx_x[x]
            for k_xptr in range(5):
                idx_y = img_ytr + k_yptr
                idx_x = img_xptr + k_xptr
                if idx_y == 0 or idx_y == 1 or idx_y == 2 or idx_y == 3 or idx_x == 0 or idx_x == 1 \
                    or idx_x == 2 or idx_x == 3:
                        conv += 0
                elif idx_y == lower_bound0 or idx_y == lower_bound1 or idx_y == lower_bound2 or idx_y == lower_bound3 \
                    or idx_x == lower_bound0 or idx_x == lower_bound1 or idx_x == lower_bound2 or idx_x == lower_bound3 :
                        conv += 0
                else:
                   # Address translation
                   conv += kernal[4-k_yptr,4-k_xptr] * img[idx_y-4,idx_x-4]

        new_trans_convoluted_results[img_ytr,img_xptr] = conv


# %%
kernal

# %%
rotateMatrix(kernal)

# %%
new_trans_convoluted_results

# %%
np.array_equal(new_trans_convoluted_results,trans_convoluted_results)

# %%
new_trans_convoluted_results = np.zeros((matrix_size+4,matrix_size+4))
lower_bound0 = matrix_size + 4
lower_bound1 = matrix_size + 5
lower_bound2 = matrix_size + 6
lower_bound3 = matrix_size + 7

for img_ytr in range(matrix_size+4):
    for img_xptr in range(matrix_size+4):
        conv = 0
        if(img_yptr ==2 and img_xptr == 0): print("DEBUG")
        for k_yptr in range(5):
            # for k_xptr in range(5):
                idx_y = img_ytr + k_yptr
                idx_x_0 = img_xptr + 0
                idx_x_1 = img_xptr + 1
                idx_x_2 = img_xptr + 2
                idx_x_3 = img_xptr + 3
                idx_x_4 = img_xptr + 4
                # 0
                if idx_y == 0 or idx_y == 1 or idx_y == 2 or \
                    idx_y == 3 or idx_x_0 == 0 or idx_x_0 == 1 \
                    or idx_x_0 == 2 or idx_x_0 == 3:
                        conv += 0
                elif idx_y == lower_bound0 or idx_y == lower_bound1 or idx_y == lower_bound2 or idx_y == lower_bound3 \
                    or idx_x_0 == lower_bound0 or idx_x_0 == lower_bound1 or idx_x_0 == lower_bound2 or idx_x_0 == lower_bound3 :
                        conv += 0
                else:
                   conv += kernal[4-k_yptr,4] * img[idx_y-4,idx_x_0-4]
                # 1
                if idx_y == 0 or idx_y == 1 or idx_y == 2 or \
                    idx_y == 3 or idx_x_1 == 0 or idx_x_1 == 1 \
                    or idx_x_1 == 2 or idx_x_1 == 3:
                        conv += 0
                elif idx_y == lower_bound0 or idx_y == lower_bound1 or idx_y == lower_bound2 or idx_y == lower_bound3 \
                    or idx_x_1 == lower_bound0 or idx_x_1 == lower_bound1 or idx_x_1 == lower_bound2 or idx_x_1 == lower_bound3 :
                        conv += 0
                else:
                   conv += kernal[4-k_yptr,3] * img[idx_y-4,idx_x_1-4]
                # 2
                if idx_y == 0 or idx_y == 1 or idx_y == 2 or \
                    idx_y == 3 or idx_x_2 == 0 or idx_x_2 == 1 \
                    or idx_x_2 == 2 or idx_x_2 == 3:
                        conv += 0
                elif idx_y == lower_bound0 or idx_y == lower_bound1 or idx_y == lower_bound2 or idx_y == lower_bound3 \
                    or idx_x_2 == lower_bound0 or idx_x_2 == lower_bound1 or idx_x_2 == lower_bound2 or idx_x_2 == lower_bound3 :
                        conv += 0
                else:
                   conv += kernal[4-k_yptr,2] * img[idx_y-4,idx_x_2-4]
                # 3
                if idx_y == 0 or idx_y == 1 or idx_y == 2 or \
                    idx_y == 3 or idx_x_3 == 0 or idx_x_3 == 1 \
                    or idx_x_3 == 2 or idx_x_3 == 3:
                        conv += 0
                elif idx_y == lower_bound0 or idx_y == lower_bound1 or idx_y == lower_bound2 or idx_y == lower_bound3 \
                    or idx_x_3 == lower_bound0 or idx_x_3 == lower_bound1 or idx_x_3 == lower_bound2 or idx_x_3 == lower_bound3 :
                        conv += 0
                else:
                   conv += kernal[4-k_yptr,1] * img[idx_y-4,idx_x_3-4]

                # 4
                if idx_y == 0 or idx_y == 1 or idx_y == 2 or \
                    idx_y == 3 or idx_x_4 == 0 or idx_x_4 == 1 \
                    or idx_x_4 == 2 or idx_x_4 == 3:
                        conv += 0
                elif idx_y == lower_bound0 or idx_y == lower_bound1 or idx_y == lower_bound2 or idx_y == lower_bound3 \
                    or idx_x_4 == lower_bound0 or idx_x_4 == lower_bound1 or idx_x_4 == lower_bound2 or idx_x_4 == lower_bound3 :
                        conv += 0
                else:
                   conv += kernal[4-k_yptr,0] * img[idx_y-4,idx_x_4-4]

        new_trans_convoluted_results[img_ytr,img_xptr] = conv


# %%
new_trans_convoluted_results

# %% [markdown]
# #### Convert results to LSB binary representation

# %%
twocomplement(57,20)

# %%
vf = np.vectorize(twocomplement)
bits_result = vf(trans_convoluted_results,20)

# %%
bits_result[0][0]

# %%
result = bits_result[0][0]

# %%
result = result[::-1]

# %%
result
