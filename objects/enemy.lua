local Class = require('middleclass')
local Object = require('objects/object')
local Enemy = Class('enemy', Object)
local Vector = require('vector')

function Enemy:initialize(collider, body)
    Object.initialize(self, collider, body)
    self.tags = { 'enemy' }

    self.maxHealth = self.maxHealth or 1
    self.health = self.maxHealth
    self.healthTimer = 0
    self.preHealth = self.maxHealth
    self.healthOffset = self.healthOffset or Vector(0, 0) --health bar offset
    self.ground = nil
end

function Enemy:update()
    if self.healthTimer > 0 then
        self.healthTimer = self.healthTimer - 1
    end
    Object.update(self)
end

function Enemy:hit(other, damage, hitstun)
    damage = damage or 0
    self.hitTimer = hitstun or 0
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

function Enemy:isHarmful()
    return false
end

function Enemy:isDead()
    return false
end

return Enemy
