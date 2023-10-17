# -*- coding: utf-8 -*-
from math import floor,ceil

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

my_out = []

# print(f"Div of -4/3 = {-4//3}")
cnt = 0
for i in range(0,len(data_in) // 4):
  cnt += 1
  # print(f"==================Pattern {i}====================")
  # Read in the vertices of quadrilateral
  (xul, yu) = data_in[4 * i + 0]
  (xur, yu) = data_in[4 * i + 1]
  (xdl, yd) = data_in[4 * i + 2]
  (xdr, yd) = data_in[4 * i + 3]

  # slope of line, main function
  for y in range(yd, yu + 1):
    # Hold yu-yd make them always positive, choose (x0,y0) according to (xu - xd)
    # Goal is to make the division always positive
    if xul >= xdl:
      xl = xdl + floor(((y-yd) * (xul - xdl)) / (yu - yd))
    else:
      # xdl > xul thus (xdl - xul) > 0 , selects yu s.t. (yu - y) > 0
      xl = xul + floor(((yu-y) * (xdl - xul)) / (yu - yd))

    if xur >= xdr:
      xr = xdr + floor(((y - yd) * (xur - xdr)) / (yu - yd))
    else:
      # xdr > xur thus (xdr - xur) > 0, selects yu s.t. ( yu - y ) > 0
      xr = xur + floor(((yu-y) * (xdr - xur)) / (yu - yd))

    for x in range(xl, xr + 1):
      my_out.append((x, y))

flag = 0

for i in range(len(my_out)):
  if(my_out[i] != data_out[i]):
    flag = 1

if(len(my_out) == len(data_out)):
  length = len(my_out)
  print(length)
  for i in range(length):
    if(my_out[i] != data_out[i]):
      print(f"FAIL at {i}")
else:
  flag = 1
  print("Fail (total length of out)")

if flag == 1:
  print("Error")
else:
  print("Success")