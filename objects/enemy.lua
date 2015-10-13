local Class = require('middleclass')
local Object = require('objects/object')
local Enemy = Class('enemy', Object)
local Vector = require('vector')

Enemy.static.hitShader = love.graphics.newShader[[
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(texture, texture_coords);
        pixel.rgb = vec3(1.0);
        return pixel * color;
    }
]]

function Enemy:initialize(collider, body)
    Object.initialize(self, collider, body)
    self.tags = { 'enemy' }
    self.direction.x = math.random() > 0.5 and 1 or -1

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
    self.hitTimer = hitstun or 2
    if self.healthTimer < 40 then
        self.preHealth = self.health
    end
    if damage >= 0 and self.health > damage then
        self.health = self.health - damage
    else
        self.health = 0
        self:gotoState('Dead')
    end
    self:pushState('Hit')
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
