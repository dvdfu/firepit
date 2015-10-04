local Game = {}
local GUI = require 'gui'
local Camera = require 'camera'
local HC = require 'modules/hardon-collider'
local Object = require 'objects/object'
local Solid = require 'objects/solid'
local Player = require 'objects/guy'
local EnemyRock = require 'objects/enemy-rock'
local EnemyFloat = require 'objects/enemy-float'
-- local Powerup = require 'powerup'
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
    l = Lava:new(collider, sh)
    gui = GUI:new(p)

    enemies = {}
    timer = 0

    cx, cy = sw/2, sh/2
    cs = 0
    cam = Camera(cx, cy)
end

function addSolids()
    love.graphics.setBackgroundColor(16, 24, 40)
    local function addSolid(x, y, w, h, color, platform)
        local s = Solid:new(collider, x, y, w, h, color, platform)
        table.insert(solids, s)
        -- collider:addToGroup('solids', s.body)
        return s
    end
    addSolid(sw/2-128, sh-256, 128, 256, { r = 40, g = 48, b = 80 }, true) -- 4
    addSolid(sw/2, sh-192, 128, 192, { r = 60, g = 64, b = 104 }, true) -- 3
    addSolid(0, sh-128, 128, 128, { r = 72, g = 72, b = 128 }, true) -- 2l
    addSolid(sw-128, sh-128, 128, 128, { r = 72, g = 72, b = 128 }, true) -- 2r
    addSolid(sw/2-128, sh-64, 256, 64) --1

    addSolid(-128, sh-256, 128, 256) --wl
    addSolid(sw, sh-256, 128, 256) --wr
end

function addEnemy(x, y)
    local e = {}
    if math.random() > 0 then
        e = EnemyRock:new(collider, x, y)
    else
        -- e = EnemyFloat:new(world, x, y)
    end
    table.insert(enemies, e)
    return e
end

function Game:update(dt)
    if timer > 0 then
        timer = timer - 1
    else
        timer = 2*60
        addEnemy(128, 0)
    end

    cx = cx + (sw/2 + (p.pos.x - sw/2)/4 - cx)/20
    cy = cy + (p.pos.y - cy)/20
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
            collider:remove(enemy.body)
            enemies[key] = nil
        end
    end
    for _, solid in pairs(solids) do
        solid:update(dt)
    end
    collider:update(dt)
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
        p:draw()
        for _, enemy in pairs(enemies) do
            enemy:draw()
        end
        l:draw()
    end)
    gui:draw()
end

return Game
