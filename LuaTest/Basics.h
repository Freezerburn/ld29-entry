//
//  Basics.h
//  LuaTest
//
//  Created by Vincent K on 4/7/14.
//  Copyright (c) 2014 Unlocked Doors. All rights reserved.
//

#ifndef __LuaTest__Basics__
#define __LuaTest__Basics__

//#include <iostream>

#include "lua.hpp"

int luaload_sdl2(lua_State *L);
int luaload_img(lua_State *L);
int luaload_ttf(lua_State *L);
int luaload_mixer(lua_State *L);

#endif /* defined(__LuaTest__Basics__) */
