require 'AnAL'
local Class = require 'middleclass'
local Object = require 'object'
local Enemy = Class('enemy', Object)

Enemy.static.sprWalk = love.graphics.newImage('assets/enemy_walk.png')
Enemy.static.sprRock = love.graphics.newImage('assets/enemy_rock.png')
Enemy.static.sprStar = love.graphics.newImage('assets/star.png')

Enemy.static.collisions = {
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
                self.vx = -self.vx
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
            if col.normal.x ~= 0 then
                self.vx = -self.vx
            end
        end
    }
}

local _vFall = 10
local _vMove = 4

function Enemy:initialize(world, x, y)
    Object.initialize(self, world, x, y, 16, 16)
    self.name = 'enemy'
    self.vx, self.vy = 0.4, 0
    self.ground = nil
    self.state = 'walk'
    self.direction = self.vx > 0 and 1 or -1

    self.stompTimer = 0
    self.animWalk = newAnimation(Enemy.sprWalk, 24, 24, 1/8, 0)
    self.animRock = newAnimation(Enemy.sprRock, 24, 24, 1/8, 0)
    self.animStar = newAnimation(Enemy.sprStar, 10, 10, 1/8, 0)
	self.sprite = self.animWalk
end

local function update(self, dt)
    self.vy = self.vy + 0.4
    if self.vy > _vFall then
        self.vy = _vFall
    end

    self.x = self.x + self.vx
    self.y = self.y + self.vy
    self.ground = nil
    self:collide()

    self.sprite:update(dt)
    self.animStar:update(dt)
end

function Enemy:update(dt)
    self.direction = self.vx > 0 and 1 or -1
    update(self, dt)
end

function Enemy:draw()
    self.sprite:draw(self.x + self.w/2, self.y, 0, self.direction, 1, self.sprite:getWidth()/2, self.sprite:getHeight()-self.h)
    if self.stompTimer > 0 then
        local numStars = math.ceil(self.stompTimer/60)
        for i = 1, numStars do
            local sx = self.x+self.w/2-5 + 12*math.cos(self.stompTimer/20 + i/numStars*2*math.pi)
            local sy = self.y-12 + 6*math.sin(self.stompTimer/20 + i/numStars*2*math.pi)
            self.animStar:draw(sx, sy)
        end
    end
    -- love.graphics.rectangle('line', self.x, self.y, self.w, self.h)
end

function Enemy:stomp()
    self:gotoState('Rock')
end

local Rock = Enemy:addState('Rock')

function Rock:update(dt)
    if self.stompTimer > 0 then
        self.stompTimer = self.stompTimer - 1
    else
        self:gotoState(nil)
    end
    update(self, dt)
end

function Rock:exitedState()
    self.sprite = self.animWalk
    self.vx = self.direction*0.4
end

function Rock:enteredState()
    self.sprite = self.animRock
    self.stompTimer = 5*60
    self.vx = 0
    self.sprite.speed = 0
end

return Enemy
