local Class = require('middleclass')
local Object = require 'objects/object'
local Player = Class('player', Object)

local Vector = require('vector')

function Player:initialize(collider, x, y)
    self.w, self.h = 8, 20
    Object.initialize(self, collider:addRectangle(x, y, self.w, self.h))
    self.x, self.y = x, y
    self.offset.y = self.h/2
end

function Player:update(dt)
    self.velocity.y = self.velocity.y + 0.2
    if Input:isDown('left') then
        self.velocity.x = -2
    elseif Input:isDown('right') then
        self.velocity.x = 2
    else
        self.velocity.x = 0
    end
    if Input:pressed('up') then
        self.velocity.y = -5
    end
    self.body:move(self.velocity:unpack())
end

function Player:draw()
end

Player.static.collisions = {
    solid = function(self, dt, other, dx, dy)
        if dy < 0 and self.velocity.y > 0 then
            self.velocity.y = 0
            self.body:move(dx, dy)
        end
    end,
    platform = function(self, dt, other, dx, dy)
        self.body:move(dx, dy)
    end
}

return Player
