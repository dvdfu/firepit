local Class = require 'middleclass'
local Tile = require 'objects/tile'
local Object = require 'objects/object'
local Solid = Class('solid', Object)

Solid.static.sprite = love.graphics.newImage('assets/images/stage/terrain.png')

function Solid:initialize(world, x, y, w, h, color, platform)
    Object.initialize(self, world, x, y, w, h)
    table.insert(self.tags, Solid.name)
    if platform then
        table.insert(self.tags, 'platform')
    end
    self.color = color or { r = 104, g = 96, b = 160 }
    self.image = love.graphics.newCanvas(self.w, self.h)
    self:redraw()

    self.tiles = {}
    for i = 0, self.w/16-1, 1 do
        self.tiles[i] = Tile:new(self.x+i*16, self.y)
    end
end

function Solid:update(dt)
    for i = 0, #self.tiles do
        self.tiles[i]:update(dt)
    end
end

function Solid:draw()
    love.graphics.draw(self.image, self.x, self.y)
    for i = 0, #self.tiles do
        self.tiles[i]:draw()
    end
end

function Solid:setState(state, x)
    local i = math.floor((x-self.x)/16)
    if i < 0 then
        i = 0
    elseif i > #self.tiles then
        i = #self.tiles
    end
    self.tiles[i]:setState(state)
end

function Solid:getState(x)
    local i = math.floor((x-self.x)/16)
    if i < 0 or i > #self.tiles then
        return nil
    end
    return self.tiles[i]:getState()
end

function Solid:redraw()
    self.image:clear()
    local oldCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas(self.image)
    love.graphics.setColor(self.color.r, self.color.g, self.color.b)
    love.graphics.setStencil(function()
        love.graphics.rectangle('fill', 0, 0, self.w, self.h)
    end)
    for i = 0, self.w, 32 do
        for j = 0, self.h, 32 do
            love.graphics.draw(Solid.sprite, i, j)
        end
    end
    love.graphics.setStencil()

    love.graphics.setColor(200, 144, 200)
    love.graphics.setLineWidth(4)
    love.graphics.line(0, 2, self.w, 2)
    love.graphics.setColor(255, 255, 255)
    love.graphics.setCanvas(oldCanvas)
end

return Solid
