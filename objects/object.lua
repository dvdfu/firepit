local Class = require 'middleclass'
local Stateful = require 'stateful'
local Object = Class('object')
Object:include(Stateful)

local Vector = require('vector')

function Object:initialize(collider, body)
    self.collider = collider
    self.body = body
    self.body.object = self --body reference to self
    self.activeBody = self.activeBody or true --should update self in collider
    self.immobile = self.immobile or false --should not move
    self.offset = self.offset or Vector(0, 0) --origin relative to body center
    self.pos = self.pos or Vector(0, 0)
    self.vel = self.vel or Vector(0, 0)
    self.size = self.size or Vector(0, 0)
    self.direction = self.direction or Vector(1, 1)
    self.tags = self.tags or {} --collision categories
end

function Object:update() --invoke this after velocity is set
    if not self.immobile then
        self.pos = self.pos + self.vel
        self:move()
    end
    self:collide()
end

function Object:move() --update body to position
    local dp = self.pos - self.offset
    self.body:moveTo(dp:unpack())
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

function Object:collide()
    if not self.activeBody then return end
    for other, d in pairs(self.collider:collisions(self.body)) do
        other = other.object
        d = d + self.pos
        if other.activeBody then
            for _, tag in ipairs(other.tags) do
                if self['collide_'..tag] then
                    self['collide_'..tag](self, other, d.x, d.y)
                end
            end
        end
    end
    self:move()
end

function Object:addTag(tag)
    table.insert(self.tags, tag)
end

-- Object.collisions = {} --collision logic by category

return Object
