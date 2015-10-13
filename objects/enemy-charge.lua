local Class = require 'middleclass'
local Enemy = require 'objects/enemy'
local EnemyCharge = Class('enemy_charge', Enemy)
local Object = require 'objects/object'

local Particles = require('objects/particles')
local Tile = require 'objects/tile'
local Vector = require('vector')
require 'AnAL'

EnemyCharge.static.sprMove = love.graphics.newImage('assets/images/enemies/charge_move.png')
EnemyCharge.static.sprAttack = love.graphics.newImage('assets/images/enemies/charge_attack.png')
EnemyCharge.static.sprParticle = love.graphics.newImage('assets/images/particles/dot.png')

EnemyCharge.static.glowShader = love.graphics.newShader[[
    float fudge(vec2 seed) {
        return fract(sin(dot(seed.xy, vec2(12.9898, 78.233))) * 43758.5453);
    }

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = vec4(0.6, 0.4, 0.1, 1);
        vec2 d = 2.0*(texture_coords - vec2(0.5));
        pixel.a = 1.0 - length(d);
        pixel.a = floor(pixel.a*5)/5;
        //pixel.a = floor(pixel.a*5 - fudge(texture_coords))/5;
        return pixel * color;
    }
]]

EnemyCharge.Move = EnemyCharge:addState('Move')
EnemyCharge.Attack = EnemyCharge:addState('Attack')
EnemyCharge.Hit = EnemyCharge:addState('Hit')
EnemyCharge.Dead = EnemyCharge:addState('Dead')

EnemyCharge.static.fallVel = 7
EnemyCharge.static.fallAcc = 0.3
EnemyCharge.static.moveVel = 0.4

function EnemyCharge:initialize(collider, x, y)
    self.pos = Vector(x, y)
    self.size = Vector(16, 16)
    self.maxHealth = 5
    Enemy.initialize(self, collider, collider:rectangle(x, y, self.size:unpack()))
    self:addTag('enemy_charge')
    self.healthOffset = Vector(0, -32)
    self.offset.y = self.size.y/2
    self.direction.x = -1

    self.player = nil

    self.animMove = newAnimation(EnemyCharge.sprMove, 24, 24, 1/8, 0)
    self.animAttack = newAnimation(EnemyCharge.sprAttack, 24, 24, 1/8, 0)
    self:gotoState('Move')

    self.fire = Particles.newFire()
    self.fire:setAreaSpread('normal', 2, 2)
    self.fire:setSpeed(0)
end

function EnemyCharge:update()
    self.vel.y = self.vel.y + EnemyCharge.fallAcc
    if self.vel.y > EnemyCharge.fallVel then
        self.vel.y = EnemyCharge.fallVel
    end
    if self.ground and self.ground:getState(self.pos.x) == Tile.state.iced then
        self:hit(nil, 1, 4)
    end
    self.ground = nil
    Enemy.update(self)
end

function EnemyCharge:collide_solid(other, x, y)
    if math.abs(x-self.pos.x) > 0.1 then
        self.vel.x = -self.vel.x
    end
    self.pos = Vector(x, y)
end

function EnemyCharge:collide_platform(other, x, y)
    if y <= self.pos.y and self.vel.y >= 0 and self.pos.y - self.vel.y <= other.pos.y then
        self.vel.y = 0
        self.pos.y = y
        self.ground = other
    end
end

function EnemyCharge:collide_lava(other, x, y)
    other:touch(self.pos.x, true)
    self:hit(nil, -1)
end

function EnemyCharge:draw()
    self.fire:setPosition(self.pos.x, self.pos.y-self.size.y/2)
    self.fire:update(1/60)
    love.graphics.draw(self.fire)
    self.sprite:update(1/60)
    local x, y = math.floor(self.pos.x+0.5), math.floor(self.pos.y+0.5)
    self.sprite:draw(x, y, 0, self.direction.x, 1, self.sprite:getWidth()/2, self.sprite:getHeight())
end

function EnemyCharge:drawGlow()
    love.graphics.setBlendMode('additive')
    love.graphics.setShader(EnemyCharge.glowShader)
    love.graphics.draw(EnemyCharge.sprParticle, self.pos.x, self.pos.y-self.size.y/2, 0, 8, 8, EnemyCharge.sprParticle:getWidth()/2, EnemyCharge.sprParticle:getHeight()/2)
    love.graphics.setShader()
    love.graphics.setBlendMode('alpha')
end

function EnemyCharge:stomp()
    self:hit(nil, 3, 4)
    return true
end

--[[======== MOVE STATE ========]]

function EnemyCharge.Move:enteredState()
    self.sprite = self.animMove
    self.sprite.speed = 1
    self.vel.x = EnemyCharge.moveVel * self.direction.x
end

function EnemyCharge.Move:update()
    self.direction.x = self.vel.x > 0 and 1 or -1
    EnemyCharge.update(self)
    if self.ground and (self.player.pos.x > self.pos.x) == (self.direction.x == 1) and
        math.abs(self.pos.x - self.player.pos.x) < 200 and
        math.abs(self.pos.y - self.player.pos.y) < 16 then
            self:gotoState('Attack')
    end
end

function EnemyCharge.Move:draw()
    self:drawGlow()
    EnemyCharge.draw(self)
end

function EnemyCharge.Move:isHarmful()
    return true
end

--[[======== ATTACK STATE ========]]

function EnemyCharge.Attack:enteredState()
    self.sprite = self.animAttack
end

function EnemyCharge.Attack:update()
    if self.direction.x == 1 then
        if self.vel.x < 10 then
            self.vel.x = self.vel.x + 0.3
        else
            self.vel.x = 10
        end
    else
        if self.vel.x > -10 then
            self.vel.x = self.vel.x - 0.3
        else
            self.vel.x = -10
        end
    end
    self.fire:emit(3)
    Enemy.update(self)
end

function EnemyCharge.Attack:collide_solid(other, x, y)
    if math.abs(x-self.pos.x) > 0.1 then
        self:gotoState('Move')
    end
    self.pos = Vector(x, y)
end

function EnemyCharge.Attack:draw()
    self:drawGlow()
    EnemyCharge.draw(self)
end

--[[======== HIT STATE ========]]

function EnemyCharge.Hit:enteredState()
    self.immobile = true
end

function EnemyCharge.Hit:exitedState()
    self.immobile = false
end
function EnemyCharge.Hit:update()
    if self.hitTimer == 0 then
        self:popState()
    else
        self.hitTimer = self.hitTimer-1
    end
    Enemy.update(self)
end

function EnemyCharge.Hit:draw()
    self:drawGlow()
    love.graphics.setShader(Enemy.hitShader)
    EnemyCharge.draw(self)
    love.graphics.setShader()
end

function EnemyCharge.Hit:hit()
    return false
end

--[[======== DEAD STATE ========]]

function EnemyCharge.Dead:enteredState()
    self.activeBody = false
    self.vel = Vector(0, 0)
    self.deadTimer = 60
end

function EnemyCharge.Dead:update()
    if self.deadTimer > 0 then
        self.deadTimer = self.deadTimer - 1
    end
    Enemy.update(self)
end

function EnemyCharge.Dead:draw()
    love.graphics.setColor(255, 255, 255, 255*self.deadTimer/60)
    self:drawGlow()
    love.graphics.setColor(255, 255, 255, 255)
    EnemyCharge.draw(self)
end

function EnemyCharge.Dead:hit()
    return false
end

function EnemyCharge.Dead:isDead()
    return self.deadTimer == 0
end

function EnemyCharge.Dead:stomp()
    return false
end

return EnemyCharge
