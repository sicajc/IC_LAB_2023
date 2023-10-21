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

def conv(img,kernal,matrix_size):
  convoluted_results = np.zeros((matrix_size-4,matrix_size-4))
  for i in range(matrix_size-4):
      for j in range(matrix_size-4):
          conv = 0
          for k in range(5):
              for l in range(5):
                  conv += kernal[k,l] * img[i+k,j+l]
          convoluted_results[i,j] = conv

  return convoluted_results

def max_pooling(convoluted_results):
   convoluted_img_width = len(convoluted_results)
   max_pooling_results = np.zeros((convoluted_img_width//2,convoluted_img_width//2))
   for i in range(0,convoluted_img_width,2):
       for j in range(0,convoluted_img_width,2):
           max_pooling_results[i//2,j//2] = max(convoluted_results[i,j],convoluted_results[i+1,j],\
                                                   convoluted_results[i+1,j+1],convoluted_results[i,j+1])

   return max_pooling_results

def trans_conv(img,kernal,matrix_size):
  trans_convoluted_results = np.zeros((matrix_size+4,matrix_size+4))
  for i in range(matrix_size):
      for j in range(matrix_size):
          for k in range(5):
              for l in range(5):
                  conv = kernal[k,l] * img[i,j]
                  trans_convoluted_results[i+k,j+l] += conv

  return trans_convoluted_results

def int2hex(num,bit_width):
    if num<0:
        num = (1 << bit_width) + num
    hex_string = hex(num)[2:]
    return '{:0>{width}}'.format(hex_string,width = (bit_width+3)//4)

def reverse_str(bits):
    return str(bits)[::-1]

def bin2hex(bin):
   return hex(int(bin,2))

vf_two_comp = np.vectorize(twocomplement)
vf_reverse = np.vectorize(reverse_str)
vf_bin2hex = np.vectorize(bin2hex)

with open('lab05/input.txt', 'r') as file1:
  file_in = file1.readlines()

with open('lab05/output.txt', 'w') as file:
  NUM = int(file_in[0])

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
      img_in = (np.array([int(toDec(val,8)) for val in file_in[1 + 65 * i + (1+j)].split()]))
      img_16.append(np.reshape(img_in,(matrix_size,matrix_size)))

    for k in range(16):
      kernal_in = np.array([int(toDec(val,8)) for val in file_in[1 + 65 * i + (17+k)].split()])
      kernal_16.append(np.reshape(kernal_in,(5,5)))

    # Start processing
    for idx in range(16):
      mode.append(int(file_in[1 + 65 * i +(33+idx*2)])) #0 2 4
      matrix_idx.append(np.array([int(val) for val in file_in[1 + 65 * i + (34+idx*2)].split()]))# 1 3 5


      # print("Mode index",mode)
      if mode[idx] == 0:
        conv_result = conv(img_16[matrix_idx[idx][0]],kernal_16[matrix_idx[idx][1]],matrix_size)
        result = max_pooling(conv_result)
      else:
        result = trans_conv(img_16[matrix_idx[idx][0]],kernal_16[matrix_idx[idx][1]],matrix_size)

      result = np.array(result,dtype='int32')

      # Turn all value into bits representation, reverse them then convert into hex
      # print(result[0][0],result[0][1],result[1][0],result[1][1])
      two_comp_bit_result = vf_two_comp(result,20)

      hex_result = vf_bin2hex(two_comp_bit_result)

      file.write(f"{result.size}\n")
      for value in np.nditer(hex_result):
         file.write(f"{str(value)[2:]} ")

      file.write("\n")
