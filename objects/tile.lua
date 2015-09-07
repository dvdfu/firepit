local Class = require 'middleclass'
local Tile = Class('tile')

Tile.static.sprParticle = love.graphics.newImage('assets/particle2.png')

Tile.static.states = {
    ice = 'ice'
}

function Tile:initialize(x, y)
    self.x, self.y = x, y
    self.w = 16
    self.state = ''--Tile.states.ice
    self.stateTimer = 0

    self.frost = love.graphics.newParticleSystem(Tile.sprParticle)
    self.frost:setParticleLifetime(0.1, 0.3)
    self.frost:setDirection(-math.pi/2)
    self.frost:setSpread(math.pi/2)
    self.frost:setAreaSpread('normal', 4, 0)
    self.frost:setSpeed(0, 100)
    -- self.frost:setColors(208, 190, 209, 255, 249, 239, 191, 255)
    self.frost:setSizes(1, 0)
    self.frost:setPosition(self.x+self.w/2, self.y-4)
    self.frost:setEmissionRate(4)
end

function Tile:update(dt)
    if self.stateTimer > 0 then
        self.stateTimer = self.stateTimer-1
        if self.stateTimer == 0 then
            self.state = ''
        end
    end
end

function Tile:draw()
    if self.state == 'ice' then
        self.frost:update(1/60)
        love.graphics.draw(self.frost)
        love.graphics.rectangle('fill', self.x, self.y, self.w, 4)
    end
end

function Tile:setState(state)
    self.state = state
    if state == 'ice' then
        self.stateTimer = 3*60
    end
end

function Tile:getState()
    return self.state
end

return Tile
