# 如果要编译libpomelo版本,将下面websocket相关部分注释,打开libpomelo部分即可。当然lua源码中需要修改为使用libpomelo
GCC=gcc
OBJDIR=./obj
CFLAGS= -Wall -c -I../lua_engine/ -I../tolua/ -I../lua/ -I../pomelolib/libpomelo/deps/jansson/src \
 -I../pomelolib/libpomelo/include -I../pomelolib/libpomelo/deps/uv/include -I../

#websockets
CFLAGS_WEBSOCKETS = -I../websocket
MAKEEOS = -DUSE_LUA_WEBSOCKET=1
CFLAGS += $(CFLAGS_WEBSOCKETS) $(MAKEEOS)
#websockets end

libjansson_la_obj = dump.o error.o hashtable.o load.o \
memory.o pack_unpack.o strbuffer.o strconv.o utf.o value.o

tolua_obj = tolua_event.o tolua_fix.o tolua_is.o tolua_map.o \
tolua_push.o tolua_to.o

luaengine_obj = CCLuaEngine.o CCLuaStack.o CCLuaValue.o

websocket_obj = WebSocket.o CCPomeloWebSocket.o Lua_web_socket.o bit.o lua_dhcrypt.o

lua_obj = lapi.o lauxlib.o lbaselib.o lcode.o ldblib.o ldebug.o \
ldo.o ldump.o lfunc.o lgc.o linit.o liolib.o llex.o lmathlib.o \
lmem.o loadlib.o lobject.o lopcodes.o loslib.o lparser.o lstate.o \
lstring.o lstrlib.o ltable.o ltablib.o ltm.o lundump.o \
lvm.o lzio.o print.o

client_obj = CCPomelo.o LuaExtension.o main.o 
# lipomelo
# objects = $(luaengine_obj) $(tolua_obj) $(client_obj)
#websockets
objects = $(luaengine_obj) $(tolua_obj) $(client_obj) $(websocket_obj)

all: kod_client
	@$(MAKE) cleanObjects lua

kod_client: $(objects)
	# lipomelo
	# $(GCC) $(objects) -o kod_client -g -L ../lua -L ../pomelolib/libpomelo/out/Default/obj.target/ -L ../pomelolib/libpomelo/out/Default/obj.target/deps/jansson -L ../pomelolib/libpomelo/out/Default/obj.target/deps/uv -L ../libopenssl/openssl-1.0.2e -pthread -std=c++11 -lstdc++ -lresolv  -lpomelo -lcrypto -luv -ljansson -llua -lm -ldl
	# websockets
	$(GCC) $(objects) -o kod_client -g -L ../lua -L ../libopenssl/openssl-1.0.2e -L../websocket -pthread -std=c++11 -lstdc++ -lresolv -lcrypto -llua -lm -ldl -lz -lwebsockets  

%.o: ../lua_engine/%.cpp
	$(GCC) -std=c++11 $(CFLAGS) -o $@ $<
#
%.o: ../tolua/%.cpp
	$(GCC) -std=c++11 $(CFLAGS) -o $@ $<
%.o: ../tolua/%.c
	$(GCC) $(CFLAGS) -o $@ $<

%.o: %.cpp
	$(GCC) -std=c++11 $(CFLAGS) -std=c++11 -o $@ $<


.PHONY : cleanObjects
cleanObjects:
	-@rm *.o

clean:
	-@rm kod_client

lua:
	-@cp -rvf ../resource/* .
	
