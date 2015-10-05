local Class = require 'middleclass'
local Object = require 'objects/object'
local Enemy = Class('enemy', Object)

function Enemy:initialize(collider, body)
    Object.initialize(self, collider, body)
    self.tags = { 'enemy' }

    self.health = 1
    self.ground = nil
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
