#########################################
# Author: Betsaleel Henry
# Date created: 11/10/2023
#########################################
PATNUM=100
import numpy as np
import random
import numpy as np
import skimage.measure
import struct
import bitstring
from scipy.special import expit, logit
#create two images with random numbers of range + - 0:255
# the images are RGB with 4x4 pixels and 3
#[][][][][][][][][][][][][][][] Matrix creation    #[][][]][][][][][][][][][]]][][][][][][][][][][][][][][][][][][][][][][][][][][][]

with open ("input_images.txt", "a") as f:
    with open("output.txt", "a") as f2:
        f2.write(str(PATNUM))
        f2.write("\n")
        for i in range(PATNUM):
            # For Kernel in the range of -0.5 to 0.5
            Kernel = np.random.uniform(-0.5, 0.5, size=(3, 3, 3)).astype(np.float32)
            # For Weight in the range of -0.5 to 0.5
            Weight = np.random.uniform(-0.5, 0.5, size=(1, 2, 2)).astype(np.float32)
            Image1 = np.random.rand(3, 4, 4).astype(np.float32)
            Image2 = np.random.rand(3, 4, 4).astype(np.float32)
            # Kernel = np.random.rand(3, 3, 3).astype(np.float32)
            # Weight = np.random.rand(1,2, 2).astype(np.float32)
            Padding_type=random.randint(0,3)
            #][][][]][][][][][][][][][][][][][][][][][][] welcome to test with own data. your own float values for testing :)][][][][][][][]][][][][][][][][][][][][][][][][][][][][][][][][][][][]
            # for i in range(0,3):
            #     for j in range (0,4):
            #         for k in range(0,4):
            #             Image1[i][j][k]=random.uniform(0,255)
            #             Image2[i][j][k]=random.uniform(0,255)

            # Generate random numbers in the range (-255, 255) for Image1 and Image2
            Image1 = np.random.uniform(-255, 255, size=(3, 4, 4)).astype(np.float32)
            Image2 = np.random.uniform(-255, 255, size=(3, 4, 4)).astype(np.float32)

            # Filter out values within the range (-0.5, 0.5) and replace them with new random values
            Image1[(Image1 > -0.5) & (Image1 < 0.5)] = np.random.uniform(0.5, 255, size=Image1[(Image1 > -0.5) & (Image1 < 0.5)].shape).astype(np.float32)
            Image2[(Image2 > -0.5) & (Image2 < 0.5)] = np.random.uniform(-255, -0.5, size=Image2[(Image2 > -0.5) & (Image2 < 0.5)].shape).astype(np.float32)

           # print(Padding_type)
            #[][][][][][][][][][][][][][][]   Replication/zero padding  [][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]


            def Replication(Matrix):
                return np.pad(Matrix, [1, 1], mode='edge')
            def Zero(Matrix):
                return np.pad(Matrix, [1, 1], mode='constant')

            # 6x6x3 matrix to receive paddings later
            Im10=np.random.rand(3,6,6).astype(np.float32)
            Im20=np.random.rand(3,6,6).astype(np.float32)
            Im11=np.random.rand(3,6,6).astype(np.float32)
            Im21=np.random.rand(3,6,6).astype(np.float32)

            for i in range(0,3):
                Im10[i]=Zero(Image1[i])
                Im20[i]=Zero(Image2[i])
                Im11[i]=Replication(Image1[i])
                Im21[i]=Replication(Image2[i])
            # print("After padding")
            # print("image1")
            # print(Im10)
            # print("image2")
            # print(Im20)
            # print("image1")
            # print(Im11)
            # print("image2")
            # print(Im21)

            #[][][][][][][][][][][][][][][]   Convolution on 6x6x3   [][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]

            def convolution(kernel, matrix):
                # Get the dimensions of the kernel and matrix
                k_rows, k_cols = kernel.shape
                m_rows, m_cols = matrix.shape

                # Create a new matrix to store the result of the convolution
                result = np.zeros((m_rows - k_rows + 1, m_cols - k_cols + 1))

                # Perform the convolution
                for i in range(result.shape[0]):
                    for j in range(result.shape[1]):
                        result[i][j] = np.sum(kernel * matrix[i:i+k_rows, j:j+k_cols])

                return result
            #creat two arrays to contain the result of convolution
            FirstIMGconv=np.random.rand(3,4,4).astype(np.float32)
            SecondIMGconv=np.random.rand(3,4,4).astype(np.float32)

            if(Padding_type==1 or Padding_type==3):
                for i in range(0,3):
                    FirstIMGconv[i]=convolution(Kernel[i],Im10[i])
                    SecondIMGconv[i]=convolution(Kernel[i],Im20[i])
            else:
                for i in range(0,3):
                    FirstIMGconv[i]=convolution(Kernel[i],Im11[i])
                    SecondIMGconv[i]=convolution(Kernel[i],Im21[i])
            #[][][][][][][][][][][][][][][][][][][][][]   Feature map   [][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]

            # print("Padding type= ",Padding_type)
            # print("After convolution")
            # print(FirstIMGconv)
            # print("After convolution")
            # print(SecondIMGconv)
            #//////////////////////#
            #feature map for 4x4x1 we add the 3 feature maps
            FeatureMap=np.random.rand(2,4,4).astype(np.float32)
            # print("Feature Map")
            FeatureMap[0]=FirstIMGconv[0]+FirstIMGconv[1]+FirstIMGconv[2]
            FeatureMap[1]=SecondIMGconv[0]+SecondIMGconv[1]+SecondIMGconv[2]
            # print(FeatureMap)

            #[][][][][][][][][][][][][][]{}{}{}{}{}{}{}  max POOLING    [][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]
            Pooling=np.random.rand(2,2,2).astype(np.float32)

            def max_pool(img, factor: int):
                """ Perform max pooling with a (factor x factor) kernel"""
                ds_img = np.full((img.shape[0] // factor, img.shape[1] // factor), -float('inf'), dtype=img.dtype)
                np.maximum.at(ds_img, (np.arange(img.shape[0])[:, None] // factor, np.arange(img.shape[1]) // factor), img)
                return ds_img
            for i in range(0,2):
                for j in range(0,2):
                    Pooling[0][i][j]=np.max(FeatureMap[:,i:i+2,j:j+2])


            Pooling[0]=max_pool(FeatureMap[0],2)
            Pooling[1]=max_pool(FeatureMap[1],2)

            #print("Pooling")
            #print(Pooling)
            #Multiply feature map with wheights

            #{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{} FUlly connected   {}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{{}}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{{}#{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}

            FullyConnected=np.random.rand(2,2,2).astype(np.float32)
            FullyConnected[0]=Pooling[0]*Weight
            FullyConnected[1]=Pooling[1]*Weight
            #print the size of each matrxi
            # print("feature",FeatureMap.shape)
            # print("weight",Weight.shape)
            # print("pooling",Pooling.shape)
            #print("FullyConnected")
            #print(FullyConnected)



            #{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}   Compute MIN Max NORMalization for each values in Normalization array {}{}{}{}{}{}{}{}{}{}
            # Calculate the minimum and maximum values
            xmin = np.min(FullyConnected)
            xmax = np.max(FullyConnected)

            # Apply min-max normalization to each element in the array
            normalized_numbers = (FullyConnected - xmin) / (xmax - xmin)
            #print("Normalized numbers really")
            #print(normalized_numbers)

            #{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{} Normalization  {}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{

            ACTIVATION=np.random.rand(2,2,2).astype(np.float32)

            # sigmoid=lambda x:1/(1+np.exp(-x))
            # tanh=lambda x:(np.exp(x)-np.exp(-x))/(np.exp(x)+np.exp(-x))






            def sigmoid(x):
                return expit(x)
            def tanh(x):
                return np.tanh(x)



            if(Padding_type==0 or Padding_type==1):
                ACTIVATION[0]=sigmoid(FullyConnected[0])
                ACTIVATION[1]=sigmoid(FullyConnected[1])
            else:
                ACTIVATION[0]=tanh(FullyConnected[0])
                ACTIVATION[1]=tanh(FullyConnected[1])
            #print("ACTIVATION")
            #print(ACTIVATION)
            #{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}  Take vector representation in raster code {}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}
            RasterCODE1=[normalized_numbers[0][0][0],normalized_numbers[0][0][1],normalized_numbers[0][1][0],normalized_numbers[0][1][1]]
            RasterCODE2=[normalized_numbers[1][0][0],normalized_numbers[1][0][1],normalized_numbers[1][1][0],normalized_numbers[1][1][1]]

            #print("Encoding vector")
            #print(RasterCODE1)
            #print(RasterCODE2)

            #{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}   Compute L1 distance {}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}
            RasterCODE1 = np.array(RasterCODE1)
            RasterCODE2 = np.array(RasterCODE2)

            # Perform element-wise subtraction
            L1_distance = np.sum(np.abs(RasterCODE1 - RasterCODE2))#OUTPUT


            #{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}   Do conversion to binary representationof float {}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}


            # Convert a float32 to its 32-bit binary representation
            def float_to_binary(float_value):
                # Use struct.pack to convert the float to bytes
                float_bytes = struct.pack('f', float_value)

                # Use bin() to convert the bytes to a binary string
                float_binary = bin(int.from_bytes(float_bytes, byteorder='big'))

                return float_binary

            # Example usage:
            float_value = 3.14159
            binary_representation = float_to_binary(float_value)
            # print(binary_representation)

            #input image matrix conversion to binary
            def matrix_conversion(matrix):
                binary_matrix=np.zeros((3,4,4))
                for i in range(0,3):
                    for j in range(0,4):
                        for k in range(0,4):
                            binary_matrix[i][j][k]=float_to_binary(matrix[i][j][k])
                return binary_matrix
            #todo:
            #image matrix conversion to binary is to be done and tested. (DONE)
            #todo:
            # write the matrix to a file as a binary(DONE)
            #todo:
            #write the answer to the file as a binary number(DONE)
            #todo:
            #file format is to be decided (DONE)
            import bitstring
            f1 = bitstring.BitArray(float=1.0, length=32)
            # print(f1.bin)
            #convert the whole array using bitstring to binary
            def matrix_conversion_bitstring(matrix):
                binary_matrix=np.zeros((3,4,4))
                for i in range(0,3):
                    for j in range(0,4):
                        for k in range(0,4):
                            binary_matrix[i][j][k]=bitstring.BitArray(float=matrix[i][j][k], length=32).bin
                return binary_matrix
            Image1_binary=matrix_conversion_bitstring(Image1)
            Image2_binary=matrix_conversion_bitstring(Image2)
            # print("Image1_binary")
            # print(Image1_binary)
            # print("Image2_binary")
            # print(Image2_binary)
            # print(float_to_binary(Image1[1][1][1]))
            # Convert the float to its binary representation as bytes
            # Convert the bytes to a binary string

            A=[0.001234,0.325345,-1.0]
            # Print the binary representation
            Binary_array=np.zeros((3,4,4))
            Binary_array2=np.zeros((3,3,3))
            Binary_array3=np.zeros((1,2,2))

            Binary_array_strings = np.empty_like(Binary_array, dtype=np.dtype('<U32'))
            Binary_array_strings2 = np.empty_like(Binary_array2, dtype=np.dtype('<U32'))
            Binary_array_strings3 = np.empty_like(Binary_array3, dtype=np.dtype('<U32'))
            import bitstring
            def Float_to_binary(Matrix):
                for i in range (0,3):
                    for j in range(0,4):
                        for k in range(0,4):
                            f1 =(bitstring.BitArray(float=Matrix[i][j][k], length=32))
                            Binary_array_strings[i][j][k]=f1.bin
                return Binary_array_strings
            def Float_to_binary_kernel(Matrix):
                for i in range (0,3):
                    for j in range(0,3):
                        for k in range(0,3):
                            f1 =(bitstring.BitArray(float=Matrix[i][j][k], length=32))
                            Binary_array_strings2[i][j][k]=f1.bin
                return Binary_array_strings2
            def Float_to_binary_weight(Matrix):
                for i in range (0,1):
                    for j in range(0,2):
                        for k in range(0,2):
                            f1 =(bitstring.BitArray(float=Matrix[i][j][k], length=32))
                            Binary_array_strings3[i][j][k]=f1.bin
                return Binary_array_strings3

            Mymatrix1=Float_to_binary(Image1)
            Mymatrix2=Float_to_binary(Image2)
            #print(Mymatrix1)
            #print(Mymatrix2)
            Mykernel=Float_to_binary_kernel(Kernel)
            MyWeight=Float_to_binary_weight(Weight)
            OUT =(bitstring.BitArray(float=L1_distance, length=32))
            # print(OUT.bin)
            # print("Kernel")
            # print(Mykernel)
            # print("Weight")
            # print(MyWeight)
            #{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}   File output writing {}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}{}

            #creat a new file input.txt
            #write the first image in raster code
            f.write("\n")
            for i in range(0,3):
                for j in range(0,4):
                    for k in range(0,4):
                        f.write(Mymatrix1[i][j][k])
                        f.write("\n")
            #write the second image in raster code
            f.write("\n")
            for i in range(0,3):
                for j in range(0,4):
                    for k in range(0,4):
                        f.write(Mymatrix2[i][j][k])
                        f.write("\n")
            #write the kernel in raster code
            with open("input_kernel.txt", "a") as f3:
                f3.write("\n")
                for i in range(0,3):
                    for j in range(0,3):
                        for k in range(0,3):
                            f3.write(Mykernel[i][j][k])
                            f3.write("\n")
            #write the weight in raster code
            with open("input_weight.txt", "a") as f4:
                f4.write("\n")
                for i in range(0,1):
                    for j in range(0,2):
                        for k in range(0,2):
                            f4.write(MyWeight[i][j][k])
                            f4.write("\n")
            #write the output in raster code
            f2.write(OUT.bin)
            f2.write("\n")
            f.write("\n")
print("Done")