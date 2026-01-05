# print numbers stored as byte sequences in hex format
def print_num(num):
    print("0x", end="")
    for i in reversed(range(len(num))):
        if num[i] < 0x10:
            print("0", end="")
        print(format(num[i], 'x'), end="")

# compare two numbers stored as byte sequences
def compare(a, b):
    for i in reversed(range(len(a))):
        if a[i] > b[i]: return 1
        if a[i] < b[i]: return -1
    return 0

def shift_left_1(x):
    carry = 0
    for i in range(len(x)):
        new_carry = (x[i] >> 7) & 1
        x[i] = ((x[i] << 1) & 0xFF) | carry
        carry = new_carry

def get_bit(a, bit_index):
    byte_i = bit_index // 8
    bit_i  = bit_index % 8
    return (a[byte_i] >> bit_i) & 1

def set_bit(a, bit_index):
    byte_i = bit_index // 8
    bit_i  = bit_index % 8
    a[byte_i] |= (1 << bit_i)

def get_bits_cnt(x):
    cnt = 0
    while x > 0:
        cnt += 1
        x >>= 1
    return cnt

def subtract(a, b):
    borrow = 0
    for i in range(len(a)):
        tmp = a[i] - b[i] - borrow
        if tmp < 0:
            tmp += 256
            borrow = 1
        else:
            borrow = 0
        a[i] = tmp

# convert number x into a list of n bytes
def int_to_bytes_list(x, n):
    return list(x.to_bytes(n, byteorder='little'))
