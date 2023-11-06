# %%
import numpy as np
import copy
MAP_SIZE = 64

# Do data structure augmentation on both map
# Path map, 0 as passable, 1 as block, 2,3 as seq for further optimization
# Counting sequence 2->2->3->3
path_map = np.array([[1 for y in range(MAP_SIZE)] for x in range(MAP_SIZE)])

# Location map, 0 as passable, 1 as blocked
location_map = np.array([[0 for y in range(MAP_SIZE)] for x in range(MAP_SIZE)])
## Given net_id,loc_x and loc_y
net_id_1 = 9
# src_x_1 = 32  #source
# src_y_1 = 15
# dst_x_1 = 16 #sink
# dst_y_1 = 40

src_x_1 = 16  #source
src_y_1 = 40
dst_x_1 = 32 #sink
dst_y_1 = 15

net_id_2 = 4
src_x_2 = 2  #source
src_y_2 = 2
dst_x_2 = 13 # sink
dst_y_2 = 13

target_num_ff = 2

# (x,y)
# Assign example location map
# Macro 1
location_map[15:16+1,32:37+1] = 9
location_map[40:42+1,13:16+1] = 9
# Macro 2
location_map[2:5,2:6] = 0
location_map[12:14,11:14] = 0

# Wall padding for boundary condition handling on only path map
# Updates path map when reading in data from DRAM
for y in range(0,MAP_SIZE):
    for x in range(0,MAP_SIZE):
        if location_map[y,x] == 0:
            path_map[y,x] = 0

# %%
def adjacent_has_2_3(path_map,dst_y,dst_x):
    # since 2,3 encodes as 10,11 simply sees if the [1] bits is 1
    if path_map[dst_y+1,dst_x]//2 == 1 or path_map[dst_y-1,dst_x]//2==1 or \
       path_map[dst_y,dst_x+1]//2 == 1 or path_map[dst_y,dst_x-1]//2==1:
        return True
    else:
        return False

# %%
def fillpath(src_x,src_y,dst_x,dst_y,path_map):
    # Initailize source, all source must be offsetted by (1,1)
    cur_y = src_y
    cur_x = src_x
    target_y = dst_y
    target_x = dst_x

    # Simply fill the original src wth 2, then start expanding
    path_map[cur_y,cur_x] = 2
    # Fill the destination as passable
    path_map[target_y,target_x] = 0

    cnt = 1
    path_map_nxt = copy.deepcopy(path_map)
    while path_map[target_y,target_x] != 2 and path_map[target_y,target_x] != 3:
        if cnt == 4:
            cnt = 0

        for cur_y in range(1,MAP_SIZE-1):
            for cur_x in range(1,MAP_SIZE-1):
                if path_map[cur_y,cur_x] == 0:
                    # Down,up,right,left
                    if adjacent_has_2_3(path_map,cur_y,cur_x):
                        if cnt == 0:
                            path_map_nxt[cur_y,cur_x] = 2
                        elif cnt == 1:
                            path_map_nxt[cur_y,cur_x] = 2
                        elif cnt == 2:
                            path_map_nxt[cur_y,cur_x] = 3
                        elif cnt == 3:
                            path_map_nxt[cur_y,cur_x] = 3

        # Upper,
        #    -X-
        #     |
        for cur_x in range(1,MAP_SIZE-1):
            if path_map[0,cur_x] == 0:
                if path_map[1,cur_x]//2 == 1 or path_map[0,cur_x+1]//2 == 1 or \
                path_map[0,cur_x-1]//2 == 1:
                    if cnt == 0:
                        path_map_nxt[0,cur_x] = 2
                    elif cnt == 1:
                        path_map_nxt[0,cur_x] = 2
                    elif cnt == 2:
                        path_map_nxt[0,cur_x] = 3
                    elif cnt == 3:
                        path_map_nxt[0,cur_x] = 3

        # Lower
        #       |
        #      -X-
        for cur_x in range(1,MAP_SIZE-1):
           if path_map[63,cur_x] == 0:
               if path_map[62,cur_x]//2 == 1 or path_map[63,cur_x+1]//2 == 1 or \
               path_map[63,cur_x-1]//2 == 1:
                   if cnt == 0:
                       path_map_nxt[63,cur_x] = 2
                   elif cnt == 1:
                       path_map_nxt[63,cur_x] = 2
                   elif cnt == 2:
                       path_map_nxt[63,cur_x] = 3
                   elif cnt == 3:
                       path_map_nxt[63,cur_x] = 3

        # LEFT
        for cur_y in range(1,MAP_SIZE-1):
          if path_map[cur_y,0] == 0:
              if path_map[cur_y-1,0]//2 == 1 or path_map[cur_y+1,0]//2 == 1 or \
              path_map[cur_y,1]//2 == 1:
                  if cnt == 0:
                      path_map_nxt[cur_y,0] = 2
                  elif cnt == 1:
                      path_map_nxt[cur_y,0] = 2
                  elif cnt == 2:
                      path_map_nxt[cur_y,0] = 3
                  elif cnt == 3:
                      path_map_nxt[cur_y,0] = 3

        # RIGHT
        for cur_y in range(1,MAP_SIZE-1):
          if path_map[cur_y,63] == 0:
              if path_map[cur_y-1,63]//2 == 1 or path_map[cur_y+1,63]//2 == 1 or \
              path_map[cur_y,62]//2 == 1:
                  if cnt == 0:
                      path_map_nxt[cur_y,63] = 2
                  elif cnt == 1:
                      path_map_nxt[cur_y,63] = 2
                  elif cnt == 2:
                      path_map_nxt[cur_y,63] = 3
                  elif cnt == 3:
                      path_map_nxt[cur_y,63] = 3


        # Coners cases vertices.
        # Upper left
        if path_map[0,0] == 0:
              if path_map[0,1]//2 == 1 or path_map[1,0]//2 == 1:
                  if cnt == 0:
                      path_map_nxt[0,0] = 2
                  elif cnt == 1:
                      path_map_nxt[0,0] = 2
                  elif cnt == 2:
                      path_map_nxt[0,0] = 3
                  elif cnt == 3:
                      path_map_nxt[0,0] = 3

        # Lower left
        if path_map[63,0] == 0:
              if path_map[63,1]//2 == 1 or path_map[62,0]//2 == 1:
                  if cnt == 0:
                      path_map_nxt[63,0] = 2
                  elif cnt == 1:
                      path_map_nxt[63,0] = 2
                  elif cnt == 2:
                      path_map_nxt[63,0] = 3
                  elif cnt == 3:
                      path_map_nxt[63,0] = 3

        # Lower right
        if path_map[63,63] == 0:
              if path_map[62,63]//2 == 1 or path_map[63,62]//2 == 1:
                  if cnt == 0:
                      path_map_nxt[63,63] = 2
                  elif cnt == 1:
                      path_map_nxt[63,63] = 2
                  elif cnt == 2:
                      path_map_nxt[63,63] = 3
                  elif cnt == 3:
                      path_map_nxt[63,63] = 3

        # Upper right
        if path_map[0,63] == 0:
              if path_map[0,62]//2 == 1 or path_map[1,63]//2 == 1:
                  if cnt == 0:
                      path_map_nxt[0,63] = 2
                  elif cnt == 1:
                      path_map_nxt[0,63] = 2
                  elif cnt == 2:
                      path_map_nxt[0,63] = 3
                  elif cnt == 3:
                      path_map_nxt[0,63] = 3

        # print(path_map_nxt)
        path_map = copy.deepcopy(path_map_nxt)
        cnt += 1

    return path_map,cnt

# %%
path_map,cnt = fillpath(src_x_1,src_y_1,dst_x_1,dst_y_1,path_map)

# %%
path_map,cnt

# %% [markdown]
# ### Notice that you can reuse the cnt final state for retracing, retrace simply subtracts the cnt

# %%
def retrace_path(net_id,src_x,src_y,dst_x,dst_y,location_map,path_map,cnt):
    # Uses the cnt value finished at filling path for retrace
    cur_x   = dst_x
    cur_y   = dst_y
    target_x = src_x
    target_y = src_y

    cnt = cnt - 1
    # From the cnt given, counts back
    while path_map[target_y,target_x] != 1:
        if cnt == 0:
            nxt_count = 3
        else:
            nxt_count = cnt-1

        path_map[cur_y,cur_x] = 1
        # Writing into location map, notes must be offsetted by (1,1)
        location_map[cur_y,cur_x] = net_id

        if nxt_count == 2 or nxt_count == 3: # Expect 3
            # Down
            if path_map[cur_y+1,cur_x] == 3:
                cur_y = cur_y + 1
            # Up
            elif path_map[cur_y-1,cur_x] == 3:
                cur_y = cur_y-1
            # Right
            elif path_map[cur_y,cur_x+1] == 3:
                cur_x = cur_x+1
            # Left
            elif path_map[cur_y,cur_x-1] == 3:
                cur_x = cur_x-1

        elif nxt_count == 0 or nxt_count == 1: # Expect 2
            # Down
            if path_map[cur_y+1,cur_x] == 2:
                cur_y = cur_y + 1
            # Up
            elif path_map[cur_y-1,cur_x] == 2:
                cur_y = cur_y-1
            # Right
            elif path_map[cur_y,cur_x+1] == 2:
                cur_x = cur_x+1
            # Left
            elif path_map[cur_y,cur_x-1] == 2:
                cur_x = cur_x-1

        cnt = nxt_count

    return

# %%
retrace_path(net_id_1,src_x_1,src_y_1,dst_x_1,dst_y_1,location_map,path_map,cnt)

# %%
for y in range(MAP_SIZE):
    for x in range(MAP_SIZE):
        if path_map[y,x] != 1:
            path_map[y,x] = 0

# %%
def clear_pathmap(path_map):
    for y in range(0,MAP_SIZE):
        for x in range(0,MAP_SIZE):
            if path_map[y,x] != 1:
                path_map[y,x] = 0

    return

# %%
path_map,cnt = fillpath(src_x_2,src_y_2,dst_x_2,dst_y_2,path_map)

# %%
path_map

# %%
retrace_path(net_id_2,src_x_2,src_y_2,dst_x_2,dst_y_2,location_map,path_map,cnt)

# %%
location_map

# 0. Read in the target numbers and their indices.
# 1. Setup Location map and path map and weight map
#   1. 1 64x64x2 register files, 2 X 128 X 128 SRAMs
#   2. Note that SRAM has 1 cycle of read out delay.
#   3. Note the output logic of SRAM need buffer, thus total 2 cycles of Delay.

# 2. Read location map into path map from DRAM using AXI-4
    # 1. Develop Control logic for AXI-4
    # 2. Address generation for readings
    # 3. Remember buffers when reading in Data from DRAM
# 3. Read out the weight matrix

# 4. for idx in range(target_num_ff):
    # 1. Fill path map
    # 2. From cnt of path map, retrace path map and update location map
    # 3. Clear path map
    # 4. Do these for all sources and destination

# 5. Write back the location map SRAM->DRAM
# 6. Do accumulation then output the golden cost