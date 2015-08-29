local Game = {}
local Camera = require 'camera'
local Bump = require 'bump'
local Solid = require 'objects/solid'
local Player = require 'objects/player'
local Enemy = require 'objects/enemy'
local Item = require 'objects/item'
local Lava = require 'objects/lava'

local world = {}
local sw = love.graphics.getWidth()/2
local sh = love.graphics.getHeight()/2

function Game:enter()
    world = Bump.newWorld(64)
    solids = {}
    addSolids()

    p = Player:new(world, 32, 0)
    l = Lava:new(world)
    cx, cy = sw/2, sh/2
    cs = 0
    cam = Camera(cx, cy)

    enemies = {}
    items = {}
end

timer = 0

function addSolids()
    love.graphics.setBackgroundColor(16, 24, 40)
    local function addSolid(x, y, w, h, platform)
        local s = Solid:new(world, x, y, w, h)
        if platform then
            s.name = 'platform'
        end
        table.insert(solids, s)
        return s
    end
    addSolid((sw-224)/2, sh-256, 112, 256, true).color = { --4
        r = 24,
        g = 36,
        b = 60
    }
    addSolid(sw/2, sh-192, 112, 192, true).color = { --3
        r = 40,
        g = 48,
        b = 80
    }
    addSolid(32, sh-128, 112, 128, true).color = { --2l
        r = 72,
        g = 72,
        b = 128
    }
    addSolid(sw-112-32, sh-128, 112, 128, true).color = { --2r
        r = 72,
        g = 72,
        b = 128
    }
    addSolid((sw-224)/2, sh-64, 224, 64) --1
    addSolid(-64, -96, 32+64, sh+96) --wl
    addSolid(sw-32, -96, 32+64, sh+96) --wr
end

function addEnemy(x, y)
    local e = Enemy:new(world, x, y)
    e.dropItem = addItem
    table.insert(enemies, e)
    return e
end

function addItem(x, y)
    local i = Item:new(world, x, y)
    table.insert(items, i)
    return i
end

function Game:update(dt)
    if timer < 2 then
        timer = timer + dt
    else
        timer = 0
        addEnemy(150, 0)
    end
    cx = cx + (sw/2 + (p.x+p.w/2 - sw/2)/4 - cx)/20
    cy = cy + (p.y+p.h/2 - cy)/20
    if cs > 0 then
        cam:lookAt(math.floor(cx+0.5) + math.random(-cs/2, cs/2), math.floor(cy+0.5) + math.random(-cs/2, cs/2))
        cs = cs-1
    else
        cam:lookAt(math.floor(cx+0.5), math.floor(cy+0.5))
    end
    -- TODO: add functionality to camera class

    p:update(dt)
    for key, enemy in pairs(enemies) do
        enemy:update(dt)
        if enemy:isDead() then
            enemies[key] = nil
        end
    end
    for key, item in pairs(items) do
        item:update(dt)
        if item:isDead() then
            items[key] = nil
        end
    end
    l:update(dt)
end

local function camDraw(func)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.translate(-sw/2*(scale-1), -sh/2*(scale-1))
    cam:draw(func)
    love.graphics.pop()
end

function Game:draw()
    camDraw(function()
        for _, solid in pairs(solids) do
            solid:draw()
        end
        l:draw()
        p:draw()
        for _, enemy in pairs(enemies) do
            enemy:draw()
        end
        for key, item in pairs(items) do
            item:draw()
        end
    end)
end

return Game