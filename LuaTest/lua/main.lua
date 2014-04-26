package.path = lfs.packagedir() .. "/?.lua"

local _width = 640
local _height = 480
local _windowFlags = bit32.bor(sdl.WINDOW_OPENGL,
    sdl.WINDOW_ALLOW_HIGHDPI, sdl.WINDOW_SHOWN,
    sdl.WINDOW_MOUSE_FOCUS, sdl.WINDOW_INPUT_FOCUS)
local _renderFlags = bit32.bor(sdl.RENDERER_PRESENTVSYNC, sdl.RENDERER_ACCELERATED)
local _tickTime = 1 / 60
local window = nil
local renderer = nil

local font = nil
local startMenuScene = nil

local engine = require "engine"
local class = require "middleclass"
local log = require "log"

local components = require "components"
local entities = require "entities"

local Entity = engine.Entity
local Vector = engine.Vector
local Rectangle = engine.Rectangle
local getCurrentScene = engine.getCurrentScene

function main()
    sdl.init(sdl.INIT_EVERYTHING)
    ttf.init()
    img.init(bit32.bor(img.INIT_JPG, img.INIT_PNG))

    window = sdl.createWindow("LD29!",
        sdl.WINDOWPOS_UNDEFINED, sdl.WINDOWPOS_UNDEFINED,
        _width, _height,
        _windowFlags)
    renderer = sdl.createRenderer(window, -1, _renderFlags)

    font = ttf.openFont("Arial.ttf", 42)

    startMenuScene = engine.Scene.new({
        name = "StartScreen",
        init = function(self)
        end
    })
    engine.Scene.swap(startMenuScene)

    engine.startGameLoop(renderer, _tickTime)
end
