//
//  main.m
//  LuaTest
//
//  Created by Vincent K on 4/7/14.
//  Copyright (c) 2014 Unlocked Doors. All rights reserved.
//

#include <iostream>
#include <unistd.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#include "Filesystem.h"
#include "Basics.h"

#include "SDL2/SDL.h"

int main(int argc, const char * argv[]) {
    std::string luaSource = fs::getLuaSourcePath();

    lua_State *L;

    L = luaL_newstate();
    luaL_openlibs(L);

    lua_settop(L, 0);

    int err;
    err = luaL_dofile(L, fs::pathJoin(luaSource, "main.lua").c_str());
    if(0 != err) {
        luaL_error(L, "cannot compile lua file: %s", lua_tostring(L, -1));
        return 1;
    }

    lua_getglobal(L, "main");
    err = lua_pcall(L, 0, 0, 0);
    if(0 != err) {
        luaL_error(L, "cannot run lua file: %s", lua_tostring(L, -1));
        return 1;
    }

    lua_close(L);

    return 0;
}
