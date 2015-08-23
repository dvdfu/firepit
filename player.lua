local Class = require 'middleclass'
local Object = require 'object'
local Player = Class('player', Object)

local _vJump = 7
local _vFall = 10
local _aFall = 0.4
local _vMove = 2
local _aMoveAir = 0.1
local _aMoveGround = 0.5

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
			if col.normal.y == -1 then
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
            if col.normal.y == -1 and self.vy > _aFall then
                col.other:stomp()
                self.vy = -_vJump
            end
        end
    }
}

function Player:initialize(world, x, y)
    self.name = 'player'
    self.world = world
    self.x, self.y = x, y
    self.vx, self.vy = 0, 0
    self.w, self.h = 24, 24
    self.ground = nil
    world:add(self, x, y, self.w, self.h)
end

function Player:update(dt)
    local aMove = self.ground and _aMoveGround or _aMoveAir
    if love.keyboard.isDown('left') then
        self.vx = self.vx - aMove
        if self.vx < -_vMove then
            self.vx = -_vMove
        end
    elseif love.keyboard.isDown('right') then
        self.vx = self.vx + aMove
        if self.vx > _vMove then
            self.vx = _vMove
        end
    else
        if self.vx > aMove then
            self.vx = self.vx - aMove
        elseif self.vx < -aMove then
            self.vx = self.vx + aMove
        else
            self.vx = 0
        end
    end

    if self.ground then
        if love.keyboard.isDown('up') then
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
end

return Player
