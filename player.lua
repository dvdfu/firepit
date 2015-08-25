require 'AnAL'
local Class = require 'middleclass'
local Object = require 'object'
local Player = Class('player', Object)

local _vJump = 7
local _vFall = 10
local _aFall = 0.3
local _vMove = 2
local _aMoveAir = 0.2
local _aMoveGround = 0.5

Player.static.sprIdle = love.graphics.newImage('assets/player_idle.png')
Player.static.sprRun = love.graphics.newImage('assets/player_run.png')
Player.static.sprJump = love.graphics.newImage('assets/player_jump.png')
Player.static.sprFall = love.graphics.newImage('assets/player_fall.png')

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
            if col.normal.y == -1 and self.vy > _aFall and self.y+self.h-self.vy <= col.other.y then
                col.other:stomp()
                self.vy = -_vJump*0.7
            end
        end
    }
}

function Player:initialize(world, x, y)
    Object.initialize(self, world, x, y, 16, 24)
    self.name = 'player'
    self.ground = nil
    self.jumpTimer = 0
    self.direction = self.vx > 0 and 1 or -1

    self.animIdle = newAnimation(Player.sprIdle, 24, 24, 1/8, 0)
    self.animRun = newAnimation(Player.sprRun, 24, 24, 1/12, 0)
    self.animJump = newAnimation(Player.sprJump, 24, 24, 1/8, 0)
    self.animFall = newAnimation(Player.sprFall, 24, 24, 1/8, 0)
    self.sprite = self.animRun
end

function Player:update(dt)
    local aMove = self.ground and _aMoveGround or _aMoveAir
    if love.keyboard.isDown('a') then
        self.vx = self.vx - aMove
        if self.vx < -_vMove then
            self.vx = -_vMove
        end
        self.direction = -1
        self.sprite = self.animRun
    elseif love.keyboard.isDown('d') then
        self.vx = self.vx + aMove
        if self.vx > _vMove then
            self.vx = _vMove
        end
        self.direction = 1
        self.sprite = self.animRun
    else
        if self.vx > aMove then
            self.vx = self.vx - aMove
        elseif self.vx < -aMove then
            self.vx = self.vx + aMove
        else
            self.vx = 0
        end
        self.sprite = self.animIdle
    end

    if self.ground then
        if love.keyboard.isDown('w') then
            self.vy = -_vJump
            self.ground = nil
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

    if not self.ground then
        self.sprite = self.vy < 0 and self.animJump or self.animFall
    end
    self.sprite:update(dt)
end

function Player:draw()
    -- Object.draw(self)
    self.sprite:draw(self.x+self.w/2, self.y+self.h, 0, self.direction, 1, self.sprite:getWidth()/2, self.sprite:getHeight())
end

return Player
