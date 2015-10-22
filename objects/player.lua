local Class = require('middleclass')
local Object = require 'objects/object'
local Player = Class('player', Object)

local Powerup = require('powerup')
local Tile = require('objects/tile')
local Bullet = require 'objects/bullet'
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
    Object.initialize(self, collider, collider:rectangle(x, y, self.size:unpack()))
    self.tags = { 'player' }
    self.pos = Vector(x, y)
    self.offset.y = self.size.y/2

    self.moveVel = Vector(0, 0)
    self.pushVel = Vector(0, 0)
    self.ground = nil
    self.hold = nil
    self.jumpTimer = 0
    self.maxHealth = 6
    self.health = self.maxHealth
    self.activePower = Powerup:new()
    self.staticPowers = { [1] = Powerup:new(), [2] = Powerup:new() }

    self.animIdle = newAnimation(Player.sprIdle, 24, 24, 1/8, 0)
    self.animRun = newAnimation(Player.sprRun, 24, 24, 1/16, 0)
    self.animJump = newAnimation(Player.sprJump, 24, 24, 1/8, 0)
    self.animFall = newAnimation(Player.sprFall, 24, 24, 1/8, 0)
    self.sprite = self.animFall
    self:gotoState('Neutral')

    self.keyLeft = 'left'
    self.keyRight = 'right'
    self.keyUp = 'up'
    self.keyDown = 'down'
    self.keyA = 'z'
    self.keyB = 'x'
    self.keyC = 'c'

    self.dust = Particles.newDust()
    self.fire = Particles.newFire()
end

function Player:update(dt)
    self.vel.y = self.vel.y + Player.fallAcc

    local moveAcc = self.ground and Player.moveAccGround or Player.moveAccAir
    if self:hasPower(Powerup.names.coldFeet) and self.ground then
        moveAcc = moveAcc * 0.2
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
    elseif Input:isDown(self.keyLeft) then
        self.moveVel.x = self.moveVel.x - moveAcc
        self.direction.x = -1
        if self.ground then
            self.sprite = self.animRun
            if self.vel.x >= -moveAcc then
                self.dust:emit(1)
            end
        end
    elseif Input:isDown(self.keyRight) then
        self.moveVel.x = self.moveVel.x + moveAcc
        self.direction.x = 1
        if self.ground then
            self.sprite = self.animRun
            if self.vel.x <= moveAcc then
                self.dust:emit(1)
            end
        end
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
        if self.hurtTimer == 0 and self.ground:getState(self.pos.x) == Tile.names.fire then --TODO
            self.pushVel.y = -4 * self.direction.x
            self.pushVel.y = -4
            self:gotoState('Hurt')
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

    if Input:isDown(self.keyC) then
        self:useActivePower()
    end

    self.staticPowers[1]:update()
    self.staticPowers[2]:update()
    self.activePower:update()

    self.vel.x = self.moveVel.x + self.pushVel.x
    self.ground = nil
    Object.update(self, dt)
end

function Player:collide_solid(other, x, y)
    self.pos = Vector(x, y)
end

function Player:collide_platform(other, x, y)
    if y <= self.pos.y and self.vel.y >= 0 and self.pos.y - self.vel.y <= other.pos.y then
        self.vel.y = 0
        self.pos.y = y
        self.ground = other
        if self:hasPower(Powerup.names.coldFeet) and other.setState then
            other:setState(Tile.names.iced, self.pos.x)
            other:setState(Tile.names.iced, self.pos.x+16*self.direction.x)
            -- other:setState(Tile.names.iced, self.pos.x-16)
        end
    end
end

function Player:collide_lava(other, x, y)
    self.pos.y = y
    self.vel.y = -7
    self:gotoState('Hurt')
end

function Player:collide_enemy_rock(other, x, y)
    if y < self.pos.y and self.vel.y > 0 and self.pos.y < other.pos.y then
        self.vel.y = -Player.jumpVel
        self.y = y
        other:stomp()
        if Input:isDown(self.keyB) and other:grab(self) then
            self.hold = other
            self:gotoState('Lift')
        end
    else
        self:getHit(other)
    end
end

function Player:collide_enemy_float(other, x, y)
    if self:hasPower(Powerup.names.coldFeet) and y < self.pos.y and self.vel.y > 0 and self.pos.y < other.pos.y then
        self.vel.y = -Player.jumpVel
        self.y = y
        other:stomp()
    else
        self:getHit(other)
    end
end

function Player:collide_enemy_charge(other, x, y)
    if self:hasPower(Powerup.names.coldFeet) and y < self.pos.y and self.vel.y > 0 and self.pos.y < other.pos.y then
        self.vel.y = -Player.jumpVel
        self.y = y
        other:stomp()
    else
        self:getHit(other)
    end
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
    self.sprite:draw(x, y, 0, self.direction.x, 1, self.sprite:getWidth()/2, self.sprite:getHeight())
end

function Player:hasPower(power)
    if self.staticPowers[1].set and self.staticPowers[1].name == power then return true end
    if self.staticPowers[2].set and self.staticPowers[2].name == power then return true end
    if self.activePower.set and self.activePower.name == power then return true end
    return false
end

function Player:getPower(power)
    if self.staticPowers[1].set and self.staticPowers[1].name == power then
        return self.staticPowers[1]
    end
    if self.staticPowers[2].set and self.staticPowers[2].name == power then
        return self.staticPowers[2]
    end
    if self.activePower.set and self.activePower.name == power then
        return self.activePower
    end
    return nil
end

function Player:setPower(name)
    local power = Powerup.info[name]
    if power.active then
        self.activePower:setPower(name)
    else
        if not self.staticPowers[1].set then
            self.staticPowers[1]:setPower(name)
        else
            self.staticPowers[2]:setPower(name)
        end
    end
end

function Player:useActivePower()
    local power = self.activePower
    if not power.set then
        return
    end
    if power.name == Powerup.names.apple then
        power:use()
        self.health = self.maxHealth
    elseif power.name == Powerup.names.bubble then
        if power:use() then
            self:createBullet(Bullet.names.bubble)
        end
    elseif power.name == Powerup.names.star then
        if power:use() then
            self:createBullet(Bullet.names.star)
            self.pushVel = self:getAimDirection(true) * -5
        end
    elseif power.name == Powerup.names.flower then
        if power.timer == 0 then
            power:use()
            self:createBullet(Bullet.names.flower)
        end
    end
end

function Player:createBullet(type)
    local b = Bullet:new(type, self, self.bullets)
    table.insert(self.bullets, b)
end

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

function Player:getAimDirection(fixed)
    local dir = Vector(0, 0)
    if fixed then
        dir.x = self.direction.x
    end
    if Input:isDown(self.keyLeft) and not Input:isDown(self.keyRight) then
        dir.x = -1
    elseif Input:isDown(self.keyRight) then
        dir.x = 1
    end
    if Input:isDown(self.keyUp) and not Input:isDown(self.keyDown) then
        dir.y = -1
        if fixed then
            dir.x = 0
        end
    elseif Input:isDown(self.keyDown) then
        dir.y = 1
        if fixed then
            dir.x = 0
        end
    end
    return dir
end

--[[======== NEUTRAL STATE ========]]

function Player.Neutral:update(dt)
    Player.update(self, dt)
end

function Player.Neutral:collide_enemy_rock(other, x, y)
    if Input:isDown(self.keyB) and other:grab(self) then
        self.hold = other
        self:gotoState('Lift')
    else
        Player.collide_enemy_rock(self, other, x, y)
    end
end

--[[======== LIFT STATE ========]]

function Player.Lift:exitedState()
    if self.hold then --TODO
        self.hold:release()
        self.hold = nil
    end
end

function Player.Lift:update(dt)
    if self.hold then
        if Input:pressed(self.keyB) then
            self.hold.vel = self:getAimDirection() * 7
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

function Player.Hurt:collide_lava(other, x, y)
    self.pos.y = y
    self.vel.y = -7
end

function Player.Hurt:getHit() end

return Player
