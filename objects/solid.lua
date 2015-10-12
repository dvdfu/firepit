local Class = require 'middleclass'
local Tile = require 'objects/tile'
local Object = require 'objects/object'
local Solid = Class('solid', Object)

local Vector = require('vector')

Solid.static.sprTerrain = love.graphics.newImage('assets/images/stage/terrain.png')
Solid.static.sprTop = love.graphics.newImage('assets/images/stage/terrain_top.png')

function Solid:initialize(collider, x, y, w, h, color, solid)
    Object.initialize(self, collider, collider:rectangle(x, y, w, h))
    self.immobile = true
    self:addTag('tiled')
    self:addTag('platform')
    if solid then self:addTag('solid') end
    self.pos = Vector(x, y)
    self.size = Vector(w, h)
    self.offset = -self.size / 2
    self.color = color or { r = 104, g = 96, b = 160 }
    self:render()

    self.tiles = {}
    for i = 0, self.size.x/16 - 1, 1 do
        self.tiles[i] = Tile:new(self.pos.x+i*16, self.pos.y)
    end
end

function Solid:update(dt)
    for i = 0, #self.tiles do
        self.tiles[i]:update(dt)
    end
end

function Solid:move() end

function Solid:draw()
    love.graphics.draw(self.image, self.pos:unpack())
    for i = 0, #self.tiles do
        self.tiles[i]:draw()
    end
end

function Solid:setState(state, x)
    local i = math.floor((x-self.pos.x)/16)
    if i < 0 then
        i = 0
    elseif i > #self.tiles then
        i = #self.tiles
    end
    self.tiles[i]:setState(state)
end

function Solid:getState(x)
    local i = math.floor((x-self.pos.x)/16)
    if i < 0 or i > #self.tiles then
        return nil
    end
    return self.tiles[i]:getState()
end

function Solid:render()
    local image = love.graphics.newCanvas(self.size:unpack())
    local oldCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas(image)
    love.graphics.setColor(self.color.r, self.color.g, self.color.b)
    love.graphics.setStencil(function()
        love.graphics.rectangle('fill', 0, 0, self.size:unpack())
    end)
    for i = 0, self.size.x, 32 do
        for j = 0, self.size.y, 32 do
            love.graphics.draw(Solid.sprTerrain, i, j)
        end
    end
    love.graphics.setStencil()

    local altColor = {
        r = math.min(255, self.color.r*2.5),
        g = math.min(255, self.color.g*2),
        b = math.min(255, self.color.b*2)
    }
    love.graphics.setColor(altColor.r, altColor.g, altColor.b)
    for i = 0, self.size.x, 32 do
        love.graphics.draw(Solid.sprTop, i, 0)
    end
    love.graphics.setColor(255, 255, 255)
    love.graphics.setCanvas(oldCanvas)
    self.image = love.graphics.newImage(image:getImageData())
end

return Solid
