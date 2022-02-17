 
from cryptography.hazmat.primitives.asymmetric.x25519 import X25519PrivateKey, X25519PublicKey 
from cryptography.hazmat.primitives.serialization import Encoding, PublicFormat
import x25519 


class KeyPairString:
    def __init__(self, privateKey,  publicKey, note):
        self.privateKey = privateKey
        self.publicKey = publicKey
        self.note = note


TEST_KEY_PAIRS = {
    "A": KeyPairString(
        privateKey="0a857b942485fee18e4c55b6ec02fef6fc0c1c3872c10e669c7790f315fd3d0b",
        publicKey="7ff3e362f825ab868e20e767fe580d0311181632707e7c878cbeca0238d45b8b",note="A"),
    "B": KeyPairString(
        privateKey="a2582f40f38e32546df2cd8f25f19265386820347237c234a223a0d4704f3940",
        publicKey="45c59ad0c053925072f4503a39fe579ca8b7b8fa6bf0c7297e6db8f6585ee77f",note="B"),
    'C': KeyPairString(
        privateKey='77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a',
        publicKey='8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a',note="C")
}

def gb(val):
    return list(bytes.fromhex(val))

def gl(a):
    return list(a)
     
def test():
    for k, v in TEST_KEY_PAIRS.items(): 
        print( "\nTest to Generate Public Key" , v.note, "from private Key" )
        private_key = X25519PrivateKey.from_private_bytes( bytes.fromhex(v.privateKey))
        public_key_gen = private_key.public_key().public_bytes(encoding=Encoding.Raw, format=PublicFormat.Raw) 
        public_key = X25519PublicKey.from_public_bytes( bytes.fromhex(v.publicKey) ).public_bytes(encoding=Encoding.Raw, format=PublicFormat.Raw)

        pubkey = x25519.scalar_base_mult( bytes.fromhex(v.privateKey))
         
        if public_key == public_key_gen:
            print(f"Passed - Key pair {v.note} are a match")
        else: 
            print(f"Failed - Key pair {v.note} do not match")

        print("Original x22519 pk",gl(public_key)) 
        print("Lib 1 x22519 Go", gl(pubkey))
        print("Lib 2 x22519 generated", gl(public_key_gen)) 
         



test()
