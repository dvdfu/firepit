local Class = require 'middleclass'
local Solid = Class('solid')

function Solid:initialize(world, x, y, w, h)
    self.name = 'solid'
    self.world = world
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    world:add(self, x, y, w, h)
end

function Solid:getBounds()
    return self.x, self.y, self.w, self.h
end

function Solid:draw()
    love.graphics.rectangle('line', self:getBounds())
end

return Solid
