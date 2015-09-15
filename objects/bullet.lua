require 'AnAL'
local Class = require 'middleclass'
local Object = require 'objects/object'
local Bullet = Class('bullet', Object)

Bullet.static.names = {
    bubble = 'Bubble',
    star = 'Star'
}

Bullet.static.info = {
    ['Bubble'] = {
        name = 'Bubble',
        sprite = love.graphics.newImage('assets/images/bullets/bubble.png'),
        animated = false,
        width = 8,
        height = 8,
        speed = 1,
        speedMax = 3,
        angle = 0,
        angleSpread = 10,
        ax = 0.98,
        ay = 0.99,
        time = 30,
        timeMax = 80
    },
    ['Star'] = {
        name = 'Star',
        sprite = love.graphics.newImage('assets/images/bullets/star.png'),
        animated = true,
        width = 16,
        height = 16,
        speed = 6,
        speedMax = 6,
        angle = 0,
        angleSpread = 0,
        ax = 1,
        ay = 1,
        time = 80,
        timeMax = 80
    }
}

Bullet.collide_enemy = {
    type = 'cross',
    func = function(self, col)
        self.dead = true
        col.other:hit(self)
    end
}

function Bullet:initialize(name, parent)
    self.info = Bullet.info[name]
    Object.initialize(self, parent.world, parent.x, parent.y, self.info.width, self.info.height)
    table.insert(self.tags, Bullet.name)

    self.anim = nil
    if self.info.animated then
        self.anim = newAnimation(self.info.sprite, self.info.sprite:getHeight(), self.info.sprite:getHeight(), 1/8, 0)
    end
    self.angle = (parent.direction == 1 and 0 or 180) + self.info.angleSpread*2*math.random()-self.info.angleSpread
    local speed = self.info.speed + (self.info.speedMax-self.info.speed)*math.random()
    self.vx = parent.vx + speed * math.cos(self.angle/180*math.pi)
    self.vy = speed * math.sin(self.angle/180*math.pi)
    self.dead = false
    self.timer = self.info.time + (self.info.timeMax-self.info.time)*math.random()
end

function Bullet:update(dt)
    self.vx = self.vx*self.info.ax
    self.vy = self.vy*self.info.ay
    self.x = self.x + self.vx
    self.y = self.y + self.vy
    self.timer = self.timer - 1
    self:collide()
end

function Bullet:draw()
    if self.info.animated then
        self.anim:update(1/60)
        self.anim:draw(self.x, self.y)
    else
        local sprite = self.info.sprite
        love.graphics.draw(sprite, self.x+self.w/2, self.y+self.h/2, 0, 1, 1, sprite:getWidth()/2, sprite:getHeight()/2)
    end
end

function Bullet:isDead()
    return self.dead or self.timer <= 0
end

return Bullet
