local Class = require('middleclass')
local Object = require 'objects/object'
local Player = Class('player', Object)

local Powerup = require('powerup')
local Particles = require('objects/particles')
local Vector = require('vector')
require('AnAL')

Player.Neutral = Player:addState('Neutral')
Player.Lift = Player:addState('Lift')
Player.Hurt = Player:addState('Hurt')

Player.static.sprIdle = love.graphics.newImage('assets/images/player/dragon_idle.png')
Player.static.sprRun = love.graphics.newImage('assets/images/player/dragon_move.png')
Player.static.sprJump = love.graphics.newImage('assets/images/player/dragon_jump.png')
Player.static.sprFall = love.graphics.newImage('assets/images/player/dragon_fall.png')

Player.static.moveVel = 2
Player.static.moveAccAir = 0.2
Player.static.moveAccGround = 0.3
Player.static.jumpVel = 4.5
Player.static.jumpTimerMax = 10
Player.static.fallVel = 7
Player.static.fallAcc = 0.3

function Player:initialize(collider, x, y)
    self.size = Vector(12, 22)
    Object.initialize(self, collider, collider:addRectangle(x, y, self.size:unpack()))
    self.tags = { 'player' }
    self.pos = Vector(x, y)
    self.offset.y = self.size.y/2

    self.moveVel = Vector(0, 0)
    self.pushVel = Vector(0, 0)
    self.ground = nil
    self.hold = nil
    self.jumpTimer = 0
    self.direction = 1
    self.maxHealth = 6
    self.health = self.maxHealth
    self.activePower = Powerup:new()
    self.staticPowers = {
        [1] = Powerup:new(),
        [2] = Powerup:new()
    }

    self.animIdle = newAnimation(Player.sprIdle, 24, 24, 1/8, 0)
    self.animRun = newAnimation(Player.sprRun, 24, 24, 1/16, 0)
    self.animJump = newAnimation(Player.sprJump, 24, 24, 1/8, 0)
    self.animFall = newAnimation(Player.sprFall, 24, 24, 1/8, 0)
    self.sprite = self.animFall

    self.keyLeft = 'left'
    self.keyRight = 'right'
    self.keyUp = 'up'
    self.keyDown = 'down'
    self.keyA = 'z'
    self.keyB = 'x'

    self.dust = Particles.newDust()
    self.fire = Particles.newFire()
end

function Player:update(dt)
    self.vel.y = self.vel.y + Player.fallAcc

    local moveAcc = self.ground and Player.moveAccGround or Player.moveAccAir
    if Input:isDown(self.keyLeft) and not Input:isDown(self.keyRight) then
        self.moveVel.x = self.moveVel.x - moveAcc
        if self.ground then
            self.sprite = self.animRun
            self.direction = -1
            if self.vel.x >= -moveAcc then
                self.dust:emit(1)
            end
        end
    end
    if Input:isDown(self.keyRight) and not Input:isDown(self.keyLeft) then
        self.moveVel.x = self.moveVel.x + moveAcc
        if self.ground then
            self.sprite = self.animRun
            self.direction = 1
            if self.vel.x <= moveAcc then
                self.dust:emit(1)
            end
        end
    end
    if Input:isDown(self.keyLeft) == Input:isDown(self.keyRight) then
        if self.moveVel.x > moveAcc then
            self.moveVel.x = self.moveVel.x - moveAcc
        elseif self.moveVel.x < -moveAcc then
            self.moveVel.x = self.moveVel.x + moveAcc
        else
            self.moveVel.x = 0
        end
        self.sprite = self.animIdle
    end
    if self.moveVel.x < -Player.moveVel then
        self.moveVel.x = -Player.moveVel
    elseif self.moveVel.x > Player.moveVel then
        self.moveVel.x = Player.moveVel
    end

    if self.ground then
        if Input:pressed(self.keyA) then
            self.vel.y = -Player.jumpVel
            self.jumpTimer = Player.jumpTimerMax
            self.dust:emit(8)
        end
    else
        if self.jumpTimer > 0 then
            self.jumpTimer = self.jumpTimer - 1
            self.vel.y = -Player.jumpVel
            if not Input:isDown(self.keyA) then
                self.jumpTimer = 0
            end
        end
        self.sprite = self.vel.y < 0 and self.animJump or self.animFall
    end

    if self.pushVel.y ~= 0 then
        self.vel.y = self.pushVel.y
        self.pushVel.y = 0
    end
    if math.abs(self.pushVel.x) > 0.1 then
        self.pushVel.x = self.pushVel.x * 0.9
    else
        self.pushVel.x = 0
    end

    self.vel.x = self.moveVel.x + self.pushVel.x
    self.ground = nil
    Object.update(self, dt)
end

function Player:draw()
    self.dust:setPosition(self.pos.x, self.pos.y)
    self.dust:update(1/60)
    love.graphics.draw(self.dust)

    self.fire:setPosition(self.body:center())
    self.fire:update(1/60)
    love.graphics.draw(self.fire)

    self.sprite:update(1/60)
    self.sprite.speed = math.abs(self.vel.x/Player.moveVel)
    local x, y = math.floor(self.pos.x+0.5), math.floor(self.pos.y+0.5)
    self.sprite:draw(x, y, 0, self.direction, 1, self.sprite:getWidth()/2, self.sprite:getHeight())
end

Player.collisions = {
    solid = function(self, dt, other, x, y)
        self.pos = Vector(x, y)
    end,
    platform = function(self, dt, other, x, y)
        if y <= self.pos.y and self.vel.y >= 0 and self.pos.y - self.vel.y <= other.pos.y then
            self.vel.y = 0
            self.pos.y = y
            self.ground = other
        end
    end,
    lava = function(self, dt, other, x, y)
        self.pos.y = y
        self.vel.y = -7
        self:gotoState('Hurt')
    end,
    enemyRock = function(self, dt, other, x, y)
        if Input:isDown(self.keyB) and not self.hold then
            if other:grab(self) then
                self.hold = other
                self:gotoState('Lift')
            end
        end
        if y < self.pos.y and self.vel.y > 0 and self.pos.y < other.pos.y then
            self.vel.y = -Player.jumpVel
            self.y = y
            other:stomp()
        else
            self:getHit(other)
        end
    end,
    enemyFloat = function(self, dt, other, x, y)
        self:getHit(other)
    end
}

function Player:getHit(other)
    if not other:isHarmful() then return end
    if self.pos.x > other.pos.x then
        self.pushVel.x = 5
    else
        self.pushVel.x = -5
    end
    self.pushVel.y = -4
    self:gotoState('Hurt')
end

--[[======== NEUTRAL STATE ========]]

function Player.Neutral:update(dt)
    Player.update(self, dt)
end

--[[======== LIFT STATE ========]]

function Player.Lift:exitedState()
    if not self.hold then return end --TODO
    self.hold:release()
    self.hold = nil
end

function Player.Lift:update(dt)
    if self.hold then
        if Input:pressed(self.keyB) then
            local vel = Vector(0, 0)
            if Input:isDown(self.keyLeft) then vel.x = vel.x - 7 end
            if Input:isDown(self.keyRight) then vel.x = vel.x + 7 end
            if Input:isDown(self.keyUp) then vel.y = vel.y - 7 end
            if Input:isDown(self.keyDown) then vel.y = vel.y + 7 end
            self.hold.vel = vel
            self:gotoState('Neutral')
        end
    end
    Player.update(self, dt)
end

--[[======== HURT STATE ========]]

function Player.Hurt:enteredState()
    self.hurtTimer = 60
    if self.health > 0 then
        self.health = self.health - 1
    end
end

function Player.Hurt:update(dt)
    if self.hurtTimer > 0 then
        self.hurtTimer = self.hurtTimer - 1
    else
        self:gotoState('Neutral')
    end
    self.fire:emit(self.hurtTimer % 2)
    Player.update(self, dt)
end

function Player.Hurt:draw()
    if self.hurtTimer % 4 < 2 then
        love.graphics.setColor(255, 73, 73)
    end
    Player.draw(self)
    love.graphics.setColor(255, 255, 255)
end

function Player.Hurt:getHit() end

return Player
