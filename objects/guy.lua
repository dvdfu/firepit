local Class = require('middleclass')
local Object = require 'objects/object'
local Player = Class('player', Object)

local Vector = require('vector')
require('AnAL')

Player.static.sprIdle = love.graphics.newImage('assets/images/player/dragon_idle.png')
Player.static.sprRun = love.graphics.newImage('assets/images/player/dragon_move.png')
Player.static.sprJump = love.graphics.newImage('assets/images/player/dragon_jump.png')
Player.static.sprFall = love.graphics.newImage('assets/images/player/dragon_fall.png')
Player.static.sprParticle = love.graphics.newImage('assets/images/particles/dot.png')

Player.static.moveVel = 2
Player.static.moveAccAir = 0.2
Player.static.moveAccGround = 0.3
Player.static.jumpVel = 4.5
Player.static.jumpTimerMax = 10
Player.static.fallVel = 7
Player.static.fallAcc = 0.3

function Player:initialize(collider, x, y)
    self.size = Vector(10, 22)
    Object.initialize(self, collider:addRectangle(x, y, self.size:unpack()))
    self.tags = { 'player' }
    self.pos = Vector(x, y)
    self.offset.y = self.size.y/2

    self.mx = 0
    self.ground = nil
    self.jumpTimer = 0
    self.direction = 1

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

    self.dust = love.graphics.newParticleSystem(Player.sprParticle)
    self.dust:setParticleLifetime(0.1, 0.3)
    self.dust:setDirection(-math.pi/2)
    self.dust:setSpread(math.pi/2)
    self.dust:setAreaSpread('normal', 4, 0)
    self.dust:setSpeed(0, 100)
    self.dust:setColors(208, 190, 209)
    self.dust:setSizes(1, 0)
end

function Player:update(dt)
    self.vel.y = self.vel.y + Player.fallAcc

    local moveAcc = self.ground and Player.moveAccGround or Player.moveAccAir
    if Input:isDown(self.keyLeft) and not Input:isDown(self.keyRight) then
        self.mx = self.mx - moveAcc
        if self.ground then
            self.sprite = self.animRun
            self.direction = -1
            if self.vel.x >= -moveAcc then
                self.dust:emit(1)
            end
        end
    end
    if Input:isDown(self.keyRight) and not Input:isDown(self.keyLeft) then
        self.mx = self.mx + moveAcc
        if self.ground then
            self.sprite = self.animRun
            self.direction = 1
            if self.vel.x <= moveAcc then
                self.dust:emit(1)
            end
        end
    end
    if Input:isDown(self.keyLeft) == Input:isDown(self.keyRight) then
        if self.mx > moveAcc then
            self.mx = self.mx - moveAcc
        elseif self.mx < -moveAcc then
            self.mx = self.mx + moveAcc
        else
            self.mx = 0
        end
        self.sprite = self.animIdle
    end
    if self.mx < -Player.moveVel then
        self.mx = -Player.moveVel
    elseif self.mx > Player.moveVel then
        self.mx = Player.moveVel
    end
    self.vel.x = self.mx

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

    self.ground = nil
    Object.update(self, dt)
end

function Player:draw()
    self.dust:setPosition(self.pos.x, self.pos.y)
    self.dust:update(1/60)
    love.graphics.draw(self.dust)

    self.sprite:update(1/60)
    self.sprite.speed = math.abs(self.vel.x/Player.moveVel)
    self.sprite:draw(self.pos.x, self.pos.y, 0, self.direction, 1, self.sprite:getWidth()/2, self.sprite:getHeight())
    -- Object.draw(self)
end

Player.static.collisions = {
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
    end
}

return Player
