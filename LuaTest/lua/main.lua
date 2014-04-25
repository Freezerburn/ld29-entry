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
local menuFont = nil
local splashFont = nil
local paddleSize = {w=_width / 7, h=_width / 39}
local ballSize = {w=_width / 39, h=_width / 39}
local paddleSpeed = 150
local textureCache = {}
local winningScore = 1
-- 1 == easy, 2 == normal, 3 == hard, 4 == impossible
local cpuDifficulty = 1
local difficultyMapping = {}
table.insert(difficultyMapping, "Easy")
table.insert(difficultyMapping, "Normal")
table.insert(difficultyMapping, "Hard")
table.insert(difficultyMapping, "Impossible")

local startMenuScene = nil
local optionMenuScene = nil
local gameScene = nil
local victoryScene = nil
local defeatScene = nil

local engine = require "engine"
local class = require "middleclass"
local log = require "log"

local Entity = engine.Entity
local Vector = engine.Vector
local Rectangle = engine.Rectangle
local getCurrentScene = engine.getCurrentScene

local RandomVelocityMixin = {
    getRandomVelocity = function(self, totalVelocity, constrainX, constraint)
        if not constraint then
            constraint = 65
        end
        local xvel = math.min(math.random() * totalVelocity, constrainX and constraint or totalVelocity)
        local xdirection = math.random()
        local ydirection = math.random()
        local velx = 0
        local vely = 0
        if xdirection < 0.5 then
            velx = -xvel
        else
            velx = xvel
        end
        if ydirection < 0.5 then
            vely = -(totalVelocity - xvel)
        else
            vely = totalVelocity - xvel
        end
        return Vector.new(velx, vely)
    end
}
local TwoWayMovementMixin = {
    initTwoWayMovement = function(self, leftButton, rightButton, speed, negativeIsLeft)
        self._twowayLeft = leftButton
        self._twowayRight = rightButton
        self._twowaySpeed = negativeIsLeft and speed or -speed
    end,
    input = function(self, event, pushed)
        if event.repeated then
            return
        end

        if event.sym == self._twowayLeft then
            if pushed then
                self._vel.x = self._vel.x - self._twowaySpeed
            else
                self._vel.x = self._vel.x + self._twowaySpeed
            end
        elseif event.sym == self._twowayRight then
            if pushed then
                self._vel.x = self._vel.x + self._twowaySpeed
            else
                self._vel.x = self._vel.x - self._twowaySpeed
            end
        end
    end
}
local ColoredRect = {
    initColoredRect = function(self, renderer, r, g, b, texName)
        if not texName then
            texName = self.name
        end
        if not textureCache[texName] then
            local surface = sdl.createRGBSurface(1, 1)
            self._color = {r=r, g=g, b=b}
            surface:fillRect(nil, r, g, b)
            self._coloredrectTex = renderer:createTextureFromSurface(surface)
            textureCache[texName] = self._coloredrectTex
        else
            self._coloredrectTex = textureCache[texName]
        end
    end,
    getColor = function(self)
        return self._color
    end,
    render = function(self, renderer, dt)
        renderer:copy(self._coloredrectTex, nil, self._rect)
    end
}
local DrawText = {
    initText = function(self, renderer, font, text, r, g, b, offsetX, offsetY)
        self._textRenderer = renderer
        self._textFont = font
        self._textR = r
        self._textG = g
        self._textB = b
        self._offsetX = offsetX
        self._offsetY = offsetY

        local surface = font:renderTextBlended(text, r, g, b)
        self._textTex = renderer:createTextureFromSurface(surface)
        local w, h = font:sizeText(text)
        self._textW = w
        self._textH = h
        if offsetX then
            self._rect.x = self._rect.x - w
        end
        if offsetY then
            self._rect.y = self._rect.y - h
        end
        self._rect.w = w
        self._rect.h = h
    end,
    changeText = function(self, text)
        local surface = self._textFont:renderTextBlended(text, self._textR, self._textG, self._textB)
        local w, h = font:sizeText(text)
        if w > self._textW or h > self._textH then
            self._textTex = self._textRenderer:createTextureFromSurface(surface)
        else
            self._textTex:update(surface)
        end

        if self._offsetX and w ~= self._textW then
            self._rect.x = self._rect.x + self._textW
            self._rect.x = self._rect.x - w
            self._textW = w
            self._rect.w = w
        end
        if self._offsetY and h ~= self._textH then
            self._rect.y = self._rect.y + self._textH
            self._rect.y = self._rect.y - h
            self._textH = h
            self._rect.h = h
        end
    end,
    render = function(self, renderer, dt)
        renderer:copy(self._textTex, nil, self._rect)
    end
}
local TrackPosition = {
    initTrackPosition = function(self, entToTrack, trackX, trackY)
        self._trackEnt = entToTrack
        self._trackX = trackX
        self._trackY = trackY
    end,
    trackTick = function(self)
        local entRect = self._trackEnt:getRect()
        if self._trackX then
            self._rect.x = entRect.x - self._rect.w / 2 + entRect.w / 2
        end
        if self._trackY then
            self._rect.y = entRect.y - self._rect.h / 2 + entRect.h / 2
        end
    end
}
local ParticleGenerator = {
    initGenerator = function(self, type, name, from, size)
        self._genType = type
        self._genName = name
        self._genScene = engine.getCurrentScene()
        self._genFrom = from
        self._genSize = size
        self._particlesGenerated = 1
        self._createdParticles = {}
    end,
    genParticles = function(self, numParticles, args)
        for i = 1, numParticles do
            local genCenter = self._rect:getCenter()
            local x = genCenter.x
            local y = genCenter.y
            local w = self._genSize.x
            local h = self._genSize.y
            local particleName = self._genName .. self._particlesGenerated
            table.insert(self._createdParticles, particleName)
            self._genScene:createEntity(self._genType, particleName,
                x, y, w, h, args)
            self._particlesGenerated = self._particlesGenerated + 1
        end
    end,
    killParticles = function(self)
        for i = 1, #self._createdParticles do
            getCurrentScene():removeEntity(self._createdParticles[i])
        end
        self._createdParticles = {}
    end
}
local FollowPosition = {
    initFollower = function(self, entToFollow, followAtDistance, speed, followX, followY)
        self._followEnt = entToFollow
        self._followAtDistance = followAtDistance
        self._followSpeed = speed
        self._followX = followX
        self._followY = followY
    end,
    followTick = function(self, dt)
        if self._followX and self._followY then
            local vec = self._rect:getCenter() - self._followEnt:getCenter()
            local length = vec:length()
            if length < self._followAtDistance then
                local speedY = (vec.y / vec.x) * self._followSpeed
                local speedX = self._followSpeed - speedY
                if vec.y < 0 then
                    local speedY = -speedY
                end
                if vec.x < 0 then
                    local speedX = -speedX
                end
                self._vel.y = speedY
                self._vel.x = speedX
            end
        elseif self._followX then
            local selfCenter = self._rect:getCenter()
            local otherCenter = self._followEnt:getRect():getCenter()
            local distance = otherCenter.y - selfCenter.y
            if math.abs(distance) < self._followAtDistance then
                local xdistance = otherCenter.x - selfCenter.x
                if math.abs(xdistance) > 15 then
                    if (otherCenter.x - selfCenter.x) < 0 then
                        self._vel.x = -self._followSpeed
                    else
                        self._vel.x = self._followSpeed
                    end
                else
                    self._vel.x = 0
                end
            elseif self._vel.x ~= 0 then
                self._vel.x = 0
            end
        elseif self._followY then
            local selfCenter = self._rect:getCenter()
            local otherCenter = self._followEnt:getRect():getCenter()
            local distance = selfCenter.y - otherCenter.y
            if math.abs(distance) < self._followAtDistance then
                self._vel.y = self._followSpeed
            end
        end

        self:moveTick(dt)
    end
}
local Animated = {
    initAnimation = function(self, settings)
        if settings.filename then
            local surface = img.load(settings.filename)
            self._animatedTex = renderer:createTextureFromSurface(surface)
        elseif settings.texture then
            self._animatedTex = settings.texture
        end
        self._currentFrame = 1
        self._frames = settings.frames
        self._tileWidth = settings.width
        self._tileHeight = settings.height
        self._srcRects = {}
        local startx = settings.start.x
        local starty = settings.start.y
        for i = 0, settings.frames - 1 do
            table.insert(self._srcRects, Rectangle.new(startx + i * self._tileWidth, starty,
                self._tileWidth, self._tileHeight))
        end

        self._animationTime = settings.animationTime
        if type(settings.animationTime) == "table" and self._frames > 1 then
            self._currentTiming = 1
            self._differentTimings = true
        else
            self._differentTimings = false
        end
        self._currentTime = 0
    end,
    renderAnimation = function(self, renderer, dt)
        renderer:copy(self._animatedTex, self._srcRects[self._currentFrame], self._rect)
    end,
    tickAnimation = function(self, dt)
        self._currentTime = self._currentTime + dt
        if self._differentTimings then
            local timing = self._animationTime[self._currentTiming]
            if self._currentTime > timing then
                self._currentTime = self._currentTime - timing
                self._currentTiming = self._currentTiming + 1
                self._currentFrame = self._currentFrame + 1
                if self._currentFrame > self._frames then
                    self._currentFrame = 1
                    self._currentTiming = 1
                end
            end
        else
            if self._currentTime > self._animationTime then
                self._currentTime = self._currentTime - self._animationTime
                self._currentFrame = self._currentFrame + 1
                if self._currentFrame > self._frames then
                    self._currentFrame = 1
                end
            end
        end
    end
}

SimpleParticle = class("SimpleParticle", Entity)
SimpleParticle:include(ColoredRect)
SimpleParticle:include(RandomVelocityMixin)
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

Ball = class("Ball", Entity)
Ball.static._particlesGenerated = 1
Ball:include(RandomVelocityMixin)
-- Ball:include(ColoredRect)
Ball:include(ParticleGenerator)
Ball:include(Animated)
function Ball:init(settings)
    -- self:initColoredRect(engine.renderer, 255, 255, 0)
    self:initAnimation({
        filename = "BallAnimation.png",
        frames = 3,
        width = ballSize.w,
        height = ballSize.h,
        tiles = {w=3, h=1},
        start = {x=0, y=0},
        animationTime = 0.1
    })
    self._color = {r=100, g=100, b=100}
    self:initGenerator("SimpleParticle", "BallParticle", self._rect, Vector.new(5, 5))
    self._initialVelocity = 190
    self:randomizeVelocity()
end
function Ball:randomizeVelocity()
    self._vel = self:getRandomVelocity(self._initialVelocity, true, 65)
end
function Ball:render(renderer, dt)
    self:renderAnimation(renderer, dt)
end
function Ball:tick(dt)
    self:moveTick(dt)
    self:tickAnimation(dt)

    if self._rect.y > _height + 10 then
        self._rect.x = _width / 2 - self._rect.w / 2
        self._rect.y = _height / 2 - self._rect.h / 2
        self:randomizeVelocity()
        engine.getCurrentScene():getEntity("EnemyScore"):increment()
    elseif self._rect.y + self._rect.h < -10 then
        self._rect.x = _width / 2 - self._rect.w / 2
        self._rect.y = _height / 2 - self._rect.h / 2
        self:randomizeVelocity()
        engine.getCurrentScene():getEntity("PlayerScore"):increment()
    end
end
function Ball:collision(between, normals)
    for i, ent in ipairs(between) do
        local otherColor = ent:getColor()
        local r = (self._color.r + otherColor.r) / 2
        local g = (self._color.g + otherColor.g) / 2
        local b = (self._color.b + otherColor.b) / 2
        local newColor = {r=r, g=g, b=b}
        self:genParticles(15, {r=r, g=g, b=b, lifetime=1})
        if self._timerName then
            getCurrentScene():getEntity(self._timerName):reset(1)
        else
            self._timerName = "BallTimer"
            getCurrentScene():createEntity("Timer", "BallTimer", 0, 0, 0, 0,
                {timeout = 1, callback = function()
                    local ball = getCurrentScene():getEntity("Ball")
                    ball._timerName = nil
                    ball:killParticles()
                end})
        end
        if ent.name == "Paddle" or ent.name == "Enemy" then
            local totalVelocity = math.abs(self._vel.y) + math.abs(self._vel.x) + 15
            local myPos = self._rect
            local paddlePos = ent:getRect()
            local myCenter = myPos:getCenter()
            local paddleCenter = paddlePos:getCenter()
            local offset = myCenter.x - paddleCenter.x
            local percentOffCenter = math.abs(offset) / (paddlePos.w / 2)
            percentOffCenter = math.min(percentOffCenter, 0.63)

            if ent.name == "Paddle" then
                self._vel.y = -totalVelocity * (1 - percentOffCenter)
            else
                self._vel.y = totalVelocity * (1 - percentOffCenter)
            end
            if offset < 0 then
                self._vel.x = -totalVelocity * percentOffCenter
            else
                self._vel.x = totalVelocity * percentOffCenter
            end
            self._rect = self._rect + normals[i]
        elseif ent.name == "LeftWall" or ent.name == "RightWall" then
            self._vel.x = -self._vel.x
            local norm = normals[i]
            self._rect.x = self._rect.x + norm.x
            self._rect.y = self._rect.y + norm.y
        end
    end
end

Player = class("Player", Entity)
Player:include(TwoWayMovementMixin)
Player:include(ColoredRect)
function Player:init(settings)
    self:initColoredRect(engine.renderer, 0, 0, 255)
    self:initTwoWayMovement(sdl.KEY_LEFT, sdl.KEY_RIGHT, settings.speed, true)
    self._scene = settings.scene
end
function Player:tick(dt)
    self:moveTick(dt)

    local leftWall = self._scene:getEntity("LeftWall")
    local leftPos = leftWall:getRect()
    local rightWall = self._scene:getEntity("RightWall")
    local rightPos = rightWall:getRect()
    if self._rect.x < leftPos.x + leftPos.w then
        self._rect.x = leftPos.x + leftPos.w
    elseif self._rect.x + self._rect.w > rightPos.x then
        self._rect.x = rightPos.x - self._rect.w
    end
end

Enemy = class("Enemy", Entity)
Enemy:include(ColoredRect)
Enemy:include(TrackPosition)
Enemy:include(FollowPosition)
function Enemy:init(settings)
    self:initColoredRect(engine.renderer, 255, 0, 0)
    self:initTrackPosition(settings.scene:getEntity("Ball"), true, false)
    self:initFollower(settings.scene:getEntity("Ball"), 200, 150, true, false)
    self._scene = settings.scene
end
function Enemy:tick(dt)
    self:followTick(dt)
    -- self:trackTick()

    local leftWall = self._scene:getEntity("LeftWall")
    local leftPos = leftWall:getRect()
    local rightWall = self._scene:getEntity("RightWall")
    local rightPos = rightWall:getRect()
    if self._rect.x < leftPos.x + leftPos.w then
        self._rect.x = leftPos.x + leftPos.w
    elseif self._rect.x + self._rect.w > rightPos.x then
        self._rect.x = rightPos.x - self._rect.w
    end
end

Wall = class("Wall", Entity)
Wall:include(ColoredRect)
function Wall:init(settings)
    self:initColoredRect(engine.renderer, 0, 255, 0)
end

Score = class("Score", Entity)
Score:include(DrawText)
function Score:init(settings)
    self:initText(renderer, font, tostring(settings.score), settings.r, settings.g, settings.b,
        settings.offsetX, settings.offsetY)
    self._score = settings.score
    self._incrementedCallback = settings.incremented
end
function Score:reset(score)
    self._score = score
    self:changeText(tostring(score))
end
function Score:increment()
    self._score = self._score + 1
    self._incrementedCallback(self._score)
    self:changeText(tostring(self._score))
end

TextButton = class("TextButton", Entity)
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

StartMenu = class("StartMenu", Entity)
function StartMenu:init(settings)
    local surface = menuFont:renderTextBlended("Start Game", 255, 255, 255)
    self._startText = renderer:createTextureFromSurface(surface)
    surface = menuFont:renderTextBlended("Options", 255, 255, 255)
    self._optionsText = renderer:createTextureFromSurface(surface)
    surface = menuFont:renderTextBlended("Quit", 255, 255, 255)
    self._quitText = renderer:createTextureFromSurface(surface)

    local text = "スーパー　ポング！"
    surface = splashFont:renderUTF8Blended(text, 255, 200, 200)
    self._splashText = renderer:createTextureFromSurface(surface)
    self._splashTextWidth, self._splashTextHeight = splashFont:sizeUTF8(text)

    local totalHeight = 0
    local maxWidth = 0
    local w = 0
    local maxWidth, h = menuFont:sizeText("Start Game")

    self._triangleHeight = h / 2
    self._triangleWidth = self._triangleHeight
    self._triangleBuffer = 10
    surface = sdl.createRGBSurface(self._triangleWidth, self._triangleHeight)
    local rect = Rectangle.new(0, 0, 1)
    for i = 0, self._triangleWidth do
        rect.x = i
        rect.y = i
        rect.h = self._triangleHeight - i * 2
        surface:fillRect(rect, 255, 255, 255)
    end
    self._triangleTex = renderer:createTextureFromSurface(surface)

    self._startTextWidth = maxWidth
    self._startTextHeight = h
    totalHeight = totalHeight + h

    w, h = menuFont:sizeText("Options")
    self._optionsTextWidth = w
    self._optionsTextHeight = h
    totalHeight = totalHeight + h

    w, h = menuFont:sizeText("Quit")
    self._quitTextWidth = w
    self._quitTextHeight = h
    totalHeight = totalHeight + h

    self._topLeft = {x=self._rect.x - maxWidth / 2, y=self._rect.y - totalHeight / 2}
end
function StartMenu:render(renderer, dt)
    local currentRect = {x=self._topLeft.x, y=self._topLeft.y,
        w=self._startTextWidth, h=self._startTextHeight}
    renderer:copy(self._startText, nil, currentRect)
    currentRect.y = currentRect.y + currentRect.h

    currentRect.w = self._optionsTextWidth
    currentRect.h = self._optionsTextHeight
    renderer:copy(self._optionsText, nil, currentRect)
    currentRect.y = currentRect.y + currentRect.h

    currentRect.w = self._quitTextWidth
    currentRect.h = self._quitTextHeight
    renderer:copy(self._quitText, nil, currentRect)

    currentRect.x = _width / 2 - self._splashTextWidth / 2
    currentRect.y = 50
    currentRect.w, currentRect.h = self._splashTextWidth, self._splashTextHeight
    renderer:copy(self._splashText, nil, currentRect)

    if self._triangleRenderRect then
        renderer:copy(self._triangleTex, nil, self._triangleRenderRect)
    end
end
function StartMenu:startClicked()
    engine.Scene.swap(gameScene)
end
function StartMenu:optionsClicked()
end
function StartMenu:quitClicked()
    engine.quit()
end
function StartMenu:input(event, pushed)
    if event.name == "MOUSEMOTION" then
        local rect = Rectangle.new(self._topLeft.x, self._topLeft.y,
            self._startTextWidth, self._startTextHeight)
        if rect:isPointIn(event) then
            self._triangleRenderRect = Rectangle.new(
                rect.x - self._triangleBuffer - self._triangleWidth,
                rect.y + rect.h / 2 - self._triangleHeight / 2,
                self._triangleWidth, self._triangleHeight)
            self._clickCallback = self.startClicked
            return
        end
        rect.y = rect.y + self._startTextHeight
        if rect:isPointIn(event) then
            self._triangleRenderRect = Rectangle.new(
                rect.x - self._triangleBuffer - self._triangleWidth,
                rect.y + rect.h / 2 - self._triangleHeight / 2,
                self._triangleWidth, self._triangleHeight)
            self._clickCallback = self.optionsClicked
            return
        end
        rect.y = rect.y + self._optionsTextHeight
        if rect:isPointIn(event) then
            self._triangleRenderRect = Rectangle.new(
                rect.x - self._triangleBuffer - self._triangleWidth,
                rect.y + rect.h / 2 - self._triangleHeight / 2,
                self._triangleWidth, self._triangleHeight)
            self._clickCallback = self.quitClicked
            return
        end
        self._triangleRenderRect = nil
        self._clickCallback = nil
    elseif event.name == "MOUSEBUTTONDOWN" then
        if self._clickCallback then
            self:_clickCallback()
        end
    end
end

OptionsMenu = class("OptionsMenu", Entity)
function OptionsMenu:init(setting)
end
function OptionsMenu:difficultyClicked()
    cpuDifficulty = cpuDifficulty + 1
    if cpuDifficulty == 4 then
        cpuDifficulty = 1
    end
end
function OptionsMenu:render(renderer, dt)
end
function OptionsMenu:input(event, pushed)
end

Text = class("Text", Entity)
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

Timer = class("Timer", Entity)
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


function main()
    sdl.init(sdl.INIT_EVERYTHING)
    ttf.init()
    img.init(bit32.bor(img.INIT_JPG, img.INIT_PNG))

    window = sdl.createWindow("Pong!",
        sdl.WINDOWPOS_UNDEFINED, sdl.WINDOWPOS_UNDEFINED,
        _width, _height,
        _windowFlags)
    renderer = sdl.createRenderer(window, -1, _renderFlags)
    font = ttf.openFont("Arial.ttf", 42)
    menuFont = ttf.openFont("Arial.ttf", 36)
    splashFont = ttf.openFont("Hiragino.otf", 54)

    startMenuScene = engine.Scene.new({
        name = "StartScreen",
        init = function(self)
            self:createEntity("StartMenu", "StartMenu", _width / 2, _height / 2, 0, 0)
        end
    })
    optionMenuScene = engine.Scene.new({
        name = "OptionsMenuScreen",
        init = function(self)
        end
    })
    gameScene = engine.Scene.new({
        name = "Game",
        init = function(self)
            self:createEntity("Player", "Paddle", _width / 2.0, _height - 50, 100, 20, {speed=250, scene=self})
            self:createEntity("Wall", "LeftWall", 80, 0, 15, _height)
            self:createEntity("Wall", "RightWall", _width - 95, 0, 15, _height)
            self:createEntity("Ball", "Ball", _width / 2.0 - ballSize.w / 2, _height / 2 - ballSize.h / 2,
                20, 20)
            self:createEntity("Enemy", "Enemy", _width / 2.0 - paddleSize.w / 2, paddleSize.h, 100, 20,
                {scene=self})
            self:createEntity("Score", "PlayerScore", 10, _height - 10, 0, 0,
                {score = 0, r=255, g=255, b=255, offsetY=true,
                incremented = function(score) if score >= winningScore then engine.Scene.swap(victoryScene) end end})
            self:createEntity("Score", "EnemyScore", _width - 10, 10, 0, 0,
                {score = 0, r=255, g=255, b=255, offsetX=true,
                incremented = function(score) if score >= winningScore then engine.Scene.swap(defeatScene) end end})
        end,
        show = function(self)
            if self:getEntity("Paddle") then
                self:getEntity("Paddle"):setRect(Rectangle.new(_width / 2, _height - 50, 100, 20))
                self:getEntity("Ball"):setRect(Rectangle.new(_width / 2 - ballSize.w / 2, _height / 2 - ballSize.h / 2, 20, 20))
                self:getEntity("Ball"):randomizeVelocity()
                self:getEntity("Enemy"):setRect(Rectangle.new(_width / 2 - paddleSize.w / 2, paddleSize.h, 100, 20))
                self:getEntity("PlayerScore"):reset(0)
                self:getEntity("EnemyScore"):reset(0)
            end
        end
    })
    victoryScene = engine.Scene.new({
        name = "Victory",
        init = function(self)
            self:createEntity("Text", "VictoryText", _width / 2, _height / 2, 0, 0,
                {text = "You Win!!", useRectAsCenter = true})
        end,
        show = function(self)
            self:createEntity("Timer", "Timer1", 0, 0, 0, 0,
                {timeout = 3, callback = function() engine.Scene.swap(startMenuScene) end})
        end
    })
    defeatScene = engine.Scene.new({
        name = "Defeat",
        init = function(self)
            self:createEntity("Text", "DefeatText", _width / 2, _height / 2, 0, 0,
                {text = "You Lose! :(", useRectAsCenter = true})
        end,
        show = function(self)
            self:createEntity("Timer", "Timer1", 0, 0, 0, 0,
                {timeout = 3, callback = function() engine.Scene.swap(startMenuScene) end})
        end
    })
    engine.Scene.swap(startMenuScene)
    engine.startGameLoop(renderer, _tickTime)
end
