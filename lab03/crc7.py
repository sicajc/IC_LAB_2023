def CRC7(data):
    crc = 0
    polynomial = 0x9

    for i in range(40):
        data_in = (data >> (39-i)) & 0x1
        data_out = (crc >>6) & 0x1
        crc = crc << 1

        if data_in ^ data_out:
            crc = crc ^ polynomial


    return crc & 0x7f

def CRC16(data):
    crc = 0
    polynomial = 0x1021

    for i in range(64):
        data_in  = (data >> (63-i)) & 0x1
        data_out =  (crc>>15) & 0x1
        crc = crc << 1

        if data_in ^ data_out:
            crc = crc ^ polynomial

    return crc & 0xffff

if __name__ == '__main__':
    data_input = 0x580000250c
    result = CRC7(data_input)
    print(f"CRC7: {result:02x}")

    data_input = 0x417acb820f9dbf1f
    result = CRC16(data_input)
    print(f"CRC16: {result:02x}")