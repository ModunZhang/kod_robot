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
#include <semaphore.h>


extern "C"{	
	#include "../lua/lua.h"
	#include "../lua/lualib.h"
	#include "../lua/lauxlib.h"
	#include "../tolua/tolua++.h"
	#include "../tolua/tolua_fix.h"
}
#include "Common.h"
#include "CTimerHandle.h"
#include "../lua_engine/CCLuaEngine.h"



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

#ifndef MULTI_THREAD
#define MULTI_THREAD 1
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
//		return;
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
    if(MULTI_THREAD)
    {
        pthread_exit(0);
    }
    else
    {
        exit(0);
    }
	return 0;
}
//

static bool stop_server = false;
void *
client(void * data)
{
	CCPomelo *pomelo = static_cast<CCPomelo*>(data);
	lua_State* L = GlobalPomeloToLuaEngine[pomelo]->getLuaStack()->getLuaState();
	luaL_openlibs(L);
	open_tolua_fix(L);
	tolua_cc_pomelo_open(L);
	tolua_cc_lua_extension(L);

	int n = pomelo->GetSelfIndex();
    stringstream ss;
    string s;
    ss << device_id_string;
    ss << "_";
    ss << n;
    ss >> s;
	lua_pushstring(L, s.c_str());
	lua_setglobal(L, "GlobalDeviceId");
	lua_pushcfunction(L, thread_exit);
	lua_setglobal(L, "threadExit");
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

int 
main(int argc, char *argv[])
{
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
	if(MULTI_THREAD)
	{
		pthread_t clients[MAX_CLIENT] = {};
		CCPomelo *pomelos[MAX_CLIENT] = {};
		for (int i = 0; i < MAX_CLIENT; ++i)
		{
			// sleep(1);
			CCPomelo * pomelo = new CCPomelo();
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
	else // 单线程模式
	{
		CCPomelo * pomelo = new CCPomelo();
		pomelo->setWirtePipeFd(pipefd[1]);
		pomelo->setReadPipeFd(pipefd[0]);
		GlobalPomeloToLuaEngine.insert(std::make_pair(pomelo, new LuaEngine()));
		client(pomelo);
	}
	


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







