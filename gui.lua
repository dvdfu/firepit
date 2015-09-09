local Class = require 'middleclass'
local GUI = Class('gui')
local Powerups = require 'powerups'

function GUI:initialize(player)
    self.player = player
end

function GUI:draw()
    local powerup = Powerups.power[self.player.powerup].icon
    love.graphics.draw(powerup, 32, 32)
end

return GUI
