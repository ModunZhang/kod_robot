//
//  main.cpp
//  kod_client
//
//  Created by gaozhou on 15/1/19.
//  Copyright (c) 2015年 batcat. All rights reserved.
//

#include <iostream>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <assert.h>
#include <signal.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <fcntl.h>
#include <stdlib.h>
#include <pthread.h>
#include <libgen.h>
#include <iostream>
#include <sstream>
#include <math.h>
#include <stdio.h>
#include <string.h>
#include <semaphore.h>

extern "C"{	
	#include "../lua/lua.h"
	#include "../lua/lualib.h"
	#include "../lua/lauxlib.h"
	#include "../tolua/tolua++.h"
	#include "../tolua/tolua_fix.h"
    #include "../openssl/dh.h"
    #include "../openssl/rc4.h"
}
#include "Common.h"
#include "CTimerHandle.h"
#include "../lua_engine/CCLuaEngine.h"
#if USE_LUA_WEBSOCKET
#include "CCPomeloWebSocket.h"
#include "Lua_web_socket.h"
#endif
#if (USE_LUA_WEBSOCKET == 0)
extern "C" {
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

unsigned *
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

void 
freeDh(void *d) {
    if(d) {
        DH_free((DH*)d);
    }
}

void *
createdh() {
    DH* d = DH_new();
    d->p = BN_bin2bn((const unsigned char*)group_modp1, sizeof(group_modp1), 0);
    d->g = BN_bin2bn((const unsigned char*)two_generator, 1, 0);
    int codes;
    if (!DH_check(d, &codes)) {
        assert(0);
    }
    if (!DH_generate_key(d)) {
        assert(0);
    }
    return (void *)d;
}

unsigned char*
getpublickey(void * d, int * len) {
    if (!d) {
        assert(0);
    }
    DH * dh = (DH*)d;
    if (dh->pub_key == NULL) {
        assert(0);
    }
    int dataSize = BN_num_bytes(dh->pub_key);
    unsigned char* data = (unsigned char*)malloc(dataSize);
    BN_bn2bin(dh->pub_key, (unsigned char*)data);
    *len = dataSize;
    return data;
}

char *
computesecret(void * d, const char * buffer, int len) {
    if (!d) {
        assert(0);
    }
    DH* dh = (DH*)d;
    BIGNUM* key = BN_bin2bn((const unsigned char *)(buffer), len, 0);
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
    return data;
}

char *
rc4(char * key_buf, const char * in, int in_len) {
    size_t key_buf_len = strlen(key_buf);
    size_t datalen = in_len;
    
    char * out = (char *)malloc(datalen);
    memmove(out, in, datalen);
    
    unsigned char *md = (unsigned char *)md5((char *)key_buf, key_buf_len);
    RC4_KEY rc4_key;
    RC4_set_key(&rc4_key, 16, md);
    RC4(&rc4_key, datalen, (const unsigned char *)in, (unsigned char *)out);
    return out;
}


unsigned char alphabet[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

int _base64Decode(const unsigned char *input, unsigned int input_len, unsigned char *output, unsigned int *output_len )
{
    static char inalphabet[256], decoder[256];
    int i, bits, c = 0, char_count, errors = 0;
    unsigned int input_idx = 0;
    unsigned int output_idx = 0;
    
    for (i = (sizeof alphabet) - 1; i >= 0 ; i--) {
        inalphabet[alphabet[i]] = 1;
        decoder[alphabet[i]] = i;
    }
    
    char_count = 0;
    bits = 0;
    for( input_idx=0; input_idx < input_len ; input_idx++ ) {
        c = input[ input_idx ];
        if (c == '=')
            break;
        if (c > 255 || ! inalphabet[c])
            continue;
        bits += decoder[c];
        char_count++;
        if (char_count == 4) {
            output[ output_idx++ ] = (bits >> 16);
            output[ output_idx++ ] = ((bits >> 8) & 0xff);
            output[ output_idx++ ] = ( bits & 0xff);
            bits = 0;
            char_count = 0;
        } else {
            bits <<= 6;
        }
    }
    
    if( c == '=' ) {
        switch (char_count) {
            case 1:
#if (CC_TARGET_PLATFORM != CC_PLATFORM_BADA)
                fprintf(stderr, "base64Decode: encoding incomplete: at least 2 bits missing");
#endif
                errors++;
                break;
            case 2:
                output[ output_idx++ ] = ( bits >> 10 );
                break;
            case 3:
                output[ output_idx++ ] = ( bits >> 16 );
                output[ output_idx++ ] = (( bits >> 8 ) & 0xff);
                break;
        }
    } else if ( input_idx < input_len ) {
        if (char_count) {
#if (CC_TARGET_PLATFORM != CC_PLATFORM_BADA)
            fprintf(stderr, "base64 encoding incomplete: at least %d bits truncated",
                    ((4 - char_count) * 6));
#endif
            errors++;
        }
    }
    
    *output_len = output_idx;
    return errors;
}

void _base64Encode( const unsigned char *input, unsigned int input_len, char *output )
{
    unsigned int char_count;
    unsigned int bits;
    unsigned int input_idx = 0;
    unsigned int output_idx = 0;
    
    char_count = 0;
    bits = 0;
    for( input_idx=0; input_idx < input_len ; input_idx++ ) {
        bits |= input[ input_idx ];
        
        char_count++;
        if (char_count == 3) {
            output[ output_idx++ ] = alphabet[(bits >> 18) & 0x3f];
            output[ output_idx++ ] = alphabet[(bits >> 12) & 0x3f];
            output[ output_idx++ ] = alphabet[(bits >> 6) & 0x3f];
            output[ output_idx++ ] = alphabet[bits & 0x3f];
            bits = 0;
            char_count = 0;
        } else {
            bits <<= 8;
        }
    }
    
    if (char_count) {
        if (char_count == 1) {
            bits <<= 8;
        }
        
        output[ output_idx++ ] = alphabet[(bits >> 18) & 0x3f];
        output[ output_idx++ ] = alphabet[(bits >> 12) & 0x3f];
        if (char_count > 1) {
            output[ output_idx++ ] = alphabet[(bits >> 6) & 0x3f];
        } else {
            output[ output_idx++ ] = '=';
        }
        output[ output_idx++ ] = '=';
    }
    
    output[ output_idx++ ] = 0;
}

int
base64Decode(const unsigned char *in, unsigned int inLength, unsigned char **out)
{
    unsigned int outLength = 0;
    
    //should be enough to store 6-bit buffers in 8-bit buffers
    *out = (unsigned char*)malloc(inLength * 3.0f / 4.0f + 1);
    if( *out ) {
        int ret = _base64Decode(in, inLength, *out, &outLength);
        
        if (ret > 0 )
        {
#if (CC_TARGET_PLATFORM != CC_PLATFORM_BADA)
            printf("Base64Utils: error decoding");
#endif
            free(*out);
            *out = nullptr;
            outLength = 0;
        }
    }
    return outLength;
}

int
base64Encode(const unsigned char *in, unsigned int inLength, char **out) {
    unsigned int outLength = inLength * 4 / 3 + (inLength % 3 > 0 ? 4 : 0);
    
    //should be enough to store 8-bit buffers in 6-bit buffers
    *out = (char*)malloc(outLength+1);
    if( *out ) {
        _base64Encode(in, inLength, *out);
    }
    return outLength;
}

    
};

//
//#include "../cjson/lua_cjson.h"
//static luaL_Reg luax_exts[] = {
//    {"cjson", luaopen_cjson_safe},
//    {NULL, NULL}
//};
//void luaopen_lua_extensions_more(lua_State *L)
//{
//    // load extensions
//    luaL_Reg* lib = luax_exts;
//    lua_getglobal(L, "package");
//    lua_getfield(L, -1, "preload");
//    for (; lib->func; lib++)
//    {
//        lua_pushcfunction(L, lib->func);
//        lua_setfield(L, -2, lib->name);
//    }
//    lua_pop(L, 2);
//}



std::map<CCPomelo*, LuaEngine*> GlobalPomeloToLuaEngine;
#else
std::map<CCPomeloWebSocket*, LuaEngine*> GlobalPomeloToLuaEngine;
#endif
#ifndef MULTI_THREAD
#define MULTI_THREAD 0
#endif

const int MAX_CLIENT = 10;
static int pipefds[MAX_CLIENT * 2] = {};
static int pipefd[2];



void 
sig_handler( int sig )
{	
	if (sig == SIGCHLD)
	{
        wait(NULL);
		// return;
	}
	printf("receive sig %d\n", sig);
	int save_errno = errno;
	int msg = sig;
	send( pipefd[1], (char *)&msg, 1, 0 );
	errno = save_errno;
}
void 
addsig( int sig )
{
	struct sigaction sa;
	memset( &sa, '\0', sizeof( sa ) );
	sa.sa_handler = sig_handler;
	sa.sa_flags |= SA_RESTART;
	sigfillset( &sa.sa_mask );
	assert( sigaction( sig, &sa, NULL ) != -1 );
}

void 
open_tolua_fix(lua_State *L)
{
	lua_pushstring(L, TOLUA_REFID_PTR_MAPPING);
    lua_newtable(L);
    lua_rawset(L, LUA_REGISTRYINDEX);

    lua_pushstring(L, TOLUA_REFID_TYPE_MAPPING);
    lua_newtable(L);
    lua_rawset(L, LUA_REGISTRYINDEX);

    lua_pushstring(L, TOLUA_REFID_FUNCTION_MAPPING);
    lua_newtable(L);
    lua_rawset(L, LUA_REGISTRYINDEX);
}

static const char * device_id_string = NULL;
static int 
l_device_id(lua_State *L){
	lua_pushstring(L, device_id_string);
	return 1;
}

static int 
thread_exit(lua_State *L){
#if MULTI_THREAD
    {
        pthread_exit(0);
    }
#else
    {
        exit(0);
    }
#endif
	return 0;
}
//

static bool stop_server = false;
void *
client(void * data)
{
#if (USE_LUA_WEBSOCKET == 0)
	CCPomelo *pomelo = static_cast<CCPomelo*>(data);
#else
    CCPomeloWebSocket *pomelo = static_cast<CCPomeloWebSocket*>(data);
#endif
	lua_State* L = GlobalPomeloToLuaEngine[pomelo]->getLuaStack()->getLuaState();
	luaL_openlibs(L);
	open_tolua_fix(L);
#if (USE_LUA_WEBSOCKET == 0)
	tolua_cc_pomelo_open(L);
#else
    tolua_web_socket_open(L);
    register_web_socket_manual(L);
#endif
	tolua_cc_lua_extension(L);

	int n = pomelo->GetSelfIndex();
    std::stringstream ss;
    std::string s;
    ss << device_id_string;
    ss << "_";
    ss << n;
    ss >> s;
	lua_pushstring(L, s.c_str());
	lua_setglobal(L, "GlobalDeviceId");
	lua_pushcfunction(L, thread_exit);
	lua_setglobal(L, "threa dExit");
	if (luaL_loadfile(L, "main.lua") || lua_pcall(L, 0, 0, 0)){
		printf("cannot run *.lua %s", lua_tostring(L, -1));
	}

	fd_set time_set, test_set;  
	FD_ZERO( &time_set );
	FD_SET( pomelo->GetReadFd(), &time_set );
	bool time_out = false;
	while( !stop_server )
	{
		test_set = time_set; 
		struct timeval timeout;   
		timeout.tv_sec = 1;
       	timeout.tv_usec = 0;
       	int result = select( pomelo->GetReadFd() + 1, &test_set, (fd_set *)0, (fd_set *)0, &timeout ); 
       	switch(result)   
       	{   
       		case 0:   
       		{
           		time_out = true;   
           		break;  
       		}
       		case -1:
       		{
       			if ( errno == EINTR )
       			{
       				continue;
       			}
           		perror("select");
           		return 0;
       		}
       		default:   
       		{
           		if(FD_ISSET( pomelo->GetReadFd(), &test_set ) )   
           		{
	            	char signals[1024];
	            	int ret = recv( pomelo->GetReadFd(), signals, sizeof( signals ), 0 );
	            	if ( ret == -1 )
	            	{
	            		printf("errors occurs\n");
	            		continue;
	            	}
	            	else if ( ret == 0 )
	            	{
	            		continue;
	            	}
	            	else
	            	{
	            		for (int i = 0; i < ret; ++i)
	            		{
	            			switch( signals[i] )
	            			{
	            				case SIGTERM:
	            				{
	            					stop_server = true;
	            				}
                                default:
                                {
                                    pomelo->getTimerHandle()->tick();
                                }
	            			}
	            		}
	            	}
	         	}   
	         	break;
       		}
      	}   
		if ( time_out )
		{
			time_out = false;
			pomelo->getTimerHandle()->tick();
			lua_getglobal(L, "Run");
 			if (lua_pcall(L, 0, 0, 0)){
				printf("Run error %s", lua_tostring(L, -1));
			}
		}
	}
	return 0;
}
#if MULTI_THREAD
void
run()
{
	fd_set test_set;  
	FD_ZERO(&test_set);
	FD_SET(pipefd[0], &test_set);
    CONTINUE:
   	int result = select( pipefd[0] + 1, &test_set, (fd_set *)0, (fd_set *)0, NULL); 
   	switch(result)   
   	{   
   		case -1:
   		{
   			 if ( errno == EINTR )
   			 {
   			 	goto CONTINUE;
   			 }
       		perror("select");
       		stop_server = true;
   		}
   		default:   
   		{
       		if(FD_ISSET(pipefd[0], &test_set))   
       		{
            	char signals[1024];
            	int ret = recv( pipefd[0], signals, sizeof( signals ), 0 );
            	if ( ret == -1 )
            	{
            		printf("errors occurs\n");
            		// continue;
            		stop_server = true;
            	}
            	else if ( ret == 0 )
            	{
            		// continue;
            		stop_server = true;
            	}
            	else
            	{
            		for (int i = 0; i < ret; ++i)
            		{
            			switch( signals[i] )
            			{
            				case SIGTERM:
            				{
            					stop_server = true;
            				}
                            default:
                            {

                            }
            			}
            		}
            	}
         	}   
         	break;
   		}
  	}   
}
#endif
int 
main(int argc, char *argv[])
{
    // char * encrypt = rc4("hello", "123456", 6);
	if ( argc <= 1 )
	{
		device_id_string = "1";
	}
	else
	{
		device_id_string = argv[1];
	}
	addsig(SIGTERM);
	addsig(SIGCHLD);
	int ret = socketpair( PF_UNIX, SOCK_STREAM, 0, pipefd );
	assert( ret != -1 );

// 多线程模式
#if MULTI_THREAD
	{
		pthread_t clients[MAX_CLIENT] = {};
#if (USE_LUA_WEBSOCKET == 0)
        CCPomelo *pomelos[MAX_CLIENT] = {};
#else
        CCPomeloWebSocket *pomelos[MAX_CLIENT] = {};
#endif
		
		for (int i = 0; i < MAX_CLIENT; ++i)
		{
			// sleep(1);
#if (USE_LUA_WEBSOCKET == 0)
			CCPomelo * pomelo = new CCPomelo();
#else
            CCPomeloWebSocket * pomelo = new CCPomeloWebSocket();
            pomelo->setSelfIndex(i);
#endif
			int ret = socketpair( PF_UNIX, SOCK_STREAM, 0, &pipefds[i] );
			assert( ret != -1 );
		    pomelo->setWirtePipeFd(pipefds[i + 1]);
		    pomelo->setReadPipeFd(pipefds[i]);
			GlobalPomeloToLuaEngine.insert(std::make_pair(pomelo, new LuaEngine()));
			pomelos[i] = pomelo;
		}

		for (int i = 0; i < MAX_CLIENT; ++i)
		{
			if ((ret = pthread_create(clients + i, NULL, client, pomelos[i])) != 0)
		     {
		         fprintf(stderr, "pthread create: %s\n", strerror(ret));
		         exit(EXIT_FAILURE);
		     }
		}

		run();

		for (int i = 0; i < MAX_CLIENT; ++i)
		{
			void *value;
			if ((ret = pthread_join(clients[i], &value)) != 0)
			{
			 fprintf(stderr, "pthread join: %s\n", strerror(ret));
			 exit(EXIT_FAILURE);
			}
		}
	}
#else /* MULTI_THREAD */
	{
#if (USE_LUA_WEBSOCKET == 0)
		CCPomelo * pomelo = new CCPomelo();
#else
        CCPomeloWebSocket * pomelo = new CCPomeloWebSocket();
#endif
		pomelo->setWirtePipeFd(pipefd[1]);
		pomelo->setReadPipeFd(pipefd[0]);
		GlobalPomeloToLuaEngine.insert(std::make_pair(pomelo, new LuaEngine()));
		client(pomelo);
	}
#endif


	for ( auto item : GlobalPomeloToLuaEngine )
	{
		delete item.first;
		delete item.second;
	}
	GlobalPomeloToLuaEngine.clear();
    
    
	close(pipefd[0]);
	close(pipefd[1]);
	return 0;
}







