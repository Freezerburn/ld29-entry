local components = require "components"

local engine = require "engine"
local Entity = engine.Entity
local Vector = engine.Vector
local Rectangle = engine.Rectangle
local getCurrentScene = engine.getCurrentScene

local entities = {}

local SimpleParticle = class("SimpleParticle", Entity)
SimpleParticle:include(components.ColoredRect)
SimpleParticle:include(components.RandomVelocityMixin)
function SimpleParticle:init(settings)
    self:initColoredRect(engine.renderer, settings.r, settings.g, settings.b,
        string.format("SimpleParticle{%d,%d,%d}", settings.r, settings.g, settings.b))
    self._vel = self:getRandomVelocity((settings.speed or 175) * math.random(), false)
    self._lifetime = settings.lifetime * math.random()
end
function SimpleParticle:tick(dt)
    self._lifetime = self._lifetime - dt
    if self._lifetime <= 0 then
        self:kill()
    else
        self:moveTick(dt)
    end
end
entities.SimpleParticle = SimpleParticle

local TextButton = class("TextButton", Entity)
function TextButton:init(settings)
    self._buttonFont = settings.font
    self._buttonText = settings.text
    self._clickCallback = settings.clicked
    self._enterCallback = settings.entered
    self._leftCallback = settings.left
    self._mouseEntered = false

    local backgroundColor = settings.background
    local textColor = settings.textColor
    local w, h = settings.font:sizeUTF8(settings.text)
    local baseSurface = sdl.createRGBSurface(w, h)
    baseSurface:fillRect(nil, backgroundColor.r, backgroundColor.b, backgroundColor.g)
    local textSurface = settings.font:renderUTF8Blended(settings.text, settings.r, settings.g, settings.b)
    baseSurface:blit(textSurface)
    self._buttonTex = renderer:createTextureFromSurface(baseSurface)
end
function TextButton:render(renderer, dt)
    renderer:copy(self._buttonTex, nil, self._rect)
end
function TextButton:input(event, pushed)
    if event.name == "MOUSEMOTION" then
        if not self._mouseEntered then
            if self._rect:isPointIn(event) then
                self._mouseEntered = true
                if self._enterCallback then
                    self._enterCallback()
                end
            end
        else
            if not self._rect:isPointIn(event) then
                self._mouse = false
                if self._leftCallback then
                    self._leftCallback()
                end
            end
        end
    elseif string.find(event.name, "MOUSEBUTTON") and pushed and self._mouseEntered then
        if self._clickCallback then
            self._clickCallback()
        end
    end
end
entities.TextButton = TextButton

local Text = class("Text", Entity)
function Text:init(settings)
    local surface = splashFont:renderUTF8Blended(settings.text, 255, 255, 255)
    self._textTex = renderer:createTextureFromSurface(surface)
    self._rect.w, self._rect.h = splashFont:sizeUTF8(settings.text)
    if settings.useRectAsCenter then
        self._rect.x = self._rect.x - self._rect.w / 2
        self._rect.y = self._rect.y - self._rect.h / 2
    end
end
function Text:render(renderer, dt)
    renderer:copy(self._textTex, nil, self._rect)
end
entities.Text = Text

local Timer = class("Timer", Entity)
function Timer:init(settings)
    self._timeoutAt = settings.timeout
    self._callback = settings.callback
end
function Timer:reset(timeout)
    self._timeoutAt = timeout
end
function Timer:tick(dt)
    self._timeoutAt = self._timeoutAt - dt
    if self._timeoutAt <= 0 then
        self:kill()
        self._callback()
    end
end
entities.Timer = Timer

return entities
