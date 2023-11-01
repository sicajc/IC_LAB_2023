import numpy as np
import copy
MAP_SIZE = 16

# Do data structure augmentation on both map
# Path map, 0 as passable, 1 ,2 as sequence, 3 as block
path_map = np.array([[0 for y in range(MAP_SIZE+2)] for x in range(MAP_SIZE+2)])

# Location map, 0 as passable, 1 as blocked
location_map = np.array([[0 for y in range(MAP_SIZE+2)] for x in range(MAP_SIZE+2)])

# Wall padding for boundary condition handling
for y in range(MAP_SIZE+2):
    for x in range(MAP_SIZE+2):
        if y == 0 or x == 0 or y == MAP_SIZE+1 or x == MAP_SIZE+1:
            path_map[y,x] = 3
            location_map[y,x] = 1