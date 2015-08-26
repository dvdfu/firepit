local Game = {}

local Camera = require 'hump.camera'
local Solid = require 'solid'
local Player = require 'player'
local Enemy = require 'enemy'
local Lava = require 'lava'
local Bump = require 'bump'

local world = Bump.newWorld(64)
local sw = love.graphics.getWidth()/2
local sh = love.graphics.getHeight()/2

function Game:enter()
    level1 = Solid:new(world, (sw-224)/2, sh-64, 224, 64)
    level2_l = Solid:new(world, 32, sh-128, 112, 128)
    level2_r = Solid:new(world, sw-112-32, sh-128, 112, 128)
    level3 = Solid:new(world, sw/2, sh-192, 112, 192)
    level2_l.name = 'platform'
    level2_r.name = 'platform'
    level3.name = 'platform'
    level3.color = {
        r = 40,
        g = 48,
        b = 80
    }
    level2_l.color = {
        r = 72,
        g = 72,
        b = 128
    }
    level2_r.color = {
        r = 72,
        g = 72,
        b = 128
    }
    wall_l = Solid:new(world, -64, -96, 32+64, sh+96)
    wall_r = Solid:new(world, sw-32, -96, 32+64, sh+96)
    p = Player:new(world, 32, 0)
    l = Lava:new(world)
    cx, cy = sw/2, 0
    cam = Camera(cx, cy)
    e1 = Enemy:new(world, sw-64, 0)
    e2 = Enemy:new(world, sw-64, -32)
end

function Game:update(dt)
    cx = cx + (sw/2 + (p.x+p.w/2 - sw/2)/4 - cx)/20
    cy = cy + (p.y+p.h/2 - cy)/20
    cam:lookAt(math.floor(cx+0.5), math.floor(cy+0.5))
    -- TODO: add functionality to camera class

    p:update(dt)
    e1:update(dt)
    e2:update(dt)
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
        level3:draw()
        level2_l:draw()
        level2_r:draw()
        level1:draw()
        wall_l:draw()
        wall_r:draw()
        p:draw()
        e1:draw()
        e2:draw()
        l:draw()
    end)
end

return Game
