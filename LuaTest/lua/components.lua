local components = {}
local engine = require "engine"

local Entity = engine.Entity
local Vector = engine.Vector
local Rectangle = engine.Rectangle
local getCurrentScene = engine.getCurrentScene

components.RandomVelocityMixin = {
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
components.TwoWayMovementMixin = {
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
components.ColoredRect = {
    initColoredRect = function(self, renderer, r, g, b, texName)
        if not texName then
            texName = self.name
        end
        if not engine.getCachedTexture(texName) then
            local surface = sdl.createRGBSurface(1, 1)
            self._color = {r=r, g=g, b=b}
            surface:fillRect(nil, r, g, b)
            self._coloredrectTex = renderer:createTextureFromSurface(surface)
            engine.cacheTexture(self._coloredrectTex, texName)
        else
            self._coloredrectTex = engine.getCachedTexture(texName)
        end
    end,
    getColor = function(self)
        return self._color
    end,
    renderColoredRect = function(self, renderer, dt)
        renderer:copy(self._coloredrectTex, nil, self._rect)
    end
}
components.DrawText = {
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
components.TrackPosition = {
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
components.ParticleGenerator = {
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
components.FollowPosition = {
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
components.Animated = {
    initAnimated = function(self, settings)
        self._animations = {}
    end,
    addAnimation = function(self, settings)
        local renderer = self._renderer
        local animationInfos = {}
        if settings.filename then
            local cached = engine.getCachedTexture(settings.filename)
            if cached then
                animationInfos.animatedTex = cached
            else
                local surface = img.load(settings.filename)
                animationInfos.animatedTex = renderer:createTextureFromSurface(surface)
                engine.cacheTexture(animationInfos.animatedTex, settings.filename)
            end
        elseif settings.texture then
            animationInfos.animatedTex = settings.texture
        end
        animationInfos.flipx = settings.flipx
        animationInfos.flipy = settings.flipy
        animationInfos.currentFrame = 1
        animationInfos.frames = settings.frames
        animationInfos.tileWidth = settings.width
        animationInfos.tileHeight = settings.height
        animationInfos.srcRects = {}
        local startx = settings.start.x
        local starty = settings.start.y
        for i = 0, settings.frames - 1 do
            table.insert(animationInfos.srcRects, Rectangle.new(startx + i * animationInfos.tileWidth, starty,
                animationInfos.tileWidth, animationInfos.tileHeight))
        end

        animationInfos.animationTime = settings.animationTime
        if type(settings.animationTime) == "table" and animationInfos.frames > 1 then
            animationInfos.currentTiming = 1
            animationInfos.differentTimings = true
        else
            animationInfos.differentTimings = false
        end
        animationInfos.currentTime = 0
        self._animations[settings.name] = animationInfos
    end,
    setAnimation = function(self, name)
        self._currentAnimation = name
        local animationInfos = self._animations[name]
        animationInfos.currentTime = 0
        animationInfos.currentFrame = 1
        animationInfos.currentTiming = 1
    end,
    renderAnimated = function(self, renderer, dt)
        if self._currentAnimation then
            local animationInfos = self._animations[self._currentAnimation]
            if animationInfos.flipx and animationInfos.flipy then
                renderer:copyEx(animationInfos.animatedTex,
                    animationInfos.srcRects[animationInfos.currentFrame],
                    self._rect,
                    {flip = bit32.bor(sdl.FLIP_HORIZONTAL, sdl.FLIP_VERTICAL)})
            elseif animationInfos.flipx then
                renderer:copyEx(animationInfos.animatedTex,
                    animationInfos.srcRects[animationInfos.currentFrame],
                    self._rect,
                    {flip = sdl.FLIP_HORIZONTAL})
            elseif animationInfos.flipy then
                renderer:copyEx(animationInfos.animatedTex,
                    animationInfos.srcRects[animationInfos.currentFrame],
                    self._rect,
                    {flip = sdl.FLIP_VERTICAL})
            else
                renderer:copy(animationInfos.animatedTex,
                    animationInfos.srcRects[animationInfos.currentFrame],
                    self._rect)
            end
        end
    end,
    tickAnimated = function(self, dt)
        if self._currentAnimation then
            local animationInfos = self._animations[self._currentAnimation]
            animationInfos.currentTime = animationInfos.currentTime + dt
            if animationInfos.differentTimings then
                local timing = animationInfos.animationTime[self._currentTiming]
                if animationInfos.currentTime > timing then
                    animationInfos.currentTime = animationInfos.currentTime - timing
                    animationInfos.currentTiming = animationInfos.currentTiming + 1
                    animationInfos.currentFrame = animationInfos.currentFrame + 1
                    if animationInfos.currentFrame > animationInfos.frames then
                        animationInfos.currentFrame = 1
                        animationInfos.currentTiming = 1
                    end
                end
            else
                if animationInfos.currentTime > animationInfos.animationTime then
                    animationInfos.currentTime = animationInfos.currentTime - animationInfos.animationTime
                    animationInfos.currentFrame = animationInfos.currentFrame + 1
                    if animationInfos.currentFrame > animationInfos.frames then
                        animationInfos.currentFrame = 1
                    end
                end
            end
        end
    end
}
components.FourWayMovement = {
    initFourWayMovement = function(self, settings)
        self._speedx = settings.speed.x
        self._speedy = settings.speed.y

        self._leftKey = settings.keys.left
        self._rightKey = settings.keys.right
        self._upKey = settings.keys.up
        self._downKey = settings.keys.down

        self._leftPushed = false
        self._rightPushed = false
        self._upPushed = false
        self._downPushed = false
        self._shouldChange = false

        self._idleName = settings.names.idle
        self._walkLeftName = settings.names.left
        self._walkRightName = settings.names.right
        self._walkUpName = settings.names.up
        self._walkDownName = settings.names.down

        self._walkUpLeftName = settings.names.upLeft
        self._walkUpRightName = settings.names.upRight
        self._walkDownLeftName = settings.names.downLeft
        self._walkDownRightName = settings.names.downRight

        self:setAnimation(self._idleName)
    end,
    inputFourWayMovement = function(self, event, pushed)
        if string.find(event.name, "KEY") and not event.repeated then
            if event.sym == self._leftKey then
                if self._leftPushed ~= pushed then
                    self._shouldChange = true
                end
                self._leftPushed = pushed
                if pushed then
                    self._vel.x = self._vel.x - self._speedx
                else
                    self._vel.x = self._vel.x + self._speedx
                end
            elseif event.sym == self._rightKey then
                if self._rightPushed ~= pushed then
                    self._shouldChange = true
                end
                self._rightPushed = pushed
                if pushed then
                    self._vel.x = self._vel.x + self._speedx
                else
                    self._vel.x = self._vel.x - self._speedx
                end
            elseif event.sym == self._upKey then
                if self._upPushed ~= pushed then
                    self._shouldChange = true
                end
                self._upPushed = pushed
                if pushed then
                    self._vel.y = self._vel.y - self._speedy
                else
                    self._vel.y = self._vel.y + self._speedy
                end
            elseif event.sym == self._downKey then
                if self._downPushed ~= pushed then
                    self._shouldChange = true
                end
                self._downPushed = pushed
                if pushed then
                    self._vel.y = self._vel.y + self._speedy
                else
                    self._vel.y = self._vel.y - self._speedy
                end
            end
        end
    end,
    tickFourWayMovement = function(self, dt)
        if self._shouldChange then
            if self._upPushed then
                if self._leftPushed then
                    if self._walkUpLeftName then
                        self:setAnimation(self._walkUpLeftName)
                    else
                        self:setAnimation(self._walkLeftName)
                    end
                elseif self._rightPushed then
                    if self._walkUpRightName then
                        self:setAnimation(self._walkUpRightName)
                    else
                        self:setAnimation(self._walkRightName)
                    end
                else
                    self:setAnimation(self._walkUpName)
                end
            elseif self._downPushed then
                if self._leftPushed then
                    if self._walkDownLeftName then
                        self:setAnimation(self._walkDownLeftName)
                    else
                        self:setAnimation(self._walkLeftName)
                    end
                elseif self._rightPushed then
                    if self._walkDownRightName then
                        self:setAnimation(self._walkDownRightName)
                    else
                        self:setAnimation(self._walkRightName)
                    end
                else
                    self:setAnimation(self._walkDownName)
                end
            elseif self._leftPushed then
                self:setAnimation(self._walkLeftName)
            elseif self._rightPushed then
                self:setAnimation(self._walkRightName)
            else
                self:setAnimation(self._idleName)
            end

            self._shouldChange = false
        end
    end
}

return components
