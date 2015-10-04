require 'AnAL'
local Class = require 'middleclass'
local Object = require 'objects/object'
local Bullet = Class('bullet', Object)
local Vector = require('vector')

Bullet.static.names = {
    bubble = 'Bubble',
    star = 'Star'
}

Bullet.static.info = {
    ['Bubble'] = {
        name = 'Bubble',
        sprite = love.graphics.newImage('assets/images/bullets/bubble.png'),
        spritePop = love.graphics.newImage('assets/images/bullets/bubble_pop.png'),
        animated = true,
        makeBody = function(collider, x, y)
            return collider:addCircle(x, y, 4)
        end,
        offset = Vector(0, -16),
        damage = 1,
        speed = 1,
        speedMax = 3,
        angle = 0,
        angleSpread = 10,
        damp = Vector(0.98, 0.99),
        time = 30,
        timeMax = 80
    },
    ['Star'] = {
        name = 'Star',
        sprite = love.graphics.newImage('assets/images/bullets/star.png'),
        animated = true,
        makeBody = function(collider, x, y)
            return collider:addCircle(x, y, 10)
        end,
        offset = Vector(0, -16),
        damage = 8,
        speed = 6,
        speedMax = 6,
        angle = 0,
        angleSpread = 0,
        damp = Vector(1, 1),
        time = 80,
        timeMax = 80
    }
}

function Bullet:collide_enemy(other, x, y)
    self:gotoState('Dead')
    other:hit(self, self.info.damage)
end

function Bullet:collide_solid(other, x, y)
    self:gotoState('Dead')
end

Bullet.Dead = Bullet:addState('Dead')

function Bullet:initialize(name, parent)
    self.info = Bullet.info[name]
    self.pos = parent.pos + self.info.offset
    Object.initialize(self, parent.collider, self.info.makeBody(parent.collider, self.pos:unpack()))
    self:addTag('bullet')

    self.anim = nil
    if self.info.animated then
        self.anim = newAnimation(self.info.sprite, self.info.sprite:getHeight(), self.info.sprite:getHeight(), 1/8, 0)
    end
    self.angle = (parent.direction == 1 and 0 or 180) + self.info.angleSpread*2*math.random()-self.info.angleSpread
    local speed = self.info.speed + (self.info.speedMax-self.info.speed)*math.random()
    self.vel.x = parent.vel.x + speed * math.cos(self.angle/180*math.pi)
    self.vel.y = speed * math.sin(self.angle/180*math.pi)
    self.timer = self.info.time + (self.info.timeMax-self.info.time)*math.random()
    self.deadTimer = 0
end

function Bullet:update(dt)
    self.vel = self.vel:permul(self.info.damp)
    self.pos = self.pos + self.vel
    if self.timer > 0 then
        self.timer = self.timer - 1
    else
        self:gotoState('Dead')
    end
    self:move()
end

function Bullet:draw()
    if self.info.animated then
        self.anim:update(1/60)
        self.anim:draw(self.pos.x, self.pos.y, 0, 1, 1, self.anim:getWidth()/2, self.anim:getHeight()/2)
    else
        local sprite = self.info.sprite
        love.graphics.draw(sprite, self.pos.x, self.pos.y, 0, 1, 1, sprite:getWidth()/2, sprite:getHeight()/2)
    end
end

function Bullet:isDead()
    return false
end

--[[======== DEAD STATE ========]]

function Bullet.Dead:enteredState()
    self.collider:setGhost(self.body)
    if self.info.name == Bullet.names.bubble then
        self.deadTimer = 5
        local sprite = Bullet.info.Bubble.spritePop
        self.anim = newAnimation(sprite, sprite:getHeight(), sprite:getHeight(), 1/60, 0)
        self.anim:setMode('once')
    end
end

function Bullet.Dead:update(dt)
    self.deadTimer = self.deadTimer - 1
end

function Bullet.Dead:isDead()
    if self.info.name == Bullet.names.bubble then
        return self.deadTimer == 0
    end
    return true
end

return Bullet
