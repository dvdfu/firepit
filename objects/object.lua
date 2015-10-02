local Class = require 'middleclass'
local Stateful = require 'stateful'
local Object = Class('object')
Object:include(Stateful)

function Object:initialize(collider, body)
    self.collider = collider
    self.body = body
    self.body.object = self
end

function Object:update(dt)
end

function Object:draw()
    local x1, y1, x2, y2 = self.body:bbox()
    love.graphics.rectangle('line', x1, y1, x2-x1, y2-y1)
    love.graphics.setColor(0, 255, 0)
    self.body:draw()
    love.graphics.setColor(0, 255, 255)
    love.graphics.line(self.x, self.y-4, self.x, self.y+4)
    love.graphics.line(self.x-4, self.y, self.x+4, self.y)
    love.graphics.setColor(255, 255, 255)
end

function Object:collide(dt, other, dx, dy)
    self.body:move(dx, dy)
end

return Object
