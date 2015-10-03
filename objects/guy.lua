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
    self.keyB = 'x'

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
    end,
    enemy_rock = function(self, dt, other, x, y)
        if y < self.pos.y and self.vel.y > 0 and self.pos.y < other.pos.y then
            self.vel.y = -Player.jumpVel
            self.y = y
            other:stomp()
        else
            if Input:isDown(self.keyB) then
                if other:grab(self) then
                    self.hold = other
                    self:gotoState('Lift')
                end
            end
            -- self:getHit(other)
        end
    end
}

function Player:getHit(other)
    if other:isHarmful() then
        self:gotoState('Hurt')
        if self.x > other.x then
            self.px = 5
        else
            self.px = -5
        end
        self.py = -4
    end
end

--[[======== NORMAL STATE ========]]

Player.Normal = Player:addState('Normal')

-- Player.Normal.collisions = {
--     enemy_rock = {
--         type = 'cross',
--         func = function(self, col)
--             Player.collisions.enemy_rock.func(self, col)
--             if Input:isDown(Player.keyB) then
--                 if col.other:grab(self) then
--                     self.hold = col.other
--                     self:gotoState('Lift')
--                 end
--             end
--         end
--     }
-- }

function Player.Normal:update(dt)
    Player.update(self, dt)
    if not self.ground then
        self.sprite = self.vel.y < 0 and self.animJump or self.animFall
    end
end

--[[======== LIFT STATE ========]]

Player.Lift = Player:addState('Lift')

function Player.Lift:exitedState()
    -- self.hold:release()
    -- self.hold = nil
end

function Player.Lift:update(dt)
    Player.update(self, dt)
    -- if not self.ground then
    --     self.sprite = self.vel.y < 0 and self.animJumpLift or self.animFallLift
    -- end

    -- if self.hold and self.hold.holdTimer >= 20 and Input:pressed(Player.keyB) then
    --     local rx, ry = 0, 0
    --     if Input:isDown(Player.keyLeft) then rx = rx - 7 end
    --     if Input:isDown(Player.keyRight) then rx = rx + 7 end
    --     if Input:isDown(Player.keyUp) then ry = ry - 7 end
    --     if Input:isDown(Player.keyDown) then ry = ry + 7 end
    --     self.hold.vel.x, self.hold.vel.y = rx, ry
    --     self:gotoState('Normal')
    -- end
end

--[[======== HURT STATE ========]]

Player.Hurt = Player:addState('Hurt')

function Player.Hurt:enteredState()
    self.hurtTimer = 60
    if self.health > 0 then
        self.health = self.health - 1
    end
end

function Player.Hurt:update(dt)
    Player.update(self, dt)
    if not self.ground then
        self.sprite = self.vel.y < 0 and self.animJump or self.animFall
    end
    if self.hurtTimer > 0 then
        self.hurtTimer = self.hurtTimer - 1
    else
        self:gotoState('Normal')
    end
    if self.hurtTimer % 2 == 0 then
        self.fire:emit(1)
    end
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
