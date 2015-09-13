local Class = require 'middleclass'
local Stateful = require 'stateful'
local Object = Class('object')
Object:include(Stateful)

--[[
Object:
    .name
    .world
    .x
    .y
    .vx
    .vy
    .w
    .h
    :new(world, x, y)
    :update(dt)
    :collide()
    :draw()
]]--

function Object:initialize(world, x, y, w, h)
    self.tags = {}
    table.insert(self.tags, Object.name)
    self.world = world
    self.x, self.y = x, y
    self.vx, self.vy = 0, 0
    self.w, self.h = w, h
    self.world:add(self, x, y, self.w, self.h)
end

function Object:update(dt)
    self:collide()
end

function Object:collide()
    local cols, len, col, other
    self.x, self.y, cols, len = self.world:move(self, self.x, self.y, function(item, other)
        for i = #other.tags, 1, -1 do
            if self['collide_'..other.tags[i]] then
                return self['collide_'..other.tags[i]].type
            end
        end
        return 'cross'
    end)
	for i = 1, len do
		col = cols[i]
        for j = #col.other.tags, 1, -1 do
            if self['collide_'..col.other.tags[j]] then
                self['collide_'..col.other.tags[j]].func(self, col)
                break
            end
        end
	end
end

function Object:drawDebug()
    love.graphics.rectangle('line', self.x, self.y, self.w, self.h)
    love.graphics.setColor(0, 255, 0)
    love.graphics.line(self.x, self.y-4, self.x, self.y+4)
    love.graphics.line(self.x-4, self.y, self.x+4, self.y)
    love.graphics.setColor(255, 255, 255)
end

return Object
