local Class = require 'middleclass'
local Stateful = require 'stateful'
local Object = Class('object')
Object:include(Stateful)

Object.static.collisions = {}

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
    self.name = 'object'
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
        if self.class.collisions[other.name] then
            return self.class.collisions[other.name].type
        end
        return 'cross'
    end)
	for i = 1, len do
		col = cols[i]
        for k, v in pairs(self.class.collisions) do
            if col.other.name == k then
                v.func(self, col)
            end
        end
	end
end

function Object:draw()
    love.graphics.rectangle('line', self.x, self.y, self.w, self.h)
end

return Object
