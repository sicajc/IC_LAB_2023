import numpy as np

def reverseRow(data, index):

    cols = len(data[index])
    for i in range(cols // 2):
        temp = data[index][i]
        data[index][i] = data[index][cols - i - 1]
        data[index][cols - i - 1] = temp

    return data

# Rotate Matrix by 180 degrees
def rotateMatrix(data):

    rows = len(data)
    cols = len(data[0])

    if (rows % 2):
        # If N is odd reverse the middle
        # row in the matrix
        data = reverseRow(data, len(data) // 2)

        # Swap the value of matrix [i][j] with
        # [rows - i - 1][cols - j - 1] for half
        # the rows size.
        for i in range(rows // 2):
            for j in range(cols):
                temp = data[i][j]
                data[i][j] = data[rows - i - 1][cols - j - 1]
                data[rows - i - 1][cols - j - 1] = temp
        return data

img    = np.array([[1,2,3,8],[4,5,6,9],[7,8,9,1]])
kernal = np.array([[1,2,3],[3,4,5],[6,7,8]])

matrix_size = len(img)
kernal_size = len(kernal)

trans_convoluted_results = np.zeros((matrix_size+(kernal_size-1),matrix_size+(kernal_size-1)))
for i in range(matrix_size):
    for k in range(kernal_size):
        for j in range(matrix_size):
            for l in range(kernal_size):
                conv = kernal[k,l] * img[i,j]
                trans_convoluted_results[i+k,j+l] += conv


# Zero-padding the img with size of kernal, simply instantiate an array of size (kernal_size -1) + img_size
zero_padded_img = np.zeros(((kernal_size-1)*2+matrix_size,(kernal_size-1)*2+matrix_size))


for i in range(matrix_size):
    for j in range(matrix_size):
        zero_padded_img[i+kernal_size-1,j+kernal_size-1] = img[i,j]

print(zero_padded_img)

# Flip kernals
flipped_kernals = rotateMatrix(kernal)

print(flipped_kernals)

convoluted_results = np.zeros((matrix_size+(kernal_size-1),matrix_size+(kernal_size-1)))

# Do normal convolution
for i in range(matrix_size+(kernal_size-1)):
    for j in range(matrix_size+(kernal_size-1)):
        conv = 0
        for k in range(kernal_size):
            for l in range(kernal_size):
                conv += flipped_kernals[k,l] * zero_padded_img[i+k,j+l]

        convoluted_results[i,j] = conv

print(f"Transposed matrix with zero_padding = \n{convoluted_results}")
print(f"Transpoed matrix with accumulation = \n{trans_convoluted_results}")
