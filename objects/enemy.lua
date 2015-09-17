local Class = require 'middleclass'
local Object = require 'objects/object'
local Enemy = Class('enemy', Object)

Enemy.collide_block = {
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
}

Enemy.collide_platform = {
    type = 'cross',
    func = function(self, col)
        if col.normal.y == -1 and self.y+self.h-self.vy <= col.other.y then
			self.vy = 0
            self.y = col.other.y - self.h
            self.world:update(self, self.x, self.y)
			self.ground = col.other
		end
    end
}

Enemy.collide_lava = {
    type = 'cross',
    func = function(self, col)
        col.other:touch(self.x, false)
        self:gotoState('Dead')
        self.deadTimer = 60
    end
}

function Enemy:initialize(world, x, y, w, h)
    Object.initialize(self, world, x, y, w, h)
    table.insert(self.tags, Enemy.name)
    self.vx, self.vy = 0, 0
    self.vx = math.random() > 0.5 and 1 or -1
    self.ground = nil

    self.deadTimer = 0
    self.direction = 1
end

function Enemy:update(dt)
    self.x = self.x + self.vx
    self.y = self.y + self.vy
    self:collide()
end

function Enemy:hit(enemy)
    self.vx = enemy.vx/2
    self:gotoState('Dead')
end

function Enemy:isHarmful()
    return false
end

function Enemy:isDead()
    return false
end

return Enemy
