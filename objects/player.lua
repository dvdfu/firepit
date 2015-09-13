require 'AnAL'
local Tile = require 'objects/tile'
local Powerups = require 'powerups'
local Enemy = require 'objects/enemy'
local Class = require 'middleclass'
local Object = require 'objects/object'
local Player = Class('player', Object)

local _vJump = 4.5
local _vFall = 7
local _aFall = 0.3
local _vMove = 2
local _aMoveAir = 0.2
local _aMoveGround = 0.3
local _jumpTimerMax = 10

Player.static.keyLeft = 'left'
Player.static.keyRight = 'right'
Player.static.keyUp = 'up'
Player.static.keyDown = 'down'
Player.static.keyA = 'z'
Player.static.keyB = 'x'
Player.static.keyC = 'c'

Player.static.sprIdle = love.graphics.newImage('assets/images/player/idle.png')
Player.static.sprRun = love.graphics.newImage('assets/images/player/move.png')
Player.static.sprJump = love.graphics.newImage('assets/images/player/jump.png')
Player.static.sprFall = love.graphics.newImage('assets/images/player/fall.png')
Player.static.sprIdleLift = love.graphics.newImage('assets/images/player/idle_lift.png')
Player.static.sprRunLift = love.graphics.newImage('assets/images/player/move_lift.png')
Player.static.sprJumpLift = love.graphics.newImage('assets/images/player/jump_lift.png')
Player.static.sprFallLift = love.graphics.newImage('assets/images/player/fall_lift.png')
Player.static.sprParticle = love.graphics.newImage('assets/images/particles/dot.png')

Player.collide_solid = {
    type = 'slide',
    func = function(self, col)
        if col.normal.y ~= 0 then
            self.vy = 0
            if col.normal.y == -1 then
                self.ground = col.other
                if self:hasPower(Powerups.coldFeet) then
                    col.other:setState(Tile.state.iced, self.x+self.w/2)
                    col.other:setState(Tile.state.iced, self.x+self.w/2+16*self.direction)
                end
            end
        end
        if col.normal.x ~= 0 then
            self.vx = 0
        end
    end
}

Player.collide_platform = {
    type = 'cross',
    func = function(self, col)
        if col.normal.y == -1 and self.y+self.h-self.vy <= col.other.y then
            self.vy = 0
            self.y = col.other.y - self.h
            self.world:update(self, self.x, self.y)
            self.ground = col.other
            if self:hasPower(Powerups.coldFeet) then
                col.other:setState(Tile.state.iced, self.x+self.w/2)
                col.other:setState(Tile.state.iced, self.x+self.w/2-16)
                col.other:setState(Tile.state.iced, self.x+self.w/2+16)
            end
        end
    end
}

Player.collide_enemy_rock = {
    type = 'cross',
    func = function(self, col)
        if col.normal.y == -1 and self.vy > 0 and self.y+self.h-self.vy <= col.other.y then
            self.vy = -_vJump
            self.y = col.other.y - self.h
            self.world:update(self, self.x, self.y)
            col.other:stomp()
        else
            self:getHit(col.other)
        end
    end
}

Player.collide_enemy_float = {
    type = 'cross',
    func = function(self, col)
        if self:hasPower(Powerups.coldFeet) and col.normal.y == -1 and self.vy > 0 and self.y+self.h-self.vy <= col.other.y then
            self.vy = -_vJump
            self.y = col.other.y - self.h
            self.world:update(self, self.x, self.y)
            col.other:stomp()
        else
            self:getHit(col.other)
        end
    end
}

Player.collide_lava = {
    type = 'cross',
    func = function(self, col)
        self.vy = -7
        self.y = col.other.level - self.h
        self.world:update(self, self.x, self.y)
        self:gotoState('Hurt')
    end
}

Player.collide_item = {
    type = 'cross',
    func = function(self, col)
        if Input:isDown(Player.keyDown) then
            col.other:grab(self)
        end
    end
}

function Player:initialize(world, x, y)
    Object.initialize(self, world, x, y, 8, 20)
    table.insert(self.tags, Player.name)

    self.ground = nil
    self.direction = self.vx > 0 and 1 or -1
    self.hold = nil
    self.mx = 0 --move
    self.px, self.py = 0, 0 --push
    self.jumpTimer = 0
    self.glideTimer = 0

    self.staticPowers = {}
    table.insert(self.staticPowers, Powerups.coldFeet)
    table.insert(self.staticPowers, Powerups.jumpGlide)
    self.maxHealth = 6
    self.health = self.maxHealth

    self.animIdle = newAnimation(Player.sprIdle, 24, 24, 1/8, 0)
    self.animRun = newAnimation(Player.sprRun, 24, 24, 1/12, 0)
    self.animJump = newAnimation(Player.sprJump, 24, 24, 1/8, 0)
    self.animFall = newAnimation(Player.sprFall, 24, 24, 1/8, 0)
    self.animIdleLift = newAnimation(Player.sprIdleLift, 24, 24, 1/8, 0)
    self.animRunLift = newAnimation(Player.sprRunLift, 24, 24, 1/12, 0)
    self.animJumpLift = newAnimation(Player.sprJumpLift, 24, 24, 1/8, 0)
    self.animFallLift = newAnimation(Player.sprFallLift, 24, 24, 1/8, 0)
    self.sprite = self.animRun
    self:gotoState('Normal')

    self.dust = love.graphics.newParticleSystem(Player.sprParticle)
    self.dust:setParticleLifetime(0.1, 0.3)
    self.dust:setDirection(-math.pi/2)
    self.dust:setSpread(math.pi/2)
    self.dust:setAreaSpread('normal', 4, 0)
    self.dust:setSpeed(0, 100)
    self.dust:setColors(208, 190, 209, 255, 249, 239, 191, 255)
    self.dust:setSizes(1, 0)

    self.fire = love.graphics.newParticleSystem(Player.sprParticle)
    self.fire:setParticleLifetime(0.1, 0.3)
    self.fire:setDirection(-math.pi/2)
    self.fire:setSpread(math.pi/4)
    self.fire:setAreaSpread('normal', 4, 4)
    self.fire:setSpeed(0, 200)
    self.fire:setColors(255, 255, 0, 255, 255, 182, 0, 255, 255, 73, 73, 255, 146, 36, 36, 255)
    self.fire:setSizes(2, 0)
end

function Player:update(dt)
    local aMove = self.ground and _aMoveGround or _aMoveAir
    if self:hasPower(Powerups.coldFeet) and self.ground then
        aMove = aMove * 0.2
    end
    if Input:isDown(Player.keyLeft) then
        if self.vx >= -aMove and self.ground then
            self.dust:emit(1)
        end
        self.mx = self.mx - aMove
        if self.mx < -_vMove then
            self.mx = -_vMove
        end
        self.direction = -1
        self.sprite = self.hold and self.animRunLift or self.animRun
    elseif Input:isDown(Player.keyRight) then
        if self.vx <= aMove and self.ground then
            self.dust:emit(1)
        end
        self.mx = self.mx + aMove
        if self.mx > _vMove then
            self.mx = _vMove
        end
        self.direction = 1
        self.sprite = self.hold and self.animRunLift or self.animRun
    else
        if self.mx > aMove then
            self.mx = self.mx - aMove
        elseif self.mx < -aMove then
            self.mx = self.mx + aMove
        else
            self.mx = 0
        end
        self.sprite = self.hold and self.animIdleLift or self.animIdle
    end

    if self.ground then
        self.jumpTimer = 0
        self.glideTimer = 0
        if Input:pressed(Player.keyA) then
            self.vy = -_vJump
            self.jumpTimer = _jumpTimerMax
            self.ground = nil
            self.dust:emit(10)
        end
    else
        if Input:isDown(Player.keyA) then
            if self.jumpTimer > 0 then
                self.vy = -_vJump
                self.jumpTimer = self.jumpTimer - 1
            end
        else
            self.jumpTimer = 0
        end
    end

    if self.glideTimer > 0 and not Input:isDown(Player.keyA) then
        self.glideTimer = 120
    end

    if self:hasPower(Powerups.jumpGlide) and not self.ground and Input:isDown(Player.keyA) and self.jumpTimer == 0 and self.vy >= 0 and self.glideTimer < 120 then
        self.vy = 0
        self.glideTimer = self.glideTimer+1
    else
        self.vy = self.vy + _aFall
        if self.vy > _vFall then
            self.vy = _vFall
        end
    end

    self.vx = self.mx + self.px
    if self.py ~= 0 then
        self.vy = self.py
        self.py = 0
    end
    if math.abs(self.px) > 0.1 then
        self.px = self.px * 0.9
    else
        self.px = 0
    end
    self.x = self.x + self.vx
    self.y = self.y + self.vy
    self.ground = nil
    self:collide()
end

function Player:draw()
    self.dust:setPosition(self.x+self.w/2, self.y+self.h)
    self.dust:update(1/60)
    love.graphics.draw(self.dust)

    self.fire:setPosition(self.x+self.w/2, self.y+self.h/2)
    self.fire:update(1/60)
    love.graphics.draw(self.fire)

    local dx, dy = math.floor(self.x+self.w/2 + 0.5), math.floor(self.y+self.h + 0.5)
    self.sprite:update(1/60)
    self.sprite:draw(dx, dy, 0, self.direction, 1, self.sprite:getWidth()/2, self.sprite:getHeight())
end

function Player:hasPower(power)
    for _, p in ipairs(self.staticPowers) do
        if p == power then
            return true
        end
    end
    return false
end

function Player:getPowerTimer(power)
    if power == Powerups.jumpGlide then
        return self.glideTimer / 120
    end
    return 0
end

function Player:getPowerUses(power)
    if power == Powerups.jumpGlide then
        return 1
    end
    return -1
end

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

Player.Normal.collide_enemy_rock = {
    type = 'cross',
    func = function(self, col)
        Player.collide_enemy_rock.func(self, col)
        if Input:isDown(Player.keyB) then
            if col.other:grab(self) then
                self.hold = col.other
                self:gotoState('Lift')
            end
        end
    end
}

function Player.Normal:update(dt)
    Player.update(self, dt)
    if not self.ground then
        self.sprite = self.vy < 0 and self.animJump or self.animFall
    end
end

--[[======== LIFT STATE ========]]

Player.Lift = Player:addState('Lift')

function Player.Lift:exitedState()
    self.hold:release()
    self.hold = nil
end

function Player.Lift:update(dt)
    Player.update(self, dt)
    if not self.ground then
        self.sprite = self.vy < 0 and self.animJumpLift or self.animFallLift
    end

    if self.hold and self.hold.holdTimer >= 20 and Input:pressed(Player.keyB) then
        local rx, ry = 0, 0
        if Input:isDown(Player.keyLeft) then rx = rx - 7 end
        if Input:isDown(Player.keyRight) then rx = rx + 7 end
        if Input:isDown(Player.keyUp) then ry = ry - 7 end
        if Input:isDown(Player.keyDown) then ry = ry + 7 end
        self.hold.vx, self.hold.vy = rx, ry
        self:gotoState('Normal')
    end
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
        self.sprite = self.vy < 0 and self.animJump or self.animFall
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
