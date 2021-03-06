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
    self.maxHealth = 5
    self.healthOffset = Vector(0, -32)
    Enemy.initialize(self, collider, collider:rectangle(x, y, self.size:unpack()))
    self:addTag('enemy_rock')
    self.offset.y = self.size.y/2

    self.player = nil

    self.animMove = newAnimation(EnemyRock.sprMove, 24, 24, 1/8, 0)
    self.animStun = newAnimation(EnemyRock.sprStun, 24, 24, 1/8, 0)
    self.animStar = newAnimation(EnemyRock.sprStar, 10, 10, 1/8, 0)

    self.dust = Particles.newDust()

    self:gotoState('Move')
end

function EnemyRock:update()
    self.vel.y = self.vel.y + EnemyRock.static.fallAcc
    if self.vel.y > EnemyRock.fallVel then
        self.vel.y = EnemyRock.fallVel
    end
    self.ground = nil
    Enemy.update(self)
end

function EnemyRock:collide_solid(other, x, y)
    if math.abs(x-self.pos.x) > 0.1 then
        self.vel.x = -self.vel.x
        self.direction.x = self.vel.x > 0 and 1 or -1
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
    other:touch(self.pos.x, false)
    self:hit(nil, -1)
    self.deadTimer = 0
end

function EnemyRock:draw()
    self.dust:setPosition(self.pos.x, self.pos.y)
    self.dust:update(1/60)
    love.graphics.draw(self.dust)

    self.sprite:update(1/60)
    local x, y = math.floor(self.pos.x+0.5), math.floor(self.pos.y+0.5)
    self.sprite:draw(x, y, 0, self.direction.x, 1, self.sprite:getWidth()/2, self.sprite:getHeight())
end

function EnemyRock:grab(player)
    return false
end

function EnemyRock:hit(other, damage, hitstun)
    Enemy.hit(self, other, damage, hitstun)
    if self.health <= 0 and other then
        self.vel = (self.pos - other.pos):normalized() * 6
        self.vel.y = -6
    end
    return true
end

function EnemyRock:release() end

function EnemyRock:stomp()
    if self.health > 3 then
        self:gotoState('Stun')
    else
        self.vel.y = -6
    end
    self:hit(nil, 3, 4)
    return true
end

--[[======== MOVE STATE ========]]

function EnemyRock.Move:enteredState()
    self.sprite = self.animMove
    self.sprite.speed = 1
end

function EnemyRock.Move:update()
    self.vel.x = EnemyRock.moveVel * self.direction.x
    if self.ground and self.ground:getState(self.pos.x) == Tile.names.iced then
        self.vel.x = EnemyRock.moveVel/4 * self.direction.x
    end
    self.direction.x = self.vel.x > 0 and 1 or -1
    EnemyRock.update(self)
end

function EnemyRock.Move:collide_lava(other, x, y)
    other:touch(self.pos.x, true)
    self:hit(nil, -1)
    self.deadTimer = 0
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

function EnemyRock.Stun:update()
    EnemyRock.update(self)
    if self.stompTimer > 0 then
        self.stompTimer = self.stompTimer - 1
    else
        self:gotoState('Move')
    end
end

function EnemyRock.Stun:draw()
    EnemyRock.draw(self)
    local numStars = math.ceil(self.stompTimer/60)
    self.animStar:update(1/60)
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
    self.activeBody = false
    self.sprite = self.animStun
    self.sprite.speed = 0
    self.holdTimer = 20
    self.vel = Vector(0, 0)
end

function EnemyRock.Hold:exitedState()
    self.activeBody = true
    if self.player and self.player.hold == self then
        self.player.hold = nil
    end
end

function EnemyRock.Hold:update()
    local target = self.player.pos:clone() - Vector(0, self.player.size.y)
    if self.holdTimer > 0 then
        self.holdTimer = self.holdTimer - 1
        target = target - (target-self.pos)*self.holdTimer/20
    end
    self.pos = target
    -- self:move() TODO
    Enemy.update(self)
end

function EnemyRock.Hold:release()
    self:gotoState('Throw')
end

function EnemyRock.Hold:stomp() end

--[[======== THROW STATE ========]]

function EnemyRock.Throw:enteredState()
    self.throwTimer = 30
end

function EnemyRock.Throw:update()
    self.direction.x = self.vel.x > 0 and 1 or -1
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

    EnemyRock.update(self)
end

function EnemyRock.Throw:collide_enemy(other, x, y)
    other:hit(self, 8, 4)
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
    self.immobile = true
end

function EnemyRock.Hit:exitedState()
    self.immobile = false
end

function EnemyRock.Hit:update()
    if self.hitTimer > 0 then
        self.hitTimer = self.hitTimer - 1
    else
        self:popState()
    end
    Enemy.update(self)
end

function EnemyRock.Hit:draw()
    love.graphics.setShader(Enemy.hitShader)
    EnemyRock.draw(self)
    love.graphics.setShader()
end

function EnemyRock.Hit:hit()
    return false
end

--[[======== DEAD STATE ========]]

function EnemyRock.Dead:enteredState()
    self.activeBody = false
    self.deadTimer = 60
    self.sprite = self.animStun
end

function EnemyRock.Dead:update()
    if self.deadTimer > 0 then
        self.deadTimer = self.deadTimer - 1
    end
    self.vel.y = self.vel.y + EnemyRock.static.fallAcc
    self.vel.x = self.vel.x * 0.98
    Enemy.update(self)
end

function EnemyRock.Dead:hit()
    return false
end

function EnemyRock.Dead:isDead()
    return self.deadTimer == 0
end

return EnemyRock
