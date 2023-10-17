from math import floor
import copy
file_in = None
file_out = None

with open('lab02/area_in_v2.txt', 'r') as file:
  file_in = file.readlines()

with open('lab02/area_out_v2.txt', 'r') as file:
  file_out = file.readlines()


data_in  = [line for line in file_in]
data_out = [line for line in file_out]

out = []

def cross_product(v0,v1):
    value = 0
    value = v0[0] * v1[1] - v0[1] * v1[0]

    return value

area_list = []
area_not_floor = []
<<<<<<< HEAD:lab02/mode_2.py

=======
cnt = 0
>>>>>>> ec8ed58bfe623d8fa9413089c164aecfd50e9dad:lab02/algorithm/mode_2.py
for i in range(len(data_in) // 8):
    cnt += 1
    a1 = int(data_in[8 * i + 0])
    a2 = int(data_in[8 * i + 1])
    b1 = int(data_in[8 * i + 2])
    b2 = int(data_in[8 * i + 3])
    c1 = int(data_in[8 * i + 4])
    c2 = int(data_in[8 * i + 5])
    d1 = int(data_in[8 * i + 6])
    d2 = int(data_in[8 * i + 7])

    # Pick a pivot, then shift all points according to this pivot point
    # Take a1,a2 as pivot
    e1 = b1-a1
    e2 = b2-a2

    f1 = c1-a1
    f2 = c2-a2

    g1 = d1-a1
    g2 = d2-a2

    cross_e_f = e1 * f2 - e2 * f1

    cross_f_g = f1 * g2 - f2 * g1

    area = 1/2 * abs(cross_e_f + cross_f_g)

    area = floor(area)

    area_list.append(area)

    out.append(area)

flag = 0
for i in range(len(data_out)):
    if int(data_out[i]) != out[i]:
        print("===============Inputs============")
        print(f" a1 = {int(data_in[8 * i + 0])}")
        print(f" a2 = {int(data_in[8 * i + 1])}")
        print(f" b1 = {int(data_in[8 * i + 2])}")
        print(f" b2 = {int(data_in[8 * i + 3])}")
        print(f" c1 = {int(data_in[8 * i + 4])}")
        print(f" c2 = {int(data_in[8 * i + 5])}")
        print(f" d1 = {int(data_in[8 * i + 6])}")
        print(f" d2 = {int(data_in[8 * i + 7])}")
        print(f"Area with floor = {area_list[i]}")
        print(f"Area not floor = {area_not_floor[i]}")
        print(f"{i} th value error, expect {data_out[i]}, but get {out[i]}")
        flag = 1
        break

if flag == 1:
    print("Error!")
else:
    print("Success!")
