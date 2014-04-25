local log = {
    _AUTHOR      = "Vincent 'Freezerburn Vinny' Kuyatt",
    _EMAIL       = "vincentk@unlocked-doors.com",
    _VERSION     = "log 0.1",
    _DESCRIPTION = "Simple logging for Lua",
    _URL         = "None. Maybe Github after Ludum Dare?",
    _LICENSE     = [[
        MIT LICENSE

        Copyright (c) 2014 Vincent Kuyatt

        Permission is hereby granted, free of charge, to any person obtaining a
        copy of this software and associated documentation files (the
        "Software"), to deal in the Software without restriction, including
        without limitation the rights to use, copy, modify, merge, publish,
        distribute, sublicense, and/or sell copies of the Software, and to
        permit persons to whom the Software is furnished to do so, subject to
        the following conditions:

        The above copyright notice and this permission notice shall be included
        in all copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
        OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
        MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
        IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
        CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
        TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
        SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    ]]
}

log.LEVEL_CRITICAL = 0
log.LEVEL_ERROR = 1
log.LEVEL_WARNING = 2
log.LEVEL_INFO = 3
log.LEVEL_DEBUG = 4
local _logLevel = log.LEVEL_DEBUG

function log.setLevel(level)
    _logLevel = level
end

function _parseTraceback()
    local tracebackInfos = {}
    for file, line, fun in string.gmatch(debug.traceback(), "/([a-zA-Z0-9]*[.]lua):([0-9]*): in function '(%a*)'") do
        tracebackInfos[#tracebackInfos + 1] = {
            file = file,
            line = line,
            f = fun
        }
    end
    return tracebackInfos
end

function log.critical(str, ...)
    if log.LEVEL_CRITICAL <= _logLevel then
        local tracebackInfos = _parseTraceback()
        local file = tracebackInfos[2].file
        local line = tracebackInfos[2].line
        local f = tracebackInfos[2].f
        print(string.format("[CRITICAL] %s:%s function %s: " .. str, file, line, f, ...))
    end
end
function log.error(str, ...)
    if log.LEVEL_ERROR <= _logLevel then
        local tracebackInfos = _parseTraceback()
        local file = tracebackInfos[2].file
        local line = tracebackInfos[2].line
        local f = tracebackInfos[2].f
        print(string.format("[ERROR] %s:%s function %s: " .. str, file, line, f, ...))
    end
end
function log.warning(str, ...)
    if log.LEVEL_WARNING <= _logLevel then
        local tracebackInfos = _parseTraceback()
        local file = tracebackInfos[2].file
        local line = tracebackInfos[2].line
        local f = tracebackInfos[2].f
        print(string.format("[WARNING] %s:%s function %s: " .. str, file, line, f, ...))
    end
end
function log.info(str, ...)
    if log.LEVEL_INFO <= _logLevel then
        local tracebackInfos = _parseTraceback()
        local file = tracebackInfos[2].file
        local line = tracebackInfos[2].line
        local f = tracebackInfos[2].f
        print(string.format("[INFO] %s:%s function %s: " .. str, file, line, f, ...))
    end
end
function log.debug(str, ...)
    if log.LEVEL_DEBUG <= _logLevel then
        local tracebackInfos = _parseTraceback()
        local file = tracebackInfos[2].file
        local line = tracebackInfos[2].line
        local f = tracebackInfos[2].f
        print(string.format("[DEBUG] %s:%s function %s: " .. str, file, line, f, ...))
    end
end

return log
