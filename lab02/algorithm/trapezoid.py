# -*- coding: utf-8 -*-
"""
Created on Wed Sep 27 16:12:57 2023

@author: Jyunwei
"""
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

def div(dx, dy): # dy > 0 in all case
  if (dx >= 0):
    return dx // dy
  else:
    return -((-dx) // dy)

data_in  = [hex2xy(line) for line in file_in]
data_out = [hex2xy(line) for line in file_out]

my_out = []
for i in range(len(data_in) // 4):
  (xul, yu) = data_in[4 * i + 0] # x0 y0
  (xur, yu) = data_in[4 * i + 1] # x1 y1
  (xdl, yd) = data_in[4 * i + 2] # x2 y2
  (xdr, yd) = data_in[4 * i + 3] # x3 y3

  dxl = None
  dxr = None
  dyy = None
  ofl = None
  ofr = None

  if xul > xdl: # posedge
    dxl = xul - xdl
    ofl = 1
  else:
    dxl = xdl - xul
    ofl = -1
  if xur > xdr:
    dxr = xur - xdr
    ofr = 1
  else:
    dxr = xdr - xur
    ofr = -1
  dyy = (yu - yd)

  tralx = xdr
  currx = xdl
  curry = yd

  # slope of line
  #ml = (xul - xdl) / (yu - yd)
  #mr = (xur - xdr) / (yu - yd)

  while(currx <= tralx):
    my_out.append((currx, curry))
    if(currx == tralx): #terminal
      if ofl == 1:
        currx = xdl + div((curry + 1 - yd) * dxl, dyy)
      else:
        currx = xul + div((yu - (curry + 1)) * dxl, dyy)
      if ofr == 1:
        tralx = xdr + div((curry + 1 - yd) * dxr, dyy)
      else:
        tralx = xur + div((yu - (curry + 1)) * dxr, dyy)
        #print(div((yu - (curry + 1)) * dxr, dyy))
      #input()
      curry += 1
      #currx = xdl + (curry - yd) * dxl // dyy
      #tralx = xdr + (curry - yd) * dxr // dyy
    else: # in same line
      currx += 1
    if(curry > yu):
      #print("break")
      break
    #print(f"{yu} {curry} {dxr} {dyy}")
    #input()


print("=====check=====")
if(len(my_out) == len(data_out)):
  length = len(my_out)
  print(length)
  for i in range(length):
    if(my_out[i] != data_out[i]):
      print(f"FAIL at {i}")
else:
  print("Fail (total length of out)")