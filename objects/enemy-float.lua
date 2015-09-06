require 'AnAL'
local Class = require 'middleclass'
local Enemy = require 'objects/enemy'
local EnemyFloat = Class('enemy_float', Enemy)

EnemyFloat.static.sprMove = love.graphics.newImage('assets/enemy_float_move.png')
EnemyFloat.static.sprParticle = love.graphics.newImage('assets/particle.png')

EnemyFloat.collide_enemy = {
    type = 'cross',
    func = function(self, col)
    end
}

function EnemyFloat:initialize(world, x, y)
    Enemy.initialize(self, world, x, y, 24, 24)
    table.insert(self.tags, EnemyFloat.name)
    self.player = nil

    self.vFall = 7
    self.aFall = 0.02
    self.vMove = 0.4

    self.moveTimer = 0
    self.stompTimer = 0
    self.holdTimer = 0
    self.throwTimer = 0

    self.animMove = newAnimation(EnemyFloat.sprMove, 32, 32, 1/8, 0)

    self.speck = love.graphics.newParticleSystem(EnemyFloat.sprParticle)
    self.speck:setParticleLifetime(0, 0.3)
    self.speck:setDirection(-math.pi/2)
    self.speck:setSpread(math.pi/4)
    self.speck:setAreaSpread('normal', 4, 2)
    self.speck:setSpeed(0, 30)
    self.speck:setColors(255, 255, 0, 255, 255, 182, 0, 255, 255, 73, 73, 255, 146, 36, 36, 255)
    self.speck:setSizes(1, 0)

    self:gotoState('Move')
end

function EnemyFloat:update(dt)
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

function EnemyFloat:draw()
    self.speck:setPosition(self.x+self.w/2, self.y+self.h/2)
    self.speck:update(1/60)
    love.graphics.draw(self.speck)

    self.sprite:update(1/60)
    local dy = 6*math.sin(self.moveTimer/12)
    self.sprite:draw(self.x + self.w/2, self.y+dy, 0, self.direction, 1, self.sprite:getWidth()/2, self.sprite:getHeight()-self.h)
end

function EnemyFloat:release() end

--[[======== MOVE STATE ========]]

EnemyFloat.Move = EnemyFloat:addState('Move')

EnemyFloat.Move.collide_lava = {
    type = 'cross',
    func = function(self, col)
        col.other:touch(self.x, true)
        self:gotoState('Dead')
        self.deadTimer = 60
    end
}

function EnemyFloat.Move:enteredState()
    self.moveTimer = 0
    self.speck:setEmissionRate(50)
    self.sprite = self.animMove
    self.sprite.speed = 1
    self.vx = self.vMove * self.direction
end

function EnemyFloat.Move:update(dt)
    self.moveTimer = self.moveTimer + 1
    self.direction = self.vx > 0 and 1 or -1
    EnemyFloat.update(self, dt)
end

function EnemyFloat.Move:isHarmful()
    return true
end

--[[======== DEAD STATE ========]]

EnemyFloat.Dead = EnemyFloat:addState('Dead')

function EnemyFloat.Dead:enteredState()
    self.speck:emit(40)
    self.world:remove(self)
    self.vx = 0
    self.vy = 0
    self.deadTimer = 0
end

function EnemyFloat.Dead:update(dt)
    self.deadTimer = self.deadTimer + 1
end

function EnemyFloat.Dead:hit() end

function EnemyFloat.Dead:isDead()
    return self.deadTimer > 20
end

return EnemyFloat
