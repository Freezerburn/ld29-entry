package.path = lfs.packagedir() .. "/?.lua"

local engine = require "engine"
local class = require "middleclass"
local log = require "log"

local components = require "components"
local entities = require "entities"

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
local smallText = nil
local npcDialogWidth = 150
local npcDialogBuffer = 20
local npcTextBackground = {r = 0, g = 0, b = 0}
-- local npcTextColor = {r = 255, g = 255, b = 255}
local npcTextColor = {r = 0, g = 255, b = 255}
local figures = {}

local tileSize = 16
local tileDrawSize = 48
local wallColor = {r = 255, g = 50, b = 50}
local floorLayer = 0
local wallLayer = 5
local triggerLayer = 6
local playerLayer = 10
local playerSpeed = 250
local useKey = sdl.KEY_E
local triggerCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local timersCreated = 0
local levelSize = {w = 0, h = 0}
local glitchesCreated = 0
local floorCreated = 0

local treasureLocation = {}

local buttonsPressed = {room2 = false}
local activations = {}

local glyphs = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789?!.,-()'\" "
local glyphAtlas = {}

local Entity = engine.Entity
local Vector = engine.Vector
local Rectangle = engine.Rectangle
local getCurrentScene = engine.getCurrentScene

local gameScene = nil
local menuScene = nil
local startCutscene = nil
local loseCutscene = nil
local winCutscene = nil

local artGalleryStart = nil
local artGalleryFromExit1 = nil
local artGalleryFromExit2 = nil

local exit1FromStart = nil
local exit1FromExit3 = nil

local objectiveRoomFrom2 = nil
local objectiveRoomFrom3 = nil

local artGalleryStartSettings = {
    filename = "art_gallery_start.level",
    a = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtABubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "A beautiful piece of art.",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "ArtPiece1.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
            flipx = true
        }
    },
    b = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtBBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "You think of your childhood...",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "ArtPiece1.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
            flipx = true
        }
    },
    c = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtCBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "You aren't sure what you feel about this piece.",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "ArtPiece2.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100
        }
    },
    d = {
        callback = function(self, rect)
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "ArtPiece2.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100
        }
    },
    e = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtEBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "I love this art.",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "NPCLeft.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100
        }
    },
    f = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtFBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2 - 30, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "This really captures the depth of human emotion.",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer + 30,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "NPCLeft.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
            flipx = true
        }
    },
    g = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtGBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "You like the color of the sky.",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "ArtPiece3.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100
        }
    },
    h = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtHBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "What pretty flowers.",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "ArtPiece3.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100
        }
    },
    i = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtIBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "I don't like this one as much as I like the one farther down.",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "ArtPiece4.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100
        }
    },
    j = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtJBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "A beautiful night sky as rendered by a famouse impressionist. Long dead.",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "ArtPiece4.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100
        }
    },
    k = {
        callback = function(self, rect)
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "ArtPiece5.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100
        }
    },
    l = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtLBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2 + 30, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "A wonderful commentary on modern political matters.",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "NPCLeft.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100
        }
    },
    m = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtMBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2 - 30, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "Looks like a loaf of bread...",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "Statue1.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
        }
    },
    n = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtNBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2 - 30, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "Modern art is terrible.",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "Statue1.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
        }
    },
    o = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtOBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2 - 30, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "An ode to bean counters.",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "Statue1.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
            flipx = true
        }
    },
    p = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtPBubble"
            if not activations.fakeStatue then
                activations.fakeStatue = 0
            end
            if not scene:getEntity(name) then
                if activations.fakeStatue == 0 then
                    scene:createEntity("TextBubble", name,
                        rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                        playerLayer + 1,
                        {
                            text = "I don't even know what this is. What was the creator thinking?",
                            background = npcTextBackground,
                            textColor = npcTextColor,
                            font = dialogBubbleFont,
                            buffer = npcDialogBuffer,
                            timeout = 2
                        })
                    activations.fakeStatue = 1
                elseif activations.fakeStatue == 1 then
                    scene:createEntity("TextBubble", name,
                        rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                        playerLayer + 1,
                        {
                            text = "Wait, is this statue the same as the others?",
                            background = npcTextBackground,
                            textColor = npcTextColor,
                            font = dialogBubbleFont,
                            buffer = npcDialogBuffer,
                            timeout = 2
                        })
                    activations.fakeStatue = 2
                elseif activations.fakeStatue == 2 then
                    scene:createEntity("TextBubble", name,
                        rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                        playerLayer + 1,
                        {
                            text = "Let me examine it closely...",
                            background = npcTextBackground,
                            textColor = npcTextColor,
                            font = dialogBubbleFont,
                            buffer = npcDialogBuffer,
                            timeout = 2
                        })
                    activations.fakeStatue = 3
                elseif activations.fakeStatue == 3 then
                    scene:createEntity("TextBubble", name,
                        rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                        playerLayer + 1,
                        {
                            text = "It's insane to call this art.",
                            background = npcTextBackground,
                            textColor = npcTextColor,
                            font = dialogBubbleFont,
                            buffer = npcDialogBuffer,
                            timeout = 2
                        })
                    activations.fakeStatue = 4
                else
                    if not buttonsPressed.room1 then
                        scene:createEntity("TextBubble", name,
                            rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                            playerLayer + 1,
                            {
                                text = "A hidden switch! You press it, but nothing seems to happen.",
                                background = npcTextBackground,
                                textColor = npcTextColor,
                                font = dialogBubbleFont,
                                buffer = npcDialogBuffer,
                                timeout = 2
                            })
                        buttonsPressed.room1 = true
                    else
                        scene:createEntity("TextBubble", name,
                            rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                            playerLayer + 1,
                            {
                                text = "I wonder if there are other switches elsewhere...",
                                background = npcTextBackground,
                                textColor = npcTextColor,
                                font = dialogBubbleFont,
                                buffer = npcDialogBuffer,
                                timeout = 2
                            })
                    end
                end
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "StatueKey.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
            flipx = true
        }
    },
    q = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtQBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2 - 30, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "It's perfect!",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "NPCLeft.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
        }
    },
    r = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtQBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2 - 30, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "Amazing!",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "NPCLeft.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
            flipx = true
        }
    },
    u = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtUBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "What do you think of art?",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "NPCLeft.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100
        }
    },
    v = {
        callback = function(self, rect)
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "ArtPiece2.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
            flipx = true
        }
    },
    t = {
        callback = function(self, rect)
            engine.Scene.swap(objectiveRoomFrom2)
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "Door.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
            flipx = true
        }
    },
    w = {
        callback = function(self, rect)
            engine.Scene.swap(exit1FromStart)
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "Door.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
            flipx = true
        }
    },
    x = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtXBubble"
            if not activations.gotTreasure then
                if not scene:getEntity(name) then
                    scene:createEntity("TextBubble", name,
                        rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                        playerLayer + 1,
                        {
                            text = "I can't abandon my mission!",
                            background = npcTextBackground,
                            textColor = npcTextColor,
                            font = dialogBubbleFont,
                            buffer = npcDialogBuffer,
                            timeout = 2
                        })
                end
            else
                if buttonsPressed.room1 and buttonsPressed.room2 then
                    engine.Scene.swap(winCutscene)
                else
                    engine.Scene.swap(loseCutscene)
                end
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "Door.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
            flipx = true
        }
    },
}

local room1Settings = {
    filename = "room1_fromstart.level",
    a = {
        callback = function(self, rect)
            engine.Scene.swap(artGalleryFromExit1)
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "Door.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
            flipx = true
        }
    },
    b = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtBBubble"
            if not buttonsPressed.room2 then
                local ent = scene:getEntity(name)
                if not ent then
                    scene:createEntity("TextBubble", name,
                        rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                        playerLayer + 1,
                        {
                            text = "A curious place for a switch... You press it, but nothing seems to happen.",
                            background = npcTextBackground,
                            textColor = npcTextColor,
                            font = dialogBubbleFont,
                            buffer = npcDialogBuffer,
                            timeout = 2
                        })
                    buttonsPressed.room2 = true
                end
            else
                local ent = scene:getEntity(name)
                if not ent then
                    scene:createEntity("TextBubble", name,
                        rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                        playerLayer + 1,
                        {
                            text = "I wonder if there are other switches elsewhere...",
                            background = npcTextBackground,
                            textColor = npcTextColor,
                            font = dialogBubbleFont,
                            buffer = npcDialogBuffer,
                            timeout = 2
                        })
                end
            end
        end,
        triggerOnUse = true,
        texture = {
            filename = "Filler.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
            flipx = true
        }
    },
    c = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtCBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "Soothing. That's it.",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "ArtPiece2.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
            flipx = true
        }
    },
    d = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtDBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "Why do people like painting the night sky so much?",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "ArtPiece2.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
            flipx = true
        }
    },
    e = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtEBubble"
            if not activations.fakePainting then
                activations.fakePainting = 0
            end
            if not scene:getEntity(name) then
                if activations.fakePainting == 0 then
                    scene:createEntity("TextBubble", name,
                        rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                        playerLayer + 1,
                        {
                            text = "A beautiful painting. Something bothers you about it though...",
                            background = npcTextBackground,
                            textColor = npcTextColor,
                            font = dialogBubbleFont,
                            buffer = npcDialogBuffer,
                            timeout = 2
                        })
                    activations.fakePainting = activations.fakePainting + 1
                elseif activations.fakePainting == 1 then
                    scene:createEntity("TextBubble", name,
                        rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                        playerLayer + 1,
                        {
                            text = "A beautiful painting. Hmm...",
                            background = npcTextBackground,
                            textColor = npcTextColor,
                            font = dialogBubbleFont,
                            buffer = npcDialogBuffer,
                            timeout = 2
                        })
                    activations.fakePainting = activations.fakePainting + 1
                elseif activations.fakePainting == 2 then
                    scene:createEntity("TextBubble", name,
                        rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                        playerLayer + 1,
                        {
                            text = "A beautiful painting. Why is this painting so odd?",
                            background = npcTextBackground,
                            textColor = npcTextColor,
                            font = dialogBubbleFont,
                            buffer = npcDialogBuffer,
                            timeout = 2
                        })
                    activations.fakePainting = activations.fakePainting + 1
                elseif activations.fakePainting == 3 then
                    scene:createEntity("TextBubble", name,
                        rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                        playerLayer + 1,
                        {
                            text = "A beautiful painting.",
                            background = npcTextBackground,
                            textColor = npcTextColor,
                            font = dialogBubbleFont,
                            buffer = npcDialogBuffer,
                            timeout = 2
                        })
                    activations.fakePainting = activations.fakePainting + 1
                else
                    scene:createEntity("TextBubble", name,
                        rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                        playerLayer + 1,
                        {
                            text = "What? The painting can be moved. You move it out of the way to reveal a hidden passage.",
                            background = npcTextBackground,
                            textColor = npcTextColor,
                            font = dialogBubbleFont,
                            buffer = npcDialogBuffer,
                            timeout = 2
                        })
                    self:kill()
                end
            end
        end,
        unique = true,
        solid = true,
        triggerOnUse = true,
        texture = {
            filename = "ArtPieceKey.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100
        }
    },
    f = {
        callback = function(self, rect)
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "ArtPiece2.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
            flipx = true
        }
    },
    g = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtGBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "Is there nothing this artist can't do?",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "NPCUp.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
            flipx = true
        }
    },
    h = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtHBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "I'm so tired of seeing this piece of art...",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "ArtPiece2.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
            flipx = true
        }
    },
    i = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtIBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "Honestly? Kind of boring. You expect better from this artist.",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "ArtPiece2.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
            flipx = true
        }
    },
    l = {
        callback = function(self, rect)
            engine.Scene.swap(objectiveRoomFrom3)
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "Door.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
            flipx = true
        }
    },
    m = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtMBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "Is this some kind of alien baby?",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "Statue1.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
            flipx = true
        }
    },
    n = {
        callback = function(self, rect)
            local scene = getCurrentScene()
            local name = "ArtNBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "The artist that made this obviously has too modern of tastes for you.",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "Statue1.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
            flipx = true
        }
    },
}

local function getTreasureCallback(self, rect)
    local entf = getCurrentScene():getEntity("Triggerf")
    if entf then
        activations.gotTreasure = true
        entf:kill()
        print("Creating trigger with empty pedestal.")
        getCurrentScene():createEntity("Trigger", "Trigger" .. 290853097320984329,
            entf._rect.x, entf._rect.y, rect.w, rect.h, playerLayer + 1,
            {
                callback = function() end,
                onUse = true,
                solid = true,
                texture = {
                    filename = "Objective2.png",
                    name = "main",
                    frames = 1,
                    width = tileSize,
                    height = tileSize,
                    start = {x = 0, y = 0},
                    animationTime = 100
                }
            })
        print("Creating text bubble.")
        getCurrentScene():createEntity("TextBubble", "GotTreasure",
            entf._rect.x + rect.w / 2, entf._rect.y + rect.h * 2, 200, 0, playerLayer + 2,
            {
                text = "I got the treasure I was assigned to steal. Now I just need to make it back out of the museum.",
                background = npcTextBackground,
                textColor = npcTextColor,
                font = dialogBubbleFont,
                buffer = npcDialogBuffer,
                timeout = 4
            })
    end
end
local objectiveRoomSettings = {
    filename = "objective_room_from2.level",
    a = {
        callback = function(self, rect)
            engine.Scene.swap(artGalleryFromExit2)
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "Door.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100
        }
    },
    b = {
        callback = function(self, rect)
            engine.Scene.swap(exit1FromExit3)
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "Door.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100
        }
    },
    c = {
        callback = function(self, rect)
            local name = "ArtCBubble"
            local ent = getCurrentScene():getEntity(name)
            if not ent then
                getCurrentScene():createEntity("TextBubble", name,
                    rect.x + rect.w / 2 - 100, rect.y, 200, 0, playerLayer + 1,
                    {
                        text = "It's nice, but I need to focus on getting that treasure!",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "ArtPiece1.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100
        }
    },
    d = {
        callback = function(self, rect)
            local name = "ArtDBubble"
            local ent = getCurrentScene():getEntity(name)
            if not ent then
                getCurrentScene():createEntity("TextBubble", name,
                    rect.x + 120, rect.y, 200, 0, playerLayer + 1,
                    {
                        text = "It's calming, but I need to focus on getting that treasure!",
                        background = npcTextBackground,
                        textColor = npcTextColor,
                        font = dialogBubbleFont,
                        buffer = npcDialogBuffer,
                        timeout = 2
                    })
            end
        end,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "ArtPiece4.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100
        }
    },
    e = {
        callback = getTreasureCallback,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "ObjectiveSurroundBottom.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100
        }
    },
    f = {
        callback = function(self, rect)
        end,
        unique = true,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "Objective1.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100
        }
    },
    g = {
        callback = getTreasureCallback,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "ObjectiveSurroundBottomLeft.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100
        }
    },
    h = {
        callback = getTreasureCallback,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "ObjectiveSurroundBottomLeft.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
            flipx = true
        }
    },
    i = {
        callback = getTreasureCallback,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "ObjectiveSurroundLeft.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
        }
    },
    j = {
        callback = getTreasureCallback,
        triggerOnUse = true,
        solid = true,
        texture = {
            filename = "ObjectiveSurroundLeft.png",
            name = "main",
            frames = 1,
            width = tileSize,
            height = tileSize,
            start = {x = 0, y = 0},
            animationTime = 100,
            flipx = true
        }
    },
}

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
    local prevx, prevy = self._rect.x, self._rect.y
    self:tickMove(dt)
    camera.move(prevx - self._rect.x, prevy - self._rect.y)
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
        camera.move(-minx, 0)
    end
    if miny ~= math.huge then
        self._rect.y = self._rect.y + miny
        camera.move(0, -miny)
    end
end
function Player:getRect()
    return Rectangle.new(self._rect.x + 15, self._rect.y + 15,
        self._rect.w - 25, self._rect.h - 25)
end
function Player:setRect(rect)
    camera.move(self._rect.x - rect.x, self._rect.y - rect.y)
    self._rect = rect
end

local wallsCreated = 0
Wall = class("Wall", Entity)
Wall:include(components.ColoredRect)
function Wall:init(settings)
    self:initColoredRect(renderer, settings.r, settings.g, settings.b,
        string.format("Wall{%d,%d,%d}", settings.r, settings.g, settings.b))
    self._frames = 0
end
function Wall:render(renderer, dt)
    self:renderColoredRect(renderer, dt)
end
function Wall:tick(dt)
    self._frames = self._frames + 1
    if self._frames % 10 == 0 then
        if math.random() < 0.001 then
            getCurrentScene():createEntity("Glitch", "Glitch" .. glitchesCreated,
                self._rect.x, self._rect.y, self._rect.w, self._rect.h,
                wallLayer + 1)
            glitchesCreated = glitchesCreated + 1
        end
    end
end

local fillerCreated = 0
Filler = class("Filler", Entity)
Filler:include(components.Animated)
function Filler:init(settings)
    self:initAnimated()
    self:addAnimation({
        filename = "Filler.png",
        name = "idle",
        frames = 1,
        width = tileSize,
        height = tileSize,
        start = {x = 0, y = 0},
        animationTime = 100
    })
    self:setAnimation("idle")
    self._frames = 0
end
function Filler:tick(dt)
    self:tickAnimated(dt)
    self._frames = self._frames + 1
    if self._frames % 10 == 0 then
        if math.random() < 0.0001 then
            getCurrentScene():createEntity("Glitch", "Glitch" .. glitchesCreated,
                self._rect.x, self._rect.y, self._rect.w, self._rect.h,
                wallLayer + 1)
            glitchesCreated = glitchesCreated + 1
        end
    end
end
function Filler:render(renderer, dt)
    self:renderAnimated(renderer, dt)
end

Floor = class("Floor", Entity)
Floor:include(components.Animated)
function Floor:init(settings)
    self:initAnimated()
    self:addAnimation({
        filename = "Floor.png",
        name = "floor",
        frames = 1,
        width = tileSize,
        height = tileSize,
        start = {x = 0, y = 0},
        animationTime = 100
    })
    self:setAnimation("floor")
end
function Floor:render(renderer, dt)
    self:renderAnimated(renderer, dt)
end
function Floor:tick(dt)
    self:tickAnimated(dt)
end

Glitch = class("Glitch", Entity)
Glitch:include(components.Animated)
function Glitch:init(settings)
    self:initAnimated()
    self:addAnimation({
        filename = "Glitch.png",
        name = "glitch",
        frames = 3,
        width = tileSize,
        height = tileSize,
        start = {x = 0, y = 0},
        animationTime = 0.5 / 3
    })
    self:setAnimation("glitch")
    getCurrentScene():createEntity("Timer", "Timer" .. timersCreated, 0, 0, 0, 0, 0,
        {callback = function() self:kill() end,
        timeout = 0.5})
    timersCreated = timersCreated + 1
end
function Glitch:tick(dt)
    self:tickAnimated(dt)
end
function Glitch:render(renderer, dt)
    self:renderAnimated(renderer, dt)
end

local numCreatedTriggers = 0
Level = class("Level", Entity)
function Level:init(settings)
    self._levelMatrix = {}
    self._unique = {}
    local maxLineSize = 0
    local filename = lfs.packagedir() .. "/" .. settings.filename
    for line in io.lines(filename) do
        table.insert(self._levelMatrix, line)
        if #line > maxLineSize then
            maxLineSize = #line
        end
    end
    self._levelWidth, self._levelHeight = maxLineSize * tileDrawSize, #self._levelMatrix * tileDrawSize
    self:setLimits()

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
                self._playerStart = {x = (x - 1) * tileDrawSize + tileDrawSize / 2,
                    y = (y - 1) * tileDrawSize + tileDrawSize / 2}
                self:setCamera()
                getCurrentScene():createEntity("Player", "Player",
                    (x - 1) * tileDrawSize, (y - 1) * tileDrawSize,
                    tileDrawSize, tileDrawSize, playerLayer)
                getCurrentScene():createEntity("Floor", "Floor" .. floorCreated,
                    (x - 1) * tileDrawSize, (y - 1) * tileDrawSize,
                    tileDrawSize, tileDrawSize, floorLayer)
                floorCreated = floorCreated + 1
            elseif c == "." then
                getCurrentScene():createEntity("Filler", "Filler" .. fillerCreated,
                    (x - 1) * tileDrawSize, (y - 1) * tileDrawSize,
                    tileDrawSize, tileDrawSize, wallLayer)
                fillerCreated = fillerCreated + 1
            elseif c == "*" then
                getCurrentScene():createEntity("Floor", "Floor" .. floorCreated,
                    (x - 1) * tileDrawSize, (y - 1) * tileDrawSize,
                    tileDrawSize, tileDrawSize, floorLayer)
                floorCreated = floorCreated + 1
            elseif triggerCharacters:find(c) then
                if settings[c] then
                    local triggerSettings = {callback = settings[c].callback,
                        name = c, solid = settings[c].solid}
                    if settings[c].once then
                        triggerSettings.once = settings[c].once
                    end
                    if settings[c].triggerOnUse then
                        triggerSettings.onUse = settings[c].triggerOnUse
                    end
                    if settings[c].texture then
                        triggerSettings.texture = settings[c].texture
                    end
                    local entName = nil
                    if settings[c].unique then
                        entName = "Trigger" .. c
                        print(string.format("Scene '%s' making unique trigger '%s'.",
                            getCurrentScene().name, entName))
                        table.insert(self._unique, entName)
                    else
                        entName = "Trigger" .. numCreatedTriggers
                    end
                    if c == "f" then
                        self._treasureLocation = {x = (x - 1) * tileDrawSize, y = (y - 1) * tileDrawSize}
                    end
                    -- print("Adding in trigger: " .. entName)
                    getCurrentScene():createEntity("Trigger", entName,
                        (x - 1) * tileDrawSize, (y - 1) * tileDrawSize,
                        tileDrawSize, tileDrawSize, triggerLayer,
                        triggerSettings)
                    numCreatedTriggers = numCreatedTriggers + 1
                end
                getCurrentScene():createEntity("Floor", "Floor" .. floorCreated,
                    (x - 1) * tileDrawSize, (y - 1) * tileDrawSize,
                    tileDrawSize, tileDrawSize, floorLayer)
                floorCreated = floorCreated + 1
            end
            x = x + 1
        end
    end
end
function Level:setLimits()
    levelSize.w, levelSize.h = self._levelWidth, self._levelHeight
    camera.setLimit(true)
    camera.setLimits({x = 0, y = 0, w = levelSize.w, h = levelSize.h})
end
function Level:setCamera()
    camera.set(self._playerStart.x, self._playerStart.y)
end
function Level:resetPlayer()
    local player = getCurrentScene():getEntity("Player")
    player._rect.x, player._rect.y = self._playerStart.x, self._playerStart.y
    treasureLocation.x, treasureLocation.y = self._treasureLocation.x, self._treasureLocation.y
end
function Level:kill()
    for _, name in ipairs(self._unique) do
        local ent = getCurrentScene():getEntity(name)
        if ent then
            ent:kill()
        end
    end
    Entity.kill(self)
end

Trigger = class("Trigger", Entity)
Trigger:include(components.ColoredRect)
Trigger:include(components.Animated)
function Trigger:init(settings)
    self._triggeredCallback = settings.callback
    self._triggerOnUse = settings.onUse
    self._triggerOnce = settings.once
    self._triggerName = settings.name
    self._triggered = false
    self._playerIn = false
    self._solid = settings.solid
    self._collisionOffset = settings.collisionOffset
    if not settings.texture then
        self:initColoredRect(renderer, 200, 200, 0, string.format("Trigger{%d,%d,%d}", 200, 200, 0))
    else
        self._texture = true
        self:initAnimated()
        self:addAnimation(settings.texture)
        self:setAnimation(settings.texture.name)
    end
end
function Trigger:render(renderer, dt)
    if not self._texture then
        self:renderColoredRect(renderer, dt)
    else
        self:renderAnimated(renderer, dt)
    end
end
function Trigger:getRect()
    if self._collisionOffset then
        return Rectangle.new(self._rect.x + self._collisionOffset.x, self._rect.y + self._collisionOffset.y,
            self._rect.w - self._collisionOffset.x * 2, self._rect.h - self._collisionOffset.y * 2)
    else
        return self._rect
    end
end
function Trigger:input(event, pushed)
    local player = getCurrentScene():getEntity("Player")
    if player then
        local totalVel = math.abs(player._vel.x) + math.abs(player._vel.y)
        if self._triggerOnUse and
           self._playerIn and
           not getCurrentScene().triggersThatHaveBeenTriggered[self._triggerName] and
           not getCurrentScene().triggeredThisFrame[self._triggerName] and
           totalVel == 0 then
            if pushed and not event.repeated then
                if string.find(event.name, "KEY") then
                    if event.sym == useKey then
                        self:_triggeredCallback(self._rect)
                        getCurrentScene().triggeredThisFrame[self._triggerName] = true
                        if self._triggerOnce then
                            getCurrentScene().triggersThatHaveBeenTriggered[self._triggerName] = true
                        end
                    end
                end
            end
        end
    end
end
function Trigger:tick(dt)
    local player = getCurrentScene():getEntity("Player")
    if player then
        local playerCenter = player:getRect():getCenter()
        local selfRect = self:getRect()
        local center = selfRect:getCenter()
        if (center - playerCenter):length() < (selfRect.w > selfRect.h and selfRect.w or selfRect.h) * 1.5 then
            self._playerIn = true
        else
            self._playerIn = false
        end
        if self._texture then
            self:tickAnimated(dt)
        end
    end
end
function Trigger:collision(between, deltas)
    for i, ent in ipairs(between) do
        if ent.name:find("Player") then
            if self._solid then
                ent:setRect(ent._rect - deltas[i])
            end
            if not self._triggerOnUse and
               not getCurrentScene().triggersThatHaveBeenTriggered[self._triggerName] and
               not getCurrentScene().triggeredThisFrame[self._triggerName] then
                self:_triggeredCallback(self._rect)
                getCurrentScene().triggeredThisFrame[self._triggerName] = true
                if self._triggerOnce then
                    getCurrentScene().triggersThatHaveBeenTriggered[self._triggerName] = true
                end
            end
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

SimpleRenderer = class("SimpleRenderer", Entity)
function SimpleRenderer:init(settings)
    self._texture = settings.texture
end
function SimpleRenderer:render(renderer, dt)
    renderer:copy(self._texture, nil, self._rect)
end

GetInput = class("GetInput", Entity)
function GetInput:init(settings)
    self._callback = settings.callback
end
function GetInput:input(event, pushed)
    self._callback(event, pushed)
end

function main()
    math.randomseed(os.time())

    sdl.init(sdl.INIT_EVERYTHING)
    ttf.init()
    img.init(bit32.bor(img.INIT_JPG, img.INIT_PNG))

    window = sdl.createWindow("LD29!",
        sdl.WINDOWPOS_UNDEFINED, sdl.WINDOWPOS_UNDEFINED,
        _width, _height,
        _windowFlags)
    renderer = sdl.createRenderer(window, -1, _renderFlags)
    engine.renderer = renderer
    -- local cliprect = renderer:getClipRect()
    -- local viewport = renderer:getViewport()
    -- print(string.format("x = %d, y = %d, w = %d, h = %d", cliprect.x, cliprect.y, cliprect.w, cliprect.h))
    -- print(string.format("x = %d, y = %d, w = %d, h = %d", viewport.x, viewport.y, viewport.w, viewport.h))
    -- renderer:setViewport({x=-50, y=-50, w=viewport.w, h=viewport.h})

    font = ttf.openFont("Arial.ttf", 42)
    dialogBubbleFont = ttf.openFont("Arial.ttf", 20)
    systemDialogFont = ttf.openFont("Arial.ttf", 26)
    smallText = ttf.openFont("Arial.ttf", 14)
    engine.cacheAtlas(font, {r=0, g=0, b=0}, glyphs)
    engine.cacheAtlas(dialogBubbleFont, npcTextColor, glyphs)
    engine.cacheAtlas(systemDialogFont, {r=0, g=0, b=0}, glyphs)
    local surface = img.load("LightRedFigure.png")
    table.insert(figures, renderer:createTextureFromSurface(surface))
    surface = img.load("LightGreenFigure.png")
    table.insert(figures, renderer:createTextureFromSurface(surface))

    menuScene = engine.Scene.new({
        name = "Menu",
        init = function(self)
            self._triangleHeight = 18
            self._triangleWidth = 18
            self._triangleBuffer = 10
            local surface = sdl.createRGBSurface(self._triangleWidth, self._triangleHeight)
            local rect = Rectangle.new(0, 0, 1)
            for i = 0, self._triangleWidth do
                rect.x = i
                rect.y = i
                rect.h = self._triangleHeight - i * 2
                surface:fillRect(rect, 255, 255, 255)
            end
            self._triangleTex = renderer:createTextureFromSurface(surface)
            local this = self
            self:createEntity("Text", "GameNameText",
                _width / 2, 100, 0, 0, 5,
                {useRectAsCenter = true, font = font, text = "Hidden in Plain Sight",
                r = 190, g = 190, b = 0})
            self:createEntity("TextButton", "GameStart",
                _width / 2, _height / 2, 0, 0, 5,
                {
                    font = font,
                    text = "Start",
                    clicked = function(self)
                        engine.Scene.swap(startCutscene)
                    end,
                    entered = function(self)
                        local name = "RenderStartTriangle"
                        if not getCurrentScene():getEntity(name) then
                            this:createEntity("SimpleRenderer", name,
                                self._rect.x - this._triangleBuffer - this._triangleWidth,
                                self._rect.y + self._rect.h / 2 - this._triangleHeight / 2,
                                this._triangleWidth, this._triangleHeight, 6,
                                {texture = this._triangleTex})
                        end
                    end,
                    left = function(self)
                        local name = "RenderStartTriangle"
                        local ent = getCurrentScene():getEntity(name)
                        if ent then
                            ent:kill()
                        end
                    end,
                    background = {r = 0, g = 0, b = 0},
                    textColor = {r = 255, g = 255, b = 255},
                    originIsCenter = true
                })
            self:createEntity("TextButton", "GameQuit",
                _width / 2, _height / 2 + 50, 0, 0, 5,
                {
                    font = font,
                    text = "Quit",
                    clicked = function(self)
                        engine.quit()
                    end,
                    entered = function(self)
                        local name = "RenderQuitTriangle"
                        if not getCurrentScene():getEntity(name) then
                            this:createEntity("SimpleRenderer", name,
                                self._rect.x - this._triangleBuffer - this._triangleWidth,
                                self._rect.y + self._rect.h / 2 - this._triangleHeight / 2,
                                this._triangleWidth, this._triangleHeight, 6,
                                {texture = this._triangleTex})
                        end
                    end,
                    left = function(self)
                        local name = "RenderQuitTriangle"
                        local ent = getCurrentScene():getEntity(name)
                        if ent then
                            ent:kill()
                        end
                    end,
                    background = {r = 0, g = 0, b = 0},
                    textColor = {r = 255, g = 255, b = 255},
                    originIsCenter = true
                })
        end,
        show = function(self)
        end
    })
    startCutscene = engine.Scene.new({
        name = "Start Cutscene",
        init = function(self)
            self._nextText = 1
            self._texts = {
                {{"Congratulations on making it into", "the National Spy Program. "}, 1},
                {{"You have endured much to get here, and", "today you will be going on" ..
                 " your first mission."}, 1},
                {{"You are tasked with stealing the", "centerpiece item from a foreign museum."}, 1},
                {{"It is of great important you get this", "item. Proceed with caution."}, 1},
                {{"You leave the briefing room and head", "out on your mission."}, 0},
                {{"Do you think he suspects anything?"}, 2},
                {{"No. There is no way he will figure it out."}, 1},
                {{"Controls for this game are:", "W - go up",
                "S - go down",
                "A - go left",
                "D - go right",
                "E - interact with things"}, 0}
            }
            self._textNames = {}
            self._createTexts = function(self)
                for i, name in ipairs(self._textNames) do
                    local ent = self:getEntity(name)
                    if ent then
                        ent:kill()
                    end
                end
                local figure = self:getEntity("Figure")
                if figure then
                    figure:kill()
                end

                local pair = self._texts[self._currentText]
                if pair then
                    if pair[2] == 0 then
                        for i, text in ipairs(pair[1]) do
                            table.insert(self._textNames, "Main text " .. self._nextText)
                            self:createEntity("Text", "Main text " .. self._nextText,
                                50, 50 + (i - 1) * 40, 0, 0, 5,
                                {font = systemDialogFont, text = text,
                                r = 255, g = 255, b = 255})
                            self._nextText = self._nextText + 1
                        end
                    else
                        self:createEntity("SimpleRenderer", "Figure",
                            10, 50, 80, 80, 5, {texture = figures[pair[2]]})
                        for i, text in ipairs(pair[1]) do
                            table.insert(self._textNames, "Main text " .. self._nextText)
                            self:createEntity("Text", "Main text " .. self._nextText,
                                100, 50 + (i - 1) * 40, 0, 0, 5,
                                {font = systemDialogFont, text = text,
                                r = 255, g = 255, b = 255})
                            self._nextText = self._nextText + 1
                        end
                    end
                    self._currentText = self._currentText + 1
                else
                    engine.Scene.swap(gameScene)
                end
            end

            local this = self
            self:createEntity("GetInput", "InputCapture", 0, 0, 0, 0, 0,
                {callback = function(event, pushed)
                    if event.sym == sdl.KEY_E and pushed and not event.repeated then
                        this:_createTexts()
                    end
                end})
            self:createEntity("Text", "E to continue",
                _width / 2, _height - 10, 0, 0, 5,
                {useRectAsCenter = true, font = smallText, text = "Press E to continue.",
                r = 255, g = 255, b = 255})
        end,
        show = function(self)
            print("Lose show.")
            self.triggersThatHaveBeenTriggered = {}
            self.triggeredThisFrame = {}
            renderer:setDrawColor(0, 0, 0)
            camera.set(_width / 2, _height / 2)

            self._currentText = 1
            self:_createTexts()
        end
    })
    loseCutscene = engine.Scene.new({
        name = "Lose Cutscene",
        init = function(self)
            print("Lose init.")
            self._nextText = 1
            self._texts = {
                {{"You have done well, doing axactly as", "we have asked."}, 1},
                {{"You will be with us for a very, very", "long time as our loyal agent."}, 1},
                {{"You win!"}, 0},
                {{"... or did you? Explore the museum more", "to find out. There might be more to this",
                "world beneath the surface than you might think."}, 0}
            }
            self._textNames = {}
            self._createTexts = function(self)
                for i, name in ipairs(self._textNames) do
                    local ent = self:getEntity(name)
                    if ent then
                        ent:kill()
                    end
                end
                local figure = self:getEntity("Figure")
                if figure then
                    figure:kill()
                end

                local pair = self._texts[self._currentText]
                if pair then
                    if pair[2] == 0 then
                        for i, text in ipairs(pair[1]) do
                            table.insert(self._textNames, "Main text " .. self._nextText)
                            self:createEntity("Text", "Main text " .. self._nextText,
                                50, 50 + (i - 1) * 40, 0, 0, 5,
                                {font = systemDialogFont, text = text,
                                r = 255, g = 255, b = 255})
                            self._nextText = self._nextText + 1
                        end
                    else
                        self:createEntity("SimpleRenderer", "Figure",
                            10, 50, 80, 80, 5, {texture = figures[pair[2]]})
                        for i, text in ipairs(pair[1]) do
                            table.insert(self._textNames, "Main text " .. self._nextText)
                            self:createEntity("Text", "Main text " .. self._nextText,
                                100, 50 + (i - 1) * 40, 0, 0, 5,
                                {font = systemDialogFont, text = text,
                                r = 255, g = 255, b = 255})
                            self._nextText = self._nextText + 1
                        end
                    end
                    self._currentText = self._currentText + 1
                else
                    activations = {}
                    buttonsPressed = {}
                    engine.Scene.swap(menuScene)
                end
            end

            local this = self
            self:createEntity("GetInput", "InputCapture", 0, 0, 0, 0, 0,
                {callback = function(event, pushed)
                    if event.sym == sdl.KEY_E and pushed and not event.repeated then
                        this:_createTexts()
                    end
                end})
            self:createEntity("Text", "E to continue",
                _width / 2, _height - 10, 0, 0, 5,
                {useRectAsCenter = true, font = smallText, text = "Press E to continue.",
                r = 255, g = 255, b = 255})
        end,
        show = function(self)
            print("Lose show.")
            self.triggersThatHaveBeenTriggered = {}
            self.triggeredThisFrame = {}
            renderer:setDrawColor(0, 0, 0)
            camera.set(_width / 2, _height / 2)

            self._currentText = 1
            self:_createTexts()
        end
    })
    winCutscene = engine.Scene.new({
        name = "Lose Cutscene",
        init = function(self)
            print("Lose init.")
            self._nextText = 1
            self._texts = {
                {{"What? How did you figure out we had you", "trapped in a simulation?! Impossible!"}, 1},
                {{"You assured me he would not escape! You", "have severely disappointed me. Your",
                "termination will be swift."}, 2},
                {{"He's escaping the facility! Stop him!"}, 2},
                {{"You win! You managed to see beneath the", "surface of the illusion world they made",
                "for you and escape their nefarious", "clutches by findind the switches that would",
                "grant your freedom. Congratulations!"}, 0}
            }
            self._textNames = {}
            self._createTexts = function(self)
                for i, name in ipairs(self._textNames) do
                    local ent = self:getEntity(name)
                    if ent then
                        ent:kill()
                    end
                end
                local figure = self:getEntity("Figure")
                if figure then
                    figure:kill()
                end

                local pair = self._texts[self._currentText]
                if pair then
                    if pair[2] == 0 then
                        for i, text in ipairs(pair[1]) do
                            table.insert(self._textNames, "Main text " .. self._nextText)
                            self:createEntity("Text", "Main text " .. self._nextText,
                                50, 50 + (i - 1) * 40, 0, 0, 5,
                                {font = systemDialogFont, text = text,
                                r = 255, g = 255, b = 255})
                            self._nextText = self._nextText + 1
                        end
                    else
                        self:createEntity("SimpleRenderer", "Figure",
                            10, 50, 80, 80, 5, {texture = figures[pair[2]]})
                        for i, text in ipairs(pair[1]) do
                            table.insert(self._textNames, "Main text " .. self._nextText)
                            self:createEntity("Text", "Main text " .. self._nextText,
                                100, 50 + (i - 1) * 40, 0, 0, 5,
                                {font = systemDialogFont, text = text,
                                r = 255, g = 255, b = 255})
                            self._nextText = self._nextText + 1
                        end
                    end
                    self._currentText = self._currentText + 1
                else
                    activations = {}
                    buttonsPressed = {}
                    engine.Scene.swap(menuScene)
                end
            end

            local this = self
            self:createEntity("GetInput", "InputCapture", 0, 0, 0, 0, 0,
                {callback = function(event, pushed)
                    if event.sym == sdl.KEY_E and pushed and not event.repeated then
                        this:_createTexts()
                    end
                end})
            self:createEntity("Text", "E to continue",
                _width / 2, _height - 10, 0, 0, 5,
                {useRectAsCenter = true, font = smallText, text = "Press E to continue.",
                r = 255, g = 255, b = 255})
        end,
        show = function(self)
            print("Lose show.")
            self.triggersThatHaveBeenTriggered = {}
            self.triggeredThisFrame = {}
            renderer:setDrawColor(0, 0, 0)
            camera.set(_width / 2, _height / 2)

            self._currentText = 1
            self:_createTexts()
        end
    })

    gameScene = engine.Scene.new({
        name = "StartScreen",
        init = function(self)
            self.triggersThatHaveBeenTriggered = {}
            self.triggeredThisFrame = {}
            local this = self
            self:createEntity("Level", "Level", 0, 0, 0, 0, 0,
                artGalleryStartSettings)
            renderer:setDrawColor(255, 255, 255)
            self:createEntity("Cleanup", "Cleanup", 0, 0, 0, 0, 100)
        end,
        show = function(self)
            local level = self:getEntity("Level")
            if level then
                level:setLimits()
                level:setCamera()
                level:resetPlayer()
            end
        end
    })
    exit1FromStart = engine.Scene.new({
        name = "Room1 From Start",
        init = function(self)
            self.triggersThatHaveBeenTriggered = {}
            self.triggeredThisFrame = {}
            -- renderer:setDrawColor(255, 255, 255)
            self:createEntity("Cleanup", "Cleanup", 0, 0, 0, 0, 100)
        end,
        show = function(self)
            local level = self:getEntity("Level")
            if level then
                level:setLimits()
                level:setCamera()
                level:resetPlayer()
            end

            if activations.fakePainting == 4 then
                local this = self
                self:createEntity("Timer", "KillTriggereTimer", 0, 0, 0, 0, 0,
                    {callback = function()
                        if this:getEntity("Triggere") then
                            this:getEntity("Triggere"):kill()
                        end
                    end, timeout = 0.1})
            end

            if not activations.fakePainting or not level then
                activations.fakePainting = 1
                self.triggersThatHaveBeenTriggered = {}
                self.triggeredThisFrame = {}
                room1Settings.filename = "room1_fromstart.level"
                if self:getEntity("Level") then
                    self:getEntity("Level"):kill()
                end
                if self:getEntity("Player") then
                    self:getEntity("Player"):kill()
                end
                self:createEntity("Level", "Level", 0, 0, 0, 0, 0,
                    room1Settings)
            end
        end
    })
    exit1FromExit3 = engine.Scene.new({
        name = "Room1 From Start",
        init = function(self)
            self.triggersThatHaveBeenTriggered = {}
            self.triggeredThisFrame = {}
            -- renderer:setDrawColor(255, 255, 255)
            self:createEntity("Cleanup", "Cleanup", 0, 0, 0, 0, 100)
        end,
        show = function(self)
            local level = self:getEntity("Level")
            if level then
                level:setLimits()
                level:setCamera()
                level:resetPlayer()
            end

            if activations.fakePainting == 4 then
                local this = self
                self:createEntity("Timer", "KillTriggereTimer", 0, 0, 0, 0, 0,
                    {callback = function()
                        if this:getEntity("Triggere") then
                            this:getEntity("Triggere"):kill()
                        end
                    end, timeout = 0.1})
            end

            if not activations.fakePainting or not level then
                activations.fakePainting = 1
                self.triggersThatHaveBeenTriggered = {}
                self.triggeredThisFrame = {}
                room1Settings.filename = "room1_from3.level"
                if self:getEntity("Level") then
                    self:getEntity("Level"):kill()
                end
                if self:getEntity("Player") then
                    self:getEntity("Player"):kill()
                end
                self:createEntity("Level", "Level", 0, 0, 0, 0, 0,
                    room1Settings)
            end
        end
    })
    artGalleryFromExit1 = engine.Scene.new({
        name = "Start From Room1",
        init = function(self)
            self.triggersThatHaveBeenTriggered = {}
            self.triggeredThisFrame = {}
            local this = self
            artGalleryStartSettings.filename = "art_gallery_start_from1.level"
            self:createEntity("Level", "Level", 0, 0, 0, 0, 0,
                artGalleryStartSettings)
            -- renderer:setDrawColor(255, 255, 255)
            self:createEntity("Cleanup", "Cleanup", 0, 0, 0, 0, 100)
        end,
        show = function(self)
            local level = self:getEntity("Level")
            if level then
                level:setLimits()
                level:setCamera()
                level:resetPlayer()
            end
        end
    })
    artGalleryFromExit2 = engine.Scene.new({
        name = "Start From Room1",
        init = function(self)
            self.triggersThatHaveBeenTriggered = {}
            self.triggeredThisFrame = {}
            local this = self
            artGalleryStartSettings.filename = "art_gallery_start_from2.level"
            self:createEntity("Level", "Level", 0, 0, 0, 0, 0,
                artGalleryStartSettings)
            -- renderer:setDrawColor(255, 255, 255)
            self:createEntity("Cleanup", "Cleanup", 0, 0, 0, 0, 100)
        end,
        show = function(self)
            local level = self:getEntity("Level")
            if level then
                level:setLimits()
                level:setCamera()
                level:resetPlayer()
            end
        end
    })
    objectiveRoomFrom2 = engine.Scene.new({
        name = "Objective room from start",
        init = function(self)
            self.triggersThatHaveBeenTriggered = {}
            self.triggeredThisFrame = {}
            -- local this = self
            -- objectiveRoomSettings.filename = "objective_room_from2.level"
            -- self:createEntity("Level", "Level", 0, 0, 0, 0, 0,
            --     objectiveRoomSettings)
            -- renderer:setDrawColor(255, 255, 255)
            self:createEntity("Cleanup", "Cleanup", 0, 0, 0, 0, 100)
        end,
        show = function(self)
            local level = self:getEntity("Level")
            if level then
                level:setLimits()
                level:setCamera()
                level:resetPlayer()
            end

            if not activations.gotTreasure or not level then
                if not activations.gotTreasure then
                    activations.gotTreasure = false
                end
                self.triggersThatHaveBeenTriggered = {}
                self.triggeredThisFrame = {}
                objectiveRoomSettings.filename = "objective_room_from2.level"
                self:clearEntities()
                -- if self:getEntity("Level") then
                --     self:getEntity("Level"):kill()
                -- end
                -- if self:getEntity("Player") then
                --     self:getEntity("Player"):kill()
                -- end
                self:createEntity("Level", "Level", 0, 0, 0, 0, 0,
                    objectiveRoomSettings)
            end

            if activations.gotTreasure then
                local this = self
                self:createEntity("Timer", "KillTriggerfTimer", 0, 0, 0, 0, 0,
                    {callback = function()
                        if this:getEntity("Triggerf") then
                            local entf = this:getEntity("Triggerf")
                            this:getEntity("Triggerf"):kill()
                            getCurrentScene():createEntity("Trigger", "Trigger" .. 290853097320984329,
                                entf._rect.x, entf._rect.y, entf._rect.w, entf._rect.h, playerLayer + 1,
                                {
                                    callback = function() end,
                                    onUse = true,
                                    solid = true,
                                    texture = {
                                        filename = "Objective2.png",
                                        name = "main",
                                        frames = 1,
                                        width = tileSize,
                                        height = tileSize,
                                        start = {x = 0, y = 0},
                                        animationTime = 100
                                    }
                                })
                        end
                    end, timeout = 0.1})
            end
        end
    })
    objectiveRoomFrom3 = engine.Scene.new({
        name = "Objective room from room 2",
        init = function(self)
            self.triggersThatHaveBeenTriggered = {}
            self.triggeredThisFrame = {}
            -- local this = self
            -- objectiveRoomSettings.filename = "objective_room_from3.level"
            -- self:createEntity("Level", "Level", 0, 0, 0, 0, 0,
            --     objectiveRoomSettings)
            -- renderer:setDrawColor(255, 255, 255)
            self:createEntity("Cleanup", "Cleanup", 0, 0, 0, 0, 100)
        end,
        show = function(self)
            self.triggersThatHaveBeenTriggered = {}
            self.triggeredThisFrame = {}

            local level = self:getEntity("Level")
            if level then
                level:setLimits()
                level:setCamera()
                level:resetPlayer()
            end

            if not activations.gotTreasure or not level then
                if not activations.gotTreasure then
                    activations.gotTreasure = false
                end
                self.triggersThatHaveBeenTriggered = {}
                self.triggeredThisFrame = {}
                objectiveRoomSettings.filename = "objective_room_from3.level"
                -- if self:getEntity("Level") then
                --     self:getEntity("Level"):kill()
                -- end
                -- if self:getEntity("Player") then
                --     self:getEntity("Player"):kill()
                -- end
                self:clearEntities()
                self:createEntity("Level", "Level", 0, 0, 0, 0, 0,
                    objectiveRoomSettings)
            end

            if activations.gotTreasure then
                local this = self
                self:createEntity("Timer", "KillTriggerfTimer", 0, 0, 0, 0, 0,
                    {callback = function()
                        if this:getEntity("Triggerf") then
                            local entf = this:getEntity("Triggerf")
                            this:getEntity("Triggerf"):kill()
                            getCurrentScene():createEntity("Trigger", "Trigger" .. 290853097320984329,
                                entf._rect.x, entf._rect.y, entf._rect.w, entf._rect.h, playerLayer + 1,
                                {
                                    callback = function() end,
                                    onUse = true,
                                    solid = true,
                                    texture = {
                                        filename = "Objective2.png",
                                        name = "main",
                                        frames = 1,
                                        width = tileSize,
                                        height = tileSize,
                                        start = {x = 0, y = 0},
                                        animationTime = 100
                                    }
                                })
                        end
                    end, timeout = 0.1})
            end
        end
    })
    engine.Scene.swap(menuScene)

    engine.startGameLoop(renderer, _tickTime)
end
