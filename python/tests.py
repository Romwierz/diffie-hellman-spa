import unittest
from python.bignum import *
from python.montgomery import *

class TestDiv(unittest.TestCase):
    def test_div(self):
        self.assertEqual(div_bignum([0xff, 0xff], [0x02, 0x00]), ([0xff, 0x7f], [0x01, 0x00]))
        self.assertEqual(div_bignum([0x04, 0x00], [0x02, 0x00]), ([0x02, 0x00], [0x00, 0x00]))
        self.assertEqual(div_bignum([0x01, 0x05], [0x00, 0x10]), ([0x00, 0x00], [0x01, 0x05]))

    def test_montpro(self):
        self.assertEqual(mont_pro(0x0008, 0x001a, 0x0033), 0x0010)

if __name__ == "__main__":
    unittest.main()
