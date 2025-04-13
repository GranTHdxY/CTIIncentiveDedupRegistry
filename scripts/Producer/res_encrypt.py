# coding:utf-8
import base64
# 对称密钥加密

from Crypto.PublicKey import RSA as rsa
from Crypto.Cipher import PKCS1_v1_5

pub_key_str = """-----BEGIN RSA PUBLIC KEY-----
##
-----END RSA PUBLIC KEY-----"""

priv_key_str = """-----BEGIN RSA PRIVATE KEY-----
##
-----END RSA PRIVATE KEY-----"""


def rsa_long_encrypt(pub_key_str, msg, length=128):
    """
    单次加密串的长度最大为 (key_size/8)-11
    1024bit的证书用100， 2048bit的证书用 200
    """
    pubobj = rsa.importKey(pub_key_str)
    pubobj = PKCS1_v1_5.new(pubobj)
    res_byte = bytes()
    for i in range(0, len(msg), length):
        res_byte += pubobj.encrypt(msg[i:i + length])
    return base64.b64encode(res_byte)


def rsa_long_decrypt(priv_key_str, msg, length=256):
    """
    1024bit的证书用128，2048bit证书用256位
    """
    privobj = rsa.importKey(priv_key_str)
    privobj = PKCS1_v1_5.new(privobj)
    res_byte = bytes()
    msg = base64.b64decode(msg)
    for i in range(0, len(msg), length):
        res_byte += privobj.decrypt(msg[i:i + length], 0)
    return res_byte.decode('utf-8')

if __name__ == "__main__":
    with open('cti.json') as f:
        msg = f.read()
    msg = msg.encode('utf-8')
    enres = rsa_long_encrypt(pub_key_str, msg)
    print(enres)
    deres = rsa_long_decrypt(priv_key_str, enres)
    print(deres)
    print(msg.decode('utf-8') == deres)

    