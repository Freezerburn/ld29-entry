local class = require "middleclass"
local log = require "log"

local engine = {
    _AUTHOR      = "Vincent 'Freezerburn Vinny' Kuyatt",
    _EMAIL       = "vincentk@unlocked-doors.com",
    _VERSION     = "Ludum Dare Engine 0.1",
    _DESCRIPTION = "Simple, dumb 'game' engine for Ludum Dare.",
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

-- This collision detection algorithm is entirely stolen (and rewritten to Lua)
-- from the Elysian Shadows source code, as posted in their forum at:
-- http://elysianshadows.com/phpBB3/viewtopic.php?f=6&t=4255&start=999999
-- I have basically no idea how to do collision detection, so having this ia
-- an absolute lifesaver for me.
local function aabbCollision(rect1, rect2, normal)
    normal.x = 0
    normal.y = 0

    local r1Pos = rect1:getCenter()
    local r2Pos = rect2:getCenter()
    local distance = r2Pos - r1Pos

    local xAdd = (rect1.w + rect2.w) / 2
    local yAdd = (rect1.h + rect2.h) / 2

    local absDistance = {}
    if distance.x < 0 then
        absDistance.x = distance.x * -1
    else
        absDistance.x = distance.x
    end
    if distance.y < 0 then
        absDistance.y = distance.y * -1
    else
        absDistance.y = distance.y
    end

    if not ((absDistance.x < xAdd) and (absDistance.y < yAdd)) then
        return false
    end

    local xMag = xAdd - absDistance.x
    local yMag = yAdd - absDistance.y

    if(xMag < yMag) then
        if distance.x > 0 then
            normal.x = -xMag
        else
            normal.x = xMag
        end
    else
        if distance.y > 0 then
            normal.y = -yMag
        else
            normal.y = yMag
        end
    end

    return true
end

function findCollisions(ents)
    local normal = engine.Vector.new()
    local collisionInfos = {}
    local between = {}
    local normals = {}

    for _, ent in pairs(ents) do
        if not ent.name:find("Particle") then
            for _, ent2 in pairs(ents) do
                if ent ~= ent2 and not ent2.name:find("Particle") then
                    local collided = aabbCollision(ent:getRect(), ent2:getRect(), normal)
                    if collided then
                        between[#between + 1] = ent2
                        normals[#normals + 1] = normal:clone()
                    end
                end
            end

            if #between > 0 then
                collisionInfos[ent] = {between=between, normals=normals}
                between = {}
                normals = {}
            end
        end
    end

    for ent, infos in pairs(collisionInfos) do
        ent:collision(infos.between, infos.normals)
    end
end

-- ############################################################################
-- Definition for a "Vector" class for some small amount of convenience.
local _vector_mt = {}
local _Vector = {}
function _Vector.new(x, y)
    local vec = {}
    vec.x = x or 0
    vec.y = y or 0
    setmetatable(vec, _vector_mt)
    return vec
end
function _Vector.add(vec1, vec2)
    return engine.Vector.new(vec1.x + vec2.x, vec1.y + vec2.y)
end
function _Vector.subtract(vec1, vec2)
    return engine.Vector.new(vec1.x - vec2.x, vec1.y - vec2.y)
end
function _Vector.length(self)
    return math.sqrt(self:length2())
end
function _Vector.length2(self)
    return self.x * self.x + self.y * self.y
end
function _Vector.clone(self)
    return engine.Vector.new(self.x, self.y)
end
function _Vector.toString(self)
    return "Vector{x=" .. self.x .. ", y=" .. self.y .. "}"
end
_vector_mt.__add      = _Vector.add
_vector_mt.__sub      = _Vector.subtract
_vector_mt.__tostring = _Vector.toString
_vector_mt.clone      = _Vector.clone
_vector_mt.__index    = _vector_mt
engine.Vector         = _Vector
-- Vector definition end.

-- ############################################################################
-- Definition for a "Rectangle" class for some small amount of convenience.
local _rect_mt = {}
local _Rectangle = {}
function _Rectangle.new(x, y, w, h)
    local rect = {}
    rect.x = x or 0
    rect.y = y or 0
    rect.w = w or 0
    rect.h = h or 0
    setmetatable(rect, _rect_mt)
    return rect
end
function _Rectangle.add(rect1, rect2)
    if getmetatable(rect2) == _vector_mt then
        return _Rectangle.new(rect1.x + rect2.x,
                rect1.y + rect2.y,
                rect1.w, rect1.h)
    else
        return _Rectangle.new(rect1.x + rect2.x,
                rect1.y + rect2.y,
                rect1.w + rect2.w,
                rect1.h + rect2.h)
    end
end
function _Rectangle.isPointIn(self, point)
    if point.x < self.x then return false
    elseif point.x > self.x + self.w then return false
    elseif point.y < self.y then return false
    elseif point.y > self.y + self.h then return false
    end
    return true
end
function _Rectangle.toString(self)
    return "Rectangle{x=" .. self.x .. ", y=" .. self.y .. ", w=" .. self.w .. ", h=" .. self.h .. "}"
end
function _Rectangle.getCenter(self)
    return engine.Vector.new(self.x + self.w / 2, self.y + self.h / 2)
end
function _Rectangle.clone(self)
    return engine.Rectangle.new(self.x, self.y, self.w, self.h)
end
_rect_mt.__add      = _Rectangle.add
_rect_mt.__tostring = _Rectangle.toString
_rect_mt.isPointIn  = _Rectangle.isPointIn
_rect_mt.getCenter  = _Rectangle.getCenter
_rect_mt.clone      = _Rectangle.clone
_rect_mt.__index    = _rect_mt
engine.Rectangle    = _Rectangle
-- Rectangle definition end.

-- ############################################################################
-- Definition for a "Scene" class to allow the engine to swap between
local _created_entities = 1
local _created_scenes = 1
local _currentScene = nil
local _scene_mt = {}
local _Scene = {}
function _Scene.new(meta)
    local scene = {}
    setmetatable(scene, _scene_mt)
    scene._name2ent = {}
    scene._createNextFrame = {}
    scene._removeNextFrame = {}

    if meta.name then
        scene.name = meta.name
    else
        scene.name = "Scene_" .. _created_scenes
        log.debug("Created scene with sequential name: %s", scene.name)
    end
    scene._initted = false
    scene.init = meta.init or scene.init
    scene.show = meta.show or scene.show
    scene.hide = meta.hide or scene.hide
    scene.destroy = meta.destroy or scene.destroy

    _created_scenes = _created_scenes + 1
    return scene
end
function _Scene.swap(scene)
    if _currentScene then
        log.debug("Swapping scene '%s' out for scene '%s'.", _currentScene.name, scene.name)
        _currentScene:hide()
    else
        log.debug("Setting initial scene to '%s'.", scene.name)
    end
    _currentScene = scene
    if not scene._initted then
        scene:init()
        scene._initted = true
    end
    scene:show()
end
function _scene_mt:init(...) log.debug("Default init called for scene '%s.", self.name) end
function _scene_mt:show(...) log.debug("Default show called for scene '%s'.", self.name) end
function _scene_mt:hide(...) log.debug("Default hide called for scene '%s'.", self.name) end
function _scene_mt:destroy(...) log.debug("Default destroy called for scene '%s'.", self.name) end
function _scene_mt:createEntity(type, name, x, y, w, h, settings)
    table.insert(self._createNextFrame, {type=type, name=name, x=x, y=y, w=w, h=h, settings=settings})
end
function _scene_mt:addEntity(e, name)
    if not name then
        name = "Entity_" .. _created_entities
        log.debug("Created entity with sequential name: %s", name)
    else
        -- Can only have a potential name clash when not creating a unique, sequential name.
        assert(not self._name2ent[name], "Cannot have more than one entity with the same name.")
    end

    self._name2ent[name] = e
    _created_entities = _created_entities + 1
end
function _scene_mt:removeEntity(name)
    -- assert(self._name2ent[name], "Cannot remove an entity that is not in the scene.")
    if self._name2ent[name] then
        self._name2ent[name] = nil
    end
end
function _scene_mt:getEntity(name)
    -- assert(self._name2ent[name], "No entity in this scene with the name: " .. name)
    return self._name2ent[name]
end
function _scene_mt:tick(dt)
    for name, ent in pairs(self._name2ent) do
        ent:tick(dt)
    end
    findCollisions(self._name2ent)
end
function _scene_mt:input(event, pushed)
    for _, ent in pairs(self._name2ent) do
        ent:input(event, pushed)
    end
end
function _scene_mt:render(r, dt)
    for name, ent in pairs(self._name2ent) do
        ent:render(r, dt)
    end

    for _, o in pairs(self._createNextFrame) do
        if o.type then
            local entity = _G[o.type](o.name, o.x, o.y, o.w, o.h, o.settings)
            self:addEntity(entity, o.name)
        end
    end
    self._createNextFrame = {}

    for _, o in pairs(self._removeNextFrame) do
        self._name2ent[o.name] = nil
    end
    self._removeNextFrame = {}
end
function _scene_mt.__gc(scene) scene.destroy() end
_scene_mt.__index = _scene_mt
engine.Scene = _Scene
-- Scene definition end.

-- ############################################################################
-- Definition for an "Entity" class to use as a base for all other Entities.
local _Entity = class("Entity")
function _Entity:initialize(name, x, y, w, h, settings)
    self.name = name
    self._rect = engine.Rectangle.new(x, y, w, h)
    self._vel = engine.Vector.new()
    self._accel = engine.Vector.new()
    self:init(settings)
end
function _Entity:kill()
    _currentScene:removeEntity(self.name)
end
function _Entity:tick(dt)
    self:moveTick(dt)
end
function _Entity:moveTick(dt)
    self._vel.x = self._vel.x + self._accel.x * dt
    self._vel.y = self._vel.y + self._accel.y * dt
    self._rect.x = self._rect.x + self._vel.x * dt
    self._rect.y = self._rect.y + self._vel.y * dt
end
function _Entity:collision(between, normals)
    -- log.debug("Default collision called for entity '%s'.", self.name)
end
function _Entity:render(renderer, dt)
    -- log.warning("Default render called for entity '%s'.", self.name)
end
function _Entity:input(event, pushed)
    -- log.warning("Default input called for entity '%s'. (event=%s, pushed=%s)", self.name, event, pushed)
end
function _Entity:getRect()
    return self._rect
end
function _Entity:setRect(rect)
    self._rect = rect
end
function _Entity:setVelocity(vel)
    self._vel = vel
end
engine.Entity = _Entity

function engine.getCurrentScene()
    return _currentScene
end

local going = true
local frame = 0
function engine.quit()
    going = false
end
function engine.startGameLoop(renderer, dt)
    engine.renderer = renderer
    local needgc = false
    local didgc = false
    math.randomseed(os.time())
    collectgarbage("collect")
    collectgarbage("stop")
    while going do
        local before = sdl.getTicks()
        local event = sdl.pollEvent()
        while event do
            if event.name == "KEYDOWN" and event.state and event.sym == sdl.KEY_Q then
                going = false
                break
            elseif event.name == "QUIT" then
                going = false
                break
            else
                _currentScene:input(event, event.name == "KEYDOWN" or event.name == "MOUSEBUTTONDOWN")
            end
            event = sdl.pollEvent()
        end

        _currentScene:tick(dt)
        renderer:clear()
        _currentScene:render(renderer, dt)

        local delta = sdl.getTicks() - before
        -- Only collect garbage a few times a second, and don't let the time spent
        -- collecting garbage be too long.
        -- local gctime = 0
        -- local storeDelta = delta
        if (frame % 15) == 0 then
            needgc = true
        end
        while needgc and delta < 12 do
            -- local beforegc = sdl.getTicks()
            local finished = collectgarbage("step", 1)
            didgc = true
            -- gctime = gctime + (sdl.getTicks() - beforegc)
            if finished then
                break
            end
            delta = sdl.getTicks() - before
        end
        if didgc then
            needgc = false
            didgc = false
        end
        -- if (frame % 15) == 0 then
        --     print("GC took " .. gctime .. "ms.")
        --     print("Main loop took " .. storeDelta .. "ms.")
        -- end

        renderer:present()
    end
end

return engine
