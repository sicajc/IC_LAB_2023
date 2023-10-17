# #### 0. Create 3 kernals, 2 images with 3 channels
#
import random as rd
import numpy as np
import struct

rd.seed(1234)

LARGE_NUMBER = 99999999999999999999999999999
SMALL_NUMBER = -99999999999999999999999999999
IMG_MAX =  255.0
IMG_MIN = -255.0
NUM_OF_PATTERN = 5

KERNAL_MAX = 0.5
KERNAL_MIN = -0.5

WEIGHT_MAX = 0.5
WEIGHT_MIN = -0.5

KERNAL_SIZE = 3
IMG_SIZE    = 4

# Random inputs generators
kernal0  = np.array([[np.float32(rd.uniform(KERNAL_MIN,KERNAL_MAX)) for i in range(KERNAL_SIZE)] for j in range(KERNAL_SIZE)], dtype="float32")
kernal1  = np.array([[np.float32(rd.uniform(KERNAL_MIN,KERNAL_MAX)) for i in range(KERNAL_SIZE)] for j in range(KERNAL_SIZE)], dtype="float32")
kernal2  = np.array([[np.float32(rd.uniform(KERNAL_MIN,KERNAL_MAX)) for i in range(KERNAL_SIZE)] for j in range(KERNAL_SIZE)], dtype="float32")

img0_0    = np.array([[np.float32(rd.uniform(IMG_MIN,IMG_MAX)) for i in range(IMG_SIZE)] for j in range(IMG_SIZE)], dtype="float32")
img0_1    = np.array([[np.float32(rd.uniform(IMG_MIN,IMG_MAX)) for i in range(IMG_SIZE)] for j in range(IMG_SIZE)], dtype="float32")
img0_2    = np.array([[np.float32(rd.uniform(IMG_MIN,IMG_MAX)) for i in range(IMG_SIZE)] for j in range(IMG_SIZE)], dtype="float32")

img1_0    = np.array([[np.float32(rd.uniform(IMG_MIN,IMG_MAX)) for i in range(IMG_SIZE)] for j in range(IMG_SIZE)], dtype="float32")
img1_1    = np.array([[np.float32(rd.uniform(IMG_MIN,IMG_MAX)) for i in range(IMG_SIZE)] for j in range(IMG_SIZE)], dtype="float32")
img1_2    = np.array([[np.float32(rd.uniform(IMG_MIN,IMG_MAX)) for i in range(IMG_SIZE)] for j in range(IMG_SIZE)], dtype="float32")

weight    = np.array([[np.float32(rd.uniform(WEIGHT_MIN,WEIGHT_MAX)) for i in range(2)] for j in range(2)], dtype="float32")

def zero_padded_img(img):
    zero_padded_img = np.zeros((IMG_SIZE+2,IMG_SIZE+2),dtype= 'float32')
    for i in range(IMG_SIZE):
        for j in range(IMG_SIZE):
            zero_padded_img[i+1,j+1] = img[i,j]

    return zero_padded_img

def replication(img):
    replicated_img = np.zeros((IMG_SIZE+2,IMG_SIZE+2),dtype= 'float32')
    for wr_xptr in range(IMG_SIZE):
        for wr_yptr in range(IMG_SIZE):
            pixel = img[wr_xptr,wr_yptr]
            # Check 4 corners
            # 4 corners
            if wr_xptr == 0 and wr_yptr == 0:
                replicated_img[0][0] = pixel
                replicated_img[0][1] = pixel
                replicated_img[1][0] = pixel
                replicated_img[1][1] = pixel
            elif wr_xptr == 0 and wr_yptr == IMG_SIZE-1:
                replicated_img[1][4] = pixel
                replicated_img[1][5] = pixel
                replicated_img[0][4] = pixel
                replicated_img[0][5] = pixel
            elif wr_xptr == IMG_SIZE -1 and wr_yptr == 0:
                replicated_img[4][1] = pixel
                replicated_img[4][0] = pixel
                replicated_img[5][0] = pixel
                replicated_img[5][1] = pixel
            elif wr_xptr == IMG_SIZE -1 and wr_yptr == IMG_SIZE-1:
                replicated_img[4][4] = pixel
                replicated_img[4][5] = pixel
                replicated_img[5][4] = pixel
                replicated_img[5][5] = pixel
            elif wr_xptr == 0:
                replicated_img[0][wr_yptr+1] = pixel
                replicated_img[1][wr_yptr+1] = pixel
            elif wr_yptr == 0:
                replicated_img[wr_xptr+1][0] = pixel
                replicated_img[wr_xptr+1][1] = pixel
            elif wr_xptr == IMG_SIZE -1:
                replicated_img[4][wr_yptr+1] = pixel
                replicated_img[5][wr_yptr+1] = pixel
            elif wr_yptr == IMG_SIZE -1:
                replicated_img[wr_xptr+1][4] = pixel
                replicated_img[wr_xptr+1][5] = pixel
            else:
                replicated_img[wr_xptr+1][wr_yptr+1] = pixel

    return replicated_img

def convolution(img0_0, img0_1,img0_2,kernal0,kernal1,kernal2):
    convoluted_results = np.zeros((IMG_SIZE,IMG_SIZE),dtype= 'float32')
    for i in range(IMG_SIZE):
        for j in range(IMG_SIZE):
            conv1,conv2,conv3 = np.float32(0),np.float32(0),np.float32(0)
            for k in range(KERNAL_SIZE):
                for l in range(KERNAL_SIZE):
                    conv1 += kernal0[k,l] * img0_0[i+k,j+l]
                    conv2 += kernal1[k,l] * img0_1[i+k,j+l]
                    conv3 += kernal2[k,l] * img0_2[i+k,j+l]

            convoluted_results[i,j] = conv1 + conv2 + conv3

    return convoluted_results

def max_pooling(convoluted_results):
    max_pooled_result = np.zeros((2,2),dtype='float32')
    for i in range(0,4,2):
        for j in range(0,4,2):
            temp_max = np.float32(0)
            for k in range(0,2):
                for l in range(0,2):
                    if temp_max < convoluted_results[i+k,j+l]:
                        temp_max = convoluted_results[i+k,j+l]

            max_pooled_result[i//2,j//2] = temp_max

    return max_pooled_result

def min_max_norm(fully_connected_result,max,min):
    x_scaled = np.zeros((4,1),dtype='float32')
    for i,x in enumerate(fully_connected_result):
        x_scaled[i] = (x-min) / (max-min)

    return x_scaled

def sigmoid(x_scaled):
    activated_value = np.zeros((4,1),dtype='float32')
    for i,e in enumerate(x_scaled):
        activated_value[i] = 1/(1+np.exp(-e,dtype='float32'))

    return activated_value

def tanh(x_scaled):
    activated_value = np.zeros((4,1),dtype='float32')
    for i,e in enumerate(x_scaled):
        activated_value[i] = 1/(1+np.exp(-e,dtype='float32'))

    return activated_value

def fully_connection(max_pooled_result,weight):
    fully_connected_result = np.zeros((4,1),dtype='float32')
    min = np.float32(LARGE_NUMBER)
    max = np.float32(SMALL_NUMBER)

    for i in range(2):
        for j in range(2):
            partial_mult = 0
            for k in range(2):
                partial_mult += max_pooled_result[i,k] * weight[k,j]

            if partial_mult > max:
                max = partial_mult
            if partial_mult < min:
                min = partial_mult

            fully_connected_result[i*2+j] = partial_mult

    return fully_connected_result,max,min

def SNN(opt,kernal0,kernal1,kernal2,img0_0,img0_1,img0_2,img1_0,img1_1,img1_2,weight):
    if opt == 0 or opt == 2:
        img0_0 = replication(img0_0)
        img0_1 = replication(img0_1)
        img0_2 = replication(img0_2)
        img1_0 = replication(img1_0)
        img1_1 = replication(img1_1)
        img1_2 = replication(img1_2)
    else:
        img0_0 = zero_padded_img(img0_0)
        img0_1 = zero_padded_img(img0_1)
        img0_2 = zero_padded_img(img0_2)
        img1_0 = zero_padded_img(img1_0)
        img1_1 = zero_padded_img(img1_1)
        img1_2 = zero_padded_img(img1_2)

    activated_result = []
    #If 0 calculates the img0, else img1, must wait until both of them processed to do L1 distance
    for img_num in range(2):
        # img_num indicates which img i am processing now
        if img_num == 0:
            convolved_result = convolution(img0_0,img0_1,img0_2,kernal0,kernal1,kernal2)
        else:
            convolved_result = convolution(img1_0,img1_1,img1_2,kernal0,kernal1,kernal2)

        # Take copy of the convoled result, to prevent data contamination
        #-----------------------------Multicycle machine operation----------------------------#
        # Use ASMD, 4 registers
        # Do these only after the convolution process, notice actually 4 registers are needed
        # but first get the baseline model out
        # Max pooling, 4 cycles , 4 cmps
        max_pooling_result = max_pooling(convolved_result)

        # Fully connection, 4 cycles, 2x ,1+
        fully_connected_result ,max , min = fully_connection(max_pooling_result,weight)

        # Min-max norm, 4 cycles,  1/ , 2(+/-)
        min_max_norm_result = min_max_norm(fully_connected_result,max,min)

        # Activation
        if opt == 0 or opt == 1:
            # 2 cycles * 4
            activated_result.append(sigmoid(min_max_norm_result))
        else:
            # 2 cycles * 4
            # 2 e^x , 2 +/-
            activated_result.append(tanh(min_max_norm_result))

    # After calculation of both image, find the L1 distance
    l1_distance = np.float32(0)

    # 4 cycles of l1 caculation
    for i in range(4):
        l1_distance += np.abs(activated_result[0][i] - activated_result[1][i],dtype = 'float32')

    return l1_distance

def fp2hex(float_number):
    hex_value = struct.unpack('<I', struct.pack('<f', float_number))[0]
    return format(hex_value, 'x')

file_input = open("./inputs.txt", "w")
file_output = open("./golden_out.txt", "w")

def hex2fp(hex_value):
      fp_value = struct.unpack('<f',struct.pack('<I',int(hex_value,16)))[0]
      return fp_value

if __name__ == '__main__':
    opt = 0

    with open('lab04/test_input_output_data/input.txt', 'r') as file:
        file_in = file.readlines()

    i = 0
    opt    = int(file_in[1 + 11 * i + 0])
    img0_0  = np.array([hex2fp(val) for val in file_in[1 + 11 * i + 1].split()], dtype=np.float32)
    img0_1  = np.array([hex2fp(val) for val in file_in[1 + 11 * i + 2].split()], dtype=np.float32)
    img0_2  = np.array([hex2fp(val) for val in file_in[1 + 11 * i + 3].split()], dtype=np.float32)
    img1_0  = np.array([hex2fp(val) for val in file_in[1 + 11 * i + 4].split()], dtype=np.float32)
    img1_1  = np.array([hex2fp(val) for val in file_in[1 + 11 * i + 5].split()], dtype=np.float32)
    img1_2  = np.array([hex2fp(val) for val in file_in[1 + 11 * i + 6].split()], dtype=np.float32)
    kernal0 = np.array([hex2fp(val) for val in file_in[1 + 11 * i + 7].split()], dtype=np.float32)
    kernal1 = np.array([hex2fp(val) for val in file_in[1 + 11 * i + 8].split()], dtype=np.float32)
    kernal2 = np.array([hex2fp(val) for val in file_in[1 + 11 * i + 9].split()], dtype=np.float32)
    weight  = np.array([hex2fp(val) for val in file_in[1 + 11 * i + 10].split()], dtype=np.float32)

    img0_0 = np.reshape(img0_0,(4,4))
    img0_1 = np.reshape(img0_1,(4,4))
    img0_2 = np.reshape(img0_2,(4,4))
    img1_0 = np.reshape(img1_0,(4,4))
    img1_1 = np.reshape(img1_1,(4,4))
    img1_2 = np.reshape(img1_2,(4,4))
    kernal0 = np.reshape(kernal0,(3,3))
    kernal1 = np.reshape(kernal1,(3,3))
    kernal2 = np.reshape(kernal2,(3,3))
    weight = np.reshape(weight,(2,2))

    l1_distance = SNN(opt,kernal0,kernal1,kernal2,img0_0,img0_1,img0_2,img1_0,img1_1,img1_2,weight)

    print(f"L1 distance value is: {l1_distance}")
    hex_representation = fp2hex(l1_distance)

    print(f"l1_distance = {l1_distance} , its hex representation: {hex_representation}")

    # file_input.write(str(NUM_OF_PATTERN) + "\n\n")

    # for _ in range(NUM_OF_PATTERN):
    #     # Random inputs generators
    #     img0_0    = np.array([[np.float32(rd.uniform(IMG_MIN,IMG_MAX)) for i in range(IMG_SIZE)] for j in range(IMG_SIZE)], dtype="float32")
    #     img0_1    = np.array([[np.float32(rd.uniform(IMG_MIN,IMG_MAX)) for i in range(IMG_SIZE)] for j in range(IMG_SIZE)], dtype="float32")
    #     img0_2    = np.array([[np.float32(rd.uniform(IMG_MIN,IMG_MAX)) for i in range(IMG_SIZE)] for j in range(IMG_SIZE)], dtype="float32")

    #     img1_0    = np.array([[np.float32(rd.uniform(IMG_MIN,IMG_MAX)) for i in range(IMG_SIZE)] for j in range(IMG_SIZE)], dtype="float32")
    #     img1_1    = np.array([[np.float32(rd.uniform(IMG_MIN,IMG_MAX)) for i in range(IMG_SIZE)] for j in range(IMG_SIZE)], dtype="float32")
    #     img1_2    = np.array([[np.float32(rd.uniform(IMG_MIN,IMG_MAX)) for i in range(IMG_SIZE)] for j in range(IMG_SIZE)], dtype="float32")

    #     kernal0  = np.array([[np.float32(rd.uniform(KERNAL_MIN,KERNAL_MAX)) for i in range(KERNAL_SIZE)] for j in range(KERNAL_SIZE)], dtype="float32")
    #     kernal1  = np.array([[np.float32(rd.uniform(KERNAL_MIN,KERNAL_MAX)) for i in range(KERNAL_SIZE)] for j in range(KERNAL_SIZE)], dtype="float32")
    #     kernal2  = np.array([[np.float32(rd.uniform(KERNAL_MIN,KERNAL_MAX)) for i in range(KERNAL_SIZE)] for j in range(KERNAL_SIZE)], dtype="float32")

    #     weight    = np.array([[np.float32(rd.uniform(WEIGHT_MIN,WEIGHT_MAX)) for i in range(2)] for j in range(2)], dtype="float32")

    #     float_value = img0_0[1][1]
    #     value = fp2hex(float_value)
    #     print(f"float_value = {float_value}")
    #     print(f"value = {value}")

    #     #Write these values into txt
    #     for img in [img0_0,img0_1,img0_2,img1_0,img1_1,img1_2]:
    #         for i in range(IMG_SIZE):
    #             for j in range(IMG_SIZE):
    #                 file_input.write(str(fp2hex(img[i][j])))
    #                 file_input.write(" ")
    #             file_input.write("\n")
    #         file_input.write("\n\n")

    #     file_input.write("\n")

    #     #Write these values into txt
    #     for kernal in [kernal0,kernal1,kernal2]:
    #         for i in range(KERNAL_SIZE):
    #             for j in range(KERNAL_SIZE):
    #                 file_input.write(str(fp2hex(kernal[i][j])))
    #                 file_input.write(" ")
    #             file_input.write("\n")
    #         file_input.write("\n\n")

    #     # weight
    #     for i in range(2):
    #         for j in range(2):
    #             file_input.write(str(fp2hex(weight[i][j])))
    #             file_input.write(" ")
    #         file_input.write("\n")

    #     file_input.write("\n\n")

    #     # Golden
    #     l1_distance = SNN(opt,kernal0,kernal1,kernal2,img0_0,img0_1,img0_2,img1_0,img1_1,img1_2,weight)
    #     file_output.write(str(fp2hex(l1_distance)) + "\n")

file_input.close()
file_output.close()
