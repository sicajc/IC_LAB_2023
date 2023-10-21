import random
import struct

BIT_WIDTH = 8
PATTERN_NUM = 10
UPPER_BOUND = 127
LOWER_BOUND = -128
NUM_OF_MATRICES = 16

def int2hex(num,bit_width):
    if num<0:
        num = (1 << bit_width) + num
    hex_string = hex(num)[2:]
    return '{:0>{width}}'.format(hex_string,width = (bit_width+3)//4)

# result = int2hex(-128,8)
# print(result)

img_16    = []
kernal_16 = []
opts      = []

random.seed(1234)

if __name__ == '__main__':
    with open('lab05/input.txt', 'w') as f:
        f.write(f"{PATTERN_NUM}\n")
        for i in range(PATTERN_NUM):
            # Matrix size 8,16,32
            if i <= 10:
                matrix_size = 8
            else:
                matrix_size =  random.choice([8,16,32])

            if matrix_size == 8:
                f.write(f"{0}\n")
            elif matrix_size == 16:
                f.write(f"{1}\n")
            else:
                f.write(f"{2}\n")

            # 16 , size of img matrix, each with matrix_size
            for _ in range(16):
                for _ in range(matrix_size*matrix_size):
                    # Extreme cases all 127 and all -128
                    if i ==0:
                        matrix_value = random.randint(1,2)
                    elif i==1:
                        matrix_value = 1
                    elif i==2:
                        matrix_value = random.randint(0,1)
                    elif i==3:
                        matrix_value = random.randint(-1,1)
                    else:
                        matrix_value = random.randint(LOWER_BOUND,UPPER_BOUND)
                    matrix_value_hex = int2hex(matrix_value,BIT_WIDTH)
                    img_16.append(matrix_value)
                    f.write(f"{matrix_value_hex} ")
                f.write("\n")

            # 16 , kernal with size
            for _ in range(16):
                for _ in range(5*5):
                    if   i==0:
                        kernal_value = 1
                    elif i==1:
                        kernal_value = 2
                    elif i==2:
                        kernal_value = random.randint(-1,1)
                    elif i==3:
                        kernal_value = 2
                    else:
                        kernal_value = random.randint(LOWER_BOUND,UPPER_BOUND)
                    kernal_value_hex = int2hex(kernal_value,BIT_WIDTH)
                    kernal_16.append(kernal_value)
                    f.write(f"{kernal_value_hex} ")
                f.write("\n")

            # 16 ops for in_valid 2
            for k in range(16):
                # mode
                # if(k == 0):
                f.write(f"{0}\n")
                # else:
                    # f.write(f"{random.randint(0,1)}\n")
                i_matrix = random.randint(0,15)
                k_matrix = random.randint(0,15)
                f.write(f"{i_matrix} {k_matrix}")
                f.write("\n")

            # f.write("\n")
