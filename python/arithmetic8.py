def add8(a, b, carry_in = 0):
    total = a + b + carry_in
    result = total & 0xFF
    carry_out = 1 if total > 0xFF else 0
    return result, carry_out

def sub8(a, b, borrow_in = 0):
    total = a - b - borrow_in
    result = total & 0xFF
    borrow_out = 1 if total < 0 else 0
    return result, borrow_out

def mul8(a, b):
    product = a * b
    lo = product & 0xFF
    hi = (product >> 8) & 0xFF
    return lo, hi

def div8(a, b):
    return divmod(a, b)
