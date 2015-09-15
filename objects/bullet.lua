local Class = require 'middleclass'
local Object = require 'objects/object'
local Bullet = Class('bullet', Object)

Bullet.static.names = {
    bubble = 'Bubble'
}

Bullet.static.info = {
    ['Bubble'] = {
        name = 'Bubble',
        sprite = love.graphics.newImage('assets/images/bullets/bubble.png'),
        speed = 3,
        angle = 0,
        angleSpread = 15,
        ax = 0.98,
        ay = 0.99,
        time = 60
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
    Object.initialize(self, parent.world, parent.x, parent.y, 8, 8)
    table.insert(self.tags, Bullet.name)
    self.info = Bullet.info[name]
    self.angle = (parent.direction == 1 and 0 or 180) + math.random(-self.info.angleSpread, self.info.angleSpread)
    self.vx = parent.vx + self.info.speed * math.cos(self.angle/180*math.pi)
    self.vy = self.info.speed * math.sin(self.angle/180*math.pi)
    self.dead = false
    self.timer = 0
end

function Bullet:update(dt)
    self.vx = self.vx*self.info.ax
    self.vy = self.vy*self.info.ay
    self.x = self.x + self.vx
    self.y = self.y + self.vy
    self.timer = self.timer + 1
    self:collide()
end

function Bullet:draw()
    -- Object.drawDebug(self)
    love.graphics.draw(self.info.sprite, self.x, self.y)
end

function Bullet:isDead()
    return dead or self.timer > self.info.time
end

return Bullet
