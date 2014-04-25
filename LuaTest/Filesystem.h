//
//  Filesystem.h
//  LuaTest
//
//  Created by Vincent K on 4/7/14.
//  Copyright (c) 2014 Unlocked Doors. All rights reserved.
//

#ifndef __LuaTest__Filesystem__
#define __LuaTest__Filesystem__

#include <iostream>

namespace fs {
    std::string getLuaSourcePath();
    std::string pathJoin(std::string left, std::string right);
}

#endif /* defined(__LuaTest__Filesystem__) */
