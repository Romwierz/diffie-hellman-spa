class DiffieHellman:
    def __init__(self, p, g):
        # public parameters
        self.p = p # prime number
        self.g = g # generator in Fp

        # public keys
        self.kA = None
        self.kB = None

        # private keys
        self.cA = None
        self.cB = None

        # shared secret
        self.d = None

    def set_private_keys(self, kA, kB):
        self.kA = kA
        self.kB = kB

    def compute_public_keys(self):
        self.cA = pow(self.g, self.kA, self.p)
        self.cB = pow(self.g, self.kB, self.p)

    def compute_shared_secret(self):
        d1 = pow(self.cA, self.kB, self.p)
        d2 = pow(self.cB, self.kA, self.p)

        assert d1 == d2, "Secrets do not match!"
        self.d = d1

def main():
    p = 23
    g = 5

    dh = DiffieHellman(p, g)

    dh.set_private_keys(kA=6, kB=15)
    dh.compute_public_keys()
    dh.compute_shared_secret()

    print("p =", dh.p)
    print("g =", dh.g)
    print("kA =", dh.kA)
    print("kB =", dh.kB)
    print("cA =", dh.cA)
    print("cB =", dh.cB)
    print("d  =", dh.d)

if __name__=="__main__":
    main()
