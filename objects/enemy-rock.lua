require 'AnAL'
local Class = require 'middleclass'
local Enemy = require 'objects/enemy'
local EnemyRock = Class('enemy_rock', Enemy)

EnemyRock.static.sprMove = love.graphics.newImage('assets/enemy_walk.png')
EnemyRock.static.sprStun = love.graphics.newImage('assets/enemy_rock.png')
EnemyRock.static.sprStar = love.graphics.newImage('assets/star.png')
EnemyRock.static.sprParticle = love.graphics.newImage('assets/particle.png')

EnemyRock.collide_enemy = {
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

function EnemyRock:initialize(world, x, y)
    Enemy.initialize(self, world, x, y, 16, 16)
    self.name = 'enemy'
    self.player = nil

    self.vFall = 7
    self.aFall = 0.4
    self.vMove = 0.4

    self.stompTimer = 0
    self.holdTimer = 0
    self.throwTimer = 0

    self.animMove = newAnimation(EnemyRock.sprMove, 24, 24, 1/8, 0)
    self.animStun = newAnimation(EnemyRock.sprStun, 24, 24, 1/8, 0)
    self.animStar = newAnimation(EnemyRock.sprStar, 10, 10, 1/8, 0)

    self.dust = love.graphics.newParticleSystem(EnemyRock.sprParticle)
	self.dust:setParticleLifetime(0.1, 0.3)
	self.dust:setDirection(-math.pi/2)
    self.dust:setSpread(math.pi/2)
    self.dust:setAreaSpread('uniform', self.w/2, 0)
	self.dust:setSpeed(0, 100)
	self.dust:setColors(208, 190, 209, 255, 249, 239, 191, 255)
	self.dust:setSizes(1, 0)

    self.speck = love.graphics.newParticleSystem(EnemyRock.sprParticle)
    self.speck:setParticleLifetime(0, 0.5)
    self.speck:setDirection(-math.pi/2)
    self.speck:setSpread(math.pi/6)
    self.speck:setAreaSpread('normal', 4, 0)
    self.speck:setSpeed(10, 90)
    self.speck:setColors(255, 255, 0, 255, 255, 182, 0, 255, 255, 73, 73, 255, 146, 36, 36, 255)
    self.speck:setSizes(0.5, 0)

    self:gotoState('Move')
end

function EnemyRock:update(dt)
    self.vy = self.vy + self.aFall
    if self.vy > self.vFall then
        self.vy = self.vFall
    end
    if self.ground then
        self.x = self.x + self.ground.vx
        self.ground = nil
    end
    Enemy.update(self, dt)
end

function EnemyRock:draw()
    self.dust:setPosition(self.x+self.w/2, self.y+self.h)
    self.dust:update(1/60)
    love.graphics.draw(self.dust)

    self.speck:setPosition(self.x+self.w/2, self.y)
    self.speck:update(1/60)
    love.graphics.draw(self.speck)

    self.sprite:update(1/60)
    self.sprite:draw(self.x + self.w/2, self.y, 0, self.direction, 1, self.sprite:getWidth()/2, self.sprite:getHeight()-self.h)
end

function EnemyRock:stomp()
    self:gotoState('Stun')
end

function EnemyRock:grab(player)
    return false
end

function EnemyRock:release() end

--[[======== MOVE STATE ========]]

function EnemyRock.Move:enteredState()
    self.speck:setEmissionRate(10)
    self.sprite = self.animMove
    self.sprite.speed = 1
    self.vx = self.vMove * self.direction
end

function EnemyRock.Move:update(dt)
    self.direction = self.vx > 0 and 1 or -1
    EnemyRock.update(self, dt)
end

--[[======== STUN STATE ========]]

EnemyRock.Stun = EnemyRock:addState('Stun')

function EnemyRock.Stun:enteredState()
    self.speck:setEmissionRate(0)
    self.sprite = self.animStun
    self.stompTimer = 4*60
    self.sprite.speed = 0
end

function EnemyRock.Stun:update(dt)
    self.vx = self.vx * 0.6
    self.stompTimer = self.stompTimer - 1
    EnemyRock.update(self, dt)
    self.animStar:update(dt)
    if self.stompTimer <= 0 then
        self:gotoState('Move')
    end
end

function EnemyRock.Stun:draw()
    EnemyRock.draw(self)
    local numStars = math.ceil(self.stompTimer/60)
    for i = 1, numStars do
        local sx = self.x+self.w/2-5 + 12*math.cos(self.stompTimer/20 + i/numStars*2*math.pi)
        local sy = self.y-12 + 6*math.sin(self.stompTimer/20 + i/numStars*2*math.pi)
        self.animStar:draw(sx, sy)
    end
end

function EnemyRock.Stun:grab(player)
    self.player = player
    self:gotoState('Hold')
    return true
end

--[[======== HOLD STATE ========]]

EnemyRock.Hold = EnemyRock:addState('Hold')

function EnemyRock.Hold:enteredState()
    self.sprite = self.animStun
    self.sprite.speed = 0
    self.holdTimer = 0
    self.vx = 0
    self.vy = 0
end

function EnemyRock.Hold:exitedState()
    if self.player and self.player.hold == self then
        self.player.hold = nil
    end
end

function EnemyRock.Hold:update(dt)
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

function EnemyRock.Hold:stomp() end

function EnemyRock.Hold:hit() end

function EnemyRock.Hold:release()
    self:gotoState('Throw')
end

--[[======== THROW STATE ========]]

EnemyRock.Throw = EnemyRock:addState('Throw')

EnemyRock.Throw.collide_enemy = {
    type = 'cross',
    func = function(self, col)
        col.other:hit(self)
    end
}

function EnemyRock.Throw:enteredState()
    self.throwTimer = 0
end

function EnemyRock.Throw:update(dt)
    self.direction = self.vx > 0 and 1 or -1
    if self.ground then
        self.vx = self.vx * 0.9
    else
        self.vx = self.vx * 0.99
    end

    EnemyRock.update(self, dt)
    self.sprite.speed = math.abs(self.vx)

    if self.ground then
        self.dust:emit(self.sprite.speed)
        if self.throwTimer == 0 then
            cs = 10
        end
        if self.throwTimer < 30 and math.abs(self.vx) > 0.1 then
            self.throwTimer = self.throwTimer + 1
        else
            self:gotoState('Stun')
        end
    end
end

--[[======== THROW STATE ========]]

function EnemyRock.Dead:update(dt)
    self.deadTimer = self.deadTimer + 1
    self.vy = self.vy + self.aFall
    self.vx = self.vx * 0.98
    self.x = self.x + self.vx
    self.y = self.y + self.vy
end

return EnemyRock
