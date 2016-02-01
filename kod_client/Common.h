#include "LuaExtension.h"
#define CCLOG(format, ...) fprintf(stdout, format, ##__VA_ARGS__);printf("\n")
#if (USE_LUA_WEBSOCKET == 0)
#include "CCPomelo.h"
extern std::map<CCPomelo*, LuaEngine*> GlobalPomeloToLuaEngine;
#endif
