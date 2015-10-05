require 'AnAL'
local Class = require 'middleclass'
local Object = require 'objects/object'
local Bullet = Class('bullet', Object)
local Vector = require('vector')

Bullet.sprBubble = love.graphics.newImage('assets/images/bullets/bubble.png')
Bullet.sprBubblePop = love.graphics.newImage('assets/images/bullets/bubble_pop.png')
Bullet.sprStar = love.graphics.newImage('assets/images/bullets/star.png')
Bullet.sprStarSmall = love.graphics.newImage('assets/images/enemies/star.png')

Bullet.static.names = {
    bubble = 'Bubble',
    star = 'Star',
    miniStar = 'MiniStar'
}

Bullet.static.info = {
    ['Bubble'] = {
        name = 'Bubble',
        sprite = Bullet.sprBubble,
        spritePop = Bullet.sprBubblePop,
        animated = true,
        makeBody = function(collider, x, y)
            return collider:addCircle(x, y, 4)
        end,
        offset = Vector(0, -16),
        damage = 1,
        speed = {3, 5},
        angle = {0, 10},
        damp = Vector(0.98, 0.99),
        time = {20, 60}
    },
    ['Star'] = {
        name = 'Star',
        sprite = Bullet.sprStar,
        animated = true,
        makeBody = function(collider, x, y)
            return collider:addCircle(x, y, 10)
        end,
        offset = Vector(0, -16),
        damage = 4,
        speed = 6,
        time = 80
    },
    ['MiniStar'] = {
        name = 'MiniStar',
        sprite = Bullet.sprStarSmall,
        animated = true,
        makeBody = function(collider, x, y)
            return collider:addCircle(x, y, 4)
        end,
        offset = Vector(0, 0),
        damage = 2,
        speed = {1, 4},
        angle = {0, 180},
        damp = Vector(0.95, 0.95),
        time = {5, 40}
    }
}

Bullet.Bubble = Bullet:addState('Bubble')
Bullet.Star = Bullet:addState('Star')
Bullet.MiniStar = Bullet:addState('MiniStar')

function Bullet:initialize(name, parent, pool, override)
    self.name = name
    self.parent = parent
    self.pool = pool
    self.collider = parent.collider
    local info = Bullet.info[name]

    if override then
        for k, v in pairs(override) do
            info[k] = v
        end
    end

    self.sprite = nil
    self.animated = info.animated or false
    if self.animated then
        self.sprite = newAnimation(info.sprite, info.sprite:getHeight(), info.sprite:getHeight(), 1/8, 0)
    else
        self.sprite = info.sprite
    end

    self.damage = info.damage or 0
    self.spawnOffset = info.offset or Vector(0, 0)
    self.acc = info.acc or Vector(0, 0)
    self.damp = info.damp or Vector(1, 1)

    local speed = 0
    if info.speed then
        if type(info.speed) == 'table' then
            speed = info.speed[1] + (info.speed[2] - info.speed[1]) * math.random()
        else
            speed = info.speed
        end
    end

    local angle = 0
    if info.angle then
        if type(info.angle) == 'table' then
            angle = info.angle[1] - info.angle[2] + 2 * info.angle[2] * math.random()
        else
            angle = info.angle
        end
    end
    if parent and parent.direction.x == -1 then
        angle = 180 - angle
    end

    self.timer = 0
    if info.time then
        if type(info.time) == 'table' then
            self.timer = info.time[1] + (info.time[2] - info.time[1]) * math.random()
        else
            self.timer = info.time
        end
    end

    self.pos = parent.pos + self.spawnOffset
    self.body = info.makeBody(self.collider, self.pos:unpack())
    Object.initialize(self, self.collider, self.body)
    self:addTag('bullet')

    self.vel.x = speed*math.cos(angle/180*math.pi)-- + parent.vel.x
    self.vel.y = -speed*math.sin(angle/180*math.pi)

    self:gotoState(self.name)
    self.dead = false
end

function Bullet:update(dt)
    self.vel = self.vel:permul(self.damp)
    self.vel = self.vel + self.acc
    self.pos = self.pos + self.vel
    self.direction.x = self.vel.x < 0 and -1 or 1
    if self.timer > 0 then
        self.timer = self.timer - 1
    elseif not self.dead then
        self:die()
    end
    self:move()
end

function Bullet:collide_enemy(other, x, y)
    self:die()
    other:hit(self, self.damage)
end

function Bullet:collide_solid(other, x, y)
    self:die()
end

function Bullet:draw()
    if self.animated then
        self.sprite:update(1/60)
        self.sprite:draw(self.pos.x, self.pos.y, 0, 1, 1, self.sprite:getWidth()/2, self.sprite:getHeight()/2)
    else
        love.graphics.draw(self.sprite, self.pos.x, self.pos.y, 0, 1, 1, self.sprite:getWidth()/2, self.sprite:getHeight()/2)
    end
end

function Bullet:create(type, override)
    local b = Bullet:new(type, self, self.pool, override)
    table.insert(self.pool, b)
end

function Bullet:die()
    self.dead = true
    self.timer = 0
end

function Bullet:isDead()
    return self.timer == 0
end

--[[======== BUBBLE STATE ========]]

function Bullet.Bubble:die()
    self.dead = true
    self.timer = 5
    local sprite = Bullet.info.Bubble.spritePop
    self.sprite = newAnimation(sprite, sprite:getHeight(), sprite:getHeight(), 1/60, 0)
    self.sprite:setMode('once')
end

function Bullet.Bubble:isDead()
    return self.dead and self.timer == 0
end

--[[======== STAR STATE ========]]

function Bullet.Star:die()
    for i = 1, 24 do
        self:create(Bullet.names.miniStar, {
            angle = 360*i/24
        })
    end
    Bullet.die(self)
end

--[[======== MINISTAR STATE ========]]

function Bullet.MiniStar:collide_solid(other, x, y) end

return Bullet
