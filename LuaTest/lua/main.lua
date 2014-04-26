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
local dialogBubbleFont = nil
local systemDialogFont = nil
local npcDialogWidth = 150
local npcDialogBuffer = 10
local npcTextBackground = {r = 0, g = 0, b = 0}
-- local npcTextColor = {r = 255, g = 255, b = 255}
local npcTextColor = {r = 0, g = 255, b = 255}

local tileSize = 16
local tileDrawSize = 48
local wallColor = {r = 255, g = 50, b = 50}
local floorLayer = 0
local wallLayer = 5
local triggerLayer = 6
local playerLayer = 10
local playerSpeed = 250
local useKey = sdl.KEY_E
local gameScene = nil
local triggerCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local timersCreated = 0

local glyphs = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789?!.,-()'\" "
local glyphAtlas = {}

local engine = require "engine"
local class = require "middleclass"
local log = require "log"

local components = require "components"
local entities = require "entities"

local Entity = engine.Entity
local Vector = engine.Vector
local Rectangle = engine.Rectangle
local getCurrentScene = engine.getCurrentScene

Player = class("Player", Entity)
Player:include(components.FourWayMovement)
Player:include(components.Animated)
function Player:init(settings)
    self:initAnimated()
    self:addAnimation({
        filename = "PlayerSheet.png",
        name = "idle",
        frames = 1,
        width = tileSize,
        height = tileSize,
        start = {x = 0, y = 0},
        animationTime = 0.15
    })
    self:addAnimation({
        filename = "PlayerSheet.png",
        name = "walkRight",
        frames = 3,
        width = tileSize,
        height = tileSize,
        start = {x = 0, y = 16},
        animationTime = 0.15
    })
    self:addAnimation({
        filename = "PlayerSheet.png",
        name = "walkLeft",
        frames = 3,
        width = tileSize,
        height = tileSize,
        start = {x = 0, y = 32},
        animationTime = 0.15
    })
    self:addAnimation({
        filename = "PlayerSheet.png",
        name = "walkDown",
        frames = 3,
        width = tileSize,
        height = tileSize,
        start = {x = 0, y = 48},
        animationTime = 0.15
    })
    self:addAnimation({
        filename = "PlayerSheet.png",
        name = "walkUp",
        frames = 3,
        width = tileSize,
        height = tileSize,
        start = {x = 0, y = 64},
        animationTime = 0.15
    })
    self:initFourWayMovement({
        keys = {left = sdl.KEY_A, right = sdl.KEY_D, up = sdl.KEY_W, down = sdl.KEY_S},
        names = {left = "walkLeft", right = "walkRight", up = "walkUp", down = "walkDown", idle = "idle"},
        speed = {x = playerSpeed, y = playerSpeed}
    })
end
function Player:render(renderer, dt)
    self:renderAnimated(renderer, dt)
end
function Player:tick(dt)
    self:tickFourWayMovement(dt)
    self:tickMove(dt)
    self:tickAnimated(dt)
end
function Player:input(event, pushed)
    self:inputFourWayMovement(event, pushed)
end
function Player:collision(between, deltas)
    -- TODO: Fix player getting "caught" on the edge of a tile as the player pressed
    -- into the tile while also simultaneously moving along the tile.
    -- e.g.: Pressing left and up when against the left wall. Eventually the player
    -- will get "wedged" because when the collision happens, they are slightly in
    -- one tile pushing them out in the X direction, and on the border of another tile
    -- which is pushing them out in the Y direction. Not sure what the fix would be,
    -- so I'm going to leave it alone to work on other things instead of obsessing
    -- over slightly-imperfect collision detection which won't actually affect
    -- gameplay.
    local minx = math.huge
    local miny = math.huge
    for i, ent in ipairs(between) do
        if string.find(ent.name, "Wall") then
            if deltas[i].x ~= 0 and math.abs(deltas[i].x) < math.abs(minx) then
                minx = deltas[i].x
            end
            if deltas[i].y ~= 0 and math.abs(deltas[i].y) < math.abs(miny) then
                miny = deltas[i].y
            end
        end
    end
    if minx ~= math.huge then
        self._rect.x = self._rect.x + minx
    end
    if miny ~= math.huge then
        self._rect.y = self._rect.y + miny
    end
end
function Player:getRect()
    return Rectangle.new(self._rect.x + 15, self._rect.y + 15,
        self._rect.w - 25, self._rect.h - 25)
end

local wallsCreated = 0
Wall = class("Wall", Entity)
Wall:include(components.ColoredRect)
function Wall:init(settings)
    self:initColoredRect(renderer, settings.r, settings.g, settings.b,
        string.format("Wall{%d,%d,%d}", settings.r, settings.g, settings.b))
end
function Wall:render(renderer, dt)
    self:renderColoredRect(renderer, dt)
end

local numCreatedTriggers = 0
Level = class("Level", Entity)
function Level:init(settings)
    self._levelMatrix = {}
    local filename = lfs.packagedir() .. "/" .. settings.filename
    for line in io.lines(filename) do
        table.insert(self._levelMatrix, line)
    end

    for y, line in ipairs(self._levelMatrix) do
        local x = 1
        for c in line:gmatch(".") do
            if c == "#" then
                getCurrentScene():createEntity("Wall", "Wall" .. wallsCreated,
                    (x - 1) * tileDrawSize, (y - 1) * tileDrawSize,
                    tileDrawSize, tileDrawSize,
                    wallLayer, wallColor)
                wallsCreated = wallsCreated + 1
            elseif c == "@" then
                getCurrentScene():createEntity("Player", "Player",
                    (x - 1) * tileDrawSize, (y - 1) * tileDrawSize,
                    tileDrawSize, tileDrawSize, playerLayer)
            elseif triggerCharacters:find(c) then
                if settings[c] then
                    local triggerSettings = {callback = settings[c].callback,
                        name = c}
                    if settings[c].once then
                        triggerSettings.once = settings[c].once
                    end
                    if settings[c].triggerOnUse then
                        triggerSettings.onUse = settings[c].triggerOnUse
                    end
                    getCurrentScene():createEntity("Trigger", "Trigger" .. numCreatedTriggers,
                        (x - 1) * tileDrawSize, (y - 1) * tileDrawSize,
                        tileDrawSize, tileDrawSize, triggerLayer,
                        triggerSettings)
                    numCreatedTriggers = numCreatedTriggers + 1
                end
            end
            x = x + 1
        end
    end
end

Trigger = class("Trigger", Entity)
Trigger:include(components.ColoredRect)
function Trigger:init(settings)
    self._triggeredCallback = settings.callback
    self._triggerOnUse = settings.onUse
    self._triggerOnce = settings.once
    self._triggerName = settings.name
    self._triggered = false
    self._playerIn = false
    self:initColoredRect(renderer, 200, 200, 0, string.format("Trigger{%d,%d,%d}", 200, 200, 0))
end
function Trigger:render(renderer, dt)
    self:renderColoredRect(renderer, dt)
end
function Trigger:input(event, pushed)
    if self._triggerOnUse and
       not getCurrentScene().triggersThatHaveBeenTriggered[self._triggerName] and
       not getCurrentScene().triggeredThisFrame[self._triggerName] then
        if pushed and not event.repeated then
            if string.find(event.name, "KEY") then
                if event.sym == useKey then
                    self._triggeredCallback(self._rect)
                    getCurrentScene().triggeredThisFrame[self._triggerName] = true
                    if self._triggerOnce then
                        getCurrentScene().triggersThatHaveBeenTriggered[self._triggerName] = true
                    end
                end
            end
        end
    end
end
function Trigger:collision(between, deltas)
    if not self._triggerOnUse and
       not getCurrentScene().triggersThatHaveBeenTriggered[self._triggerName] and
       not getCurrentScene().triggeredThisFrame[self._triggerName] then
        local entsColliding = 0
        for i, ent in ipairs(between) do
            entsColliding = entsColliding + 1
            if ent.name:find("Player") then
                if not self._triggerOnUse then
                    self._triggeredCallback(self._rect)
                    getCurrentScene().triggeredThisFrame[self._triggerName] = true
                    if self._triggerOnce then
                        getCurrentScene().triggersThatHaveBeenTriggered[self._triggerName] = true
                    end
                else
                    self._playerIn = true
                end
            end
        end
        if entsColliding == 0 and self._playerIn then
            self._playerIn = false
        end
    end
end

TextBubble = class("TextBubble", Entity)
TextBubble:include(components.ColoredRect)
function TextBubble:init(settings)
    self._text = settings.text
    self._backgroundColor = settings.background
    self._textColor = settings.textColor
    self._font = settings.font
    self._rect.h = engine.getLinesHeight(self._font, self._textColor, self._rect.w, self._text)
    local halfBuffer = settings.buffer / 2
    self._buffer = settings.buffer
    self._rect.w = self._rect.w + settings.buffer
    self._rect.h = self._rect.h + settings.buffer
    self._rect.x = self._rect.x - halfBuffer - self._rect.w / 2
    self._rect.y = self._rect.y - halfBuffer - self._rect.h
    self._textOrigin = {x = self._rect.x + halfBuffer, y = self._rect.y + halfBuffer}
    self:initColoredRect(self._renderer,
        self._backgroundColor.r, self._backgroundColor.g, self._backgroundColor.b,
        string.format("TextBubble{%d,%d,%d}",
            self._backgroundColor.r, self._backgroundColor.g, self._backgroundColor.b))
    local this = self
    getCurrentScene():createEntity("Timer", "Timer" .. timersCreated, 0, 0, 0, 0, 0,
        {timeout = settings.timeout, callback = function() this:kill() end})
    timersCreated = timersCreated + 1
end
function TextBubble:render(renderer, dt)
    self:renderColoredRect(renderer, dt)
    engine.renderLines(self._font, self._textColor, self._textOrigin, self._rect.w - self._buffer, self._text)
end

Cleanup = class("Cleanup", Entity)
function Cleanup:render()
    getCurrentScene().triggeredThisFrame = {}
end

function main()
    sdl.init(sdl.INIT_EVERYTHING)
    ttf.init()
    img.init(bit32.bor(img.INIT_JPG, img.INIT_PNG))

    window = sdl.createWindow("LD29!",
        sdl.WINDOWPOS_UNDEFINED, sdl.WINDOWPOS_UNDEFINED,
        _width, _height,
        _windowFlags)
    renderer = sdl.createRenderer(window, -1, _renderFlags)
    engine.renderer = renderer

    font = ttf.openFont("Arial.ttf", 42)
    dialogBubbleFont = ttf.openFont("Arial.ttf", 18)
    systemDialogFont = ttf.openFont("Arial.ttf", 26)
    engine.cacheAtlas(font, {r=0, g=0, b=0}, glyphs)
    engine.cacheAtlas(dialogBubbleFont, npcTextColor, glyphs)
    engine.cacheAtlas(systemDialogFont, {r=0, g=0, b=0}, glyphs)

    gameScene = engine.Scene.new({
        name = "StartScreen",
        init = function(self)
            self.triggersThatHaveBeenTriggered = {}
            self.triggeredThisFrame = {}
            local this = self
            self:createEntity("Level", "Level", 0, 0, 0, 0, 0,
                {filename = "test.level",
                a = {callback = function(rect)
                                    if not this:getEntity("TestBubble") then
                                        this:createEntity(
                                            "TextBubble", "TestBubble",
                                            rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                                            playerLayer + 1,
                                            {text = "Nice weather we're having today.", background = npcTextBackground,
                                            textColor = npcTextColor, font=dialogBubbleFont, buffer = npcDialogBuffer, timeout=2}
                                            )
                                    end
                    end,
                    triggerOnUse = true,
                    solid = true}
                })
            renderer:setDrawColor(255, 255, 255)
            self:createEntity("Cleanup", "Cleanup", 0, 0, 0, 0, 100)
        end
    })
    engine.Scene.swap(gameScene)

    engine.startGameLoop(renderer, _tickTime)
end
