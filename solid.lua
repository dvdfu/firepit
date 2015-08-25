local Class = require 'middleclass'
local Object = require 'object'
local Solid = Class('solid', Object)

Solid.static.sprite = love.graphics.newImage('assets/terrain.png')

function Solid:initialize(world, x, y, w, h)
    Object.initialize(self, world, x, y, w, h)
    self.name = 'solid'
    self.color = {
        r = 104,
        g = 96,
        b = 160
    }
end

function Solid:draw()
    love.graphics.setColor(self.color.r, self.color.g, self.color.b)
    love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)
    love.graphics.setColor(200, 144, 200)
    love.graphics.line(self.x, self.y, self.x+self.w, self.y)
    love.graphics.setColor(255, 255, 255)
    -- love.graphics.draw(Solid.sprite, self.x, self.y, 0, self.w/16, self.h/16)
end

return Solid
