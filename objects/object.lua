local Class = require 'middleclass'
local Stateful = require 'stateful'
local Object = Class('object')
Object:include(Stateful)

local Vector = require('vector')

function Object:initialize(body)
    self.body = body
    self.body.object = self
    self.offset = Vector(0, 0)
    self.pos = Vector(0, 0)
    self.vel = Vector(0, 0)
    self.tags = {}
end

function Object:update(dt)
    self:move()
end

function Object:draw()
    if not self.body then return end
    local x1, y1, x2, y2 = self.body:bbox()
    love.graphics.rectangle('line', x1, y1, x2-x1, y2-y1)
    love.graphics.setColor(0, 255, 0)
    self.body:draw()
    love.graphics.setColor(0, 255, 255)
    love.graphics.line(self.pos.x, self.pos.y-4, self.pos.x, self.pos.y+4)
    love.graphics.line(self.pos.x-4, self.pos.y, self.pos.x+4, self.pos.y)
    love.graphics.setColor(255, 255, 255)
end

function Object:move()
    local dp = self.pos - self.offset
    self.body:moveTo(dp:unpack())
end

function Object:collide(dt, other, dx, dy)
    local tags = other.tags
    for _, tag in ipairs(tags) do
        if self.class.collisions[tag] then
            self.class.collisions[tag](self, dt, other, self.pos.x + dx or 0, self.pos.y + dy or 0)
        end
    end
    self:move()
end

Object.static.collisions = {}

return Object
