package.path = lfs.packagedir() .. "/?.lua"

class = require "middleclass"

function aabbCollision(rect1, rect2, normal)
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

_vector_mt = {}
Vector = {}
function Vector.new(x, y)
    local vec = {}
    vec.x = x or 0
    vec.y = y or 0
    setmetatable(vec, _vector_mt)
    return vec
end
function Vector.add(vec1, vec2)
    return Vector.new(vec1.x + vec2.x, vec1.y + vec2.y)
end
function Vector.subtract(vec1, vec2)
    return Vector.new(vec1.x - vec2.x, vec1.y - vec2.y)
end
function Vector.clone(self)
    return Vector.new(self.x, self.y)
end
function Vector.toString(self)
    return "Vector{x=" .. self.x .. ", y=" .. self.y .. "}"
end
_vector_mt.__add = Vector.add
_vector_mt.__sub = Vector.subtract
_vector_mt.__tostring = Vector.toString
_vector_mt.clone = Vector.clone
_vector_mt.__index = _vector_mt

_rect_mt = {}
Rectangle = {}
function Rectangle.new(x, y, w, h)
    local rect = {}
    rect.x = x or 0
    rect.y = y or 0
    rect.w = w or 0
    rect.h = h or 0
    setmetatable(rect, _rect_mt)
    return rect
end
function Rectangle.add(rect1, rect2)
    if getmetatable(rect2) == _vector_mt then
        return Rectangle.new(rect1.x + rect2.x,
                rect1.y + rect2.y,
                rect1.w, rect1.h)
    else
        return Rectangle.new(rect1.x + rect2.x,
                rect1.y + rect2.y,
                rect1.w + rect2.w,
                rect1.h + rect2.h)
    end
end
function Rectangle.toString(self)
    return "Rectangle{x=" .. self.x .. ", y=" .. self.y .. ", w=" .. self.w .. ", h=" .. self.h .. "}"
end
function Rectangle.getCenter(self)
    return Vector.new(self.x + self.w / 2, self.y + self.h / 2)
end
function Rectangle.clone(self)
    return Rectangle.new(self.x, self.y, self.w, self.h)
end
_rect_mt.__add = Rectangle.add
_rect_mt.__tostring = Rectangle.toString
_rect_mt.getCenter = Rectangle.getCenter
_rect_mt.clone = Rectangle.clone
_rect_mt.__index = _rect_mt

-- _entities = {}
name2ent = {}
_nextEntity = 1
function entity(meta)
    local result = {}
    result.tick = meta.tick or function(self, dt) end
    result.render = meta.render or function(self, r, dt) end
    result.input = meta.input or function(self, event, pushed) return false end
    result.name = meta.name or ("Entity" .. _nextEntity)
    if name2ent[result.name] then
        error("Cannot have two entities with the same name. (erroneous name = " .. result.name .. ")")
    end
    result.collision = meta.collision or function(self, between, deltas) end
    result.kill = function(self) name2ent[self.name] = nil end
    result.getRect = meta.getRect or function(self) return self._pos end
    result.getColor = meta.getColor or function(self) return self._color end
    -- result._entLocation = _nextEntity
    if meta.init then
        result.init = meta.init
        result:init(meta)
        result.init = nil
    end
    -- _entities[_nextEntity] = result
    name2ent[result.name] = result
    _nextEntity = _nextEntity + 1
    return result
end

function doAllEntities(thing, ...)
    for _, ent in pairs(name2ent) do
        ent[thing](ent, ...)
    end
end

function findCollisions()
    local normal = Vector.new()
    local between = {}
    local normals = {}

    for i, ent in pairs(name2ent) do
        if not ent.name:find("Particle") then
            for j, ent2 in pairs(name2ent) do
                if ent ~= ent2 and not ent2.name:find("Particle") then
                    local collided = aabbCollision(ent:getRect(), ent2:getRect(), normal)
                    if collided then
                        between[#between + 1] = ent2
                        normals[#normals + 1] = normal:clone()
                    end
                end
            end

            if #between > 0 then
                ent:collision(between, normals)
            end
            while #between > 0 do
                table.remove(between)
                table.remove(normals)
            end
        end
    end
end

function generateRandomVel(totalVelocity, limitx)
    print(debug.traceback())
    local xvel = math.min(math.random() * totalVelocity, limitx and 65 or totalVelocity)
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

_numParticlesMade = 1
function makeParticles(origin, amount, color, maxduration, size)
    local myduration = duration or 1
    local mysize = size or 5
    print(debug.traceback())

    for i = 1, amount do
        entity({
            name = "Particle" .. _numParticlesMade,
            duration = math.random() * myduration,
            init = function(self, options)
                self._surface = sdl.createRGBSurface(1, 1)
                self._surface:fillRect(nil, color.r, color.g, color.b)
                self._duration = options.duration
                self._vel = generateRandomVel(math.random() * 170, false)
                self._pos = Rectangle.new(origin.x, origin.y, mysize, mysize)
            end,
            tick = function(self, dt)
                self._duration = self._duration - dt
                if self._duration <= 0 then
                    self:kill()
                else
                    self._pos.x = self._pos.x + self._vel.x * dt
                    self._pos.y = self._pos.y + self._vel.y * dt
                end
            end,
            render = function(self, r, dt)
                if not self._tex then
                    self._tex = r:createTextureFromSurface(self._surface)
                    self._surface = nil
                end
                r:copy(self._tex, nil, self._pos)
            end
        })
        _numParticlesMade = _numParticlesMade + 1
    end
end

_width = 640
_height = 480
_windowFlags = bit32.bor(sdl.WINDOW_OPENGL,
    sdl.WINDOW_ALLOW_HIGHDPI, sdl.WINDOW_SHOWN,
    sdl.WINDOW_MOUSE_FOCUS, sdl.WINDOW_INPUT_FOCUS)
_renderFlags = bit32.bor(sdl.RENDERER_PRESENTVSYNC, sdl.RENDERER_ACCELERATED)
_tickTime = 1 / 60
function main()
    sdl.init(sdl.INIT_EVERYTHING)
    ttf.init()
    img.init(bit32.bor(img.INIT_JPG, img.INIT_PNG))

    window = sdl.createWindow("Test!",
        sdl.WINDOWPOS_UNDEFINED, sdl.WINDOWPOS_UNDEFINED,
        _width, _height,
        _windowFlags)
    renderer = sdl.createRenderer(window, -1, _renderFlags)
    playerScore = 0
    enemyScore = 0

    local font = ttf.openFont("Arial.ttf", 42)
    local paddleSize = {w=_width / 7, h=_width / 39}
    local ballSize = {w=_width / 39, h=_width / 39}
    local paddleSpeed = 150
    entity({
        name = "Paddle",
        size = paddleSize,
        pos = Rectangle.new(_width / 2 - paddleSize.w / 2, _height - paddleSize.h * 2),
        speed = paddleSpeed,
        init = function (self, options)
            local surface = sdl.createRGBSurface(1, 1)
            self._color = {r=0, g=0, b=255}
            surface:fillRect(nil, 0, 0, 255)
            self._texture = renderer:createTextureFromSurface(surface)
            self._speed = options.speed or 100
            self._vel = options.vel or {x=0, y=0}
            self._pos = options.pos or Rectangle.new(0, 0)
            if options.size then
                self._pos.w = options.size.w
                self._pos.h = options.size.h
            else
                self._pos.w = 100
                self._pos.h = 100
            end
        end,
        tick = function(self, dt)
            self._pos.x = self._pos.x + self._vel.x * dt
            self._pos.y = self._pos.y + self._vel.y * dt
        end,
        input = function(self, event, pushed)
            if event.repeated then
                return
            end

            if event.sym == sdl.KEY_LEFT then
                if pushed then
                    self._vel.x = self._vel.x - self._speed
                else
                    self._vel.x = self._vel.x + self._speed
                end
            elseif event.sym == sdl.KEY_RIGHT then
                if pushed then
                    self._vel.x = self._vel.x + self._speed
                else
                    self._vel.x = self._vel.x - self._speed
                end
            end
        end,
        render = function ( self, r, dt )
            r:copy(self._texture, nil, self._pos)
        end,
        collision = function(self, between, deltas)
            for i, ent in ipairs(between) do
                if ent.name:find("Wall") then
                    self._pos = self._pos + deltas[i]
                end
            end
        end
    })
    entity({
        name = "Enemy",
        size = paddleSize,
        pos = Rectangle.new(_width / 2 - paddleSize.w / 2, paddleSize.h),
        speed = paddleSpeed,
        init = function (self, options)
            local surface = sdl.createRGBSurface(1, 1)
            self._color = {r=255, g=0, b=0}
            surface:fillRect(nil, 255, 0, 0)
            self._texture = renderer:createTextureFromSurface(surface)
            self._speed = options.speed or 100
            self._vel = options.vel or {x=0, y=0}
            self._pos = options.pos or Rectangle.new(0, 0)
            if options.size then
                self._pos.w = options.size.w
                self._pos.h = options.size.h
            else
                self._pos.w = 100
                self._pos.h = 100
            end
        end,
        tick = function(self, dt)
            local ball = name2ent.Ball
            local ballRect = ball:getRect()
            self._pos.x = ballRect.x - self._pos.w / 2 + ballRect.w / 2

            local leftWall = name2ent.LeftWall
            local leftPos = leftWall:getRect()
            local rightWall = name2ent.RightWall
            local rightPos = rightWall:getRect()
            if self._pos.x < leftPos.x + leftPos.w then
                self._pos.x = leftPos.x + leftPos.w
            elseif self._pos.x + self._pos.w > rightPos.x then
                self._pos.x = rightPos.x - self._pos.w
            end
        end,
        render = function ( self, r, dt )
            r:copy(self._texture, nil, self._pos)
        end
    })
    entity({
        name = "LeftWall",
        pos = Rectangle.new(80, 0),
        size = {w=15, h=_height},
        init = function(self, options)
            local surface = sdl.createRGBSurface(1, 1)
            self._color = {r=0, g=255, b=0}
            surface:fillRect(nil, 0, 255, 0)
            self._tex = renderer:createTextureFromSurface(surface)
            self._pos = options.pos or Rectangle.new(0, 0)
            self._speed = options.speed or 100
            self._vel = {x=self._speed, y=self._speed}
            if options.size then
                self._pos.w = options.size.w
                self._pos.h = options.size.h
            else
                self._pos.w = 100
                self._pos.h = 100
            end
        end,
        render = function(self, r, dt)
            r:copy(self._tex, nil, self._pos)
        end
    })
    entity({
        name = "RightWall",
        pos = Rectangle.new(_width - 80 - 15, 0),
        size = {w=15, h=_height},
        init = function(self, options)
            local surface = sdl.createRGBSurface(1, 1)
            self._color = {r=0, g=255, b=0}
            surface:fillRect(nil, 0, 255, 0)
            self._tex = renderer:createTextureFromSurface(surface)
            self._pos = options.pos or Rectangle.new(0, 0)
            self._speed = options.speed or 100
            self._vel = {x=self._speed, y=self._speed}
            if options.size then
                self._pos.w = options.size.w
                self._pos.h = options.size.h
            else
                self._pos.w = 100
                self._pos.h = 100
            end
        end,
        render = function(self, r, dt)
            r:copy(self._tex, nil, self._pos)
        end
    })
    entity({
        name = "Ball",
        pos = Rectangle.new(_width / 2 - ballSize.w / 2, _height / 2 - ballSize.h / 2),
        size = ballSize,
        speed = 75,
        init = function(self, options)
            local surface = sdl.createRGBSurface(1, 1)
            self._color = {r=255, g=0, b=255}
            surface:fillRect(nil, 255, 0, 255)
            self._tex = renderer:createTextureFromSurface(surface)
            self._pos = options.pos or Rectangle.new(0, 0)
            self._speed = options.speed or 100
            self._vel = {x=self._speed, y=self._speed}
            if options.size then
                self._pos.w = options.size.w
                self._pos.h = options.size.h
            else
                self._pos.w = 100
                self._pos.h = 100
            end
        end,
        render = function(self, r, dt)
            r:copy(self._tex, nil, self._pos)
        end,
        collision = function(self, between, deltas)
            for i, ent in ipairs(between) do
                local otherColor = ent:getColor()
                local r = (self._color.r + otherColor.r) / 2
                local g = (self._color.g + otherColor.g) / 2
                local b = (self._color.b + otherColor.b) / 2
                local newColor = {r=r, g=g, b=b}
                makeParticles(self._pos, 20, newColor, 1)
                if ent.name == "Paddle" or ent.name == "Enemy" then
                    local totalVelocity = math.abs(self._vel.y) + math.abs(self._vel.x) + 15
                    local myPos = self._pos
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
                    self._pos = self._pos + deltas[i]
                elseif ent.name == "LeftWall" or ent.name == "RightWall" then
                    self._vel.x = -self._vel.x
                    local norm = deltas[i]
                    self._pos.x = self._pos.x + norm.x
                    self._pos.y = self._pos.y + norm.y
                end
            end
        end,
        tick = function(self, dt)
            self._pos.x = self._pos.x + self._vel.x * dt
            self._pos.y = self._pos.y + self._vel.y * dt

            if self._pos.x < 0 then
                self._vel.x = -self._vel.x
            elseif self._pos.x + self._pos.w > _width then
                self._vel.x = -self._vel.x
            elseif self._pos.y + self._pos.h < 0 then
                self._pos.x = _width / 2 - self._pos.w / 2
                self._pos.y = _height / 2 - self._pos.h / 2
                local totalVelocity = math.max(math.random() * 250, 125)
                local xvel = math.min(math.random() * totalVelocity, 65)
                local xdirection = math.random()
                local ydirection = math.random()
                if xdirection < 0.5 then
                    self._vel.x = -xvel
                else
                    self._vel.x = xvel
                end
                if ydirection < 0.5 then
                    self._vel.y = -(totalVelocity - xvel)
                else
                    self._vel.y = totalVelocity - xvel
                end
                enemyScore = enemyScore + 1
            elseif self._pos.y > _height then
                self._pos.x = _width / 2 - self._pos.w / 2
                self._pos.y = _height / 2 - self._pos.h / 2
                local totalVelocity = math.max(math.random() * 250, 125)
                local xvel = math.min(math.random() * totalVelocity, 65)
                local xdirection = math.random()
                local ydirection = math.random()
                if xdirection < 0.5 then
                    self._vel.x = -xvel
                else
                    self._vel.x = xvel
                end
                if ydirection < 0.5 then
                    self._vel.y = -(totalVelocity - xvel)
                else
                    self._vel.y = totalVelocity - xvel
                end
                playerScore = playerScore + 1
            end
        end
    })
    entity({
        init = function(self)
            local textw, texth = font:sizeText("0")
            self._score = playerScore
            self._pos = Rectangle.new(10, _height - 10 - texth, textw, texth)
            local surface = font:renderTextBlended("0", 255, 255, 255)
            self._tex = renderer:createTextureFromSurface(surface)
        end,
        tick = function(self, dt)
            if self._score ~= playerScore then
                local surface = font:renderTextBlended(tostring(playerScore), 255, 255, 255)
                self._tex:update(surface)
                self._score = playerScore
            end
        end,
        render = function(self, r, dt)
            r:copy(self._tex, nil, self._pos)
        end
    })
    entity({
        init = function(self)
            local textw, texth = font:sizeText("0")
            self._score = enemyScore
            self._pos = Rectangle.new(_width - 10 - textw, 10, textw, texth)
            local surface = font:renderTextBlended("0", 255, 255, 255)
            self._tex = renderer:createTextureFromSurface(surface)
        end,
        tick = function(self, dt)
            if self._score ~= enemyScore then
                local surface = font:renderTextBlended(tostring(enemyScore), 255, 255, 255)
                self._tex:update(surface)
                self._score = enemyScore
            end
        end,
        render = function(self, r, dt)
            r:copy(self._tex, nil, self._pos)
        end
    })

    local going = true
    local frame = 0
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
                doAllEntities("input", event, event.name == "KEYDOWN" or event.name == "MOUSEBUTTONDOWN")
            end
            event = sdl.pollEvent()
        end

        doAllEntities("tick", _tickTime)
        findCollisions()
        renderer:clear()
        doAllEntities("render", renderer, _tickTime)

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
