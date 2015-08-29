require 'AnAL'
local Class = require 'middleclass'
local Object = require 'objects/object'
local Player = Class('player', Object)

local _vJump = 7
local _vFall = 7
local _aFall = 0.3
local _vMove = 2
local _aMoveAir = 0.2
local _aMoveGround = 0.5

Player.static.keyLeft = 'left'
Player.static.keyRight = 'right'
Player.static.keyUp = 'up'
Player.static.keyDown = 'down'
Player.static.keyA = 'z'
Player.static.keyB = 'x'

Player.static.sprIdle = love.graphics.newImage('assets/player_idle.png')
Player.static.sprRun = love.graphics.newImage('assets/player_run.png')
Player.static.sprJump = love.graphics.newImage('assets/player_jump.png')
Player.static.sprFall = love.graphics.newImage('assets/player_fall.png')
Player.static.sprIdleLift = love.graphics.newImage('assets/player_idle_lift.png')
Player.static.sprRunLift = love.graphics.newImage('assets/player_run_lift.png')
Player.static.sprJumpLift = love.graphics.newImage('assets/player_jump_lift.png')
Player.static.sprFallLift = love.graphics.newImage('assets/player_fall_lift.png')
Player.static.sprParticle = love.graphics.newImage('assets/particle.png')

Player.static.collisions = {
    solid = {
        type = 'slide',
        func = function(self, col)
			if col.normal.y ~= 0 then
				self.vy = 0
				if col.normal.y == -1 then
					self.ground = col.other
				end
			end
            if col.normal.x ~= 0 then
                self.vx = 0
            end
        end
    },
    platform = {
        type = 'cross',
        func = function(self, col)
			if col.normal.y == -1 and self.y+self.h-self.vy <= col.other.y then
				self.vy = 0
                self.y = col.other.y - self.h
                self.world:update(self, self.x, self.y)
				self.ground = col.other
			end
        end
    },
    enemy = {
        type = 'cross',
        func = function(self, col)
            local grabbed = false
            if Input:isDown(Player.keyB) and not self.hold then
                grabbed = col.other:grab(self)
            end
            if not grabbed and col.normal.y == -1 and self.vy > _aFall and self.y+self.h-self.vy <= col.other.y then
                col.other:stomp()
                self.vy = -_vJump*0.7
            end
        end
    },
    lava = {
        type = 'bounce',
        func = function(self, col)
            self.vy = -self.vy
            -- TODO
        end
    },
    item = {
        type = 'cross',
        func = function(self, col)
            if Input:isDown(Player.keyDown) then
                col.other:grab(self)
            end
        end
    }
}

function Player:initialize(world, x, y)
    Object.initialize(self, world, x, y, 16, 24)
    self.name = 'player'
    self.ground = nil
    self.direction = self.vx > 0 and 1 or -1
    self.hold = nil

    self.animIdle = newAnimation(Player.sprIdle, 24, 24, 1/8, 0)
    self.animRun = newAnimation(Player.sprRun, 24, 24, 1/12, 0)
    self.animJump = newAnimation(Player.sprJump, 24, 24, 1/8, 0)
    self.animFall = newAnimation(Player.sprFall, 24, 24, 1/8, 0)
    self.animIdleLift = newAnimation(Player.sprIdleLift, 24, 24, 1/8, 0)
    self.animRunLift = newAnimation(Player.sprRunLift, 24, 24, 1/12, 0)
    self.animJumpLift = newAnimation(Player.sprJumpLift, 24, 24, 1/8, 0)
    self.animFallLift = newAnimation(Player.sprFallLift, 24, 24, 1/8, 0)
    self.sprite = self.animRun

    self.dust = love.graphics.newParticleSystem(Player.sprParticle)
	self.dust:setParticleLifetime(0.1, 0.3)
	self.dust:setDirection(-math.pi/2)
    self.dust:setSpread(math.pi/2)
    self.dust:setAreaSpread('normal', 4, 0)
	self.dust:setSpeed(0, 100)
	self.dust:setColors(208, 190, 209, 255, 249, 239, 191, 255)
	self.dust:setSizes(2, 0)
end

function Player:update(dt)
    local aMove = self.ground and _aMoveGround or _aMoveAir
    if Input:isDown(Player.keyLeft) then
        self.vx = self.vx - aMove
        if self.vx < -_vMove then
            self.vx = -_vMove
        end
        self.direction = -1
        self.sprite = self.hold and self.animRunLift or self.animRun
    elseif Input:isDown(Player.keyRight) then
        self.vx = self.vx + aMove
        if self.vx > _vMove then
            self.vx = _vMove
        end
        self.direction = 1
        self.sprite = self.hold and self.animRunLift or self.animRun
    else
        if self.vx > aMove then
            self.vx = self.vx - aMove
        elseif self.vx < -aMove then
            self.vx = self.vx + aMove
        else
            self.vx = 0
        end
        self.sprite = self.hold and self.animIdleLift or self.animIdle
    end

    if self.ground then
        if Input:pressed(Player.keyA) then
            self.vy = -_vJump
            self.ground = nil
            self.dust:setPosition(self.x+self.w/2, self.y+self.h)
            self.dust:emit(10)
        end
    end

    self.vy = self.vy + _aFall
    if self.vy > _vFall then
        self.vy = _vFall
    end

    self.x = self.x + self.vx
    self.y = self.y + self.vy
    self.ground = nil
    self:collide()

    if self.hold and self.hold.holdTimer >= 20 and Input:pressed(Player.keyB) then
        local rx, ry = 0, 0
        if Input:isDown(Player.keyLeft) then rx = rx - 7 end
        if Input:isDown(Player.keyRight) then rx = rx + 7 end
        if Input:isDown(Player.keyUp) then ry = ry - 7 end
        if Input:isDown(Player.keyDown) then ry = ry + 7 end
        self.hold.vx, self.hold.vy = rx, ry
        self.hold:release()
        self.hold = nil
    end

    if not self.ground then
        self.sprite = self.vy < 0 and (self.hold and self.animJumpLift or self.animJump) or (self.hold and self.animFallLift or self.animFall)
    end
    self.sprite:update(dt)
    self.dust:update(dt)
end

function Player:draw()
    -- Object.draw(self)
	love.graphics.draw(self.dust)
    local dx, dy = math.floor(self.x+self.w/2 + 0.5), math.floor(self.y+self.h + 0.5)
    self.sprite:draw(dx, dy, 0, self.direction, 1, self.sprite:getWidth()/2, self.sprite:getHeight())
end

return Player
