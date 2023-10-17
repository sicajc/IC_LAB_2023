# -*- coding: utf-8 -*-
"""
Created on Wed Sep 27 16:12:57 2023

@author: Jyunwei
"""
from math import floor

file_in = None
file_out = None

with open('C:\Users\HIBIKI\Desktop\IC_LAB_FALL_2023\lab02\input.txt', 'r') as file:
  file_in = file.readlines()

with open('C:\Users\HIBIKI\Desktop\IC_LAB_FALL_2023\lab02\ans.txt', 'r') as file:
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