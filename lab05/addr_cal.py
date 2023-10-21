def addr(x,y,img_idx):
    sram_num = x % 5
    if sram_num == 0 or sram_num == 1:
        addr = x//5 * 32 + y + img_idx * 224
    else:
        addr = x//5 * 32 + y + img_idx * 192

    return addr

for x  in range(5):
    print(addr(0,3,13))
