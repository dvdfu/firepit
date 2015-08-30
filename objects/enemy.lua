require 'AnAL'
local Class = require 'middleclass'
local Object = require 'objects/object'
local Enemy = Class('enemy', Object)

Enemy.static.sprMove = love.graphics.newImage('assets/enemy_walk.png')
Enemy.static.sprStun = love.graphics.newImage('assets/enemy_rock.png')
Enemy.static.sprStar = love.graphics.newImage('assets/star.png')
Enemy.static.sprParticle = love.graphics.newImage('assets/particle.png')

Enemy.static.moveState = 'Move'
Enemy.static.stunState = 'Stun'
Enemy.static.holdState = 'Hold'
Enemy.static.thrownState = 'Thrown'
Enemy.static.deadState = 'Dead'

Enemy.collide_solid = {
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
}

Enemy.collide_platform = {
    type = 'cross',
    func = function(self, col)
        if col.normal.y == -1 and self.y+self.h-self.vy <= col.other.y then
			self.vy = 0
            self.y = col.other.y - self.h
            self.world:update(self, self.x, self.y)
			self.ground = col.other
		end
    end
}

Enemy.collide_enemy = {
    type = 'cross',
    func = function(self, col)
        if col.normal.y == -1 and self.y+self.h-self.vy <= col.other.y then
            self.vy = 0
            self.y = col.other.y - self.h
            self.world:update(self, self.x, self.y)
            self.ground = col.other
        end
        if col.normal.x ~= 0 then
            if col.normal.x == 1 then
                self.x = col.other.x + col.other.w
            else
                self.x = col.other.x - self.w
            end
            self.world:update(self, self.x, self.y)
            self.vx = -self.vx
        end
    end
}

Enemy.collide_lava = {
    type = 'cross',
    func = function(self, col)
        col.other:touch(self.x, self.state == Enemy.moveState)
        self:gotoState(Enemy.deadState)
        self.deadTimer = 60
    end
}

local _vFall = 7
local _aFall = 0.4
local _vMove = 0.4

function Enemy:initialize(world, x, y)
    Object.initialize(self, world, x, y, 16, 16)
    self.name = 'enemy'
    self.vx, self.vy = 0, 0
    self.ground = nil
    self.player = nil

    self.stompTimer = 0
    self.holdTimer = 0
    self.throwTimer = 0
    self.deadTimer = 0

    self.animMove = newAnimation(Enemy.sprMove, 24, 24, 1/8, 0)
    self.animStun = newAnimation(Enemy.sprStun, 24, 24, 1/8, 0)
    self.animStar = newAnimation(Enemy.sprStar, 10, 10, 1/8, 0)
    self.direction = math.random() > 0.5 and -1 or 1
    self:gotoState(Enemy.moveState)

    self.dust = love.graphics.newParticleSystem(Enemy.sprParticle)
	self.dust:setParticleLifetime(0.1, 0.3)
	self.dust:setDirection(-math.pi/2)
    self.dust:setSpread(math.pi/2)
    self.dust:setAreaSpread('uniform', self.w/2, 0)
	self.dust:setSpeed(0, 100)
	self.dust:setColors(208, 190, 209, 255, 249, 239, 191, 255)
	self.dust:setSizes(1, 0)
end

function Enemy:update(dt)
    self.vy = self.vy + _aFall
    if self.vy > _vFall then
        self.vy = _vFall
    end
    self.x = self.x + self.vx
    self.y = self.y + self.vy
    if self.ground then
        self.x = self.x + self.ground.vx
        self.ground = nil
    end
    self:collide()
end

function Enemy:draw()
    self.dust:setPosition(self.x+self.w/2, self.y+self.h)
    self.dust:update(1/60)
    love.graphics.draw(self.dust)

    self.sprite:update(1/60)
    self.sprite:draw(self.x + self.w/2, self.y, 0, self.direction, 1, self.sprite:getWidth()/2, self.sprite:getHeight()-self.h)
end

function Enemy:stomp()
    self:gotoState(Enemy.stunState)
end

function Enemy:hit(enemy)
    self.vx = enemy.vx/2
    self:gotoState(Enemy.deadState)
end

function Enemy:grab(player) end

function Enemy:isDead()
    return false
end

-- MOVE STATE
local Move = Enemy:addState(Enemy.moveState)

function Move:enteredState()
    self.state = Enemy.moveState
    self.sprite = self.animMove
    self.sprite.speed = 1
    self.vx = _vMove * self.direction
end

function Move:update(dt)
    self.direction = self.vx > 0 and 1 or -1
    Enemy.update(self, dt)
end

-- STUN STATE
local Stun = Enemy:addState(Enemy.stunState)

function Stun:enteredState()
    -- cs = 6 -- TODO
    self.state = Enemy.stunState
    self.sprite = self.animStun
    self.stompTimer = 4*60
    self.sprite.speed = 0
end

function Stun:update(dt)
    self.vx = self.vx * 0.6
    self.stompTimer = self.stompTimer - 1
    Enemy.update(self, dt)
    self.animStar:update(dt)
    if self.stompTimer <= 0 then
        self:gotoState(Enemy.moveState)
    end
end

function Stun:draw()
    Enemy.draw(self)
    local numStars = math.ceil(self.stompTimer/60)
    for i = 1, numStars do
        local sx = self.x+self.w/2-5 + 12*math.cos(self.stompTimer/20 + i/numStars*2*math.pi)
        local sy = self.y-12 + 6*math.sin(self.stompTimer/20 + i/numStars*2*math.pi)
        self.animStar:draw(sx, sy)
    end
end

function Stun:grab(player)
    player.hold = self
    self.player = player
    self:gotoState(Enemy.holdState)
end

-- HOLD STATE
local Hold = Enemy:addState(Enemy.holdState)

function Hold:enteredState()
    self.state = Enemy.holdState
    self.sprite = self.animStun
    self.sprite.speed = 0
    self.holdTimer = 0
    self.vx = 0
    self.vy = 0
end

function Hold:exitedState()
    if self.player and self.player.hold == self then
        self.player.hold = nil
    end
end

function Hold:update(dt)
    if self.holdTimer < 20 then
        local dx, dy = self.player.x - self.x, self.player.y-14 - self.y
        self.x = self.x + dx*self.holdTimer/20
        self.y = self.y + dy*self.holdTimer/20
        self.holdTimer = self.holdTimer + 1
    else
        self.x, self.y = self.player.x, self.player.y-14
    end
    self.world:update(self, self.x, self.y)
end

function Hold:stomp() end

function Hold:hit() end

-- THROWN STATE
local Thrown = Enemy:addState(Enemy.thrownState)

Thrown.collide_enemy = {
    type = 'cross',
    func = function(self, col)
        col.other:hit(self)
    end
}

function Thrown:enteredState()
    self.state = Enemy.thrownState
    self.throwTimer = 0
end

function Thrown:update(dt)
    self.direction = self.vx > 0 and 1 or -1
    Enemy.update(self, dt)
    self.sprite.speed = math.abs(self.vx)

    if self.ground then
        self.vx = self.vx * 0.9
        self.dust:emit(self.sprite.speed)
        if self.throwTimer == 0 then
            cs = 10
        end
        if self.throwTimer < 30 and math.abs(self.vx) > 0.1 then
            self.throwTimer = self.throwTimer + 1
        else
            self:gotoState(Enemy.stunState)
        end
    else
        self.vx = self.vx * 0.99
    end
end

-- DEAD STATE
local Dead = Enemy:addState(Enemy.deadState)

function Dead:enteredState()
    self.state = Enemy.deadState
    self.world:remove(self)
    -- self.dropItem(self.x, self.y) --TODO
    self.deadTimer = 0
    self.vy = -8
end

function Dead:update(dt)
    self.deadTimer = self.deadTimer + 1
    self.vy = self.vy + _aFall
    self.vx = self.vx * 0.98
    self.x = self.x + self.vx
    self.y = self.y + self.vy
end

function Dead:stomp() end

function Dead:hit() end

function Dead:isDead()
    return self.deadTimer > 60 --TODO
end

return Enemy
