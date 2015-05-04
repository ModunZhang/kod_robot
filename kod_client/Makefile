GCC=gcc
OBJDIR=./obj
CFLAGS= -Wall -c  -I../lua_engine/ -I../tolua/ -I../libpomelo/deps/jansson/src \
 -I../libpomelo/include -I../libpomelo/deps/uv/include

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

objects = $(libjansson_la_obj) $(luaengine_obj) \
$(tolua_obj) $(lua_obj) $(client_obj)


all: kod_client
	@$(MAKE) clean

kod_client: $(objects)
	$(GCC) -lstdc++ -std=c++11 -framework CoreServices \
	$(objects) -o kod_client -L../libpomelo/lib/mac/ -luv -ljansson -lpomelo

%.o: ../lua/%.c 
	$(GCC) $(CFLAGS) -o $@ $<  

%.o: ../lua_engine/%.cpp
	$(GCC) $(CFLAGS) -o $@ $<
#
%.o: ../tolua/%.cpp
	$(GCC) $(CFLAGS) -o $@ $<
%.o: ../tolua/%.c
	$(GCC) $(CFLAGS) -o $@ $<
#
%.o: ../libpomelo/deps/jansson/src/%.c
	$(GCC) $(CFLAGS) -o $@ $<
#
%.o: %.cpp
	$(GCC) $(CFLAGS) -std=c++11 -o $@ $<


.PHONY : clean
clean:
	-@rm *.o

	
