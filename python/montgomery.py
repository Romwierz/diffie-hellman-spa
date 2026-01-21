from utils import get_bits_cnt

# modulus m must be odd and a,b,n < 2^k
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
        # print(i, end=":\n")
        # print("    result =", hex(result))
        # print("    a      =", hex(a))
    if result >= m:
        result -= m

    return result

def mont_convert_in(x, m):
    n_bits = get_bits_cnt(m)
    R = 1 << n_bits
    return (x * R) % m

def mont_convert_out(x, m):
    return mont_pro(x, 1, m)

def mod_exp(a, e, m):
    _a = mont_convert_in(a, m)
    _x = mont_convert_in(1, m)

    n_bits = get_bits_cnt(e)

    for i in reversed(range(n_bits)):
        _x = mont_pro(_x, _x, m)
        if e & (1 << i):
            _x = mont_pro(_a, _x, m)
        print(i, end=":\n")
        print("    x =", hex(_x))
    
    return mont_convert_out(_x, m)
