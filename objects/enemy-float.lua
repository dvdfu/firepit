local Class = require 'middleclass'
local Enemy = require 'objects/enemy'
local EnemyFloat = Class('enemy_float', Enemy)
local Object = require 'objects/object'

local Tile = require 'objects/tile'
local Particles = require('objects/particles')
local Vector = require('vector')
require 'AnAL'

EnemyFloat.static.sprMove = love.graphics.newImage('assets/images/enemies/float_move.png')
EnemyFloat.static.sprDead = love.graphics.newImage('assets/images/enemies/float_dead.png')
EnemyFloat.static.sprParticle = love.graphics.newImage('assets/images/particles/dot.png')

EnemyFloat.static.glowShader = love.graphics.newShader[[
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

EnemyFloat.Move = EnemyFloat:addState('Move')
EnemyFloat.Hit = EnemyFloat:addState('Hit')
EnemyFloat.Dead = EnemyFloat:addState('Dead')

EnemyFloat.static.fallVel = 7
EnemyFloat.static.fallAcc = 0.02
EnemyFloat.static.moveVel = 0.4
EnemyFloat.static.jumpVel = 0.7

function EnemyFloat:initialize(collider, x, y)
    self.pos = Vector(x, y)
    self.size = Vector(10, 10)
    self.maxHealth = 2
    Enemy.initialize(self, collider, collider:circle(x, y, 10))
    self:addTag('enemy_float')
    self.direction.x = -1

    self.player = nil

    self.moveTimer = 0
    self.stompTimer = 0
    self.holdTimer = 0
    self.throwTimer = 0
    self.deadTimer = 0

    self.animMove = newAnimation(EnemyFloat.sprMove, 32, 32, 1/8, 0)
    self.animDead = newAnimation(EnemyFloat.sprDead, 32, 32, 1/8, 0)
    self.animDead:setMode('once')

    self.speck = Particles.newFireSpeck()
    self.speck:setAreaSpread('normal', 4, 2)
    self.speck:setParticleLifetime(0, 0.4)
    self.speck:setSpeed(0, 30)

    self.explosion = love.graphics.newParticleSystem(EnemyFloat.sprParticle)
    self.explosion:setParticleLifetime(0, 0.5)
    self.explosion:setSpread(math.pi*2)
    self.explosion:setAreaSpread('normal', 4, 4)
    self.explosion:setSpeed(0, 100)
    self.explosion:setColors(255, 255, 0, 255, 255, 255, 0, 255, 255, 182, 0, 255, 255, 73, 73, 255, 146, 36, 36, 255)
    self.explosion:setSizes(2, 0)
    self:gotoState('Move')
end

function EnemyFloat:update(dt)
    self.vel.y = self.vel.y + EnemyFloat.fallAcc
    if self.vel.y > EnemyFloat.fallVel then
        self.vel.y = EnemyFloat.fallVel
    end
    if self.ground and self.ground:getState(self.pos.x) == Tile.state.iced then
        self:hit(nil, 1)
    end
    self.ground = nil
    Enemy.update(self, dt)
end

function EnemyFloat:collide_solid(other, x, y)
    if math.abs(x-self.pos.x) > 0.1 then
        self.vel.x = -self.vel.x
    end
    self.pos = Vector(x, y)
end

function EnemyFloat:collide_platform(other, x, y)
    if y <= self.pos.y and self.vel.y >= 0 and self.pos.y - self.vel.y <= other.pos.y then
        self.vel.y = -EnemyFloat.jumpVel
        self.pos.y = y
        self.ground = other
    end
end

function EnemyFloat:collide_lava(other, x, y)
    other:touch(self.pos.x, true)
    self:hit(nil, -1)
end

function EnemyFloat:draw()
    love.graphics.setBlendMode('additive')
    love.graphics.setShader(EnemyFloat.glowShader)
    love.graphics.draw(EnemyFloat.sprParticle, self.pos.x, self.pos.y, 0, 8, 8, EnemyFloat.sprParticle:getWidth()/2, EnemyFloat.sprParticle:getHeight()/2)
    love.graphics.setShader()
    love.graphics.setBlendMode('alpha')
    love.graphics.setColor(255, 255, 255, 255)

    self.speck:setPosition(self.pos.x, self.pos.y)
    self.speck:update(1/60)
    love.graphics.draw(self.speck)

    self.explosion:setPosition(self.pos.x, self.pos.y)
    self.explosion:update(1/60)
    love.graphics.draw(self.explosion)

    if self.sprite ~= self.animDead or self.sprite:getCurrentFrame() < self.sprite:getSize() then
        self.sprite:update(1/60)
        local x, y = math.floor(self.pos.x+0.5), math.floor(self.pos.y+0.5)
        self.sprite:draw(x, y, 0, self.direction.x, 1, self.sprite:getWidth()/2, self.sprite:getHeight()/2)
    end
end

function EnemyFloat:drawHealth(cam)
    Enemy.drawHealth(self, cam, self.pos.x, self.pos.y-16)
end

function EnemyFloat:stomp()
    self:hit(nil, 3)
    if self.health > 0 then
        self:gotoState('Stun')
    end
    return true
end

--[[======== MOVE STATE ========]]

function EnemyFloat.Move:enteredState()
    self.moveTimer = 0
    self.speck:setEmissionRate(50)
    self.sprite = self.animMove
    self.sprite.speed = 1
    self.vel.x = EnemyFloat.moveVel * self.direction.x
end

function EnemyFloat.Move:update(dt)
    self.moveTimer = self.moveTimer + 1
    self.direction.x = self.vel.x > 0 and 1 or -1
    EnemyFloat.update(self, dt)
end

function EnemyFloat.Move:isHarmful()
    return true
end

--[[======== HIT STATE ========]]

function EnemyFloat.Hit:update(dt)
    if self.hitTimer == 0 then
        self:popState()
    else
        self.hitTimer = self.hitTimer-1
    end
end

function EnemyFloat.Hit:draw()
    love.graphics.setColor(255, 0, 0)
    EnemyFloat.draw(self)
    love.graphics.setColor(255, 255, 255)
end

function EnemyFloat.Hit:hit()
    return false
end

--[[======== DEAD STATE ========]]

function EnemyFloat.Dead:enteredState()
    self.activeBody = false
    self.vel = Vector(0, 0)
    self.deadTimer = 60
    self.speck:setEmissionRate(0)
    self.explosion:emit(50)
    self.sprite = self.animDead
end

function EnemyFloat.Dead:update(dt)
    if self.deadTimer > 0 then
        self.deadTimer = self.deadTimer - 1
    end
end

function EnemyFloat.Dead:draw()
    love.graphics.setColor(255, 255, 255, 255*self.deadTimer/60)
    EnemyFloat.draw(self)
end

function EnemyFloat.Dead:hit()
    return false
end

function EnemyFloat.Dead:isDead()
    return self.deadTimer == 0
end

function EnemyFloat.Dead:stomp()
    return false
end

return EnemyFloat
