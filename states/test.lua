local Game = {}
local GUI = require 'gui'
local Camera = require 'camera'
local HC = require 'modules/hardon-collider'
local Object = require 'objects/object'
local Solid = require 'objects/solid'
local Player = require 'objects/guy'
local Powerup = require 'powerup'
local Lava = require 'objects/lava'

local collider = {}
local sw = 480
local sh = 360

function collisionStart(dt, shapeA, shapeB, dx, dy)
    shapeA.object:collide(dt, shapeB.object, dx, dy)
    shapeB.object:collide(dt, shapeA.object, -dx, -dy)
end

function collisionEnd(dt, shapeA, shapeB) end

function Game:enter()
    collider = HC(64, collisionStart, collisionEnd)
    solids = {}
    addSolids()

    p = Player:new(collider, 32, 0)
    -- p:setPower(Powerup.names.jumpGlide)
    -- p:setPower(Powerup.names.coldFeet)
    -- p:setPower(Powerup.names.bubble)
    -- l = Lava:new(collider, sh)
    -- gui = GUI:new(p)
    cx, cy = sw/2, sh/2
    cs = 0
    cam = Camera(cx, cy)
end

timer = 0

function addSolids()
    love.graphics.setBackgroundColor(16, 24, 40)
    local function addSolid(x, y, w, h, color, platform)
        local s = Solid:new(collider, x, y, w, h, color, platform)
        table.insert(solids, s)
        collider:addToGroup("solids", s.body)
        return s
    end
    addSolid(sw/2-128, sh-256, 128, 256, { r = 40, g = 48, b = 80 }, true) -- 4
    addSolid(sw/2, sh-192, 128, 192, { r = 60, g = 64, b = 104 }, true) -- 3
    addSolid(0, sh-128, 128, 128, { r = 72, g = 72, b = 128 }, true) -- 2l
    addSolid(sw-128, sh-128, 128, 128, { r = 72, g = 72, b = 128 }, true) -- 2r
    addSolid(sw/2-128, sh-64, 256, 64) --1

    -- addSolid(-64, -96, 64, sh+96) --wl
    addSolid(sw, sh-256, 128, 256) --wr
end

function Game:update(dt)
    cx = cx + (sw/2 + (p:getPosition().x - sw/2)/4 - cx)/20
    cy = cy + (p:getPosition().y - cy)/20
    if cs > 0 then
        cam:lookAt(math.floor(cx+0.5) + math.random(-cs/2, cs/2), math.floor(cy+0.5) + math.random(-cs/2, cs/2))
        cs = cs-1
    else
        cam:lookAt(math.floor(cx+0.5), math.floor(cy+0.5))
    end
    -- TODO: add functionality to camera class

    p:update(dt)
    for _, solid in pairs(solids) do
        solid:update(dt)
    end
    collider:update(dt)
    -- l:update(dt)
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
        for _, solid in pairs(solids) do
            Object.draw(solid)
        end
        p:draw()
        Object.draw(p)
        -- l:draw()
    end)
    -- gui:draw()
end

return Game
