local Class = require 'middleclass'
local Object = require 'objects/object'
local Enemy = Class('enemy', Object)

Enemy.collisions = {
    block = {
        type = 'slide',
        func = function(self, col)
            if col.normal.y ~= 0 then
                self.vy = 0
                if col.normal.y == -1 then
                    self.ground = col.other
                end
            end
            if col.normal.x ~= 0 then
                self.vx = -self.vx
            end
        end
    },
    platform = {
        type = 'cross',
        func = function(self, col)
            if col.normal.y == -1 and self.y+self.h-self.vy <= col.other.y then
    			self.vy = 0
                self.y = col.other.y - self.h
                self.world:update(self, self.x, self.y)
    			self.ground = col.other
    		end
        end
    },
    lava = {
        type = 'cross',
        func = function(self, col)
            col.other:touch(self.x, false)
            self:gotoState('Dead')
            self.deadTimer = 60
        end
    }
}

function Enemy:initialize(world, x, y, w, h)
    Object.initialize(self, world, x, y, w, h)
    table.insert(self.tags, Enemy.name)
    self.vx, self.vy = 0, 0
    self.vx = math.random() > 0.5 and 1 or -1
    self.health = 1
    self.ground = nil

    self.deadTimer = 0
    self.direction = 1
end

function Enemy:update(dt)
    self.x = self.x + self.vx
    self.y = self.y + self.vy
    self:collide()
end

function Enemy:hit(other, damage)
    -- self.vx = other.vx/2
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
