######################################################
#                                                    #
#  Silicon Perspective, A Cadence Company            #
#  FirstEncounter IO Assignment                      #
#                                                    #
######################################################

Version: 2

#Example:
#Pad: I_CLK 		W

#define your iopad location here

# NORTH 10
Pad: GNDP0       N
Pad: O_VALID     N
Pad: VDDP0       N
Pad: O_VALUE     N
Pad: GNDP1       N
Pad: I_IN_VALID2 N
Pad: VDDP1       N
Pad: I_IN_VALID  N
Pad: I_CLK       N
Pad: I_RST_N     N


# EAST 10
Pad: VDDC0          E
Pad: I_MATRIX_IDX0  E
Pad: VDDC1          E
Pad: I_MATRIX_IDX1  E
Pad: VDDC2          E
Pad: I_MATRIX_IDX2  E
Pad: VDDC3          E
Pad: I_MATRIX_IDX3  E
Pad: GNDC6          E
Pad: I_MODE         E

# SOUTH 10
Pad: I_MATRIX_3  S
Pad: GNDC1       S
Pad: I_MATRIX_4  S
Pad: GNDC2       S
Pad: I_MATRIX_5  S
Pad: GNDC3       S
Pad: I_MATRIX_6  S
Pad: GNDC4       S
Pad: I_MATRIX_7  S
Pad: GNDC5       S

# WEST 10
Pad: I_MATRIX_SIZE_0  W
Pad: VDDP2            W
Pad: I_MATRIX_SIZE_1  W
Pad: GNDP2            W
Pad: I_MATRIX_0       W
Pad: VDDP3            W
Pad: I_MATRIX_1       W
Pad: GNDP3            W
Pad: I_MATRIX_2       W
Pad: GNDC0            W

# Corners 4
Pad: PCLR SE PCORNER
Pad: PCUL NW PCORNER
Pad: PCUR NE PCORNER
Pad: PCLL SW PCORNER