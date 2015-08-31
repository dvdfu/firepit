local Class = require 'middleclass'
local Object = require 'objects/object'
local Solid = Class('solid', Object)

Solid.static.sprite = love.graphics.newImage('assets/terrain.png')

function Solid:initialize(world, x, y, w, h, color, platform)
    Object.initialize(self, world, x, y, w, h)
    self.color = color or { r = 104, g = 96, b = 160 }
    if platform then
        self.name = 'platform'
    end

    self.image = love.graphics.newCanvas(self.w, self.h)
    love.graphics.setCanvas(self.image)
    love.graphics.setColor(self.color.r, self.color.g, self.color.b)
    love.graphics.setStencil(function()
        love.graphics.rectangle('fill', 0, 0, self.w, self.h)
    end)
    for i = 0, self.w, 32 do
        for j = 0, self.h, 32 do
            love.graphics.draw(Solid.sprite, i, j)
        end
    end
    love.graphics.setStencil()

    love.graphics.setColor(200, 144, 200)
    love.graphics.setLineWidth(4)
    love.graphics.line(0, 2, self.w, 2)
    love.graphics.setColor(16, 24, 40)
    love.graphics.setLineWidth(1)
    love.graphics.line(0, 1, self.w, 1)
    if not platform then
        love.graphics.line(1, 0, 1, self.h)
        love.graphics.line(self.w, 0, self.w, self.h)
    end
    love.graphics.setColor(255, 255, 255)

    love.graphics.setCanvas()
end

function Solid:draw()
    love.graphics.draw(self.image, self.x, self.y)
end

return Solid
