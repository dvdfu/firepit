local Class = require 'middleclass'
local GUI = Class('gui')
local Powerups = require 'powerups'

function GUI:initialize(player)
    love.graphics.setLineWidth(1)
    self.player = player
end

function GUI:draw()
    if self.player.powerup then
        local powerup = Powerups.power[self.player.powerup].icon
        love.graphics.draw(powerup, 16, 16)
        love.graphics.rectangle('line', 16, 16, 32, 32)
    end

    local bar = 12
    for i = 1, self.player.health do
        love.graphics.setColor(255, 255, 255, 200)
        love.graphics.rectangle('fill', 64+(i-1)*bar, 16, bar, 8)
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.rectangle('line', 64+(i-1)*bar, 16, bar, 8)
    end
    love.graphics.rectangle('line', 64, 16, self.player.maxHealth*bar, 8)
end

return GUI
