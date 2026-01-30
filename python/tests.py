import unittest
from python.bignum import *
from python.montgomery import *
import logging

logging.disable(logging.INFO)

class TestDiv(unittest.TestCase):
    def test_div(self):
        self.assertEqual(div_bignum([0xff, 0xff], [0x02, 0x00]), ([0xff, 0x7f], [0x01, 0x00]))
        self.assertEqual(div_bignum([0x04, 0x00], [0x02, 0x00]), ([0x02, 0x00], [0x00, 0x00]))
        self.assertEqual(div_bignum([0x01, 0x05], [0x00, 0x10]), ([0x00, 0x00], [0x01, 0x05]))

    def test_montpro(self):
        self.assertEqual(mont_pro(0x0008, 0x001a, 0x0033), 0x0010)

    def test_modexp_1(self):
        self.assertEqual(mod_exp(34, 3, 49), 6)

    def test_modexp_exp_zero(self):
        self.assertEqual(mod_exp(17, 0, 31), 1)

    def test_modexp_a_one(self):
        self.assertEqual(mod_exp(1, 123, 97), 1)

    def test_modexp_a_ge_m(self):
        self.assertEqual(mod_exp(100, 5, 37), 10)

    def test_modexp_medium(self):
        self.assertEqual(mod_exp(7, 13, 33), 13)

    def test_modexp_larger_exp(self):
        self.assertEqual(mod_exp(5, 117, 19), 1)

    def test_modexp_crypto_style(self):
        self.assertEqual(mod_exp(17, 23, 97), 7)

class TestModInv(unittest.TestCase):
    def test_modular_inverse_k6(self, k=6):
        for x in range(1, 255, 2):
            with self.subTest(x=x):
                inv = mod2k_inv(x, k)
                self.assertEqual(x*inv % 2**k, 1)

    def test_modular_inverse_k32(self, k=32):
        for x in range(1, 255, 2):
            with self.subTest(x=x):
                inv = mod2k_inv(x, k)
                self.assertEqual(x*inv % 2**k, 1)

    def test_modular_inverse_k64(self, k=64):
        for x in range(1, 255, 2):
            with self.subTest(x=x):
                inv = mod2k_inv(x, k)
                self.assertEqual(x*inv % 2**k, 1)

if __name__ == "__main__":
    unittest.main()
