GCC=gcc
OBJDIR=./obj
CFLAGS= -Wall -c -I../lua_engine/ -I../tolua/ -I../lua/ -I../pomelolib/libpomelo/deps/jansson/src \
 -I../pomelolib/libpomelo/include -I../pomelolib/libpomelo/deps/uv/include -I../

libjansson_la_obj = dump.o error.o hashtable.o load.o \
memory.o pack_unpack.o strbuffer.o strconv.o utf.o value.o

tolua_obj = tolua_event.o tolua_fix.o tolua_is.o tolua_map.o \
tolua_push.o tolua_to.o

luaengine_obj = CCLuaEngine.o CCLuaStack.o CCLuaValue.o

lua_obj = lapi.o lauxlib.o lbaselib.o lcode.o ldblib.o ldebug.o \
ldo.o ldump.o lfunc.o lgc.o linit.o liolib.o llex.o lmathlib.o \
lmem.o loadlib.o lobject.o lopcodes.o loslib.o lparser.o lstate.o \
lstring.o lstrlib.o ltable.o ltablib.o ltm.o lundump.o \
lvm.o lzio.o print.o

client_obj = CCPomelo.o LuaExtension.o main.o 

objects = $(luaengine_obj) $(tolua_obj) $(client_obj)


all: kod_client
	@$(MAKE) clean

kod_client: $(objects)
	$(GCC) $(objects) -o kod_client -g -L ../lua -L ../pomelolib/libpomelo/out/Default/obj.target/ -L ../pomelolib/libpomelo/out/Default/obj.target/deps/jansson -L ../pomelolib/libpomelo/out/Default/obj.target/deps/uv -L ../libopenssl/openssl-1.0.2e -pthread -std=c++11 -lstdc++ -lresolv  -lpomelo -lcrypto -luv -ljansson -llua -lm -ldl 

# %.o: ../lua/%.c 
# 	$(GCC) $(CFLAGS) -o $@ $<  

%.o: ../lua_engine/%.cpp
	$(GCC) -std=c++11 $(CFLAGS) -o $@ $<
#
%.o: ../tolua/%.cpp
	$(GCC) -std=c++11 $(CFLAGS) -o $@ $<
%.o: ../tolua/%.c
	$(GCC) $(CFLAGS) -o $@ $<

# %.o: ../libpomelo/deps/jansson/src/%.c
# 	$(GCC) $(CFLAGS) -o $@ $<

%.o: %.cpp
	$(GCC) -std=c++11 $(CFLAGS) -std=c++11 -o $@ $<


.PHONY : clean
clean:
	-@rm *.o

	
