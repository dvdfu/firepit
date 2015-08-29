local Class = require 'middleclass'
local Object = require 'objects/object'
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
    love.graphics.setStencil(function()
        love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)
    end)
    for i = 0, self.w, 32 do
        for j = 0, self.h, 32 do
            love.graphics.draw(Solid.sprite, self.x + i, self.y + j)
        end
    end
    love.graphics.setStencil()
    love.graphics.setColor(200, 144, 200)
    love.graphics.line(self.x, self.y+2, self.x+self.w, self.y+2)
    love.graphics.setColor(255, 255, 255)
end

return Solid
