local Game = {}
local GUI = require 'gui'
local Camera = require 'camera'
local HC = require 'modules/HC'
local Object = require 'objects/object'
local Solid = require 'objects/solid'
local Player = require 'objects/player'
local EnemyRock = require 'objects/enemy-rock'
local EnemyFloat = require 'objects/enemy-float'
local Powerup = require 'powerup'
local Lava = require 'objects/lava'
Sound = require('sound')

local collider = {}
local sw = 480
local sh = 360

function Game:enter()
    collider = HC(128)
    solids = {}
    bullets = {}
    addSolids()

    p = Player:new(collider, 32, 0)
    p.bullets = bullets
    -- p:setPower(Powerup.names.chuckie)
    -- p:setPower(Powerup.names.coldFeet)
    p:setPower(Powerup.names.flower)
    l = Lava:new(collider, sh)

    enemies = {}
    timer = 0

    cx, cy = sw/2, sh/2
    cs = 0
    cam = Camera(cx, cy)
    gui = GUI:new(cam, p, enemies)
end

function addSolids()
    love.graphics.setBackgroundColor(16, 24, 40)
    local function addSolid(x, y, w, h, color, solid)
        local s = Solid:new(collider, x, y, w, h, color, solid)
        table.insert(solids, s)
        return s
    end
    addSolid(sw/2-128, sh-256, 128, 256, { r = 40, g = 48, b = 80 }, false) -- 4
    addSolid(sw/2, sh-192, 128, 192, { r = 60, g = 64, b = 104 }, false) -- 3
    addSolid(0, sh-128, 128, 128, { r = 72, g = 72, b = 128 }, false) -- 2l
    addSolid(sw-128, sh-128, 128, 128, { r = 72, g = 72, b = 128 }, false) -- 2r
    addSolid(sw/2-128, sh-64, 256, 64, nil, true) --1

    addSolid(-128, sh-256, 128, 256, nil, true) --wl
    addSolid(sw, sh-256, 128, 256, nil, true) --wr
end

function addEnemy(x, y)
    local e = {}
    if math.random() > 0.5 then
        e = EnemyRock:new(collider, x, y)
    else
        e = EnemyFloat:new(collider, x, y)
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


    if Input:pressed('q') then p:setPower(Powerup.names.bubble) end
    if Input:pressed('w') then p:setPower(Powerup.names.star) end
    if Input:pressed('e') then p:setPower(Powerup.names.flower) end

    p:update(dt)
    for key, enemy in pairs(enemies) do
        enemy:update(dt)
        if enemy:isDead() then
            enemies[key] = nil
        end
    end
    for key, bullet in pairs(bullets) do
        bullet:update(dt)
        if bullet:isDead() then
            bullets[key] = nil
        end
    end
    for _, solid in pairs(solids) do
        solid:update(dt)
    end

    l:update(dt)

    -- object removal
    for key, enemy in pairs(enemies) do
        if enemy:isDead() then
            collider:remove(enemy.body)
            enemies[key] = nil
        end
    end
    for key, bullet in pairs(bullets) do
        if bullet:isDead() then
            collider:remove(bullet.body)
            bullets[key] = nil
        end
    end
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
        for _, bullet in pairs(bullets) do
            bullet:draw()
        end
        l:draw()
    end)
    gui:draw()
end

return Game
