# -*- coding: utf-8 -*-
"""
Created on Thu Oct 12 12:34:01 2023

@author: Jyunwei
"""
import struct
import numpy as np

def fp2hex(float_number):
    hex_value = struct.unpack('<I', struct.pack('<f', float_number))[0]
    return format(hex_value, 'x')

def hex2fp(hex_value):
  fp_value = struct.unpack('<f',struct.pack('<I',int(hex_value,16)))[0]
  return fp_value

def fc(pool, weight):
  pool = pool.reshape((2,2))
  weight = weight.reshape((2,2))
  fc_result = np.zeros((4,1), dtype='float32')

  for i in range(2):
      for j in range(2):
          partial_mult = np.float32(0) #TODO
          for k in range(2):
              partial_mult += pool[i,k] * weight[k,j]
          fc_result[i*2+j] = partial_mult

  fc_result.reshape((4,))
  return fc_result

def conv(opt_0, img, ker):
  pad = np.random.rand(6, 6).astype(np.float32)
  if(opt_0 == 0): # repeat
    pad[0][0] = img[0]
    pad[0][1] = img[0]
    pad[0][2] = img[1]
    pad[0][3] = img[2]
    pad[0][4] = img[3]
    pad[0][5] = img[3]

    pad[1][0] = img[0]
    pad[1][1] = img[0]
    pad[1][2] = img[1]
    pad[1][3] = img[2]
    pad[1][4] = img[3]
    pad[1][5] = img[3]

    pad[2][0] = img[4]
    pad[2][1] = img[4]
    pad[2][2] = img[5]
    pad[2][3] = img[6]
    pad[2][4] = img[7]
    pad[2][5] = img[7]

    pad[3][0] = img[8]
    pad[3][1] = img[8]
    pad[3][2] = img[9]
    pad[3][3] = img[10]
    pad[3][4] = img[11]
    pad[3][5] = img[11]

    pad[4][0] = img[12]
    pad[4][1] = img[12]
    pad[4][2] = img[13]
    pad[4][3] = img[14]
    pad[4][4] = img[15]
    pad[4][5] = img[15]

    pad[5][0] = img[12]
    pad[5][1] = img[12]
    pad[5][2] = img[13]
    pad[5][3] = img[14]
    pad[5][4] = img[15]
    pad[5][5] = img[15]
  else: # zero
    pad[0][0] = 0
    pad[0][1] = 0
    pad[0][2] = 0
    pad[0][3] = 0
    pad[0][4] = 0
    pad[0][5] = 0

    pad[1][0] = 0
    pad[1][1] = img[0]
    pad[1][2] = img[1]
    pad[1][3] = img[2]
    pad[1][4] = img[3]
    pad[1][5] = 0

    pad[2][0] = 0
    pad[2][1] = img[4]
    pad[2][2] = img[5]
    pad[2][3] = img[6]
    pad[2][4] = img[7]
    pad[2][5] = 0

    pad[3][0] = 0
    pad[3][1] = img[8]
    pad[3][2] = img[9]
    pad[3][3] = img[10]
    pad[3][4] = img[11]
    pad[3][5] = 0

    pad[4][0] = 0
    pad[4][1] = img[12]
    pad[4][2] = img[13]
    pad[4][3] = img[14]
    pad[4][4] = img[15]
    pad[4][5] = 0

    pad[5][0] = 0
    pad[5][1] = 0
    pad[5][2] = 0
    pad[5][3] = 0
    pad[5][4] = 0
    pad[5][5] = 0

  rslt = np.random.rand(16).astype(np.float32)
  for i in range(4):
    for j in range(4):
      tmp1 = ker[0] * pad[ i ][j] + ker[1] * pad[ i ][j+1] + ker[2] * pad[ i ][j+2]
      tmp2 = ker[3] * pad[i+1][j] + ker[4] * pad[i+1][j+1] + ker[5] * pad[i+1][j+2]
      tmp3 = ker[6] * pad[i+2][j] + ker[7] * pad[i+2][j+1] + ker[8] * pad[i+2][j+2]
      rslt[i * 4 + j] = tmp1 + tmp2 + tmp3

  return rslt

file_in = None

with open('input.txt', 'r') as file:
  file_in = file.readlines()

NUM = int(file_in[0])


for i in range(NUM):
  opt    = int(file_in[1 + 11 * i + 0])
  img11  = np.array([hex2fp(val) for val in file_in[1 + 11 * i + 1].split()], dtype=np.float32)
  img12  = np.array([hex2fp(val) for val in file_in[1 + 11 * i + 2].split()], dtype=np.float32)
  img13  = np.array([hex2fp(val) for val in file_in[1 + 11 * i + 3].split()], dtype=np.float32)
  img21  = np.array([hex2fp(val) for val in file_in[1 + 11 * i + 4].split()], dtype=np.float32)
  img22  = np.array([hex2fp(val) for val in file_in[1 + 11 * i + 5].split()], dtype=np.float32)
  img23  = np.array([hex2fp(val) for val in file_in[1 + 11 * i + 6].split()], dtype=np.float32)
  ker1   = np.array([hex2fp(val) for val in file_in[1 + 11 * i + 7].split()], dtype=np.float32)
  ker2   = np.array([hex2fp(val) for val in file_in[1 + 11 * i + 8].split()], dtype=np.float32)
  ker3   = np.array([hex2fp(val) for val in file_in[1 + 11 * i + 9].split()], dtype=np.float32)
  weight = np.array([hex2fp(val) for val in file_in[1 + 11 * i + 10].split()], dtype=np.float32)

  # OPT
  # 0   sigmoid replication
  # 1   sigmoid zero
  # 2   tanh    replication
  # 3   tan     zero

  conv11 = conv(opt%2, img11, ker1)
  conv12 = conv(opt%2, img12, ker2)
  conv13 = conv(opt%2, img13, ker3)
  conv21 = conv(opt%2, img21, ker1)
  conv22 = conv(opt%2, img22, ker2)
  conv23 = conv(opt%2, img23, ker3)

  fmap1 = conv11 + conv12 + conv13
  fmap2 = conv21 + conv22 + conv23

  pool1 = np.array(
          [max(fmap1[0],  fmap1[1],  fmap1[4],  fmap1[5] ),
           max(fmap1[2],  fmap1[3],  fmap1[6],  fmap1[7] ),
           max(fmap1[8],  fmap1[9],  fmap1[12], fmap1[13]),
           max(fmap1[10], fmap1[11], fmap1[14], fmap1[15])], dtype=np.float32)
  pool2 = np.array(
          [max(fmap2[0],  fmap2[1],  fmap2[4],  fmap2[5] ),
           max(fmap2[2],  fmap2[3],  fmap2[6],  fmap2[7] ),
           max(fmap2[8],  fmap2[9],  fmap2[12], fmap2[13]),
           max(fmap2[10], fmap2[11], fmap2[14], fmap2[15])], dtype=np.float32)

  # There is a unknown bug when doing matmul using numpy
  fc1 = fc(pool1, weight)
  fc2 = fc(pool2, weight)

  norm1 = (fc1 - min(fc1))/(max(fc1) - min(fc1))
  norm2 = (fc2 - min(fc2))/(max(fc2) - min(fc2))

  if(opt // 2) == 0: # sigmoid
    vect1 = 1 / (1 + np.exp(-norm1))
    vect2 = 1 / (1 + np.exp(-norm2))
  else: # tanh
    vect1 = (np.exp(norm1) - np.exp(-norm1)) / (np.exp(norm1) + np.exp(-norm1))
    vect2 = (np.exp(norm2) - np.exp(-norm2)) / (np.exp(norm2) + np.exp(-norm2))

  diff = np.abs(vect1 - vect2)
  out = np.sum(diff)

  print(f"{fp2hex(out)} {out:.5f}")
