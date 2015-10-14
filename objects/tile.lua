local Class = require ('middleclass')
local Stateful = require ('stateful')
local Tile = Class('tile')
Tile:include(Stateful)
local Vector = require('vector')
local Particles = require('objects/particles')
require 'AnAL'

Tile.static.names = {
    default = 'Default',
    iced = 'Iced',
    fire = 'Fire'
}

Tile.static.info = {
    Default = {
        name = 'Default',
        sprite = nil,
        duration = -1
    },
    Iced = {
        name = 'Iced',
        sprite = love.graphics.newImage('assets/images/stage/tile_ice.png'),
        duration = 5*60,
        particles = 'Frost'
    },
    Fire = {
        name = 'Fire',
        sprite = love.graphics.newImage('assets/images/stage/tile_fire.png'),
        animated = true,
        offset = Vector(0, 16),
        duration = 1*60,
        particles = 'FireSpeck'
    }
}

Tile.Default = Tile:addState('Default')
Tile.Iced = Tile:addState('Iced')
Tile.Fire = Tile:addState('Fire')

function Tile:initialize(x, y)
    self.pos = Vector(x, y)
    self.width = 16
    self:setState('Default')
end

function Tile:update()
    if self.stateTimer > 0 then
        self.stateTimer = self.stateTimer-1
    else
        self:setState('Default')
    end
end

function Tile:draw()
    if self.sprite then
        if self.animated then
            self.sprite:update(1/60)
            self.sprite:draw(self.pos.x, self.pos.y, 0, 1, 1, self.offset:unpack())
        else
            love.graphics.draw(self.sprite, self.pos.x, self.pos.y, 0, 1, 1, self.offset:unpack())
        end
    end
    if self.particles then
        self.particles:update(1/60)
        love.graphics.draw(self.particles)
    end
end

function Tile:setState(name)
    local info = Tile.info[name]
    if not info then return end

    self.state = name
    self.animated = info.animated or false
    if self.animated then
        self.sprite = newAnimation(info.sprite, info.sprite:getHeight(), info.sprite:getHeight(), 1/8, 0)
    else
        self.sprite = info.sprite or nil
    end
    self.offset = info.offset or Vector(0, 0)
    self.stateTimer = info.duration or 0
    if info.particles then
        self.particles = Particles['new'..info.particles]() or nil --TODO
        self.particles:setPosition(self.pos.x+8, self.pos.y)
    end
    self:gotoState(name)
end

function Tile:getState()
    return self.state
end

--[[======== DEFAULT STATE ========]]

function Tile.Default:enteredState()
    if self.particles then
        self.particles:setEmissionRate(0)
    end
end

--[[======== FIRE STATE ========]]

function Tile.Fire:enteredState()
    self.particles:setEmissionRate(8)
    self.particles:setParticleLifetime(0.1, 0.6)
    self.particles:setSpeed(10, 100)
    self.particles:setAreaSpread('uniform', 8, 0)
end

return Tile
