//
//  Engine.cpp
//  LuaTest
//
//  Created by Vincent K on 4/14/14.
//  Copyright (c) 2014 Unlocked Doors. All rights reserved.
//

#include "Engine.h"
#include "SDL.h"


static bool engine_going = true;

static int engine_start(lua_State *L) {
    lua_gc(L, LUA_GCSTOP, 0);
    unsigned long long frame = 0;
    
    while(engine_going) {
        unsigned int before = SDL_GetTicks();

        // Implement ticking/rendering/etc. here.

        unsigned int delta = SDL_GetTicks() - before;
        // A few times a second, spend some time doing GC work.
        while(delta < 12 && (frame % 30) == 0) {
            int finished = lua_gc(L, LUA_GCSTEP, 1);
            if(1 == finished) {
                break;
            }
            delta = SDL_GetTicks() - before;
        }
        SDL_RenderPresent(NULL);
    }
    return 0;
}

static int engine_kill(lua_State *L) {
    engine_going = false;
    return 0;
}

static const struct luaL_Reg enginelib [] {
    {NULL, NULL}
};

int luaload_engine(lua_State *L) {
    luaL_newlib(L, enginelib);
    
    return 0;
}