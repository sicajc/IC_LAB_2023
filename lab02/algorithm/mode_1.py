file_in = None
file_out = None

with open('lab02/coordinate_in.txt', 'r') as file:
    file_in = file.readlines()

with open('lab02/coordinate_out.txt', 'r') as file:
    file_out = file.readlines()


data_in = [line for line in file_in]
data_out = [line for line in file_out]

out = []
for i in range(len(data_in) // 8):
    a1 = int(data_in[8 * i + 0])
    a2 = int(data_in[8 * i + 1])
    b1 = int(data_in[8 * i + 2])
    b2 = int(data_in[8 * i + 3])
    c1 = int(data_in[8 * i + 4])
    c2 = int(data_in[8 * i + 5])
    d1 = int(data_in[8 * i + 6])
    d2 = int(data_in[8 * i + 7])

    if i == 6:
        print("Debug")

    a = a2-b2
    b = b1-a1
    f = c1-a1
    g = a2-c2

    c = a*f - b*g

    d_square = c*c

    d = d1-c1
    e = d2-c2
    r_square = d*d + e*e

    h = a*a + b*b

    r_square_determine = r_square * (a*a + b*b)

    d_square = (((a2-b2)*(c1-a1)) - ((b1-a1)*(a2-c2)))*(((a2-b2)* (c1-a1)) - ((b1-a1) * (a2-c2)))
    r_right  = (((a2-b2)*(a2-b2)) - ((a1-b1)*(b1-a1)))*((d1-c1) * (d1-c1)) - ((c2-d2) * (d2-c2))

    if d_square > r_square_determine:
        out.append(0)
    elif d_square < r_square_determine:
        out.append(1)
    else:
        out.append(2)
    # if i == 1 or 2 or 3:
    #     print("DEBUG")

    # left = (((b2-a2)**2 + (b1-a1)**2)*((c1-b1)**2 + (c2 - b2)**2))
    # right = (((b2-a2)*c1 - (b1-a1)*c2)**2)

    # if left > right:
    #     out.append(0)
    # elif left < right:
    #     out.append(1)
    # else:
    #     out.append(2)


mode0 = 17
mode1 = 4
mode2 = 3
print(f"{119*mode1 + 99*mode2+mode0}")

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
        print(f"{i} th value error, expect {data_out[i]}, but get {out[i]}")
        flag = 1
        break


if flag == 1:
    print("Error!")
else:
    print("Success!")
