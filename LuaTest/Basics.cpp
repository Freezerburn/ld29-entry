//
//  Basics.cpp
//  LuaTest
//
//  Created by Vincent K on 4/7/14.
//  Copyright (c) 2014 Unlocked Doors. All rights reserved.
//

#include "Basics.h"
#include "Filesystem.h"

#include "SDL2/SDL.h"
#include "SDL2/SDL_image.h"
#include "SDL2/SDL_ttf.h"
#include "SDL2/SDL_mixer.h"
#include "SDL2/SDL_opengl.h"

#include <iostream>
#include <sstream>
#include <vector>
#include <tuple>
#include <chrono>


static const char *WINDOW_METATABLE = "SDL.Window.Metatable";
static const char *RENDERER_METATABLE = "SDL.Renderer.Metatable";
static const char *SURFACE_METATABLE = "SDL.Surface.Metatable";
static const char *TEXTURE_METATABLE = "SDL.Texture.Metatable";

static const char *FONT_METATABLE = "SDL.TTF.Font.Metatable";

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
static int rmask = 0xff000000;
static int gmask = 0x00ff0000;
static int bmask = 0x0000ff00;
static int amask = 0x000000ff;
#else
static int rmask = 0x000000ff;
static int gmask = 0x0000ff00;
static int bmask = 0x00ff0000;
static int amask = 0xff000000;
#endif

static std::string convertToUpper(std::string str) {
    for(int i = 0; i < str.length(); i++) {
        str[i] = toupper(str[i]);
    }
    return str;
}

#define STR(S) #S
#define def2tup(C) \
    (std::tuple<int, std::string>{C, std::string(#C).substr(4)})
#define key2tup(C) \
    (std::tuple<int, std::string>{C, std::string("KEY") + convertToUpper(std::string(#C).substr(4))})
#define scan2tup(C) \
    (std::tuple<int, std::string>{C, std::string(#C).substr(4)})

#define checkwindow(L, idx) \
    (*(SDL_Window **)luaL_checkudata(L, idx, WINDOW_METATABLE))
#define checkrenderer(L, idx) \
    (*(SDL_Renderer **)luaL_checkudata(L, idx, RENDERER_METATABLE))
#define checksurface(L, idx) \
    (*(SDL_Surface **)luaL_checkudata(L, idx, SURFACE_METATABLE))
#define checktexture(L, idx) \
    (*(SDL_Texture **)luaL_checkudata(L, idx, TEXTURE_METATABLE))
#define checkfont(L, idx) \
    (*(TTF_Font **)luaL_checkudata(L, idx, FONT_METATABLE))

static void wrap_event(lua_State *L, SDL_Event e) {
    if(SDL_KEYDOWN == e.type || SDL_KEYUP == e.type) {
        SDL_KeyboardEvent ke = e.key;
        lua_newtable(L);
        lua_pushstring(L, ke.state == SDL_PRESSED ? "KEYDOWN" : "KEYUP");
        lua_setfield(L, -2, "name");
        lua_pushinteger(L, ke.type);
        lua_setfield(L, -2, "type");
        lua_pushinteger(L, ke.timestamp);
        lua_setfield(L, -2, "timestamp");
        lua_pushinteger(L, ke.windowID);
        lua_setfield(L, -2, "windowID");
        lua_pushboolean(L, ke.state == SDL_PRESSED ? true : false);
        lua_setfield(L, -2, "state");
        lua_pushboolean(L, ke.repeat);
        lua_setfield(L, -2, "repeated");
        lua_pushinteger(L, ke.keysym.sym);
        lua_setfield(L, -2, "sym");
        lua_pushinteger(L, ke.keysym.scancode);
        lua_setfield(L, -2, "scancode");
    }
    else if(SDL_MOUSEBUTTONDOWN == e.type || SDL_MOUSEBUTTONUP == e.type) {
        SDL_MouseButtonEvent mbe = e.button;
        lua_newtable(L);
        lua_pushstring(L, mbe.state == SDL_PRESSED ? "MOUSEBUTTONDOWN" : "MOUSEBUTTONUP");
        lua_setfield(L, -2, "name");
        lua_pushinteger(L, mbe.type);
        lua_setfield(L, -2, "type");
        lua_pushinteger(L, mbe.timestamp);
        lua_setfield(L, -2, "timestamp");
        lua_pushinteger(L, mbe.windowID);
        lua_setfield(L, -2, "windowID");
        lua_pushinteger(L, mbe.which);
        lua_setfield(L, -2, "which");
        lua_pushinteger(L, mbe.button);
        lua_setfield(L, -2, "button");
        lua_pushinteger(L, mbe.state == SDL_PRESSED ? true : false);
        lua_setfield(L, -2, "state");
        lua_pushinteger(L, mbe.clicks);
        lua_setfield(L, -2, "clicks");
        lua_pushinteger(L, mbe.x);
        lua_setfield(L, -2, "x");
        lua_pushinteger(L, mbe.y);
        lua_setfield(L, -2, "y");
    }
    else if(SDL_MOUSEMOTION == e.type) {
        SDL_MouseMotionEvent mme = e.motion;
        lua_newtable(L);
        lua_pushstring(L, "MOUSEMOTION");
        lua_setfield(L, -2, "name");
        lua_pushinteger(L, mme.type);
        lua_setfield(L, -2, "type");
        lua_pushinteger(L, mme.timestamp);
        lua_setfield(L, -2, "timestamp");
        lua_pushinteger(L, mme.windowID);
        lua_setfield(L, -2, "windowID");
        lua_pushinteger(L, mme.which);
        lua_setfield(L, -2, "which");
        lua_pushinteger(L, mme.state);
        lua_setfield(L, -2, "state");
        lua_pushinteger(L, mme.x);
        lua_setfield(L, -2, "x");
        lua_pushinteger(L, mme.y);
        lua_setfield(L, -2, "y");
        lua_pushinteger(L, mme.xrel);
        lua_setfield(L, -2, "xrel");
        lua_pushinteger(L, mme.yrel);
        lua_setfield(L, -2, "yrel");
    }
    else if(SDL_QUIT == e.type) {
        SDL_QuitEvent qe = e.quit;
        lua_newtable(L);
        lua_pushstring(L, "QUIT");
        lua_setfield(L, -2, "name");
        lua_pushinteger(L, qe.type);
        lua_setfield(L, -2, "type");
        lua_pushinteger(L, qe.timestamp);
        lua_setfield(L, -2, "timestamp");
    }
    else {
        lua_newtable(L);
        lua_pushstring(L, "UNKNOWN");
        lua_setfield(L, -2, "name");
    }
}

static SDL_Rect table_to_rect(lua_State *L, int idx) {
    SDL_Rect ret;
    lua_getfield(L, idx, "x");
    ret.x = luaL_checkint(L, -1);
    lua_pop(L, 1);
    lua_getfield(L, idx, "y");
    ret.y = luaL_checkint(L, -1);
    lua_pop(L, 1);
    lua_getfield(L, idx, "w");
    ret.w = luaL_checkint(L, -1);
    lua_pop(L, 1);
    lua_getfield(L, idx, "h");
    ret.h = luaL_checkint(L, -1);
    lua_pop(L, 1);
    return ret;
}

#pragma mark -
#pragma mark SDL2 Wrapper

/*
 SDL2 wrapper functions.
 */
static int wrap_sdl_init(lua_State *L) {
    int flags = luaL_checkint(L, 1);
    int err = SDL_Init(flags);
    if(err) {
        std::stringstream ss;
        ss << "Error initializing SDL: " << SDL_GetError();
        luaL_error(L, ss.str().c_str());
        return 0;
    }
    SDL_SetMainReady();
    return 0;
}

static int wrap_sdl_quit(lua_State *L) {
    SDL_Quit();
    return 0;
}

static int wrap_sdl_createwindow(lua_State *L) {
    if(lua_gettop(L) < 6) {
        luaL_error(L, "Expected 6 parameters to createWindow.");
        return 0;
    };
    const char *windowName = luaL_checkstring(L, 1);
    int windowPosX = luaL_checkint(L, 2);
    int windowPosY = luaL_checkint(L, 3);
    int windowWidth = luaL_checkint(L, 4);
    int windowHeight = luaL_checkint(L, 5);
    int flags = luaL_checkint(L, 6);

    SDL_Window **window = (SDL_Window **)lua_newuserdata(L, sizeof(SDL_Window *));
    
    *window = SDL_CreateWindow(windowName, windowPosX, windowPosY, windowWidth, windowHeight, flags);
    if(NULL == *window) {
        std::cout << "Window NULL" << std::endl;
        std::stringstream ss;
        ss << "Error creating SDL Window: " << SDL_GetError();
        luaL_error(L, ss.str().c_str());
        return 0;
    }

    luaL_getmetatable(L, WINDOW_METATABLE);
    lua_setmetatable(L, -2);
    return 1;
}

static int wrap_sdl_createrenderer(lua_State *L) {
    SDL_Window *window = checkwindow(L, 1);
    int index = luaL_checkint(L, 2);
    int flags = luaL_checkint(L, 3);

    SDL_Renderer **renderer = (SDL_Renderer **)lua_newuserdata(L, sizeof(SDL_Renderer *));
    *renderer = SDL_CreateRenderer(window, index, flags);
    if(NULL == *renderer) {
        std::stringstream ss;
        ss << "Error creating SDL Renderer: " << SDL_GetError();
        luaL_error(L, ss.str().c_str());
        return 0;
    }
    else {
        luaL_getmetatable(L, RENDERER_METATABLE);
        lua_setmetatable(L, -2);
        return 1;
    }
}

static int wrap_sdl_pollevent(lua_State *L) {
    SDL_Event e;
    int hasevent = SDL_PollEvent(&e);
    if(1 == hasevent) {
        wrap_event(L, e);
    }
    else {
        lua_pushnil(L);
    }
    return 1;
}

static int wrap_sdl_waitevent(lua_State *L) {
    SDL_Event e;
    SDL_WaitEvent(&e);
    wrap_event(L, e);
    return 1;
}

static int wrap_sdl_creatergbsurface(lua_State *L) {
    int numargs = lua_gettop(L);
    if(numargs < 2) {
        luaL_error(L, "sdl.createRGBSurface requires at least 2 arguments.");
        return 0;
    }

    int width = luaL_checkint(L, 1);
    int height = luaL_checkint(L, 2);
    int depth = numargs == 2 || lua_isnil(L, 3) ? 32 : luaL_checkint(L, 3);

    SDL_Surface **surface = (SDL_Surface **)lua_newuserdata(L, sizeof(SDL_Surface *));
    *surface = SDL_CreateRGBSurface(0, width, height, depth, rmask, gmask, bmask, amask);
    if(NULL == *surface) {
        std::stringstream ss;
        ss << "sdl.createRGBSurface: ERROR when calling SDL_CreateRGBSurface: " << SDL_GetError();
        luaL_error(L, ss.str().c_str());
        return 0;
    }

    luaL_getmetatable(L, SURFACE_METATABLE);
    lua_setmetatable(L, -2);

    return 1;
}

static int wrap_sdl_getticks(lua_State *L) {
    lua_pushinteger(L, SDL_GetTicks());
    return 1;
}

static int create_rect(lua_State *L) {
    int x = lua_isnil(L, 1) ? 0 : luaL_checkint(L, 1);
    int y = lua_isnil(L, 2) ? 0 : luaL_checkint(L, 2);
    int w = lua_isnil(L, 3) ? 0 : luaL_checkint(L, 3);
    int h = lua_isnil(L, 4) ? 0 : luaL_checkint(L, 4);

    lua_newtable(L);
    lua_pushinteger(L, x);
    lua_setfield(L, -2, "x");
    lua_pushinteger(L, y);
    lua_setfield(L, -2, "y");
    lua_pushinteger(L, w);
    lua_setfield(L, -2, "w");
    lua_pushinteger(L, h);
    lua_setfield(L, -2, "h");

    return 1;
}

#pragma mark SDL2 lua module
// Module of all the functions.
static const struct luaL_Reg sdllib [] = {
    {"init", wrap_sdl_init},
    {"quit", wrap_sdl_quit},
    {"createWindow", wrap_sdl_createwindow},
    {"createRenderer", wrap_sdl_createrenderer},
    {"pollEvent", wrap_sdl_pollevent},
    {"waitEvent", wrap_sdl_waitevent},
    {"createRGBSurface", wrap_sdl_creatergbsurface},
    {"getTicks", wrap_sdl_getticks},

    {"newRect", create_rect},

    {NULL, NULL}
};

#pragma mark -
#pragma mark SDL_Window Wrapper
/*
 SDL_Window function wrappers.
 */
static int wrap_window_getsize(lua_State *L) {
    SDL_Window *window = checkwindow(L, 1);
    int w, h;
    SDL_GetWindowSize(window, &w, &h);

    lua_newtable(L);
    lua_pushinteger(L, w);
    lua_pushvalue(L, -1);
    lua_setfield(L, -3, "w");
    lua_setfield(L, -2, "width");

    lua_pushinteger(L, h);
    lua_pushvalue(L, -1);
    lua_setfield(L, -3, "h");
    lua_setfield(L, -2, "height");

    return 1;
}

static int window_gc_meta(lua_State *L) {
    SDL_Window *window = checkwindow(L, 1);
    SDL_DestroyWindow(window);
    return 0;
}

static int window_tostring_meta(lua_State *L) {
//    SDL_Window *window = checkwindow(L, 1);
    lua_pushstring(L, "SDL_Window");
    return 1;
}

// Wrappers for SDL_Window-specific functions.
static const struct luaL_Reg sdl_windowlib [] = {
    {"getSize", wrap_window_getsize},

    {"__tostring", window_tostring_meta},
    {"__gc", window_gc_meta},

    {NULL, NULL}
};

#pragma mark -
#pragma mark SDL_Renderer Wrapper
/*
 SDL_Renderer function wrappers.
 */

static int sdl_wrap_render_texfromsurf(lua_State *L) {
    SDL_Renderer *renderer = checkrenderer(L, 1);
    SDL_Surface *surface = checksurface(L, 2);
    SDL_Texture **texture = (SDL_Texture **)lua_newuserdata(L, sizeof(SDL_Texture*));

    *texture = SDL_CreateTextureFromSurface(renderer, surface);
    if(NULL == *texture) {
        std::stringstream ss;
        ss << "Error creating texture from surface: " << SDL_GetError();
        luaL_error(L, ss.str().c_str());
        return 0;
    }

    luaL_getmetatable(L, TEXTURE_METATABLE);
    lua_setmetatable(L, -2);
    
    return 1;
}

static int sdl_wrap_render_copy(lua_State *L) {
    int size = lua_gettop(L);
    if(size < 2) {
        luaL_error(L, "SDL_Renderer:copy expected at least 2 arguments.");
        return 0;
    }

    SDL_Renderer *renderer = checkrenderer(L, 1);
    SDL_Texture *texture = checktexture(L, 2);
    if(size == 2) {
        SDL_RenderCopy(renderer, texture, NULL, NULL);
    }
    else if(size == 3) {
        if(lua_isnil(L, 3)) {
            SDL_RenderCopy(renderer, texture, NULL, NULL);
        }
        else {
            SDL_Rect srcrect = table_to_rect(L, 3);
            SDL_RenderCopy(renderer, texture, &srcrect, NULL);
        }
    }
    else {
        if(lua_isnil(L, 3)) {
            if(lua_isnil(L, 4)) {
                SDL_RenderCopy(renderer, texture, NULL, NULL);
            }
            else {
                SDL_Rect destrect = table_to_rect(L, 4);
                SDL_RenderCopy(renderer, texture, NULL, &destrect);
            }
        }
        else {
            SDL_Rect srcrect = table_to_rect(L, 3);
            if(lua_isnil(L, 4)) {
                SDL_RenderCopy(renderer, texture, &srcrect, NULL);
            }
            else {
                SDL_Rect destrect = table_to_rect(L, 4);
                SDL_RenderCopy(renderer, texture, &srcrect, &destrect);
            }
        }
    }
    return 0;
}

static int sdl_wrap_render_clear(lua_State *L) {
    SDL_Renderer *renderer = checkrenderer(L, 1);
    SDL_RenderClear(renderer);
    return 0;
}

static int sdl_wrap_renderer_present(lua_State *L) {
    SDL_Renderer *renderer = checkrenderer(L, 1);
    SDL_RenderPresent(renderer);
    return 0;
}

static int sdl_wrap_renderer_setdrawcolor(lua_State *L) {
    SDL_Renderer *renderer = checkrenderer(L, 1);
    int r = luaL_checkint(L, 2);
    int g = luaL_checkint(L, 3);
    int b = luaL_checkint(L, 4);
    int a;
    if(lua_gettop(L) < 5) {
        a = 255;
    }
    else {
        a = luaL_checkint(L, 5);
    }
    int err = SDL_SetRenderDrawColor(renderer, r, g, b, a);
    if(err < 0) {
        std::stringstream ss;
        ss << "SDL_Renderer:setDrawColor: ERROR calling SDL_SetRenderDrawColor: " << SDL_GetError();
        luaL_error(L, ss.str().c_str());
    }
    return 0;
}

static int renderer_gc_meta(lua_State *L) {
    SDL_Renderer *renderer = checkrenderer(L, 1);
    if(NULL != renderer) {
        SDL_DestroyRenderer(renderer);
    }
    return 0;
}

static const struct luaL_Reg sdl_rendererlib [] = {
    {"createTextureFromSurface", sdl_wrap_render_texfromsurf},
    {"clear", sdl_wrap_render_clear},
    {"copy", sdl_wrap_render_copy},
    {"present", sdl_wrap_renderer_present},
    {"setDrawColor", sdl_wrap_renderer_setdrawcolor},

    {"__gc", renderer_gc_meta},

    {NULL, NULL}
};

#pragma mark -
#pragma mark SDL_Surface Wrapper
/*
 SDL_Surface function wrappers.
 */

static int sdl_wrap_surface_blitscaled(lua_State *L) {
    int numargs = lua_gettop(L);
    if(numargs < 2) {
        luaL_error(L, "SDL_Surface:blitScaled requires at least a destination SDL_Surface.");
    }
    SDL_Surface *to = checksurface(L, 1);
    SDL_Surface *from = checksurface(L, 2);
    int err;

    if(numargs == 2) {
        err = SDL_BlitScaled(from, NULL, to, NULL);
    }
    else if(numargs == 3) {
        SDL_Rect srcrect = table_to_rect(L, 3);
        err = SDL_BlitScaled(from, &srcrect, to, NULL);
    }
    else {
        SDL_Rect srcrect = table_to_rect(L, 3);
        SDL_Rect destrect = table_to_rect(L, 4);
        err = SDL_BlitScaled(from, &srcrect, to, &destrect);
    }

    if(0 == err) {
        std::stringstream ss;
        ss << "SDL_Surface:blitScaled: ERROR calling SDL_BlitScaled: " << SDL_GetError();
        luaL_error(L, ss.str().c_str());
    }
    return 0;
}

static int sdl_wrap_surface_blit(lua_State *L) {
    int numargs = lua_gettop(L);
    if(numargs < 2) {
        luaL_error(L, "SDL_Surface:blitSurface requires at least a destination SDL_Surface.");
    }
    SDL_Surface *to = checksurface(L, 1);
    SDL_Surface *from = checksurface(L, 2);
    int err;

    if(numargs == 2) {
        err = SDL_BlitSurface(from, NULL, to, NULL);
    }
    else if(numargs == 3) {
        SDL_Rect srcrect = table_to_rect(L, 3);
        err = SDL_BlitSurface(from, &srcrect, to, NULL);
    }
    else {
        SDL_Rect srcrect = table_to_rect(L, 3);
        SDL_Rect destrect = table_to_rect(L, 4);
        err = SDL_BlitSurface(from, &srcrect, to, &destrect);
    }

    if(0 == err) {
        std::stringstream ss;
        ss << "SDL_Surface:blitSurface: ERROR calling SDL_BlitSurface: " << SDL_GetError();
        luaL_error(L, ss.str().c_str());
    }
    return 0;
}

static int sdl_wrap_surface_fillrect(lua_State *L) {
    int numargs = lua_gettop(L);
    if(numargs < 5) {
        luaL_error(L, "SDL_Surface:fillRect: Requires rect (or nil) and r, g, b.");
        return 0;
    }
    
    SDL_Surface *surface = checksurface(L, 1);
    int r = luaL_checkint(L, 3);
    int g = luaL_checkint(L, 4);
    int b = luaL_checkint(L, 5);
    Uint32 color = SDL_MapRGB(surface->format, r, g, b);
    int err;
    if(lua_isnil(L, 2)) {
        err = SDL_FillRect(surface, NULL, color);
    }
    else {
        SDL_Rect destrect = table_to_rect(L, 2);
        err = SDL_FillRect(surface, &destrect, color);
    }

    if(err < 0) {
        std::stringstream ss;
        ss << "SDL_Surface:fillRect: ERROR calling SDL_FillRect: " << SDL_GetError();
        luaL_error(L, ss.str().c_str());
    }
    return 0;
}

static int surface_gc_meta(lua_State *L) {
//    std::cout << "GCing SDL_Surface." << std::endl;
    SDL_Surface *surface = checksurface(L, 1);
    if(NULL != surface) {
        SDL_FreeSurface(surface);
    }
    return 0;
}

static const struct luaL_Reg sdl_surfacelib [] = {
    {"blitScaled", sdl_wrap_surface_blitscaled},
    {"blit", sdl_wrap_surface_blit},
    {"fillRect", sdl_wrap_surface_fillrect},

    {"__gc", surface_gc_meta},

    {NULL, NULL}
};

#pragma mark -
#pragma mark SDL_Texture Wrapper
/*
 SDL_Texture function wrappers.
 */

static int wrap_texture_update(lua_State *L) {
    SDL_Texture *texture = checktexture(L, 1);
    SDL_Surface *surface = checksurface(L, 2);
    int numargs = lua_gettop(L);
    int err;
    if(numargs == 2) {
        err = SDL_UpdateTexture(texture, NULL, surface->pixels, surface->pitch);
    }
    else if(lua_isnil(L, 3)) {
        err = SDL_UpdateTexture(texture, NULL, surface->pixels, surface->pitch);
    }
    else {
        SDL_Rect dest = table_to_rect(L, 3);
        err = SDL_UpdateTexture(texture, &dest, surface->pixels, surface->pitch);
    }
    if(err < 0) {
        std::stringstream ss;
        ss << "SDL_Texture:update: ERROR calling SDL_UpdateTexture: " << SDL_GetError();
        luaL_error(L, ss.str().c_str());
    }

    return 0;
}

static int texture_gc_meta(lua_State *L) {
    SDL_Texture *texture = checktexture(L, 1);
    if(NULL != texture) {
        SDL_DestroyTexture(texture);
    }
    return 0;
}

static const struct luaL_Reg sdl_texturelib [] = {
    {"update", wrap_texture_update},
    
    {"__gc", texture_gc_meta},
    
    {NULL, NULL}
};

static void InitSDLBindings(lua_State *L) {
    // Create and initialize the SDL_Window metatable.
    luaL_newmetatable(L, WINDOW_METATABLE);
    lua_pushvalue(L, -1);
    lua_setfield(L, -2, "__index");
    luaL_setfuncs(L, sdl_windowlib, 0);

    // Create and initialize the SDL_Renderer metatable.
    luaL_newmetatable(L, RENDERER_METATABLE);
    lua_pushvalue(L, -1);
    lua_setfield(L, -2, "__index");
    luaL_setfuncs(L, sdl_rendererlib, 0);

    // Create and initialize the SDL_Surface metatable.
    luaL_newmetatable(L, SURFACE_METATABLE);
    lua_pushvalue(L, -1);
    lua_setfield(L, -2, "__index");
    luaL_setfuncs(L, sdl_surfacelib, 0);

    // Create and initialize the SDL_Texture metatable.
    luaL_newmetatable(L, TEXTURE_METATABLE);
    lua_pushvalue(L, -1);
    lua_setfield(L, -2, "__index");
    luaL_setfuncs(L, sdl_texturelib, 0);
    
    luaL_newlib(L, sdllib);

    std::vector<std::tuple<int, std::string>> inits{
        // SDL Initialization Constants
        def2tup(SDL_INIT_TIMER), def2tup(SDL_INIT_AUDIO),
        def2tup(SDL_INIT_VIDEO), def2tup(SDL_INIT_JOYSTICK),
        def2tup(SDL_INIT_HAPTIC), def2tup(SDL_INIT_GAMECONTROLLER),
        def2tup(SDL_INIT_EVENTS), def2tup(SDL_INIT_NOPARACHUTE),
        def2tup(SDL_INIT_EVERYTHING),

        // SDL Event Constants.
        def2tup(SDL_DOLLARGESTURE), def2tup(SDL_DROPFILE),
        def2tup(SDL_FINGERMOTION), def2tup(SDL_FINGERUP),
        def2tup(SDL_KEYDOWN), def2tup(SDL_KEYUP), def2tup(SDL_JOYAXISMOTION),
        def2tup(SDL_JOYBALLMOTION), def2tup(SDL_JOYHATMOTION),
        def2tup(SDL_JOYBUTTONDOWN), def2tup(SDL_JOYBUTTONUP),
        def2tup(SDL_MOUSEMOTION), def2tup(SDL_MOUSEBUTTONDOWN),
        def2tup(SDL_MOUSEBUTTONUP), def2tup(SDL_MOUSEWHEEL),
        def2tup(SDL_MULTIGESTURE), def2tup(SDL_QUIT), def2tup(SDL_SYSWMEVENT),
        def2tup(SDL_TEXTEDITING), def2tup(SDL_TEXTINPUT),
        def2tup(SDL_USEREVENT), def2tup(SDL_WINDOWEVENT),

        // SDL Window Position Constants
        def2tup(SDL_WINDOWPOS_CENTERED), def2tup(SDL_WINDOWPOS_UNDEFINED),

        def2tup(SDL_WINDOW_ALLOW_HIGHDPI), def2tup(SDL_WINDOW_BORDERLESS),
        def2tup(SDL_WINDOW_FOREIGN), def2tup(SDL_WINDOW_FULLSCREEN),
        def2tup(SDL_WINDOW_FULLSCREEN_DESKTOP), def2tup(SDL_WINDOW_HIDDEN),
        def2tup(SDL_WINDOW_INPUT_FOCUS), def2tup(SDL_WINDOW_INPUT_GRABBED),
        def2tup(SDL_WINDOW_MAXIMIZED), def2tup(SDL_WINDOW_MINIMIZED),
        def2tup(SDL_WINDOW_MOUSE_FOCUS), def2tup(SDL_WINDOW_OPENGL),
        def2tup(SDL_WINDOW_RESIZABLE), def2tup(SDL_WINDOW_SHOWN),

        // SDL Renderer Constants
        def2tup(SDL_RENDERER_ACCELERATED), def2tup(SDL_RENDERER_PRESENTVSYNC),
        def2tup(SDL_RENDERER_SOFTWARE), def2tup(SDL_RENDERER_TARGETTEXTURE),

        // SDL Keysym Constants
        key2tup(SDLK_0), key2tup(SDLK_1), key2tup(SDLK_2), key2tup(SDLK_3),
        key2tup(SDLK_4), key2tup(SDLK_5), key2tup(SDLK_6), key2tup(SDLK_7),
        key2tup(SDLK_8), key2tup(SDLK_9), key2tup(SDLK_a), key2tup(SDLK_AC_BACK),
        key2tup(SDLK_AC_BOOKMARKS), key2tup(SDLK_AC_FORWARD), key2tup(SDLK_AC_HOME),
        key2tup(SDLK_AC_REFRESH), key2tup(SDLK_AC_SEARCH), key2tup(SDLK_AC_STOP),
        key2tup(SDLK_AGAIN), key2tup(SDLK_ALTERASE), key2tup(SDLK_QUOTE),
        key2tup(SDLK_APPLICATION), key2tup(SDLK_AUDIOMUTE), key2tup(SDLK_AUDIONEXT),
        key2tup(SDLK_AUDIOPLAY), key2tup(SDLK_AUDIOPREV), key2tup(SDLK_AUDIOSTOP),
        key2tup(SDLK_b), key2tup(SDLK_BACKSLASH), key2tup(SDLK_BACKSPACE),
        key2tup(SDLK_BRIGHTNESSDOWN), key2tup(SDLK_BRIGHTNESSUP), key2tup(SDLK_c),
        key2tup(SDLK_CALCULATOR), key2tup(SDLK_CANCEL), key2tup(SDLK_CAPSLOCK),
        key2tup(SDLK_CARET), key2tup(SDLK_CLEAR), key2tup(SDLK_CLEARAGAIN),
        key2tup(SDLK_COLON), key2tup(SDLK_COMMA), key2tup(SDLK_COMPUTER),
        key2tup(SDLK_COPY), key2tup(SDLK_CRSEL), key2tup(SDLK_CURRENCYSUBUNIT),
        key2tup(SDLK_CURRENCYUNIT), key2tup(SDLK_CUT), key2tup(SDLK_d),
        key2tup(SDLK_DECIMALSEPARATOR), key2tup(SDLK_DELETE), key2tup(SDLK_DISPLAYSWITCH),
        key2tup(SDLK_DOLLAR), key2tup(SDLK_DOWN), key2tup(SDLK_e), key2tup(SDLK_EJECT),
        key2tup(SDLK_END), key2tup(SDLK_EQUALS), key2tup(SDLK_ESCAPE), key2tup(SDLK_EXCLAIM),
        key2tup(SDLK_EXECUTE), key2tup(SDLK_EXSEL), key2tup(SDLK_f), key2tup(SDLK_F1),
        key2tup(SDLK_F10), key2tup(SDLK_F11), key2tup(SDLK_F12), key2tup(SDLK_F13),
        key2tup(SDLK_F14), key2tup(SDLK_F15), key2tup(SDLK_F16), key2tup(SDLK_F17),
        key2tup(SDLK_F18), key2tup(SDLK_F19), key2tup(SDLK_F2), key2tup(SDLK_F20),
        key2tup(SDLK_F21), key2tup(SDLK_F22), key2tup(SDLK_F23), key2tup(SDLK_F24),
        key2tup(SDLK_F3), key2tup(SDLK_F4), key2tup(SDLK_F5), key2tup(SDLK_F6),
        key2tup(SDLK_F7), key2tup(SDLK_F8), key2tup(SDLK_F9), key2tup(SDLK_FIND),
        key2tup(SDLK_g), key2tup(SDLK_GREATER), key2tup(SDLK_h), key2tup(SDLK_HASH),
        key2tup(SDLK_HELP), key2tup(SDLK_HOME), key2tup(SDLK_i), key2tup(SDLK_INSERT),
        key2tup(SDLK_j), key2tup(SDLK_k), key2tup(SDLK_KBDILLUMDOWN),
        key2tup(SDLK_KBDILLUMTOGGLE), key2tup(SDLK_KBDILLUMUP), key2tup(SDLK_KP_0),
        key2tup(SDLK_KP_00), key2tup(SDLK_KP_000), key2tup(SDLK_KP_1),
        key2tup(SDLK_KP_2), key2tup(SDLK_KP_3), key2tup(SDLK_KP_4), key2tup(SDLK_KP_5),
        key2tup(SDLK_KP_6), key2tup(SDLK_KP_7), key2tup(SDLK_KP_8), key2tup(SDLK_KP_9),
        key2tup(SDLK_KP_A), key2tup(SDLK_KP_AMPERSAND), key2tup(SDLK_KP_AT),
        key2tup(SDLK_KP_B), key2tup(SDLK_KP_BACKSPACE), key2tup(SDLK_KP_BINARY),
        key2tup(SDLK_KP_C), key2tup(SDLK_KP_CLEAR), key2tup(SDLK_KP_CLEARENTRY),
        key2tup(SDLK_KP_COLON), key2tup(SDLK_KP_COMMA), key2tup(SDLK_KP_D),
        key2tup(SDLK_KP_DBLAMPERSAND), key2tup(SDLK_KP_DBLVERTICALBAR), key2tup(SDLK_KP_DECIMAL),
        key2tup(SDLK_KP_DIVIDE), key2tup(SDLK_KP_E), key2tup(SDLK_KP_ENTER),
        key2tup(SDLK_KP_EQUALS), key2tup(SDLK_KP_EQUALSAS400), key2tup(SDLK_KP_EXCLAM),
        key2tup(SDLK_KP_F), key2tup(SDLK_KP_GREATER), key2tup(SDLK_KP_HASH),
        key2tup(SDLK_KP_HEXADECIMAL), key2tup(SDLK_KP_LEFTBRACE), key2tup(SDLK_KP_LEFTPAREN),
        key2tup(SDLK_KP_LESS), key2tup(SDLK_KP_MEMADD), key2tup(SDLK_KP_MEMCLEAR),
        key2tup(SDLK_KP_MEMDIVIDE), key2tup(SDLK_KP_MEMMULTIPLY), key2tup(SDLK_KP_MEMRECALL),
        key2tup(SDLK_KP_MEMSTORE), key2tup(SDLK_KP_MEMSUBTRACT), key2tup(SDLK_KP_MINUS),
        key2tup(SDLK_KP_MULTIPLY), key2tup(SDLK_KP_OCTAL), key2tup(SDLK_KP_PERCENT),
        key2tup(SDLK_KP_PERIOD), key2tup(SDLK_KP_PLUS), key2tup(SDLK_KP_PLUSMINUS),
        key2tup(SDLK_KP_POWER), key2tup(SDLK_KP_RIGHTBRACE), key2tup(SDLK_KP_RIGHTPAREN),
        key2tup(SDLK_KP_SPACE), key2tup(SDLK_KP_TAB), key2tup(SDLK_KP_VERTICALBAR),
        key2tup(SDLK_KP_XOR), key2tup(SDLK_l), key2tup(SDLK_LALT), key2tup(SDLK_LCTRL),
        key2tup(SDLK_LEFT), key2tup(SDLK_LEFTBRACKET), key2tup(SDLK_LEFTPAREN),
        key2tup(SDLK_LESS), key2tup(SDLK_LGUI), key2tup(SDLK_LSHIFT), key2tup(SDLK_m),
        key2tup(SDLK_MAIL), key2tup(SDLK_MEDIASELECT), key2tup(SDLK_MENU),
        key2tup(SDLK_MINUS), key2tup(SDLK_MODE), key2tup(SDLK_MUTE), key2tup(SDLK_n),
        key2tup(SDLK_NUMLOCKCLEAR), key2tup(SDLK_o), key2tup(SDLK_OPER),
        key2tup(SDLK_OUT), key2tup(SDLK_p), key2tup(SDLK_PAGEDOWN), key2tup(SDLK_PAGEUP),
        key2tup(SDLK_PASTE), key2tup(SDLK_PAUSE), key2tup(SDLK_PERCENT),
        key2tup(SDLK_PERIOD), key2tup(SDLK_PLUS), key2tup(SDLK_POWER), key2tup(SDLK_PRINTSCREEN),
        key2tup(SDLK_PRIOR), key2tup(SDLK_q), key2tup(SDLK_QUESTION), key2tup(SDLK_QUOTE),
        key2tup(SDLK_QUOTEDBL), key2tup(SDLK_r), key2tup(SDLK_RALT), key2tup(SDLK_RCTRL),
        key2tup(SDLK_RETURN), key2tup(SDLK_RETURN2), key2tup(SDLK_RGUI), key2tup(SDLK_RIGHT),
        key2tup(SDLK_RIGHTBRACKET), key2tup(SDLK_RIGHTPAREN), key2tup(SDLK_RSHIFT),
        key2tup(SDLK_s), key2tup(SDLK_SCROLLLOCK), key2tup(SDLK_SELECT), key2tup(SDLK_SEMICOLON),
        key2tup(SDLK_SEPARATOR), key2tup(SDLK_SLASH), key2tup(SDLK_SLEEP), key2tup(SDLK_SPACE),
        key2tup(SDLK_STOP), key2tup(SDLK_SYSREQ), key2tup(SDLK_t), key2tup(SDLK_TAB),
        key2tup(SDLK_THOUSANDSSEPARATOR), key2tup(SDLK_u), key2tup(SDLK_UNDERSCORE),
        key2tup(SDLK_UNDO), key2tup(SDLK_UNKNOWN), key2tup(SDLK_UP), key2tup(SDLK_v),
        key2tup(SDLK_VOLUMEDOWN), key2tup(SDLK_VOLUMEUP), key2tup(SDLK_w),
        key2tup(SDLK_WWW), key2tup(SDLK_x), key2tup(SDLK_y), key2tup(SDLK_z),

        // SDL Scancode Constants
        scan2tup(SDL_SCANCODE_0), scan2tup(SDL_SCANCODE_1), scan2tup(SDL_SCANCODE_2),
        scan2tup(SDL_SCANCODE_3), scan2tup(SDL_SCANCODE_4), scan2tup(SDL_SCANCODE_5),
        scan2tup(SDL_SCANCODE_6), scan2tup(SDL_SCANCODE_7), scan2tup(SDL_SCANCODE_8),
        scan2tup(SDL_SCANCODE_9), scan2tup(SDL_SCANCODE_A), scan2tup(SDL_SCANCODE_AC_BACK),
        scan2tup(SDL_SCANCODE_AC_BOOKMARKS), scan2tup(SDL_SCANCODE_AC_FORWARD),
        scan2tup(SDL_SCANCODE_AC_HOME), scan2tup(SDL_SCANCODE_AC_REFRESH), scan2tup(SDL_SCANCODE_AC_SEARCH),
        scan2tup(SDL_SCANCODE_AC_STOP), scan2tup(SDL_SCANCODE_AGAIN), scan2tup(SDL_SCANCODE_ALTERASE),
        scan2tup(SDL_SCANCODE_APOSTROPHE), scan2tup(SDL_SCANCODE_APP1), scan2tup(SDL_SCANCODE_APP2),
        scan2tup(SDL_SCANCODE_APPLICATION), scan2tup(SDL_SCANCODE_AUDIOMUTE), scan2tup(SDL_SCANCODE_AUDIONEXT),
        scan2tup(SDL_SCANCODE_AUDIOPLAY), scan2tup(SDL_SCANCODE_AUDIOPREV), scan2tup(SDL_SCANCODE_AUDIOSTOP),
        scan2tup(SDL_SCANCODE_B), scan2tup(SDL_SCANCODE_BACKSLASH), scan2tup(SDL_SCANCODE_BACKSPACE),
        scan2tup(SDL_SCANCODE_BRIGHTNESSDOWN), scan2tup(SDL_SCANCODE_BRIGHTNESSUP), scan2tup(SDL_SCANCODE_C),
        scan2tup(SDL_SCANCODE_CALCULATOR), scan2tup(SDL_SCANCODE_CANCEL), scan2tup(SDL_SCANCODE_CAPSLOCK),
        scan2tup(SDL_SCANCODE_CLEAR), scan2tup(SDL_SCANCODE_CLEARAGAIN), scan2tup(SDL_SCANCODE_COMMA),
        scan2tup(SDL_SCANCODE_COMPUTER), scan2tup(SDL_SCANCODE_COPY), scan2tup(SDL_SCANCODE_CRSEL),
        scan2tup(SDL_SCANCODE_CURRENCYSUBUNIT), scan2tup(SDL_SCANCODE_CURRENCYUNIT), scan2tup(SDL_SCANCODE_CUT),
        scan2tup(SDL_SCANCODE_D), scan2tup(SDL_SCANCODE_DECIMALSEPARATOR), scan2tup(SDL_SCANCODE_DELETE),
        scan2tup(SDL_SCANCODE_DISPLAYSWITCH), scan2tup(SDL_SCANCODE_DOWN), scan2tup(SDL_SCANCODE_E),
        scan2tup(SDL_SCANCODE_EJECT), scan2tup(SDL_SCANCODE_END), scan2tup(SDL_SCANCODE_EQUALS),
        scan2tup(SDL_SCANCODE_ESCAPE), scan2tup(SDL_SCANCODE_EXECUTE), scan2tup(SDL_SCANCODE_EXSEL),
        scan2tup(SDL_SCANCODE_F), scan2tup(SDL_SCANCODE_F1), scan2tup(SDL_SCANCODE_F10),
        scan2tup(SDL_SCANCODE_F11), scan2tup(SDL_SCANCODE_F12), scan2tup(SDL_SCANCODE_F13),
        scan2tup(SDL_SCANCODE_F14), scan2tup(SDL_SCANCODE_F15), scan2tup(SDL_SCANCODE_F16),
        scan2tup(SDL_SCANCODE_F17), scan2tup(SDL_SCANCODE_F18), scan2tup(SDL_SCANCODE_F19),
        scan2tup(SDL_SCANCODE_F2), scan2tup(SDL_SCANCODE_F20), scan2tup(SDL_SCANCODE_F21),
        scan2tup(SDL_SCANCODE_F22), scan2tup(SDL_SCANCODE_F23), scan2tup(SDL_SCANCODE_F24),
        scan2tup(SDL_SCANCODE_F3), scan2tup(SDL_SCANCODE_F4), scan2tup(SDL_SCANCODE_F5),
        scan2tup(SDL_SCANCODE_F6), scan2tup(SDL_SCANCODE_F7), scan2tup(SDL_SCANCODE_F8),
        scan2tup(SDL_SCANCODE_F9), scan2tup(SDL_SCANCODE_FIND), scan2tup(SDL_SCANCODE_G),
        scan2tup(SDL_SCANCODE_GRAVE), scan2tup(SDL_SCANCODE_H), scan2tup(SDL_SCANCODE_HELP),
        scan2tup(SDL_SCANCODE_HOME), scan2tup(SDL_SCANCODE_I), scan2tup(SDL_SCANCODE_INSERT),
        scan2tup(SDL_SCANCODE_INTERNATIONAL1), scan2tup(SDL_SCANCODE_INTERNATIONAL2),
        scan2tup(SDL_SCANCODE_INTERNATIONAL3), scan2tup(SDL_SCANCODE_INTERNATIONAL4),
        scan2tup(SDL_SCANCODE_INTERNATIONAL5), scan2tup(SDL_SCANCODE_INTERNATIONAL6),
        scan2tup(SDL_SCANCODE_INTERNATIONAL7), scan2tup(SDL_SCANCODE_INTERNATIONAL8),
        scan2tup(SDL_SCANCODE_INTERNATIONAL9), scan2tup(SDL_SCANCODE_J), scan2tup(SDL_SCANCODE_K),
        scan2tup(SDL_SCANCODE_KBDILLUMDOWN), scan2tup(SDL_SCANCODE_KBDILLUMTOGGLE), scan2tup(SDL_SCANCODE_KBDILLUMUP),
        scan2tup(SDL_SCANCODE_KP_0), scan2tup(SDL_SCANCODE_KP_00), scan2tup(SDL_SCANCODE_KP_000),
        scan2tup(SDL_SCANCODE_KP_1), scan2tup(SDL_SCANCODE_KP_2), scan2tup(SDL_SCANCODE_KP_3),
        scan2tup(SDL_SCANCODE_KP_4), scan2tup(SDL_SCANCODE_KP_5), scan2tup(SDL_SCANCODE_KP_6),
        scan2tup(SDL_SCANCODE_KP_7), scan2tup(SDL_SCANCODE_KP_8), scan2tup(SDL_SCANCODE_KP_9),
        scan2tup(SDL_SCANCODE_KP_A), scan2tup(SDL_SCANCODE_KP_AMPERSAND), scan2tup(SDL_SCANCODE_KP_AT),
        scan2tup(SDL_SCANCODE_KP_B), scan2tup(SDL_SCANCODE_KP_BACKSPACE), scan2tup(SDL_SCANCODE_KP_BINARY),
        scan2tup(SDL_SCANCODE_KP_C), scan2tup(SDL_SCANCODE_KP_CLEAR), scan2tup(SDL_SCANCODE_KP_CLEARENTRY),
        scan2tup(SDL_SCANCODE_KP_COLON), scan2tup(SDL_SCANCODE_KP_COMMA), scan2tup(SDL_SCANCODE_KP_D),
        scan2tup(SDL_SCANCODE_KP_DBLAMPERSAND), scan2tup(SDL_SCANCODE_KP_DBLVERTICALBAR),
        scan2tup(SDL_SCANCODE_KP_DECIMAL), scan2tup(SDL_SCANCODE_KP_DIVIDE), scan2tup(SDL_SCANCODE_KP_E),
        scan2tup(SDL_SCANCODE_KP_ENTER), scan2tup(SDL_SCANCODE_KP_EQUALS), scan2tup(SDL_SCANCODE_KP_EQUALSAS400),
        scan2tup(SDL_SCANCODE_KP_EXCLAM), scan2tup(SDL_SCANCODE_KP_F), scan2tup(SDL_SCANCODE_KP_GREATER),
        scan2tup(SDL_SCANCODE_KP_HASH), scan2tup(SDL_SCANCODE_KP_HEXADECIMAL), scan2tup(SDL_SCANCODE_KP_LEFTBRACE),
        scan2tup(SDL_SCANCODE_KP_LEFTPAREN), scan2tup(SDL_SCANCODE_KP_LESS), scan2tup(SDL_SCANCODE_KP_MEMADD),
        scan2tup(SDL_SCANCODE_KP_MEMCLEAR), scan2tup(SDL_SCANCODE_KP_MEMDIVIDE), scan2tup(SDL_SCANCODE_KP_MEMMULTIPLY),
        scan2tup(SDL_SCANCODE_KP_MEMRECALL), scan2tup(SDL_SCANCODE_KP_MEMSTORE), scan2tup(SDL_SCANCODE_KP_MEMSUBTRACT),
        scan2tup(SDL_SCANCODE_KP_MINUS), scan2tup(SDL_SCANCODE_KP_MULTIPLY), scan2tup(SDL_SCANCODE_KP_OCTAL),
        scan2tup(SDL_SCANCODE_KP_PERCENT), scan2tup(SDL_SCANCODE_KP_PERIOD), scan2tup(SDL_SCANCODE_KP_PLUS),
        scan2tup(SDL_SCANCODE_KP_PLUSMINUS), scan2tup(SDL_SCANCODE_KP_POWER), scan2tup(SDL_SCANCODE_KP_RIGHTBRACE),
        scan2tup(SDL_SCANCODE_KP_RIGHTPAREN), scan2tup(SDL_SCANCODE_KP_SPACE), scan2tup(SDL_SCANCODE_KP_TAB),
        scan2tup(SDL_SCANCODE_KP_VERTICALBAR), scan2tup(SDL_SCANCODE_KP_XOR), scan2tup(SDL_SCANCODE_L),
        scan2tup(SDL_SCANCODE_LALT), scan2tup(SDL_SCANCODE_LANG1), scan2tup(SDL_SCANCODE_LANG2),
        scan2tup(SDL_SCANCODE_LANG3), scan2tup(SDL_SCANCODE_LANG4), scan2tup(SDL_SCANCODE_LANG5),
        scan2tup(SDL_SCANCODE_LANG6), scan2tup(SDL_SCANCODE_LANG7), scan2tup(SDL_SCANCODE_LANG8),
        scan2tup(SDL_SCANCODE_LANG9), scan2tup(SDL_SCANCODE_LCTRL), scan2tup(SDL_SCANCODE_LEFT),
        scan2tup(SDL_SCANCODE_LEFTBRACKET), scan2tup(SDL_SCANCODE_LGUI), scan2tup(SDL_SCANCODE_LSHIFT),
        scan2tup(SDL_SCANCODE_M), scan2tup(SDL_SCANCODE_MAIL), scan2tup(SDL_SCANCODE_MEDIASELECT),
        scan2tup(SDL_SCANCODE_MENU), scan2tup(SDL_SCANCODE_MINUS), scan2tup(SDL_SCANCODE_MODE),
        scan2tup(SDL_SCANCODE_MUTE), scan2tup(SDL_SCANCODE_N), scan2tup(SDL_SCANCODE_NONUSBACKSLASH),
        scan2tup(SDL_SCANCODE_NONUSHASH), scan2tup(SDL_SCANCODE_NUMLOCKCLEAR), scan2tup(SDL_SCANCODE_O),
        scan2tup(SDL_SCANCODE_OPER), scan2tup(SDL_SCANCODE_OUT), scan2tup(SDL_SCANCODE_P),
        scan2tup(SDL_SCANCODE_PAGEDOWN), scan2tup(SDL_SCANCODE_PAGEUP), scan2tup(SDL_SCANCODE_PASTE),
        scan2tup(SDL_SCANCODE_PAUSE), scan2tup(SDL_SCANCODE_PERIOD), scan2tup(SDL_SCANCODE_POWER),
        scan2tup(SDL_SCANCODE_PRINTSCREEN), scan2tup(SDL_SCANCODE_PRIOR), scan2tup(SDL_SCANCODE_Q),
        scan2tup(SDL_SCANCODE_R), scan2tup(SDL_SCANCODE_RALT), scan2tup(SDL_SCANCODE_RCTRL),
        scan2tup(SDL_SCANCODE_RETURN), scan2tup(SDL_SCANCODE_RETURN2), scan2tup(SDL_SCANCODE_RGUI),
        scan2tup(SDL_SCANCODE_RIGHT), scan2tup(SDL_SCANCODE_RIGHTBRACKET), scan2tup(SDL_SCANCODE_RSHIFT),
        scan2tup(SDL_SCANCODE_S), scan2tup(SDL_SCANCODE_SCROLLLOCK), scan2tup(SDL_SCANCODE_SELECT),
        scan2tup(SDL_SCANCODE_SEMICOLON), scan2tup(SDL_SCANCODE_SEPARATOR), scan2tup(SDL_SCANCODE_SLASH),
        scan2tup(SDL_SCANCODE_SLEEP), scan2tup(SDL_SCANCODE_SPACE), scan2tup(SDL_SCANCODE_STOP),
        scan2tup(SDL_SCANCODE_SYSREQ), scan2tup(SDL_SCANCODE_T), scan2tup(SDL_SCANCODE_TAB),
        scan2tup(SDL_SCANCODE_THOUSANDSSEPARATOR), scan2tup(SDL_SCANCODE_U), scan2tup(SDL_SCANCODE_UNDO),
        scan2tup(SDL_SCANCODE_UNKNOWN), scan2tup(SDL_SCANCODE_UP), scan2tup(SDL_SCANCODE_V),
        scan2tup(SDL_SCANCODE_VOLUMEDOWN), scan2tup(SDL_SCANCODE_VOLUMEUP), scan2tup(SDL_SCANCODE_W),
        scan2tup(SDL_SCANCODE_WWW), scan2tup(SDL_SCANCODE_X), scan2tup(SDL_SCANCODE_Y),
        scan2tup(SDL_SCANCODE_Z)
    };
    for(int i = 0; i < inits.size(); i++) {
        int def;
        std::string name;
        std::tie(def, name) = inits[i];
        lua_pushinteger(L, def);
        lua_setfield(L, -2, name.c_str());
    }
}

#pragma mark -
#pragma mark SDL2_Image Wrapper
/*
 SDL2_Image wrapper functions.
 */

static int wrap_sdl_img_init(lua_State *L) {
    if(lua_gettop(L) < 1) {
        luaL_error(L, "img.init expected 1 argument.");
        return 0;
    }

    int flags = luaL_checkint(L, 1);
    int err = IMG_Init(flags);
    if(0 == err) {
        std::stringstream ss;
        ss << "Error when initialized SDL2 Image: " << IMG_GetError();
        luaL_error(L, ss.str().c_str());
        return 0;
    }
    return 0;
}

static int wrap_sdl_img_load(lua_State *L) {
    if(lua_gettop(L) < 1) {
        luaL_error(L, "img.load expected 1 argument.");
        return 0;
    }

    std::string file(luaL_checkstring(L, 1));
//    file = fs::pathJoin(fs::getLuaSourcePath(), file);

    SDL_Surface **surface = (SDL_Surface **)lua_newuserdata(L, sizeof(SDL_Surface *));
    *surface = IMG_Load(file.c_str());
    if(NULL == *surface) {
        std::stringstream ss;
        ss << "Error when loading image: " << IMG_GetError();
        luaL_error(L, ss.str().c_str());
        return 0;
    }

    luaL_getmetatable(L, SURFACE_METATABLE);
    lua_setmetatable(L, -2);
    return 1;
}

#pragma mark SDL2_Image lua module
static const struct luaL_Reg luaimglib [] {
    {"init", wrap_sdl_img_init},
    {"load", wrap_sdl_img_load},
    {NULL, NULL}
};

static void InitIMGBindings(lua_State *L) {
    luaL_newlib(L, luaimglib);

    lua_pushinteger(L, IMG_INIT_JPG);
    lua_setfield(L, -2, "INIT_JPG");
    lua_pushinteger(L, IMG_INIT_PNG);
    lua_setfield(L, -2, "INIT_PNG");
    lua_pushinteger(L, IMG_INIT_TIF);
    lua_setfield(L, -2, "INIT_TIF");
    lua_pushinteger(L, IMG_INIT_WEBP);
    lua_setfield(L, -2, "INIT_WEBP");
}

#pragma mark -
#pragma mark SDL_Font Wrapper

static int wrap_ttf_font_sizetext(lua_State *L) {
    int numargs = lua_gettop(L);
    if(numargs < 2) {
        luaL_error(L, "TTF_Font:sizeText: Requires a string to get the size of.");
        return 0;
    }

    TTF_Font *font = checkfont(L, 1);
    const char *str = luaL_checkstring(L, 2);
    int w, h;
    int err = TTF_SizeText(font, str, &w, &h);
    if(err < 0) {
        std::stringstream ss;
        ss << "TTF_Font:sizeText: ERROR when calling TTF_SizeText: " << TTF_GetError();
        luaL_error(L, ss.str().c_str());
        return 0;
    }

    lua_pushinteger(L, w);
    lua_pushinteger(L, h);
    return 2;
}

static int wrap_ttf_font_sizeutf8(lua_State *L) {
    int numargs = lua_gettop(L);
    if(numargs < 2) {
        luaL_error(L, "TTF_Font:sizeUTF8: Requires a string to get the size of.");
        return 0;
    }

    TTF_Font *font = checkfont(L, 1);
    const char *str = luaL_checkstring(L, 2);
    int w, h;
    int err = TTF_SizeUTF8(font, str, &w, &h);
    if(err < 0) {
        std::stringstream ss;
        ss << "TTF_Font:sizeText: ERROR when calling TTF_SizeUTF8: " << TTF_GetError();
        luaL_error(L, ss.str().c_str());
        return 0;
    }

    lua_pushinteger(L, w);
    lua_pushinteger(L, h);
    return 2;
}

static int wrap_ttf_font_rendertextsolid(lua_State *L) {
    int numargs = lua_gettop(L);
    if(numargs < 5) {
        luaL_error(L, "TTF_Font:renderTextSolid: Requires a string and r, g, b colors.");
        return 0;
    }

    TTF_Font *font = checkfont(L, 1);
    const char *str = luaL_checkstring(L, 2);
    int r = luaL_checkint(L, 3);
    int g = luaL_checkint(L, 4);
    int b = luaL_checkint(L, 5);
    SDL_Color color;
    color.r = r;
    color.g = g;
    color.b = b;
    SDL_Surface **surface = (SDL_Surface **)lua_newuserdata(L, sizeof(SDL_Surface *));
    *surface = TTF_RenderText_Solid(font, str, color);
    if(NULL == *surface) {
        std::stringstream ss;
        ss << "TTF_Font:renderTextSolid: ERROR calling TTF_RenderText_Solid: " << TTF_GetError();
        luaL_error(L, ss.str().c_str());
        return 0;
    }

    luaL_getmetatable(L, SURFACE_METATABLE);
    lua_setmetatable(L, -2);

    return 1;
}

static int wrap_ttf_font_rendertextblended(lua_State *L) {
    int numargs = lua_gettop(L);
    if(numargs < 5) {
        luaL_error(L, "TTF_Font:renderTextBlended: Requires a string and r, g, b colors.");
        return 0;
    }

    TTF_Font *font = checkfont(L, 1);
    const char *str = luaL_checkstring(L, 2);
    int r = luaL_checkint(L, 3);
    int g = luaL_checkint(L, 4);
    int b = luaL_checkint(L, 5);
    SDL_Color color;
    color.r = r;
    color.g = g;
    color.b = b;
    SDL_Surface **surface = (SDL_Surface **)lua_newuserdata(L, sizeof(SDL_Surface *));
    *surface = TTF_RenderText_Blended(font, str, color);
    if(NULL == *surface) {
        std::stringstream ss;
        ss << "TTF_Font:renderTextSolid: ERROR calling TTF_RenderText_Blended: " << TTF_GetError();
        luaL_error(L, ss.str().c_str());
        return 0;
    }

    luaL_getmetatable(L, SURFACE_METATABLE);
    lua_setmetatable(L, -2);

    return 1;
}

static int wrap_ttf_font_renderutf8blended(lua_State *L) {
    int numargs = lua_gettop(L);
    if(numargs < 5) {
        luaL_error(L, "TTF_Font:renderUTF8Blended: Requires a string and r, g, b colors.");
        return 0;
    }

    TTF_Font *font = checkfont(L, 1);
    const char *str = luaL_checkstring(L, 2);
    int r = luaL_checkint(L, 3);
    int g = luaL_checkint(L, 4);
    int b = luaL_checkint(L, 5);
    SDL_Color color;
    color.r = r;
    color.g = g;
    color.b = b;
    SDL_Surface **surface = (SDL_Surface **)lua_newuserdata(L, sizeof(SDL_Surface *));
    *surface = TTF_RenderUTF8_Blended(font, str, color);
    if(NULL == *surface) {
        std::stringstream ss;
        ss << "TTF_Font:renderUTF8Solid: ERROR calling TTF_RenderUTF8_Blended: " << TTF_GetError();
        luaL_error(L, ss.str().c_str());
        return 0;
    }

    luaL_getmetatable(L, SURFACE_METATABLE);
    lua_setmetatable(L, -2);

    return 1;
}

static int font_gc_meta(lua_State *L) {
    TTF_Font *font = checkfont(L, 1);
    if(NULL != font) {
        TTF_CloseFont(font);
    }
    return 0;
}

static const struct luaL_Reg ttffontlib [] {
    {"sizeText", wrap_ttf_font_sizetext},
    {"sizeUTF8", wrap_ttf_font_sizeutf8},
    {"renderTextSolid", wrap_ttf_font_rendertextsolid},
    {"renderTextBlended", wrap_ttf_font_rendertextblended},
    {"renderUTF8Blended", wrap_ttf_font_renderutf8blended},

    {"__gc", font_gc_meta},

    {NULL, NULL}
};

#pragma mark -
#pragma mark SDL_TTF Wrapper

static int ttf_wrap_init(lua_State *L) {
    TTF_Init();
    return 0;
}

static int ttf_wrap_openfont(lua_State *L) {
    int numargs = lua_gettop(L);
    if(numargs < 2) {
        luaL_error(L, "ttf.openFont: Requires 2 args: font name and font size.");
        return 0;
    }

    std::string fontName(luaL_checkstring(L, 1));
    int fontSize = luaL_checkint(L, 2);
    TTF_Font **font = (TTF_Font**)lua_newuserdata(L, sizeof(TTF_Font *));
    *font = TTF_OpenFont(fontName.c_str(), fontSize);
    if(NULL == *font) {
        std::stringstream ss;
        ss << "ttf.openFont: ERROR calling TTF_OpenFont: " << TTF_GetError();
        luaL_error(L, ss.str().c_str());
    }

    luaL_getmetatable(L, FONT_METATABLE);
    lua_setmetatable(L, -2);

    return 1;
}

static const struct luaL_Reg luattflib [] {
    {"init", ttf_wrap_init},
    {"openFont", ttf_wrap_openfont},

    {NULL, NULL}
};

static void InitTTFBindings(lua_State *L) {
    luaL_newmetatable(L, FONT_METATABLE);
    lua_pushvalue(L, -1);
    lua_setfield(L, -2, "__index");
    luaL_setfuncs(L, ttffontlib, 0);
    
    luaL_newlib(L, luattflib);
}

#pragma mark -
#pragma mark SDL_Mixer Wrapper

static void InitMixerBindings(lua_State *L) {
    // TODO: Implement
}

int luaload_sdl2(lua_State *L) {
    InitSDLBindings(L);
    return 1;
}

int luaload_img(lua_State *L) {
    InitIMGBindings(L);
    return 1;
}

int luaload_ttf(lua_State *L) {
    InitTTFBindings(L);
    return 1;
}

int luaload_mixer(lua_State *L) {
    InitMixerBindings(L);
    return 1;
}