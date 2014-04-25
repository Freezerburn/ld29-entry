//
//  Filesystem.cpp
//  LuaTest
//
//  Created by Vincent K on 4/7/14.
//  Copyright (c) 2014 Unlocked Doors. All rights reserved.
//

#include "Filesystem.h"

#if defined(__APPLE__) && !defined(EMSCRIPTEN)
#include <Foundation/Foundation.h>
#include <unistd.h>
#endif

namespace fs {
    std::string getLuaSourcePath() {
#if defined(__APPLE__) && !defined(EMSCRIPTEN)
        std::string resourcePath([[[NSBundle mainBundle] resourcePath] UTF8String]);
#elif defined(EMSCRIPTEN)
        std::string resourcePath("lua");
#endif
        return resourcePath;
    }

    std::string pathJoin(std::string left, std::string right) {
        if(left.empty()) {
            return right;
        }
        else {
            return left + "/" + right;
        }
    }
}