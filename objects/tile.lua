local Class = require 'middleclass'
local Tile = Class('tile')
local Vector = require('vector')
local Particles = require('objects/particles')

Tile.static.sprParticle = love.graphics.newImage('assets/images/particles/diamond.png')
Tile.static.sprIce = love.graphics.newImage('assets/images/stage/tile_ice.png')
Tile.static.state = {
    iced = 'iced'
}

function Tile:initialize(x, y)
    self.pos = Vector(x, y)
    self.width = 16
    self.state = ''
    self.stateTimer = 0

    self.frost = Particles.newFrost()
    self.frost:setPosition(self.pos.x + self.width/2, self.pos.y)
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
        love.graphics.draw(self.frost)
        love.graphics.draw(Tile.sprIce, self.pos.x, self.pos.y)
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
