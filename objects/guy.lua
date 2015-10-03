local Class = require('middleclass')
local Object = require 'objects/object'
local Player = Class('player', Object)

local Vector = require('vector')

function Player:initialize(collider, x, y)
    self.size = Vector(8, 20)
    Object.initialize(self, collider:addRectangle(x, y, self.size:unpack()))
    self.pos = Vector(x, y)
    self.offset.y = self.size.y/2
end

function Player:update(dt)
    self.vel.y = self.vel.y + 0.2
    if Input:isDown('left') then
        self.vel.x = -2
    elseif Input:isDown('right') then
        self.vel.x = 2
    else
        self.vel.x = 0
    end
    if Input:pressed('up') then
        self.vel.y = -5
    end
    self.pos = self.pos + self.vel
    self:move()
end

Player.static.collisions = {
    solid = function(self, dt, other, x, y)
        self.pos = Vector(x, y)
    end,
    platform = function(self, dt, other, x, y)
        if y <= self.pos.y and self.vel.y >= 0 and self.pos.y - self.vel.y <= other.pos.y then
            self.vel.y = 0
            self.pos.y = y
        end
    end
}

return Player
