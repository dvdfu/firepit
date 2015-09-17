local Class = require 'middleclass'
local Tile = Class('tile')

Tile.static.sprParticle = love.graphics.newImage('assets/images/particles/diamond.png')
Tile.static.sprIce = love.graphics.newImage('assets/images/stage/tile_ice.png')
Tile.static.state = {
    iced = 'iced'
}

function Tile:initialize(x, y)
    self.x, self.y = x, y
    self.w = 16
    self.state = ''
    self.stateTimer = 0

    self.frost = love.graphics.newParticleSystem(Tile.sprParticle)
    self.frost:setParticleLifetime(0.1, 0.5)
    self.frost:setDirection(-math.pi/2)
    self.frost:setSpread(math.pi/2)
    self.frost:setAreaSpread('normal', 4, 0)
    self.frost:setSpeed(0, 50)
    self.frost:setColors(255, 255, 255, 255, 120, 180, 255, 255)
    self.frost:setSizes(1, 0)
    self.frost:setPosition(self.x+self.w/2, self.y)
    self.frost:setEmissionRate(2)
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
    if self.state == Tile.state.iced then
        self.frost:update(1/60)
        -- if self.stateTimer < 10 then
        --     love.graphics.setColor(255, 255, 255, 255*self.stateTimer/10)
        -- end
        love.graphics.draw(self.frost)
        love.graphics.draw(Tile.sprIce, self.x, self.y)
        -- love.graphics.setColor(255, 255, 255, 255)
    end
end

function Tile:setState(state)
    self.state = state
    if state == Tile.state.iced then
        self.stateTimer = 5*60
    end
end

function Tile:getState()
    return self.state
end

return Tile
