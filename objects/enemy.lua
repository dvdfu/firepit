local Class = require 'middleclass'
local Object = require 'objects/object'
local Enemy = Class('enemy', Object)

Enemy.collide_solid = {
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

function Enemy:initialize(world, x, y)
    Object.initialize(self, world, x, y, 16, 16)
    self.name = 'enemy'
    self.vx, self.vy = 0, 0
    self.ground = nil

    self.vFall = 7
    self.aFall = 0.4
    self.vMove = 0.4

    self.deadTimer = 0
    self.direction = math.random() > 0.5 and -1 or 1
end

function Enemy:update(dt)
    self.vy = self.vy + self.aFall
    if self.vy > self.vFall then
        self.vy = self.vFall
    end
    self.x = self.x + self.vx
    self.y = self.y + self.vy
    if self.ground then
        self.x = self.x + self.ground.vx
        self.ground = nil
    end
    self:collide()
end

function Enemy:hit(enemy)
    self.vx = enemy.vx/2
    self:gotoState('Dead')
end

function Enemy:grab(player)
    return false
end

function Enemy:harmful()
    return false
end

function Enemy:isDead()
    return false
end

--[[======== MOVE STATE ========]]

Enemy.Move = Enemy:addState('Move')

Enemy.Move.collide_lava = {
    type = 'cross',
    func = function(self, col)
        col.other:touch(self.x, true)
        self:gotoState('Dead')
        self.deadTimer = 60
    end
}

function Enemy.Move:enteredState()
    self.vx = self.vMove * self.direction
end

function Enemy.Move:update(dt)
    self.direction = self.vx > 0 and 1 or -1
    Enemy.update(self, dt)
end

function Enemy.Move:harmful()
    return true
end

--[[======== DEAD STATE ========]]

Enemy.Dead = Enemy:addState('Dead')

function Enemy.Dead:enteredState()
    self.world:remove(self)
    -- self.dropItem(self.x, self.y) --TODO
    self.deadTimer = 0
    self.vy = -8
end

function Enemy.Dead:update(dt)
    self.deadTimer = self.deadTimer + 1
    self.vy = self.vy + self.aFall
    self.vx = self.vx * 0.98
    self.x = self.x + self.vx
    self.y = self.y + self.vy
end

function Enemy.Dead:hit() end

function Enemy.Dead:isDead()
    return self.deadTimer > 60 --TODO
end

return Enemy
