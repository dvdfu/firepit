local Class = require 'middleclass'
local Object = require 'objects/object'
local Enemy = Class('enemy', Object)

-- Enemy.collisions = {
--     block = {
--         type = 'slide',
--         func = function(self, col)
--             if col.normal.y ~= 0 then
--                 self.vy = 0
--                 if col.normal.y == -1 then
--                     self.ground = col.other
--                 end
--             end
--             if col.normal.x ~= 0 then
--                 self.vx = -self.vx
--             end
--         end
--     },
--     platform = {
--         type = 'cross',
--         func = function(self, col)
--             if col.normal.y == -1 and self.y+self.h-self.vy <= col.other.y then
--     			self.vy = 0
--                 self.y = col.other.y - self.h
--                 self.world:update(self, self.x, self.y)
--     			self.ground = col.other
--     		end
--         end
--     },
--     lava = {
--         type = 'cross',
--         func = function(self, col)
--             col.other:touch(self.x, false)
--             self:gotoState('Dead')
--             self.deadTimer = 60
--         end
--     }
-- }

function Enemy:initialize(body)
    Object.initialize(self, body)
    self.tags = { 'enemy' }

    self.health = 1
    self.ground = nil
    self.direction = 1
end

function Enemy:hit(other, damage)
    damage = damage or 0
    if damage < 0 then
        self:gotoState('Dead')
    elseif self.health > damage then
        self.health = self.health - damage
        self:pushState('Hit')
    else
        self:gotoState('Dead')
    end
end

function Enemy:isHarmful()
    return false
end

function Enemy:isDead()
    return false
end

return Enemy
