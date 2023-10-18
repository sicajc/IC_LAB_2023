# -*- coding: utf-8 -*-
"""
Created on Wed Oct 11 15:50:13 2023

@author: Jyunwei
"""
import random
import struct


'''
Opt [0, 1, 2, 3]{1}
Img1_1 [+/- 0.5-255.0]{16}
Img1_2 [+/- 0.5-255.0]{16}
Img1_3 [+/- 0.5-255.0]{16}
Img2_1 [+/- 0.5-255.0]{16}
Img2_2 [+/- 0.5-255.0]{16}
Img2_3 [+/- 0.5-255.0]{16}
Kernal1 [+/- 0.0-0.5]{9}
Kernal2 [+/- 0.0-0.5]{9}
Kernal3 [+/- 0.0-0.5]{9}
Weight [+/- 0.0-0.5]{4}
'''


def fp2hex(float_number):
    hex_value = struct.unpack('<I', struct.pack('<f', float_number))[0]
    return format(hex_value, 'x')

def hex2fp(hex_value):
  fp_value = struct.unpack('<f',struct.pack('<I',int(hex_value,16)))[0]
  return fp_value

#float_number = random.uniform(-255, 255.0)
#hex_value = fp2hex(float_number)
#fp_value  = hex2fp(hex_value)

NUM = 50
img11 = []
img12 = []
img13 = []
img21 = []
img22 = []
img23 = []
ker1 = []
ker2 = []
ker3 = []
weight = []

with open('input.txt', 'w') as f:
  f.write(f"{NUM}\n")
  for i in range(NUM):
    opt = random.randint(0, 3)
    f.write(f"{opt}\n")
    # img11
    for k in range(16):
      tmp = random.uniform(0.5, 255.0) * random.choice([1, -1])
      tmh = fp2hex(tmp)
      tmf = hex2fp(tmh)
      img11.append(tmf)
      f.write(f"{tmh} ")
    f.write("\n")
    # img12
    for k in range(16):
      tmp = random.uniform(0.5, 255.0) * random.choice([1, -1])
      tmh = fp2hex(tmp)
      tmf = hex2fp(tmh)
      img12.append(tmf)
      f.write(f"{tmh} ")
    f.write("\n")
    # img13
    for k in range(16):
      tmp = random.uniform(0.5, 255.0) * random.choice([1, -1])
      tmh = fp2hex(tmp)
      tmf = hex2fp(tmh)
      img13.append(tmf)
      f.write(f"{tmh} ")
    f.write("\n")
    # img21
    for k in range(16):
      tmp = random.uniform(0.5, 255.0) * random.choice([1, -1])
      tmh = fp2hex(tmp)
      tmf = hex2fp(tmh)
      img21.append(tmf)
      f.write(f"{tmh} ")
    f.write("\n")
    # img22
    for k in range(16):
      tmp = random.uniform(0.5, 255.0) * random.choice([1, -1])
      tmh = fp2hex(tmp)
      tmf = hex2fp(tmh)
      img22.append(tmf)
      f.write(f"{tmh} ")
    f.write("\n")
    # img23
    for k in range(16):
      tmp = random.uniform(0.5, 255.0) * random.choice([1, -1])
      tmh = fp2hex(tmp)
      tmf = hex2fp(tmh)
      img23.append(tmf)
      f.write(f"{tmh} ")
    f.write("\n")

    # ker1
    for k in range(9):
      tmp = random.uniform(0, 0.5) * random.choice([1, -1])
      tmh = fp2hex(tmp)
      tmf = hex2fp(tmh)
      ker1.append(tmf)
      f.write(f"{tmh} ")
    f.write("\n")
    # ker2
    for k in range(9):
      tmp = random.uniform(0, 0.5) * random.choice([1, -1])
      tmh = fp2hex(tmp)
      tmf = hex2fp(tmh)
      ker2.append(tmf)
      f.write(f"{tmh} ")
    f.write("\n")
    # ker3
    for k in range(9):
      tmp = random.uniform(0, 0.5) * random.choice([1, -1])
      tmh = fp2hex(tmp)
      tmf = hex2fp(tmh)
      ker3.append(tmf)
      f.write(f"{tmh} ")
    f.write("\n")

    # weight
    for k in range(4):
      tmp = random.uniform(0, 0.5) * random.choice([1, -1])
      tmh = fp2hex(tmp)
      tmf = hex2fp(tmh)
      weight.append(tmf)
      f.write(f"{tmh} ")
    f.write("\n")
