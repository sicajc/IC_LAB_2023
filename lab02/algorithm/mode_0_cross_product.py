# -*- coding: utf-8 -*-
from math import floor

file_in = None
file_out = None

with open('lab02/input.txt', 'r') as file:
  file_in = file.readlines()

with open('lab02/ans.txt', 'r') as file:
  file_out = file.readlines()

def hex2xy(data):
  x = int(data[0:2], 16)
  y = int(data[2:4], 16)
  if x > 127:
    x -= 256
  if y > 127:
    y -= 256

  return (x, y)

data_in  = [hex2xy(line) for line in file_in]
data_out = [hex2xy(line) for line in file_out]

# print(data_in)
print("==============================================")
print(f"data out = {data_out[:162]}")
test1 = data_out[:162]
print("==============================================")

def vertex_in_q(v,xul,yu,xur,xdr,yd,xdl):
  # 0 means not in Q, 1 means on edge, 2 means in Q
  val0 = cross_product((xdl-v[0],yd-v[1]),(xdr - xdl,0))
  val1 = cross_product((xdr-v[0],yd-v[1]),(xur-xdr,yu-yd))
  val2 = cross_product((xur-v[0],yu-v[1]),(xul-xur,0))
  val3 = cross_product(((xul-v[0]),(yu-v[1])),(xdl-xul,yd-yu))

  if val0 > 0:
    sign0 = 0
  elif val0 < 0:
    sign0 = 1
  else:
    sign0 = -1

  if val1 > 0:
    sign1 = 0
  elif val1 < 0:
    sign1 = 1
  else:
    sign1 = -1

  if val2 > 0:
    sign2 = 0
  elif val2 < 0:
    sign2 = 1
  else:
    sign2 = -1

  if val3 > 0:
    sign3 = 0
  elif val3 < 0:
    sign3 = 1
  else:
    sign3 = -1

  if (sign0 == 0 and sign1 == 0 and sign2 == 0 and sign3 == 0):
    return 'in Q'
  elif(sign0 == 1 and sign1 == 1 and sign2 == 1 and sign3 == 1):
    return 'in Q'
  else:
    if val0 == 0 or val1 == 0 or val2 == 0 or val3 == 0:
      return 'on edge'

  return 'not in Q'

def cross_product(v0,v1):
    value = 0
    value = v0[0] * v1[1] - v0[1] * v1[0]

    return value

# Caching
# Determine the boundary of each y using slope

my_out = []
for i in range(len(data_in) // 4):
  output_length = 0
  # Read in the vertices of quadrilateral
  (xdl, yd) = data_in[4 * i + 2] #1
  (xdr, yd) = data_in[4 * i + 3] #2
  (xur, yu) = data_in[4 * i + 1] #3
  (xul, yu) = data_in[4 * i + 0] #4

  # Compute the slope
  ml_upper = yu  - yd
  ml_lower = xul - xdl

  mr_upper = ml_upper
  mr_lower = xur - xdr

  # Write your function here
  # Corner case of on the line is annoying
  for y in range(yd, yu + 1):
    for x in range(min(xul, xdl), max(xur, xdr) + 1):
      lower_left  = (x,y)
      lower_right = (x+1,y)
      upper_right = (x+1,y+1)
      upper_left  = (x,y+1)

      if y == yu:
        if (x>=xul) and (x<=xur):
          my_out.append((x,y))
      elif y == yd:
        if (x>=xdl) and (x<=xdr):
          my_out.append((x,y))
      else:
        lower_left_in_edge  = vertex_in_q(lower_left ,xul,yu,xur,xdr,yd,xdl)

        if lower_left_in_edge == 'on edge' or lower_left_in_edge == 'in Q':
          my_out.append((x,y))
        else :
          lower_right_in_edge = vertex_in_q(lower_right,xul,yu,xur,xdr,yd,xdl)
          if lower_right_in_edge == 'in Q':
            my_out.append((x,y))


if(len(my_out) == len(data_out)):
  length = len(my_out)
  print(length)
  for i in range(length):
    if(my_out[i] != data_out[i]):
      print(f"FAIL at {i}")
else:
  print("Fail (total length of out)")

print(data_in[:16])

flag = 0
cnt = 0
for i in range(len(my_out)):
  if my_out[i] != data_out[i]:
    flag = 1
    cnt += 1

    print(f"fail at {i}, expected {data_out[i]}, yet get {my_out[i]}")

  if cnt == 20:
    break


if flag == 1:
  print("FAIL")
else:
  print("SUCCESS")