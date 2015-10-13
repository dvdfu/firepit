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
EnemyCharge.static.sprGasp = love.graphics.newImage('assets/images/enemies/charge_gasp.png')
EnemyCharge.static.sprStun = love.graphics.newImage('assets/images/enemies/charge_stun.png')
EnemyCharge.static.sprStar = love.graphics.newImage('assets/images/enemies/star.png')
EnemyCharge.static.sprExclamation = love.graphics.newImage('assets/images/enemies/exclamation.png')

EnemyCharge.Move = EnemyCharge:addState('Move')
EnemyCharge.Attack = EnemyCharge:addState('Attack')
EnemyCharge.Gasp = EnemyCharge:addState('Gasp')
EnemyCharge.Stun = EnemyCharge:addState('Stun')
EnemyCharge.Hit = EnemyCharge:addState('Hit')
EnemyCharge.Dead = EnemyCharge:addState('Dead')

EnemyCharge.static.fallVel = 7
EnemyCharge.static.fallAcc = 0.3
EnemyCharge.static.moveVel = 0.4
EnemyCharge.static.attackAcc = 0.7
EnemyCharge.static.attackVel = 9

function EnemyCharge:initialize(collider, x, y)
    self.pos = Vector(x, y)
    self.size = Vector(16, 16)
    self.maxHealth = 3
    Enemy.initialize(self, collider, collider:rectangle(x, y, self.size:unpack()))
    self:addTag('enemy_charge')
    self.healthOffset = Vector(0, -32)
    self.offset.y = self.size.y/2

    self.player = nil

    self.animMove = newAnimation(EnemyCharge.sprMove, 24, 24, 1/8, 0)
    self.animAttack = newAnimation(EnemyCharge.sprAttack, 24, 24, 1/8, 0)
    self.animGasp = newAnimation(EnemyCharge.sprGasp, 24, 24, 1/8, 0)
    self.animStun = newAnimation(EnemyCharge.sprStun, 24, 24, 1/8, 0)
    self.animStar = newAnimation(EnemyCharge.sprStar, 10, 10, 1/8, 0)
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
    other:touch(self.pos.x, false)
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

function EnemyCharge:stomp()
    self:hit(nil, 3, 4)
    return true
end

function EnemyCharge:hit(other, damage, hitstun)
    Enemy.hit(self, other, damage, hitstun)
    if self.health <= 0 and other then
        self.vel = (self.pos - other.pos):normalized() * 4
        self.vel.y = -5
    end
    return true
end

function EnemyCharge:isHarmful()
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
    if self.ground and self.player.ground and
        (self.player.pos.x > self.pos.x) == (self.direction.x == 1) and
        math.abs(self.pos.x - self.player.pos.x) < 200 and
        math.abs(self.pos.y - self.player.pos.y) < 16 then
            self:gotoState('Gasp')
    end
end

function EnemyCharge.Move:collide_lava(other, x, y)
    other:touch(self.pos.x, true)
    self:hit(nil, -1)
end

--[[======== GASP STATE ========]]

function EnemyCharge.Gasp:enteredState()
    self.vel.y = -4
    self.ground = nil
    self.sprite = self.animGasp
end

function EnemyCharge.Gasp:update()
    if self.ground then
        self:gotoState('Attack')
    end
    EnemyCharge.update(self)
end

function EnemyCharge.Gasp:draw()
    love.graphics.draw(EnemyCharge.sprExclamation, self.pos.x, self.pos.y-28, 0, 1, 1, 6, 6)
    EnemyCharge.draw(self)
end

--[[======== ATTACK STATE ========]]

function EnemyCharge.Attack:enteredState()
    self.sprite = self.animAttack
end

function EnemyCharge.Attack:update()
    if self.direction.x == 1 then
        if self.vel.x < EnemyCharge.attackVel then
            self.vel.x = self.vel.x + EnemyCharge.attackAcc
        else
            self.vel.x = EnemyCharge.attackVel
        end
    else
        if self.vel.x > -EnemyCharge.attackVel then
            self.vel.x = self.vel.x - EnemyCharge.attackAcc
        else
            self.vel.x = -EnemyCharge.attackVel
        end
    end
    self.fire:emit(3)
    Enemy.update(self)
end

function EnemyCharge.Attack:collide_solid(other, x, y)
    if math.abs(x-self.pos.x) > 0.1 then
        self:gotoState('Stun')
        self.vel.x = -self.vel.x
        self.vel.y = -4
    end
    self.pos = Vector(x, y)
end

function EnemyCharge.Attack:collide_player(other, x, y)
    if math.abs(x-self.pos.x) > 0.1 then
        self:gotoState('Stun')
        self.vel.x = -self.vel.x
        self.vel.y = -4
    end
end

--[[======== STUN STATE ========]]

function EnemyCharge.Stun:enteredState()
    self.sprite = self.animStun
    self.stunTimer = 3*60
end

function EnemyCharge.Stun:update()
    if math.abs(self.vel.x) > EnemyCharge.moveVel then
        self.vel.x = self.vel.x * 0.92
    else
        self.vel.x = 0
    end

    if self.stunTimer > 0 then
        self.stunTimer = self.stunTimer - 1
    else
        self:gotoState('Move')
    end
    EnemyCharge.update(self)
end

function EnemyCharge.Stun:draw()
    EnemyCharge.draw(self)
    self.animStar:update(1/60)
    local numStars = math.ceil(self.stunTimer/60)
    for i = 1, numStars do
        local sx = self.pos.x + 12*math.cos(self.stunTimer/20 + i/numStars*2*math.pi)
        local sy = self.pos.y + 6*math.sin(self.stunTimer/20 + i/numStars*2*math.pi)
        self.animStar:draw(sx, sy - self.size.y, 0, 1, 1, 5, 5)
    end
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
    self.sprite = self.animStun
end

function EnemyCharge.Dead:update()
    if self.deadTimer > 0 then
        self.deadTimer = self.deadTimer - 1
    end
    EnemyCharge.update(self)
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
