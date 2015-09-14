local Class = require 'middleclass'
local GUI = Class('gui')
local Powerup = require 'powerup'

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
    love.graphics.rectangle('line', 16+(i-1)*40, 16, 33, 33)
    if not power.set then return end

    love.graphics.draw(power.info.icon, 16+(i-1)*40, 16)

    local fill = power:getIconFill()*32
    love.graphics.setColor(0, 0, 0, 128)
    love.graphics.rectangle('fill', 16+(i-1)*40, 16, 32, fill)
    love.graphics.setColor(255, 255, 255, 255)
    --
    -- local uses = self.player:getPowerUses(power)
    -- if uses >= 0 then
    --     love.graphics.circle('fill', 48+(i-1)*40-4, 48-4, 6, 16)
    --         love.graphics.setColor(0, 0, 0)
    --     love.graphics.print(uses, 48+(i-1)*40-4, 48-4)
    -- end

    love.graphics.setColor(255, 255, 255)
end

return GUI
