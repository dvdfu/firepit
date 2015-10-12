local Class = require 'middleclass'
local Object = require 'objects/object'
local Enemy = Class('enemy', Object)

function Enemy:initialize(collider, body)
    Object.initialize(self, collider, body)
    self.tags = { 'enemy' }

    self.maxHealth = self.maxHealth or 1
    self.health = self.maxHealth
    self.healthTimer = 0
    self.preHealth = self.maxHealth
    self.ground = nil
end

function Enemy:hit(other, damage, time)
    damage = damage or 0
    self.hitTimer = time or 0
    if self.healthTimer == 0 then
        self.preHealth = self.health
    end
    if damage >= 0 and self.health > damage then
        self.health = self.health - damage
        self:pushState('Hit')
    else
        self.health = 0
        self:gotoState('Dead')
    end
    if damage ~= 0 then
        self.healthTimer = 60
    end
    return true
end

function Enemy:drawHealth(cam, x, y)
    if self.healthTimer <= 0 then return end
    x = x or self.pos.x
    y = y or self.pos.y
    x, y = cam:cameraCoords(x-240, y-180)
    if self.healthTimer > 0 then
        self.healthTimer = self.healthTimer - 1
    end
    local w, h = 32, 6
    local damage = self.health
    if self.healthTimer > 40 then
        damage = self.preHealth
    elseif self.healthTimer > 20 then
        damage = self.health + (self.preHealth-self.health)*(self.healthTimer-20)/20
    end
    love.graphics.setColor(128, 64, 64)
    love.graphics.rectangle('fill', x-w/2, y-h/2, w, h)
    love.graphics.setColor(255, 255, 255)
    love.graphics.rectangle('fill', x-w/2, y-h/2, w*damage/self.maxHealth, h)
    love.graphics.setColor(255, 128, 96)
    love.graphics.rectangle('fill', x-w/2, y-h/2, w*self.health/self.maxHealth, h)
    love.graphics.setColor(255, 255, 255)
end

function Enemy:isHarmful()
    return false
end

function Enemy:isDead()
    return false
end

return Enemy
