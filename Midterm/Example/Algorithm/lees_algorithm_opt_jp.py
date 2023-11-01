# %%
import numpy as np
import copy
MAP_SIZE = 16

# Do data structure augmentation on both map
# Path map, 0 as passable, 1 as block, 2,3 as seq for further optimization
path_map = np.array([[0 for y in range(MAP_SIZE+2)] for x in range(MAP_SIZE+2)])

# Location map, 0 as passable, 1 as blocked
location_map = np.array([[0 for y in range(MAP_SIZE+2)] for x in range(MAP_SIZE+2)])

# Wall padding for boundary condition handling
for y in range(MAP_SIZE+2):
    for x in range(MAP_SIZE+2):
        if y == 0 or x == 0 or y == MAP_SIZE+1 or x == MAP_SIZE+1:
            path_map[y,x] = 1
            location_map[y,x] = 1

# Thus all target is offsetted by (1,1)
# (x,y)
# Assign example location map
# Macro 1
location_map[3:5,11:15] = 9
location_map[11:13,5:7] = 9
# Macro 2
location_map[3:6,3:7] = 4
location_map[13:15,12:15] = 4

# %%
def copy_loc_path(path_map,location_map):
    for y in range(MAP_SIZE+2):
        for x in range(MAP_SIZE+2):
            if location_map[y,x] != 0:
                path_map[y,x] = 1
            else:
                path_map[y,x] = 0
    return

# %%
copy_loc_path(path_map,location_map)

# %%
location_map

# %%
path_map

# %%
## Given net_id,loc_x and loc_y
net_id_1 = 9
src_x_1 = 5  #source
src_y_1 = 10
dst_x_1 = 11 #sink
dst_y_1 = 3

net_id_2 = 4
src_x_2 = 4  #source
src_y_2 = 2
dst_x_2 = 13 # sink
dst_y_2 = 13

# %%
path_map_nxt = copy.deepcopy(path_map)

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
    cur_y = src_y+1
    cur_x = src_x+1
    target_y = dst_y+1
    target_x = dst_x+1

    # Simply fill the original src wth 2, then start expanding
    path_map[cur_y,cur_x] = 2
    # Fill the destination as passable
    path_map[target_y,target_x] = 0

    cnt = 1
    path_map_nxt = copy.deepcopy(path_map)
    while path_map[target_y,target_x] != 2 and path_map[target_y,target_x] != 3:
        if cnt == 4:
            cnt = 0

        for cur_y in range(1,MAP_SIZE+1):
            for cur_x in range(1,MAP_SIZE+1):
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
    # Find the first label and starting seq from dst, implement FSM in python
    cur_x   = dst_x + 1
    cur_y   = dst_y + 1
    target_x = src_x + 1
    target_y = src_y + 1

    cnt = cnt - 1
    # From the cnt given, counts back
    while path_map[target_y,target_x] != 1:
        if cnt == 0:
            nxt_count = 3
        else:
            nxt_count = cnt-1

        path_map[cur_y,cur_x] = 1
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
location_map

# %%
location_map

# %%
path_map

# %%
for y in range(MAP_SIZE+2):
    for x in range(MAP_SIZE+2):
        if path_map[y,x] != 1:
            path_map[y,x] = 0

# %%
def clear_pathmap(path_map):
    for y in range(MAP_SIZE+2):
        for x in range(MAP_SIZE+2):
            if path_map[y,x] != 1:
                path_map[y,x] = 0

    return

# %%
net_id_2 = 4
src_x_2 = 4  #source
src_y_2 = 4
dst_x_2 = 13 # sink
dst_y_2 = 13

# %%
path_map,cnt = fillpath(src_x_2,src_y_2,dst_x_2,dst_y_2,path_map)

# %%
path_map

# %%
retrace_path(net_id_2,src_x_2,src_y_2,dst_x_2,dst_y_2,location_map,path_map,cnt)

# %%
location_map
