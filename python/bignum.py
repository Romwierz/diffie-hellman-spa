from .arithmetic8 import *
from .utils import *

def add_bignum(a, b):
    n = max(len(a), len(b))
    result = [0] * n
    carry = 0
    for i in range(n):
        result[i], carry = add8(a[i], b[i], carry)
    return result, carry

def sub_bignum(a, b):
    n = max(len(a), len(b))
    result = [0] * n
    borrow = 0
    for i in range(n):
        result[i], borrow = sub8(a[i], b[i], borrow)
    return result, borrow

def mul_bignum(a, b):
    n = len(a)
    m = len(b)
    result = [0] * (n + m)
    for i in range(n):
        carry = 0
        for j in range(m):
            lo, hi = mul8(a[i], b[j])
            result[i + j], c = add8(result[i + j], lo, carry)
            carry = hi + c
        result[i + m], _ = add8(result[i + m], carry)
    return result

def div_bignum(a, b):
    n = max(len(a), len(b))
    quotient = [0] * n
    remainder = [0] * n
    n_bits = n * 8

    for bit in reversed(range(n_bits)):
        shift_left_1(remainder)
        remainder[0] |= get_bit(a, bit)
        if compare(remainder, b) >= 0:
            remainder, _ = sub_bignum(remainder, b)
            set_bit(quotient, bit)
    return quotient, remainder

def mod_bignum(a, m):
    _, x = div_bignum(a, m)
    return x
