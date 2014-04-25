local components = {}

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

return components
