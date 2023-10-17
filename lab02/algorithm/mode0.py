# -*- coding: utf-8 -*-
from math import floor

file_in = None
file_out = None

with open('C:/Users/HIBIKI/Desktop/IC_LAB_FALL_2023/lab02/input.txt', 'r') as file:
  file_in = file.readlines()

with open('C:/Users/HIBIKI/Desktop/IC_LAB_FALL_2023/lab02/ans.txt', 'r') as file:
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

print((-4)//(-3))

my_out = []
for i in range(len(data_in) // 4):
  # Read in the vertices of quadrilateral
  (xul, yu) = data_in[4 * i + 0]
  (xur, yu) = data_in[4 * i + 1]
  (xdl, yd) = data_in[4 * i + 2]
  (xdr, yd) = data_in[4 * i + 3]

  # slope of line, main function
  for y in range(yd, yu + 1):
    xl = xdl + floor(((y - yd) * (xul - xdl)) / (yu - yd))
    xr = xdr + floor(((y - yd) * (xur - xdr)) / (yu - yd))

    for x in range(min(xul, xdl), max(xur, xdr) + 1):
      if (xl - 1) < x and x <= (xr):
        # print((x,y))
        my_out.append((x, y))

if(len(my_out) == len(data_out)):
  length = len(my_out)
  print(length)
  for i in range(length):
    if(my_out[i] != data_out[i]):
      print(f"FAIL at {i}")
else:
  print("Fail (total length of out)")