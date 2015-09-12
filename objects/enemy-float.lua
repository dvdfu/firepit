require 'AnAL'
local Tile = require 'objects/tile'
local Class = require 'middleclass'
local Enemy = require 'objects/enemy'
local EnemyFloat = Class('enemy_float', Enemy)

EnemyFloat.static.sprMove = love.graphics.newImage('assets/enemy_float_move.png')
EnemyFloat.static.sprDead = love.graphics.newImage('assets/enemy_float_dead.png')
EnemyFloat.static.sprParticle = love.graphics.newImage('assets/particle.png')

EnemyFloat.static.glowShader = love.graphics.newShader[[
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = vec4(0.6, 0.4, 0.1, 1);
        vec2 d = 2.0*(texture_coords - vec2(0.5));
        pixel.a = 1.0 - length(d);
        pixel.a = floor(pixel.a*5)/5;
        return pixel * color;
    }
]]

EnemyFloat.collide_platform = {
    type = 'cross',
    func = function(self, col)
        Enemy.collide_platform.func(self, col)
    end
}

EnemyFloat.collide_enemy = {
    type = 'cross',
    func = function(self, col) end
}

function EnemyFloat:initialize(world, x, y)
    Enemy.initialize(self, world, x, y, 16, 32)
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
    self.animDead = newAnimation(EnemyFloat.sprDead, 32, 32, 1/8, 0)
    self.animDead:setMode('once')

    self.speck = love.graphics.newParticleSystem(EnemyFloat.sprParticle)
    self.speck:setParticleLifetime(0, 0.4)
    self.speck:setDirection(-math.pi/2)
    self.speck:setSpread(math.pi/4)
    self.speck:setAreaSpread('normal', 4, 2)
    self.speck:setSpeed(0, 30)
    self.speck:setColors(255, 255, 0, 255, 255, 182, 0, 255, 255, 73, 73, 255, 146, 36, 36, 255)
    self.speck:setSizes(1, 0)
    self.speck:setPosition(self.x+self.w/2, self.y+self.h/2)

    self.explosion = love.graphics.newParticleSystem(EnemyFloat.sprParticle)
    self.explosion:setParticleLifetime(0, 0.5)
    self.explosion:setSpread(math.pi*2)
    self.explosion:setAreaSpread('normal', 4, 4)
    self.explosion:setSpeed(0, 100)
    self.explosion:setColors(255, 255, 0, 255, 255, 255, 0, 255, 255, 182, 0, 255, 255, 73, 73, 255, 146, 36, 36, 255)
    self.explosion:setSizes(2, 0)

    self.explosion = love.graphics.newParticleSystem(EnemyFloat.sprParticle)
    self.explosion:setParticleLifetime(0, 0.5)
    self.explosion:setSpread(math.pi*2)
    self.explosion:setAreaSpread('normal', 4, 4)
    self.explosion:setSpeed(0, 100)
    self.explosion:setColors(255, 255, 0, 255, 255, 255, 0, 255, 255, 182, 0, 255, 255, 73, 73, 255, 146, 36, 36, 255)
    self.explosion:setSizes(2, 0)

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
    if self.ground and self.ground:getState(self.x+self.w/2) == Tile.state.iced then
        self:gotoState('Dead')
    end
end

function EnemyFloat:draw()
    local dy = 4*math.sin(self.moveTimer/12)

    love.graphics.setColor(255, 255, 255, 255-255*self.deadTimer/60)
    love.graphics.setBlendMode('additive')
    love.graphics.setShader(EnemyFloat.glowShader)
    love.graphics.draw(EnemyFloat.sprParticle, self.x+self.w/2, self.y+self.h/2+dy, 0, 8, 8, EnemyFloat.sprParticle:getWidth()/2, EnemyFloat.sprParticle:getHeight()/2)
    love.graphics.setShader()
    love.graphics.setBlendMode('alpha')
    love.graphics.setColor(255, 255, 255, 255)

    self.speck:setPosition(self.x+self.w/2, self.y+self.h/2)
    self.speck:update(1/60)
    love.graphics.draw(self.speck)

    self.explosion:setPosition(self.x+self.w/2, self.y+self.h/2)
    self.explosion:update(1/60)
    love.graphics.draw(self.explosion)

    if self.sprite ~= self.animDead or self.sprite:getCurrentFrame() < self.sprite:getSize() then
        self.sprite:update(1/60)
        self.sprite:draw(self.x + self.w/2, self.y+dy, 0, self.direction, 1, self.sprite:getWidth()/2, self.sprite:getHeight()-self.h)
    end
    -- Enemy.draw(self)
end

function EnemyFloat:stomp()
    self:gotoState('Dead')
end

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
-- self.explosion:setEmissionRate(40)
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
    -- self.dropItem(self.x, self.y) --TODO
    self.speck:setEmissionRate(0)
    self.explosion:emit(50)
    self.world:remove(self)
    self.sprite = self.animDead
    self.vx = 0
    self.vy = 0
    self.deadTimer = 0
end

function EnemyFloat.Dead:update(dt)
    self.deadTimer = self.deadTimer + 1
end

function EnemyFloat.Dead:hit() end

function EnemyFloat.Dead:isDead()
    return self.deadTimer > 60
    -- return self.sprite:getCurrentFrame() == self.sprite:getSize()
end

function EnemyFloat.Dead:stomp() end

return EnemyFloat
