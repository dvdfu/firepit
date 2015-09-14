local Class = require 'middleclass'
local GUI = Class('gui')
local Powerup = require 'powerup'

GUI.static.numberFont = love.graphics.newFont('assets/fonts/04b_21.ttf', 8)

function GUI:initialize(player)
    love.graphics.setLineWidth(1)
    self.player = player
end

function GUI:draw()
    self:drawPower(self.player.staticPowers[1], 1)
    self:drawPower(self.player.staticPowers[2], 2)
    self:drawPower(self.player.activePower, 3)

    local bar = 12
    for i = 1, self.player.health do
        love.graphics.setColor(255, 255, 255, 200)
        love.graphics.rectangle('fill', 16+(i-1)*bar, 56, bar, 8)
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.rectangle('line', 16+(i-1)*bar, 56, bar, 8)
    end
    love.graphics.rectangle('line', 16, 56, self.player.maxHealth*bar, 8)
end

function GUI:drawPower(power, i)
    local x, y = 16+(i-1)*40, 16
    love.graphics.rectangle('line', x, y, 33, 33)
    if not power.set then return end

    love.graphics.draw(power.info.icon, x, y)

    local uses = power.uses
    local fill = power:getIconFill()*32
    if uses == 0 then
        fill = 32
    end
    love.graphics.setColor(0, 0, 0, 128)
    love.graphics.rectangle('fill', x, y, 32, fill)
    love.graphics.setColor(255, 255, 255, 255)

    if uses >= 0 then
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.setFont(GUI.numberFont)
        love.graphics.print(uses, x+2, y+24)
    end

end

return GUI
