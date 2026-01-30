from utils import get_bits_cnt
import logging

logging.basicConfig(level=logging.DEBUG, format="%(message)s")

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
        logging.debug("index %d:", i)
        logging.debug("\tresult = %#x", result)
        logging.debug("\ta = %#x", a)
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
        logging.debug("index %d:", i)
        logging.debug("\tx = %#x", _x)
    
    return mont_convert_out(_x, m)

def newton_formula(x, y):
    return y * (2 - y * x)

def mod2k_inv(x, k):
    '''
    Calculate the modular inverse 2^k of x.

    The Newton-Raphson method is used that requires x to be odd.
    The method is about choosing the initial guess value of the inverse y for a certain precision,
    that is the amount of bits for which y is the inverse of x, and calling the recurrence formula
    until y converges, meaning it achieves the target precision of k bits.
    The most basic case is the initial precision of 1 bit, for which the value of the inverse is 1.
    With each iteration of the Newton formula the precision (number of bits) is doubled.
    '''
    assert x & 1 == 1, 'The number to be inverted x is not odd!'

    y = 1
    bits = 1

    while bits < k:
        bits *= 2
        logging.debug("bits = %d:", bits)

        y = newton_formula(x, y)
        logging.debug("\ty = %d", y)

        # quick modulo^bits by masking the bits of precision
        mask = (1 << bits) - 1 
        y &= mask
        logging.debug("\ty = y mod 2^%d = %d", bits, y)

    logging.debug("\nThe modulo 2^%d of x = %d is:", k, x)
    logging.debug("\ty = y mod 2^%d = %d", k, y & ((1 << k) - 1))
    return y & ((1 << k) - 1)
