local Class = require 'middleclass'
local Stateful = require 'stateful'
local Object = Class('object')
Object:include(Stateful)

local Vector = require('vector')

function Object:initialize(body)
    self.body = body
    self.body.object = self
    self.offset = Vector(0, 0)
    self.velocity = Vector(0, 0)
    self.tags = {}
end

function Object:update(dt)
end

function Object:draw()
    if not self.body then return end
    local x1, y1, x2, y2 = self.body:bbox()
    local x, y = self:getPosition():unpack()
    love.graphics.rectangle('line', x1, y1, x2-x1, y2-y1)
    love.graphics.setColor(0, 255, 0)
    self.body:draw()
    love.graphics.setColor(0, 255, 255)
    love.graphics.line(x, y-4, x, y+4)
    love.graphics.line(x-4, y, x+4, y)
    love.graphics.setColor(255, 255, 255)
end

function Object:getPosition()
    return Vector(self.body:center()) + self.offset
end

function Object:collide(dt, other, dx, dy)
    local tags = other.tags
    for _, tag in ipairs(tags) do
        if self.class.collisions[tag] then
            self.class.collisions[tag](self, dt, other, dx, dy)
        end
    end
end

Object.static.collisions = {}

return Object
