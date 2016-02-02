#include "openssl/dh.h"
#include "openssl/rc4.h"
#include <lua.h>
#include <lauxlib.h>
#include <time.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <math.h>
void setLuaDH(DH* dh,lua_State *tolua_S);
DH* getLuaDH(lua_State *tolua_S);

typedef union uwb {
	unsigned w;
	unsigned char b[4];
} WBunion;
 
typedef unsigned Digest[4];
 
static unsigned 
f0( unsigned abcd[] ){
	return ( abcd[1] & abcd[2]) | (~abcd[1] & abcd[3]);}
 
static unsigned
f1( unsigned abcd[] ){
	return ( abcd[3] & abcd[1]) | (~abcd[3] & abcd[2]);}
 
static unsigned 
f2( unsigned abcd[] ){
	return  abcd[1] ^ abcd[2] ^ abcd[3];}
 
static unsigned 
f3( unsigned abcd[] ){
	return abcd[2] ^ (abcd[1] |~ abcd[3]);}
 
typedef unsigned (*DgstFctn)(unsigned a[]);
 
static unsigned *
calcKs( unsigned *k)
{
	double s, pwr;
	int i;
 
	pwr = pow( 2, 32);
	for (i=0; i<64; i++) {
		s = fabs(sin(1+i));
		k[i] = (unsigned)( s * pwr );
	}
	return k;
}
 
// ROtate v Left by amt bits
static unsigned 
rol( unsigned v, short amt )
{
	unsigned  msk1 = (1<<amt) -1;
	return ((v>>(32-amt)) & msk1) | ((v<<amt) & ~msk1);
}
 
static unsigned *
md5( const char *msg, int mlen) 
{
	static Digest h0 = { 0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476 };
//    static Digest h0 = { 0x01234567, 0x89ABCDEF, 0xFEDCBA98, 0x76543210 };
	static DgstFctn ff[] = { &f0, &f1, &f2, &f3 };
	static short M[] = { 1, 5, 3, 7 };
	static short O[] = { 0, 1, 5, 0 };
	static short rot0[] = { 7,12,17,22};
	static short rot1[] = { 5, 9,14,20};
	static short rot2[] = { 4,11,16,23};
	static short rot3[] = { 6,10,15,21};
	static short *rots[] = {rot0, rot1, rot2, rot3 };
	static unsigned kspace[64];
	static unsigned *k;
 
	static Digest h;
	Digest abcd;
	DgstFctn fctn;
	short m, o, g;
	unsigned f;
	short *rotn;
	union {
		unsigned w[16];
		char     b[64];
	}mm;
	int os = 0;
	int grp, grps, q, p;
	unsigned char *msg2;
 
	if (k==NULL) k= calcKs(kspace);
 
	for (q=0; q<4; q++) h[q] = h0[q];   // initialize
 
	{
		grps  = 1 + (mlen+8)/64;
		msg2 = (unsigned char *)malloc( 64*grps);
		memcpy( msg2, msg, mlen);
		msg2[mlen] = (unsigned char)0x80;  
		q = mlen + 1;
		while (q < 64*grps){ msg2[q] = 0; q++ ; }
		{
//            unsigned char t;
			WBunion u;
			u.w = 8*mlen;
//            t = u.b[0]; u.b[0] = u.b[3]; u.b[3] = t;
//            t = u.b[1]; u.b[1] = u.b[2]; u.b[2] = t;
			q -= 8;
			memcpy(msg2+q, &u.w, 4 );
		}
	}
 
	for (grp=0; grp<grps; grp++)
	{
		memcpy( mm.b, msg2+os, 64);
		for(q=0;q<4;q++) abcd[q] = h[q];
		for (p = 0; p<4; p++) {
			fctn = ff[p];
			rotn = rots[p];
			m = M[p]; o= O[p];
			for (q=0; q<16; q++) {
				g = (m*q + o) % 16;
				f = abcd[1] + rol( abcd[0]+ fctn(abcd) + k[q+16*p] + mm.w[g], rotn[q%4]);
 
				abcd[0] = abcd[3];
				abcd[3] = abcd[2];
				abcd[2] = abcd[1];
				abcd[1] = f;
			}
		}
		for (p=0; p<4; p++)
			h[p] += abcd[p];
		os += 64;
	}
 
	if( msg2 )
		free( msg2 );
 
	return h;
}    




#define SMALL_CHUNK 256
#define CHECK_GE(a, b) CHECK((a) >= (b))
#define CHECK(exp)   do { if (!(exp)) abort(); } while (0)

static const unsigned char group_modp1[] = {
  0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xc9, 0x0f,
  0xda, 0xa2, 0x21, 0x68, 0xc2, 0x34, 0xc4, 0xc6, 0x62, 0x8b,
  0x80, 0xdc, 0x1c, 0xd1, 0x29, 0x02, 0x4e, 0x08, 0x8a, 0x67,
  0xcc, 0x74, 0x02, 0x0b, 0xbe, 0xa6, 0x3b, 0x13, 0x9b, 0x22,
  0x51, 0x4a, 0x08, 0x79, 0x8e, 0x34, 0x04, 0xdd, 0xef, 0x95,
  0x19, 0xb3, 0xcd, 0x3a, 0x43, 0x1b, 0x30, 0x2b, 0x0a, 0x6d,
  0xf2, 0x5f, 0x14, 0x37, 0x4f, 0xe1, 0x35, 0x6d, 0x6d, 0x51,
  0xc2, 0x45, 0xe4, 0x85, 0xb5, 0x76, 0x62, 0x5e, 0x7e, 0xc6,
  0xf4, 0x4c, 0x42, 0xe9, 0xa6, 0x3a, 0x36, 0x20, 0xff, 0xff,
  0xff, 0xff, 0xff, 0xff, 0xff, 0xff };
static const unsigned char group_modp5[] = {
  0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xc9, 0x0f,
  0xda, 0xa2, 0x21, 0x68, 0xc2, 0x34, 0xc4, 0xc6, 0x62, 0x8b,
  0x80, 0xdc, 0x1c, 0xd1, 0x29, 0x02, 0x4e, 0x08, 0x8a, 0x67,
  0xcc, 0x74, 0x02, 0x0b, 0xbe, 0xa6, 0x3b, 0x13, 0x9b, 0x22,
  0x51, 0x4a, 0x08, 0x79, 0x8e, 0x34, 0x04, 0xdd, 0xef, 0x95,
  0x19, 0xb3, 0xcd, 0x3a, 0x43, 0x1b, 0x30, 0x2b, 0x0a, 0x6d,
  0xf2, 0x5f, 0x14, 0x37, 0x4f, 0xe1, 0x35, 0x6d, 0x6d, 0x51,
  0xc2, 0x45, 0xe4, 0x85, 0xb5, 0x76, 0x62, 0x5e, 0x7e, 0xc6,
  0xf4, 0x4c, 0x42, 0xe9, 0xa6, 0x37, 0xed, 0x6b, 0x0b, 0xff,
  0x5c, 0xb6, 0xf4, 0x06, 0xb7, 0xed, 0xee, 0x38, 0x6b, 0xfb,
  0x5a, 0x89, 0x9f, 0xa5, 0xae, 0x9f, 0x24, 0x11, 0x7c, 0x4b,
  0x1f, 0xe6, 0x49, 0x28, 0x66, 0x51, 0xec, 0xe4, 0x5b, 0x3d,
  0xc2, 0x00, 0x7c, 0xb8, 0xa1, 0x63, 0xbf, 0x05, 0x98, 0xda,
  0x48, 0x36, 0x1c, 0x55, 0xd3, 0x9a, 0x69, 0x16, 0x3f, 0xa8,
  0xfd, 0x24, 0xcf, 0x5f, 0x83, 0x65, 0x5d, 0x23, 0xdc, 0xa3,
  0xad, 0x96, 0x1c, 0x62, 0xf3, 0x56, 0x20, 0x85, 0x52, 0xbb,
  0x9e, 0xd5, 0x29, 0x07, 0x70, 0x96, 0x96, 0x6d, 0x67, 0x0c,
  0x35, 0x4e, 0x4a, 0xbc, 0x98, 0x04, 0xf1, 0x74, 0x6c, 0x08,
  0xca, 0x23, 0x73, 0x27, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
  0xff, 0xff };

static const unsigned char two_generator[] = { 2 };

typedef struct dh_st DH;

//static DH* dh = NULL;

static int
lcreatedh(lua_State *L) {
//	if(dh) {
//		DH_free(dh);
//		dh = NULL;
//	}
	DH* dh = DH_new();
	dh->p = BN_bin2bn((const unsigned char*)group_modp1, sizeof(group_modp1), 0);
	dh->g = BN_bin2bn((const unsigned char*)two_generator, 1, 0);
	int codes;
	if (!DH_check(dh, &codes)) {
		assert(0);
	}
	if (!DH_generate_key(dh)) {
		assert(0);
	}
    setLuaDH(dh, L);
	return 0;
}

static int
lgetpublickey(lua_State *L) {
    DH* dh = getLuaDH(L);
	if (!dh) {
		assert(0);
	}
	if (dh->pub_key == NULL) {
		assert(0);
	}
	int dataSize = BN_num_bytes(dh->pub_key);
	char* data = (char*)malloc(dataSize);
	BN_bn2bin(dh->pub_key, (unsigned char*)data);
	lua_pushlstring(L, data, dataSize);
	free(data);
	return 1;
}

static int
lcomputesecret(lua_State *L) {
    DH* dh = getLuaDH(L);
	if (!dh) {
		assert(0);
	}
	size_t len = 0;
	const unsigned char *buffer = (const unsigned char *)luaL_checklstring(L, 1, &len);
	BIGNUM* key = BN_bin2bn(buffer, len, 0);
	int dataSize = DH_size(dh);
	char* data = (char*)malloc(dataSize);
	int size = DH_compute_key((unsigned char*)data,key,dh);
	if (size == -1) {
		int checkResult;
		int checked;

		checked = DH_check_pub_key(dh, key, &checkResult);
		BN_free(key);
		free(data);

		if (!checked) {
			assert(0);
		} else if (checkResult) {
		  if (checkResult & DH_CHECK_PUBKEY_TOO_SMALL) {
				assert(0);
		  } else if (checkResult & DH_CHECK_PUBKEY_TOO_LARGE) {
				assert(0);
		  } else {
				assert(0);
		  }
		} else {
			assert(0);
		}
	}

	BN_free(key);
	CHECK_GE(size, 0);

	// DH_size returns number of bytes in a prime number
	// DH_compute_key returns number of bytes in a remainder of exponent, which
	// may have less bytes than a prime number. Therefore add 0-padding to the
	// allocated buffer.
	if (size != dataSize) {
		CHECK(dataSize > size);
		memmove(data + dataSize - size, data, size);
		memset(data, 0, dataSize - size);
	}
	lua_pushlstring(L, data, dataSize);
	free(data);
	return 1;
}



static int
lrc4(lua_State *L) {
	size_t key_buf_len = 0;
	const unsigned char *key_buf = (const unsigned char *)luaL_checklstring(L, 1, &key_buf_len);

	size_t datalen = 0;
	const unsigned char *in = (const unsigned char *)luaL_checklstring(L, 2, &datalen);

	unsigned char * out = (unsigned char *)malloc(datalen);
	memmove(out, in, datalen);

	unsigned char *md = (unsigned char *)md5((char *)key_buf, key_buf_len);

	RC4_KEY rc4_key;
	RC4_set_key(&rc4_key, 16, md);
	RC4(&rc4_key, datalen, in, out);

	lua_pushlstring(L,(char *)out, datalen);
	free(out);
	return 1;
}


// base64

static int
lb64encode(lua_State *L) {
	static const char* encoding = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	size_t sz = 0;
	const uint8_t * text = (const uint8_t *)luaL_checklstring(L, 1, &sz);
	int encode_sz = (sz + 2)/3*4;
	char tmp[SMALL_CHUNK];
	char *buffer = tmp;
	if (encode_sz > SMALL_CHUNK) {
		buffer = (char *)lua_newuserdata(L, encode_sz);
	}
	int i,j;
	j=0;
	for (i=0;i<(int)sz-2;i+=3) {
		uint32_t v = text[i] << 16 | text[i+1] << 8 | text[i+2];
		buffer[j] = encoding[v >> 18];
		buffer[j+1] = encoding[(v >> 12) & 0x3f];
		buffer[j+2] = encoding[(v >> 6) & 0x3f];
		buffer[j+3] = encoding[(v) & 0x3f];
		j+=4;
	}
	int padding = sz-i;
	uint32_t v;
	switch(padding) {
	case 1 :
		v = text[i];
		buffer[j] = encoding[v >> 2];
		buffer[j+1] = encoding[(v & 3) << 4];
		buffer[j+2] = '=';
		buffer[j+3] = '=';
		break;
	case 2 :
		v = text[i] << 8 | text[i+1];
		buffer[j] = encoding[v >> 10];
		buffer[j+1] = encoding[(v >> 4) & 0x3f];
		buffer[j+2] = encoding[(v & 0xf) << 2];
		buffer[j+3] = '=';
		break;
	}
	lua_pushlstring(L, buffer, encode_sz);
	return 1;
}

static int
b64index(uint8_t c) {
	static const int decoding[] = {62,-1,-1,-1,63,52,53,54,55,56,57,58,59,60,61,-1,-1,-1,-2,-1,-1,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,-1,-1,-1,-1,-1,-1,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51};
	int decoding_size = sizeof(decoding)/sizeof(decoding[0]);
	if (c<43) {
		return -1;
	}
	c -= 43;
	if (c>=decoding_size)
		return -1;
	return decoding[c];
}

static int
lb64decode(lua_State *L) {
	size_t sz = 0;
	const uint8_t * text = (const uint8_t *)luaL_checklstring(L, 1, &sz);
	int decode_sz = (sz+3)/4*3;
	char tmp[SMALL_CHUNK];
	char *buffer = tmp;
	if (decode_sz > SMALL_CHUNK) {
		buffer = (char *)lua_newuserdata(L, decode_sz);
	}
	int i,j;
	int output = 0;
	for (i=0;i<sz;) {
		int padding = 0;
		int c[4];
		for (j=0;j<4;) {
			if (i>=sz) {
				return luaL_error(L, "Invalid base64 text");
			}
			c[j] = b64index(text[i]);
			if (c[j] == -1) {
				++i;
				continue;
			}
			if (c[j] == -2) {
				++padding;
			}
			++i;
			++j;
		}
		uint32_t v;
		switch (padding) {
		case 0:
			v = (unsigned)c[0] << 18 | c[1] << 12 | c[2] << 6 | c[3];
			buffer[output] = v >> 16;
			buffer[output+1] = (v >> 8) & 0xff;
			buffer[output+2] = v & 0xff;
			output += 3;
			break;
		case 1:
			if (c[3] != -2 || (c[2] & 3)!=0) {
				return luaL_error(L, "Invalid base64 text");
			}
			v = (unsigned)c[0] << 10 | c[1] << 4 | c[2] >> 2 ;
			buffer[output] = v >> 8;
			buffer[output+1] = v & 0xff;
			output += 2;
			break;
		case 2:
			if (c[3] != -2 || c[2] != -2 || (c[1] & 0xf) !=0)  {
				return luaL_error(L, "Invalid base64 text");
			}
			v = (unsigned)c[0] << 2 | c[1] >> 4;
			buffer[output] = v;
			++ output;
			break;
		default:
			return luaL_error(L, "Invalid base64 text");
		}
	}
	lua_pushlstring(L, buffer, output);
	return 1;
}



// defined in lsha1.c
int lsha1(lua_State *L);

#if LUA_VERSION_NUM == 501

static void
	luaL_checkversion(lua_State *L) {
		if (lua_pushthread(L) == 0) {
			luaL_error(L, "Must require in main thread");
		}
		lua_setfield(L, LUA_REGISTRYINDEX, "mainthread");
}
#endif

#if LUA_VERSION_NUM < 502
#define luaL_newlib(L,l) (lua_newtable(L), luaL_register(L,NULL,l))
#endif

int
luaopen_dhcrypt(lua_State *L) {
	luaL_checkversion(L);
	luaL_Reg l[] = {
		{ "createdh", lcreatedh },
		{ "getpublickey", lgetpublickey },
		{ "computesecret", lcomputesecret },
		{ "rc4", lrc4 },
		{ "base64encode", lb64encode },
		{ "base64decode", lb64decode },
		{ NULL, NULL },
	};
	#if LUA_VERSION_NUM < 502
		luaL_register(L, "dhcrypt", l);
	#else
		luaL_newlib(L,l);
	#endif
	return 1;
}
