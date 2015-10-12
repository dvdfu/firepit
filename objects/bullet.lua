require 'AnAL'
local Class = require 'middleclass'
local Object = require 'objects/object'
local Bullet = Class('bullet', Object)
local Vector = require('vector')
local Particles = require('objects/particles')

Bullet.sprBubble = love.graphics.newImage('assets/images/bullets/bubble.png')
Bullet.sprBubblePop = love.graphics.newImage('assets/images/bullets/bubble_pop.png')
Bullet.sprEnergy = love.graphics.newImage('assets/images/bullets/energy.png')
Bullet.sprStarSmall = love.graphics.newImage('assets/images/bullets/star.png')
Bullet.sprFlower = love.graphics.newImage('assets/images/bullets/flower.png')
Bullet.sprExplosion = love.graphics.newImage('assets/images/bullets/explosion.png')

Bullet.static.names = {
    bubble = 'Bubble',
    star = 'Star',
    miniStar = 'MiniStar',
    flower = 'FlowerBomb',
    explosion = 'Explosion'
}

Bullet.static.info = {
    ['Bubble'] = {
        name = 'Bubble',
        sprite = Bullet.sprBubble,
        spritePop = Bullet.sprBubblePop,
        animated = true,
        makeBody = function(collider, x, y)
            return collider:circle(x, y, 4)
        end,
        offset = Vector(0, -16),
        damage = 1,
        hitstun = 2,
        speed = {3, 5},
        angle = {0, 10},
        damp = Vector(0.98, 0.99),
        time = {20, 60},
        symmetrical = true
    },
    ['Star'] = {
        name = 'Star',
        sprite = Bullet.sprEnergy,
        makeBody = function(collider, x, y)
            return collider:circle(x, y, 10)
        end,
        offset = Vector(0, -16),
        damage = 4,
        hitstun = 4,
        speed = 9,
        time = 80,
        angular = true
    },
    ['MiniStar'] = {
        name = 'MiniStar',
        sprite = Bullet.sprStarSmall,
        animated = true,
        makeBody = function(collider, x, y)
            return collider:circle(x, y, 4)
        end,
        damage = 1,
        speed = {1, 9},
        damp = Vector(0.9, 0.9),
        time = {20, 40}
    },
    ['FlowerBomb'] = {
        name = 'FlowerBomb',
        sprite = Bullet.sprFlower,
        makeBody = function(collider, x, y)
            return collider:rectangle(x, y, 16, 16)
        end,
        acc = Vector(0, 0.3),
        time = 30*60
    },
    ['Explosion'] = {
        name = 'Explosion',
        sprite = Bullet.sprExplosion,
        makeBody = function(collider, x, y)
            return collider:circle(x, y, 1)
        end,
        damage = 10,
        hitstun = 12,
        time = 12
    }
}

Bullet.Bubble = Bullet:addState('Bubble')
Bullet.Star = Bullet:addState('Star')
Bullet.MiniStar = Bullet:addState('MiniStar')
Bullet.FlowerBomb = Bullet:addState('FlowerBomb')
Bullet.Explosion = Bullet:addState('Explosion')

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
    self.hitstun = info.hitstun or 4
    self.spawnOffset = info.offset or Vector(0, 0)
    self.acc = info.acc or Vector(0, 0)
    self.damp = info.damp or Vector(1, 1)
    self.symmetrical = info.symmetrical or false
    self.angular = info.angular or false

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
    if self.symmetrical and parent and parent.direction.x == -1 then
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
    self.vel.y = speed*math.sin(angle/180*math.pi)

    self:gotoState(self.name)
    self.dead = false
end

function Bullet:update(dt)
    self.vel = self.vel:permul(self.damp)
    self.vel = self.vel + self.acc
    self.direction.x = self.vel.x < 0 and -1 or 1
    if self.timer > 0 then
        self.timer = self.timer - 1
    elseif not self.dead then
        self:die()
    end
    Object.update(self)
end

function Bullet:collide_enemy(other, x, y)
    if other:hit(self, self.damage, self.hitstun) then
        self:die()
    end
end

function Bullet:collide_solid(other, x, y)
    self:die()
end

function Bullet:collide_platform(other, x, y)
    if y <= self.pos.y and self.vel.y > 0 and self.pos.y - self.vel.y <= other.pos.y then
        self:die()
    end
end

function Bullet:draw()
    local xScale = self.symmetrical and self.direction.x or 1
    local angle = self.angular and self:getAngle() or 0
    if self.animated then
        self.sprite:update(1/60)
        self.sprite:draw(self.pos.x, self.pos.y, angle, xScale, 1, self.sprite:getWidth()/2, self.sprite:getHeight()/2)
    else
        love.graphics.draw(self.sprite, self.pos.x, self.pos.y, angle, xScale, 1, self.sprite:getWidth()/2, self.sprite:getHeight()/2)
    end
end

function Bullet:create(type, override)
    local b = Bullet:new(type, self, self.pool, override)
    table.insert(self.pool, b)
end

function Bullet:getAngle()
    return self.vel:clone():angleTo(Vector(1, 0))
end

function Bullet:getAngleDeg()
    return self:getAngle()*180/math.pi
end

function Bullet:die()
    if self.dead then return end
    self.activeBody = false
    self.dead = true
    self.timer = 0
end

function Bullet:isDead()
    return self.dead or self.timer == 0
end

--[[======== BUBBLE STATE ========]]

function Bullet.Bubble:die()
    if self.dead then return end
    self.activeBody = false
    self.dead = true
    self.timer = 5
    self.vel = Vector(0, 0)
    local sprite = Bullet.info.Bubble.spritePop
    self.sprite = newAnimation(sprite, sprite:getHeight(), sprite:getHeight(), 1/60, 0)
    self.sprite:setMode('once')
end

function Bullet.Bubble:isDead()
    return self.dead and self.timer == 0
end

--[[======== STAR STATE ========]]

function Bullet.Star:enteredState()
    self.vel = self.parent:getAimDirection(true) * Bullet.info[self.name].speed
end

function Bullet.Star:die()
    if self.dead then return end
    cs = 10
    for i = 1, 16 do
        self:create(Bullet.names.miniStar, {
            angle = i*360/16 --self:getAngleDeg()+ (i-8)*3
        })
    end
    Bullet.die(self)
end

--[[======== MINISTAR STATE ========]]

function Bullet.MiniStar:collide_solid(other, x, y) end

function Bullet.MiniStar:collide_platform(other, x, y) end

--[[======== FLOWERBOMB STATE ========]]

function Bullet.FlowerBomb:collide_solid(other, x, y)
    self.pos = Vector(x, y)
end

function Bullet.FlowerBomb:collide_platform(other, x, y)
    if y <= self.pos.y and self.vel.y > 0 and self.pos.y - self.vel.y <= other.pos.y then
        self.pos.y = y
        self.vel.y = 0
    end
end

function Bullet.FlowerBomb:collide_lava(other, x, y)
    self:die()
end

function Bullet.FlowerBomb:collide_bullet(other, x, y)
    self:die()
end

function Bullet.FlowerBomb:die()
    if self.dead then return end
    self:create(Bullet.names.explosion)
    Bullet.die(self)
end

--[[======== EXPLOSION STATE ========]]

function Bullet.Explosion:enteredState()
    cs = 20
    self.smoke = Particles.newSmoke()
    self.smoke:setPosition(self.pos:unpack())
    self.smoke:emit(10)
end

function Bullet.Explosion:collide_enemy(other, x, y)
    other:hit(self, self.damage, self.hitstun)
end

function Bullet.Explosion:collide_solid(other, x, y) end

function Bullet.Explosion:collide_platform(other, x, y) end

function Bullet.Explosion:draw()
    local scale = 64*(12-self.timer)/12
    local x, y, r = self.body:outcircle()
    if scale > 0 then
        self.body:scale(scale/r)
    end

    self.smoke:update(1/60)
    love.graphics.draw(self.smoke)
    if self.dead then return end
    if self.timer % 4 == 0 then
        love.graphics.setColor(0, 0, 0)
    end
    if self.timer % 4 < 3 then
        love.graphics.circle('fill', self.pos.x, self.pos.y, r, r)
    end
    love.graphics.setColor(255, 255, 255)
end

function Bullet.Explosion:die()
    if self.dead then return end
    self.activeBody = false
    self.timer = 3*60
    self.dead = true
end

function Bullet.Explosion:isDead()
    return self.dead and self.timer == 0
end

return Bullet
