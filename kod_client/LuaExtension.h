//
//  LuaExtension.h
//  battlefront
//
//  Created by Modun on 14-4-9.
//
//

#ifndef __battlefront__LuaExtension__
#define __battlefront__LuaExtension__
#include "tolua++.h"

TOLUA_API int tolua_cc_pomelo_open(lua_State* tolua_S);
TOLUA_API int tolua_cc_lua_extension(lua_State* tolua_S);


#endif /* defined(__battlefront__LuaExtension__) */
