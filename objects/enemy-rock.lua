local Tile = require 'objects/tile'
local Class = require 'middleclass'
local Enemy = require 'objects/enemy'
local EnemyRock = Class('enemy_rock', Enemy)

local Vector = require('vector')
require 'AnAL'

EnemyRock.static.sprMove = love.graphics.newImage('assets/images/enemies/rock_move.png')
EnemyRock.static.sprStun = love.graphics.newImage('assets/images/enemies/rock_stun.png')
EnemyRock.static.sprStar = love.graphics.newImage('assets/images/enemies/star.png')
EnemyRock.static.sprParticle = love.graphics.newImage('assets/images/particles/dot.png')

EnemyRock.static.collisions = {
    solid = function(self, dt, other, x, y)
        if self.pos.x ~= x then
            self.direction = self.direction * -1
        end
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
    -- end,
    -- player = function(self, dt, other, x, y)
    --     if y > self.pos.y and other.vel.y > 0 and other.pos.y < self.pos.y then
    --         other.vel.y = -5
    --         self:stomp()
    --     end
    end
}

EnemyRock.static.fallVel = 7
EnemyRock.static.fallAcc = 0.4
EnemyRock.static.moveVel = 0.4

function EnemyRock:initialize(collider, x, y)
    self.pos = Vector(x, y)
    self.size = Vector(16, 16)
    Enemy.initialize(self, collider:addRectangle(x, y, self.size:unpack()))
    self.tags = { 'enemyRock' }
    self.offset.y = self.size.y/2

    self.health = 3
    self.player = nil

    self.animMove = newAnimation(EnemyRock.sprMove, 24, 24, 1/8, 0)
    self.animStun = newAnimation(EnemyRock.sprStun, 24, 24, 1/8, 0)
    self.animStar = newAnimation(EnemyRock.sprStar, 10, 10, 1/8, 0)

    self.dust = love.graphics.newParticleSystem(EnemyRock.sprParticle)
	self.dust:setParticleLifetime(0.1, 0.3)
	self.dust:setDirection(-math.pi/2)
    self.dust:setSpread(math.pi/2)
    self.dust:setAreaSpread('uniform', self.size.x/2, 0)
	self.dust:setSpeed(0, 100)
	self.dust:setColors(208, 190, 209, 255, 249, 239, 191, 255)
	self.dust:setSizes(1, 0)

    self:gotoState('Move')
end

function EnemyRock:update(dt)
    self.vel.y = self.vel.y + EnemyRock.static.fallAcc
    if self.vel.y > EnemyRock.fallVel then
        self.vel.y = EnemyRock.fallVel
    end
    self.ground = nil
    Enemy.update(self, dt)
end

function EnemyRock:draw()
    self.dust:setPosition(self.pos.x+self.size.x/2, self.pos.y+self.size.y)
    self.dust:update(1/60)
    love.graphics.draw(self.dust)

    self.sprite:update(1/60)
    self.sprite:draw(self.pos.x, self.pos.y, 0, self.direction, 1, self.sprite:getWidth()/2, self.sprite:getHeight())
end

function EnemyRock:stomp()
    self:gotoState('Stun')
end

function EnemyRock:grab(player)
    return false
end

function EnemyRock:release() end

--[[======== MOVE STATE ========]]

EnemyRock.Move = EnemyRock:addState('Move')

-- EnemyRock.Move.collisions = {
--     lava = {
--         type = 'cross',
--         func = function(self, col)
--             col.other:touch(self.pos.x, true)
--             self:gotoState('Dead')
--             self.deadTimer = 60
--         end
--     }
-- }

function EnemyRock.Move:enteredState()
    self.sprite = self.animMove
    self.sprite.speed = 1
end

function EnemyRock.Move:update(dt)
    self.vel.x = EnemyRock.moveVel * self.direction
    -- if self.ground and self.ground.class.name == 'solid' then
    --     if self.ground:getState(self.pos.x+self.size.x/2) == Tile.state.iced then
    --         self.vel.x = EnemyRock.moveVel/4 * self.direction
    --     else
    --         self.vel.x = EnemyRock.moveVel * self.direction
    --     end
    -- end
    EnemyRock.update(self, dt)
end

function EnemyRock.Move:isHarmful()
    return true
end

--[[======== STUN STATE ========]]

EnemyRock.Stun = EnemyRock:addState('Stun')

function EnemyRock.Stun:enteredState()
    self.sprite = self.animStun
    self.stompTimer = 4*60
    self.sprite.speed = 0
    self.vel.x = 0
end

function EnemyRock.Stun:update(dt)
    EnemyRock.update(self, dt)
    self.animStar:update(dt)
    if self.stompTimer > 0 then
        self.stompTimer = self.stompTimer - 1
    else
        self:gotoState('Move')
    end
end

function EnemyRock.Stun:draw()
    EnemyRock.draw(self)
    local numStars = math.ceil(self.stompTimer/60)
    for i = 1, numStars do
        local sx = self.pos.x + 12*math.cos(self.stompTimer/20 + i/numStars*2*math.pi)
        local sy = self.pos.y + 6*math.sin(self.stompTimer/20 + i/numStars*2*math.pi)
        self.animStar:draw(sx, sy - self.size.y, 0, 1, 1, 5, 5)
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
    self.size.yoldTimer = 0
    self.vel.x = 0
    self.vel.y = 0
end

function EnemyRock.Hold:exitedState()
    if self.player and self.player.hold == self then
        self.player.hold = nil
    end
end

function EnemyRock.Hold:update(dt)
    if self.size.yoldTimer < 20 then
        local dx, dy = (self.player.x+self.player.w/2-self.size.x/2)-self.pos.x, (self.player.y-self.size.y)-self.pos.y
        self.pos.x = self.pos.x + dx*self.size.yoldTimer/20
        self.pos.y = self.pos.y + dy*self.size.yoldTimer/20
        self.size.yoldTimer = self.size.yoldTimer + 1
    else
        self.pos.x, self.pos.y = self.player.x+self.player.w/2-self.size.x/2, self.player.y-self.size.y
    end
    self.size.xorld:update(self, self.pos.x, self.pos.y)
end

function EnemyRock.Hold:stomp() end

function EnemyRock.Hold:hit() end

function EnemyRock.Hold:release()
    self:gotoState('Throw')
end

--[[======== THROW STATE ========]]

EnemyRock.Throw = EnemyRock:addState('Throw')

EnemyRock.Throw.collisions = {
    enemy = {
        type = 'cross',
        func = function(self, col)
            col.other:hit(self, 8)
        end
    -- },
    -- enemy_rock = {
    --     type = 'cross',
    --     func = EnemyRock.Throw.collisions.enemy.func
    }
}

function EnemyRock.Throw:enteredState()
    self.throwTimer = 0
end

function EnemyRock.Throw:update(dt)
    self.direction = self.vel.x > 0 and 1 or -1
    if self.ground then
        self.vel.x = self.vel.x * 0.9
    else
        self.vel.x = self.vel.x * 0.99
    end

    EnemyRock.update(self, dt)
    self.sprite.speed = math.abs(self.vel.x)

    if self.ground then
        self.dust:emit(self.sprite.speed)
        if self.throwTimer == 0 then
            cs = 10
        end
        if self.throwTimer < 30 and math.abs(self.vel.x) > 0.1 then
            self.throwTimer = self.throwTimer + 1
        else
            self:gotoState('Stun')
        end
    end
end

function EnemyRock.Throw:stomp() end

--[[======== Hit STATE ========]]

EnemyRock.Hit = EnemyRock:addState('Hit')

function EnemyRock.Hit:enteredState()
    self.size.yitTimer = 2
end

function EnemyRock.Hit:update(dt)
    if self.size.yitTimer == 0 then
        self:popState()
    else
        self.size.yitTimer = self.size.yitTimer-1
    end
end

function EnemyRock.Hit:draw()
    love.graphics.setColor(255, 0, 0)
    EnemyRock.draw(self)
    love.graphics.setColor(255, 255, 255)
end

function EnemyRock.Hit:hit() end

--[[======== DEAD STATE ========]]

EnemyRock.Dead = EnemyRock:addState('Dead')

function EnemyRock.Dead:enteredState()
    -- self.dropItem(self.pos.x, self.pos.y) --TODO
    self.size.xorld:remove(self)
    self.deadTimer = 0
    self.vel.y = -4
end

function EnemyRock.Dead:update(dt)
    self.deadTimer = self.deadTimer + 1
    self.vel.y = self.vel.y + EnemyRock.static.fallAcc
    self.vel.x = self.vel.x * 0.98
    self.pos.x = self.pos.x + self.vel.x
    self.pos.y = self.pos.y + self.vel.y
end

function EnemyRock.Dead:hit() end

function EnemyRock.Dead:isDead()
    return self.deadTimer > 60 --TODO
end

return EnemyRock
