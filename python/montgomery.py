from utils import get_bits_cnt

def mont_pro(a, b, m):
    n_bits = get_bits_cnt(m)
    result = 0
    for i in range(n_bits):
        if a & 1:
            result += b
        if result & 1:
            result += m
        result >>= 1
        a >>= 1
        print(i, end=":\n")
        print("    result =", hex(result))
        print("    a      =", hex(a))
    if result >= m:
        result -= m

    return result

def mont_convert_in(x, m):
    n_bits = get_bits_cnt(m)
    R = 1 << n_bits
    return (x * R) % m

def mont_convert_out(x, m):
    return mont_pro(x, 1, m)

