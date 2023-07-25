# 基于Python的Rclone Crypt储存解密


<div style="text-align: center;">
    <img src="/blog_images/rclone_python.png" alt="rclone_python.png">
</div>

[Rclone](https://rclone.org/)支持将其他储存添加为[Crypt](https://rclone.org/crypt/)类型的储存，用于加密存储的文件。

本文旨在简要介绍Rclone Crypt储存的加密原理，并给出Python实现的解密代码。在本文基础上，编写了rclone加密/解密代码[rclone_crypt_py](https://github.com/Ftbom/rclone_crypt_py)。

## 加密密码

rclone加密有两个可设置的密码，分别记作passwd1和passwd2。其中passwd2可不设置，若不设置则使用默认值，默认值为`\xA8\x0D\xF4\x3A\x8F\xBD\x03\x08\xA7\xCA\xB8\x3E\x58\x1F\x86\xB1`

基于passwd1和passwd2，生成用于文件加密和文件名加密的密钥。生成密钥的算法为[scrypt](https://en.wikipedia.org/wiki/Scrypt)，scrypt算法的参数为`N=16384, r=8, p=1`，生成密钥的长度为80bytes。其中前32bytes用于文件加密，32-64bytes和64bytes之后的数据用于文件名加密。

通过passwd1和passwd2生成加密密钥的代码如下：

```python
from Crypto.Protocol.KDF import scrypt

KEY_SIZE = 32 + 32 + 16 # scrypt生成密钥的长度
DEFAULT_SALT = b"\xA8\x0D\xF4\x3A\x8F\xBD\x03\x08\xA7\xCA\xB8\x3E\x58\x1F\x86\xB1" # rclone默认salt

salt = passwd2 if passwd2 else DEFAULT_SALT
key = scrypt(passwd, salt, KEY_SIZE, 16384, 8, 1)
dataKey = key[:32]
nameKey = key[32 : 64]
nameTweak = key[64 :]
```

## 文件加密

加密后的文件由两部分组成，文件头和数据块。

其中文件头分为两部分：
* 固定rclone文件头
  >8 bytes，RCLONE\x00\x00
* 用于数据块解密的Nonce
  >24 bytes

文件头中的Nonce是加密时系统随机生成的，用于初始数据块加密。

每加密一个数据块，Nonce改变一次，以确保每个数据块的Nonce不同。在rclone的加密算法中，更改Nonce的方法为最左一位byte数字加一。实现代码为：

```python
# 单byte加1
def byte_increment(byte: int) -> int:
	if (byte > 255):
		raise ValueError('byte must be in range(0, 256)')
	return (byte + 1) if (byte < 255) else 0

# nonce加1
def nonce_increment(nonce: bytes, start: int = 0) -> bytes:
	nonce_array = bytearray(nonce) # 转为数组
	# 加1操作
	for i in range(start, len(nonce)):
		digit = nonce_array[i]
		newDigit = byte_increment(digit)
		nonce_array[i] = newDigit
		if newDigit >= digit:
			break
	return bytes(nonce_array) #转回bytes
```

除了最后一个数据块外，每个数据块包含16 + 64 * 1024bytes数据，其中16bytes是用于验证的数据头，64 * 1024bytes是64 * 1024bytes原始数据加密后得到的数据。

文件块的加密算法是[Nacl算法](https://nacl.cr.yp.to/)。

使用python实现的解密代码为：

```python
import nacl.secret

box = nacl.secret.SecretBox(dataKey)

def file_decrypt(self, input_file_path: str, output_file_path: str) -> None:
	try:
		input_file = open(input_file_path, 'rb')
	except:
		raise FileNotFoundError('input file not found')
	try:
		output_file = open(output_file_path, 'wb')
	except:
		raise ValueError('failed to write output file')
	# 读取头
	if not input_file.read(FILEMAGIC_SIZE) == b'RCLONE\x00\x00': # 标准头
		raise ValueError('not encrypted rclone file')
	Nonce = input_file.read(FILENONCE_SIZE)
	# 读取文件块
	# 16为头
	# 64kb数据
	input_bytes = input_file.read(BLOCKDATA_SIZE + BLOCKHEADER_SIZE)
	try:
		while (input_bytes):
			output_file.write(box.decrypt(input_bytes, Nonce))
			Nonce = nonce_increment(Nonce)
			input_bytes = input_file.read(BLOCKDATA_SIZE + BLOCKHEADER_SIZE)
	except:
		raise RuntimeError('failed to decrypt file')
	input_file.close()
	output_file.close()
```

## 文件名加密

文件名有两种加密方式：
* standard
  >1. 文件名补全为16bytes的倍数，补全算法为[PKCS#7](https://en.wikipedia.org/wiki/PKCS_7)
  >2. 使用[EME(ECB-Mix-ECB)](https://eprint.iacr.org/2003/147.pdf)算法对补全后的文件名进行加密
  >>使用生成的nameKey和nameTweak进行加密
  >3. 对加密结果进行base32编码
  >4. 去除结果中的`=`
* obfuscate
  >简单的文件名混淆，每个文件名都有一个对应的混淆距离。加密后的文件名为：`<混淆距离>.<混淆后文件名>`

standard解密代码：

```python
from Crypto.Cipher import AES
from .eme import Decrypt

cipher = AES.new(nameKey, AES.MODE_ECB)

def name_standard_decrypt(self, filename: str) -> str:
	if filename == '':
		return ''
	padding_num = 8 - len(filename) % 8
	filename = filename + padding_num * '=' # 添加padding
	filename = base64.b32hexdecode(filename.upper()) # base32解码
	if len(filename) == 0:
		raise ValueError('too short to decrypt')
	if len(filename) >= 2048:
		raise ValueError('too long to decrypt')
	return unpad(Decrypt(cipher, nameTweak, filename), 16, style = 'pkcs7').decode('utf-8') # EME解密
```

obfuscate解密代码：

```python
def name_obfuscate_decrypt(self, filename: str) -> str:
	if filename == '':
		return ''
	pos = filename.find('.')
	if pos == -1:
		raise ValueError('not obfuscate encrypted filename')
	num = filename[: pos]
	if num == '!':
		return filename[pos + 1 :]
	try:
		dir_ = int(num)
	except:
		raise ValueError('not obfuscate encrypted filename')
	for i in self.__nameKey:
		dir_ = dir_ + i
	inQuote = False
	out_filename = ''
	for str_ in filename[pos + 1 :]:
		code = ord(str_)
		if inQuote:
			out_filename = out_filename + str_
		elif code == ord('!'):
			inQuote = True
		elif code >= ord('0') and code <= ord('9'):
			thisdir = (dir_ % 9) + 1
			newRune = ord('0') + code - '0' - thisdir
			if newRune < ord('0'):
				newRune = newRune + 10
			out_filename = out_filename + chr(newRune)
		elif (code >= ord('A') and code <= ord('Z')) or (code >= ord('a') and code <= ord('z')):
			thisdir = dir_ % 25 + 1
			pos = code - ord('A')
			if pos >= 26:
				pos = pos -6
			pos = pos - thisdir
			if pos < 0:
				pos = pos + 52
			if pos >= 26:
				pos = pos + 6
			out_filename = out_filename + chr(ord('A') + pos)
		elif code >= 0xa0 and code <= 0xff:
			thisdir = (dir_ % 95) + 1
			newRune = 0xa0 + code - 0xa0 - thisdir
			if newRune < 0xa0:
				newRune = newRune + 96
			out_filename = out_filename + chr(newRune)
		elif code >= 0x100:
			thisdir = (dir_ % 127) + 1
			base = code - code % 256
			newRune = base + code - base - thisdir
			if newRune < base:
				newRune = newRune + 256
			out_filename = out_filename + chr(newRune)
		else:
			out_filename = out_filename + chr(code)
	return out_filename
```
