local Class = require('middleclass')
local Object = require 'objects/object'
local Player = Class('player', Object)

local Vector = require('vector')

function Player:initialize(collider, x, y)
    self.size = Vector(8, 20)
    Object.initialize(self, collider:addRectangle(x, y, self.size:unpack()))
    self.pos = Vector(x, y)
    self.offset.y = self.size.y/2

    self.grounded = false
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
    if self.grounded and Input:pressed('up') then
        self.vel.y = -5
    end
    self.grounded = false
    Object.update(self, dt)
end

Player.static.collisions = {
    solid = function(self, dt, other, x, y)
        self.pos = Vector(x, y)
    end,
    platform = function(self, dt, other, x, y)
        if y <= self.pos.y and self.vel.y >= 0 and self.pos.y - self.vel.y <= other.pos.y then
            self.vel.y = 0
            self.pos.y = y
            self.grounded = true
        end
    end,
    lava = function(self, dt, other, x, y)
        self.pos.y = y
        self.vel.y = -7
    end
}

return Player
