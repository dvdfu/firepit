local Tile = require 'objects/tile'
local Class = require 'middleclass'
local Enemy = require 'objects/enemy'
local EnemyRock = Class('enemy_rock', Enemy)

local Particles = require('objects/particles')
local Vector = require('vector')
require 'AnAL'

EnemyRock.static.sprMove = love.graphics.newImage('assets/images/enemies/rock_move.png')
EnemyRock.static.sprStun = love.graphics.newImage('assets/images/enemies/rock_stun.png')
EnemyRock.static.sprStar = love.graphics.newImage('assets/images/enemies/star.png')

EnemyRock.static.fallVel = 7
EnemyRock.static.fallAcc = 0.4
EnemyRock.static.moveVel = 0.4

EnemyRock.Move = EnemyRock:addState('Move')
EnemyRock.Stun = EnemyRock:addState('Stun')
EnemyRock.Hold = EnemyRock:addState('Hold')
EnemyRock.Throw = EnemyRock:addState('Throw')
EnemyRock.Hit = EnemyRock:addState('Hit')
EnemyRock.Dead = EnemyRock:addState('Dead')

function EnemyRock:initialize(collider, x, y)
    self.pos = Vector(x, y)
    self.size = Vector(16, 16)
    Enemy.initialize(self, collider, collider:addRectangle(x, y, self.size:unpack()))
    self:addTag('enemy_rock')
    self.offset.y = self.size.y/2

    self.health = 3
    self.player = nil

    self.animMove = newAnimation(EnemyRock.sprMove, 24, 24, 1/8, 0)
    self.animStun = newAnimation(EnemyRock.sprStun, 24, 24, 1/8, 0)
    self.animStar = newAnimation(EnemyRock.sprStar, 10, 10, 1/8, 0)

    self.dust = Particles.newDust()

    self:gotoState('Move')
end

function EnemyRock:update(dt)
    self.vel.y = self.vel.y + EnemyRock.static.fallAcc
    if self.vel.y > EnemyRock.fallVel then
        self.vel.y = EnemyRock.fallVel
    end
    self.ground = nil
    Enemy.update(self, dt)
end

function EnemyRock:collide_solid(other, x, y)
    if math.abs(x-self.pos.x) > 0.1 then
        self.vel.x = -self.vel.x
        self.direction = self.vel.x > 0 and 1 or -1
    end
    self.pos = Vector(x, y)
end

function EnemyRock:collide_platform(other, x, y)
    if y <= self.pos.y and self.vel.y >= 0 and self.pos.y - self.vel.y <= other.pos.y then
        self.vel.y = 0
        self.pos.y = y
        self.ground = other
    end
end

function EnemyRock:collide_lava(other, x, y)
    other:touch(self.pos.x, true)
    self:hit(nil, -1)
    self.deadTimer = 0
end

function EnemyRock:draw()
    self.dust:setPosition(self.pos.x, self.pos.y)
    self.dust:update(1/60)
    love.graphics.draw(self.dust)

    self.sprite:update(1/60)
    local x, y = math.floor(self.pos.x+0.5), math.floor(self.pos.y+0.5)
    self.sprite:draw(x, y, 0, self.direction, 1, self.sprite:getWidth()/2, self.sprite:getHeight())
end

function EnemyRock:grab(player)
    return false
end

function EnemyRock:release() end

function EnemyRock:stomp()
    self:gotoState('Stun')
end

--[[======== MOVE STATE ========]]

function EnemyRock.Move:enteredState()
    self.sprite = self.animMove
    self.sprite.speed = 1
end

function EnemyRock.Move:update(dt)
    self.vel.x = EnemyRock.moveVel * self.direction
    if self.ground and self.ground:getState(self.pos.x) == Tile.state.iced then
        self.vel.x = EnemyRock.moveVel/4 * self.direction
    end
    self.direction = self.vel.x > 0 and 1 or -1
    EnemyRock.update(self, dt)
end

function EnemyRock.Move:isHarmful()
    return true
end

--[[======== STUN STATE ========]]

function EnemyRock.Stun:enteredState()
    self.sprite = self.animStun
    self.stompTimer = 4*60
    self.sprite.speed = 0
    self.vel.x = 0
end

function EnemyRock.Stun:update(dt)
    EnemyRock.update(self, dt)
    self.animStar:update(dt)
    if self.stompTimer > 0 then
        self.stompTimer = self.stompTimer - 1
    else
        self:gotoState('Move')
    end
end

function EnemyRock.Stun:draw()
    EnemyRock.draw(self)
    local numStars = math.ceil(self.stompTimer/60)
    for i = 1, numStars do
        local sx = self.pos.x + 12*math.cos(self.stompTimer/20 + i/numStars*2*math.pi)
        local sy = self.pos.y + 6*math.sin(self.stompTimer/20 + i/numStars*2*math.pi)
        self.animStar:draw(sx, sy - self.size.y, 0, 1, 1, 5, 5)
    end
end

function EnemyRock.Stun:grab(player)
    self.player = player
    self:gotoState('Hold')
    return true
end

--[[======== HOLD STATE ========]]

function EnemyRock.Hold:enteredState()
    self.collider:setGhost(self.body)
    self.sprite = self.animStun
    self.sprite.speed = 0
    self.holdTimer = 20
    self.vel = Vector(0, 0)
end

function EnemyRock.Hold:exitedState()
    self.collider:setSolid(self.body)
    if self.player and self.player.hold == self then
        self.player.hold = nil
    end
end

function EnemyRock.Hold:update(dt)
    local target = self.player.pos:clone() - Vector(0, self.player.size.y)
    if self.holdTimer > 0 then
        self.holdTimer = self.holdTimer - 1
        target = target - (target-self.pos)*self.holdTimer/20
    end
    self.pos = target
    self:move()
end

function EnemyRock.Hold:release()
    self:gotoState('Throw')
end

function EnemyRock.Hold:stomp() end

--[[======== THROW STATE ========]]

function EnemyRock.Throw:enteredState()
    self.throwTimer = 30
end

function EnemyRock.Throw:update(dt)
    self.direction = self.vel.x > 0 and 1 or -1
    if self.ground then
        self.vel.x = self.vel.x * 0.9
    else
        self.vel.x = self.vel.x * 0.99
    end

    self.sprite.speed = math.abs(self.vel.x)

    if self.ground then
        self.dust:emit(self.sprite.speed)
        if self.throwTimer > 0 and self.vel:len() > 0.1 then
            self.throwTimer = self.throwTimer - 1
        else
            self:gotoState('Stun')
        end
    end

    EnemyRock.update(self, dt)
end

function EnemyRock.Throw:collide_enemy(other, x, y)
    other:hit(self, 8)
end

function EnemyRock.Throw:collide_lava(other, x, y)
    other:touch(self.pos.x, false)
    self:hit(nil, -1)
    self.deadTimer = 0
end

function EnemyRock.Throw:collide_platform(other, x, y)
    if y <= self.pos.y and self.vel.y >= 0 and self.pos.y - self.vel.y <= other.pos.y then
        if self.vel.y > 1 then
            cs = 10
        end
        self.vel.y = 0
        self.pos.y = y
        self.ground = other
    end
end

function EnemyRock.Throw:stomp() end

--[[======== HIT STATE ========]]

function EnemyRock.Hit:enteredState()
    self.hitTimer = 2
end

function EnemyRock.Hit:update(dt)
    if self.hitTimer > 0 then
        self.hitTimer = self.hitTimer - 1
    else
        self:popState()
    end
end

function EnemyRock.Hit:draw()
    love.graphics.setColor(255, 0, 0)
    EnemyRock.draw(self)
    love.graphics.setColor(255, 255, 255)
end

function EnemyRock.Hit:hit() end

--[[======== DEAD STATE ========]]

function EnemyRock.Dead:enteredState()
    self.collider:setGhost(self.body)
    self.deadTimer = 60
    self.vel.y = -4
end

function EnemyRock.Dead:update(dt)
    if self.deadTimer > 0 then
        self.deadTimer = self.deadTimer - 1
    end
    self.vel.y = self.vel.y + EnemyRock.static.fallAcc
    self.vel.x = self.vel.x * 0.98
    Enemy.update(self, dt)
end

function EnemyRock.Dead:hit() end

function EnemyRock.Dead:isDead()
    return self.deadTimer == 0
end

return EnemyRock
