local allSettings = {}

allSettings.artGalleryStartSettings = {
    filename = "art_gallery_start.level",
    a = {
        callback = function(rect)
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
        callback = function(rect)
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
        callback = function(rect)
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
        callback = function(rect)
            local scene = getCurrentScene()
            local name = "ArtDBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "Night time is so depressing... or exciting? You think of your training.",
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
    e = {
        callback = function(rect)
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
        callback = function(rect)
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
        callback = function(rect)
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
        callback = function(rect)
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
        callback = function(rect)
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
        callback = function(rect)
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
        callback = function(rect)
            local scene = getCurrentScene()
            local name = "ArtKBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2 + 30, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "Some kind of flag...?",
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
        callback = function(rect)
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
        callback = function(rect)
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
        callback = function(rect)
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
        callback = function(rect)
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
        callback = function(rect)
            local scene = getCurrentScene()
            local name = "ArtPBubble"
            if not scene:getEntity(name) then
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
    q = {
        callback = function(rect)
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
        callback = function(rect)
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
        callback = function(rect)
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
        callback = function(rect)
            local scene = getCurrentScene()
            local name = "ArtVBubble"
            if not scene:getEntity(name) then
                scene:createEntity("TextBubble", name,
                    rect.x + rect.w / 2 - 30, rect.y, npcDialogWidth, 0,
                    playerLayer + 1,
                    {
                        text = "This is a very bland piece...",
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
    t = {
        callback = function(rect)
            -- engine.Scene.swap(exit2FromStart)
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
        callback = function(rect)
            -- engine.Scene.swap(exit1FromStart)
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

return allSettings
