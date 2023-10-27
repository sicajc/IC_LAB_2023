import random as rd

# in_weight 3 bits
UPPER_BOUND = 7
LOWER_BOUND = 0
PATTERN_NUM = 100

rd.seed(1234)

ex1_in_weight = [3,7,6,5,3,3,5,7]
ex2_in_weight = [0,0,0,0,0,0,0,0]
ex3_in_weight = [7,7,7,7,7,7,7,7]
ex4_in_weight = [1,1,2,2,4,4,6,6]
ex5_in_weight = [7, 7, 1, 6, 1, 7, 7, 7] #Max weight 28

if __name__ == '__main__':
    with open('lab06/input.txt', 'w') as f:
        f.write(f"{PATTERN_NUM}\n")
        for i in range(PATTERN_NUM):
            if i==0:
               mode = 0
            elif i == 1:
               mode = 1
            else:
               mode = rd.randint(0,1)
            # out mode
            f.write(f"{mode}\n")

            # Generate 8 random weights
            for idx in range(8):
                if i==0 or i == 1:
                  weight = ex1_in_weight[idx]
                elif i == 2:
                  weight = ex2_in_weight[idx]
                elif i==3:
                  weight = ex3_in_weight[idx]
                elif i==4:
                  weight = ex4_in_weight[idx]
                elif i==5:
                  weight = ex5_in_weight[idx]
                else:
                  weight = rd.randint(LOWER_BOUND,UPPER_BOUND)

                f.write(f"{weight} ")

            f.write("\n")
