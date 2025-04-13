# coding:utf-8
import base64
# 对称密钥加密

from Crypto.PublicKey import RSA as rsa
from Crypto.Cipher import PKCS1_v1_5

pub_key_str = """-----BEGIN RSA PUBLIC KEY-----
MIIBCgKCAQEAuw4T755fepEyXTM66pzf6nv8NtnukQTMGnhmBFIFHp/P2vEpxjXU
BBDUpzKkVFR3wuK9O1FNmRDAGNGYC0N/9cZNdhykA1NixJfKQzncN31VJTmNqJNZ
W0x7H9ZGoh2aE0zCCZpRlC1Rf5rL0SVlBoQkn/n9LnYFwyLLIK5/d/y/NZVL6Z6L
cyvga0zRajamLIjY0Dy/8YIwVV6kaSsHeRv2cOB03eam6gbhLGIz/l8wuJhIn1rO
yJLQ36IOJymbbNmcC7+2hEQJP40qLvH7hZ1LaAkgQUHjfi8RvH2T1Jmce7XGPxCo
Ed0yfeFz+pL1KeSWNey6cL3N5hJZE8EntQIDAQAB
-----END RSA PUBLIC KEY-----"""

priv_key_str = """-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAuw4T755fepEyXTM66pzf6nv8NtnukQTMGnhmBFIFHp/P2vEp
xjXUBBDUpzKkVFR3wuK9O1FNmRDAGNGYC0N/9cZNdhykA1NixJfKQzncN31VJTmN
qJNZW0x7H9ZGoh2aE0zCCZpRlC1Rf5rL0SVlBoQkn/n9LnYFwyLLIK5/d/y/NZVL
6Z6Lcyvga0zRajamLIjY0Dy/8YIwVV6kaSsHeRv2cOB03eam6gbhLGIz/l8wuJhI
n1rOyJLQ36IOJymbbNmcC7+2hEQJP40qLvH7hZ1LaAkgQUHjfi8RvH2T1Jmce7XG
PxCoEd0yfeFz+pL1KeSWNey6cL3N5hJZE8EntQIDAQABAoIBAGim1ayIFK8EMQNH
uDyui/Aqcc9WWky0PGTK23irUsXxb1708gQ89WNY70Cj6qBrqZ1VMb3QHPP4FSFN
kh0rJJoi2g+ssm5R5r5KlhTKeFRrQInVC1Y3KhUUUwZa4aWtnhgSJ7Urq1yVhjU4
K7PVkhH1OHBwcp/d1Bd6jd65AgPkY63P+WpcARJkClmQ1RhgoRwThyJdpKrV4/gO
ha0AUGlJNRNvRwiZxP0zaI5C8RdrG96SnVpeYOcD0z/M1HVlkoYMXsXLKttwLfpK
88Igtm6ZJwRpfuMF5VA+9hHaYGCBdGz0B/rMp2fc+EtrOavYQGrWIWi2RL1Qk6Rt
BUyeTgECgYEA9anj4n/cak1MT+hbNFsL31mJXryl1eVNjEZj/iPMztpdS15CmFgj
Kjr9UuintjSiK7Is43nZUWWyP1XQjRhVi2uP7PRIv92QNl/YteWD6tYCInJHKe2J
QqYyZrElezsdayXb5DK6bi1UIYYji90g79N7x6pOR0UnQNQUXTv+Y8ECgYEAwuzl
6Ez4BSXIIL9NK41jfNMa73Utfl5oO1f6mHM2KbILqaFE76PSgEeXDbOKdcjCbbqC
KCGjwyPd+Clehg4vkYXTq1y2SQGHwfz7DilPSOxhPY9ND7lGbeNzDUK4x8xe52hd
MWKdgqeqCK83e5D0ihzRiMah8dbxmlfLAOZ3sPUCgYEA0dT9Czg/YqUHq7FCReQG
rg3iYgMsexjTNh/hxO97PqwRyBCJPWr7DlU4j5qdteobIsubv+kSEI6Ww7Ze3kWM
u/tyAeleQlPTnD4d8rBKD0ogpJ+L3WpBNaaToldpNmr149GAktgpmXYqSEA1GIAW
ZAL11UPIfOO6dYswobpevYECgYEApSosSODnCx2PbMgL8IpWMU+DNEF6sef2s8oB
aam9zCi0HyCqE9AhLlb61D48ZT8eF/IAFVcjttauX3dWQ4rDna/iwgHF5yhnyuS8
KayxJJ4+avYAmwEnfzdJpoPRpGI0TCovRQhFZI8C0Wb+QTJ7Mofmt9lvIUc64sff
GD0wT/0CgYASMf708dmc5Bpzcis++EgMJVb0q+ORmWzSai1NB4bf3LsNS6suWNNU
zj/JGtMaGvQo5vzGU4exNkhpQo8yUU5YbHlA8RCj7SYkmP78kCewEqxlx7dbcuj2
LAPWpiDca8StTfEphoKEVfCPHaUk0MlBHR4lCrnAkEtz23vhZKWhFw==
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

    