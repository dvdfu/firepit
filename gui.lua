local Class = require 'middleclass'
local GUI = Class('gui')
local Powerup = require 'powerup'

GUI.static.numberFont = love.graphics.newFont('assets/fonts/04b_21.ttf', 8)

GUI.static.dropShadowShader = love.graphics.newShader[[
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(texture, texture_coords);
        pixel.rgb = vec3(0);
        return pixel * color;
    }
]]

function GUI:initialize(cam, player, enemies)
    love.graphics.setLineWidth(1)
    self.cam = cam
    self.player = player
    self.enemies = enemies
    local w, h = 512, 320
    self.canvas = love.graphics.newCanvas(w, h)
end

function GUI:draw()
    local bar = 12
    self:outline(function()
        for _, enemy in pairs(self.enemies) do
            self:drawEnemyHealth(enemy)
        end

        self:drawPower(self.player.staticPowers[1], 1)
        self:drawPower(self.player.staticPowers[2], 2)
        self:drawPower(self.player.activePower, 3)

        for i = 1, self.player.maxHealth do
            if i <= self.player.health then
                love.graphics.setColor(255, 128, 96)
            else
                love.graphics.setColor(128, 64, 64)
            end
            love.graphics.rectangle('fill', 16+(i-1)*bar, 56, bar, 8)
        end
        love.graphics.setColor(255, 255, 255)
    end, true)

    self:outline(function()
        love.graphics.setFont(GUI.numberFont)
        love.graphics.print('HP: '..self.player.health..'/'..self.player.maxHealth, 16+self.player.maxHealth*bar+6, 56)
    end, false)
end

function GUI:outline(func, rounded)
    local oldCanvas = love.graphics.getCanvas()
    local oldShader = love.graphics.getShader()
    love.graphics.setCanvas(self.canvas)
    self.canvas:clear()
    func()
    love.graphics.setCanvas(oldCanvas)
    love.graphics.setShader(GUI.dropShadowShader)
    if rounded then
        love.graphics.draw(self.canvas, 0, -1)
        love.graphics.draw(self.canvas, 0, 1)
        love.graphics.draw(self.canvas, -1, 0)
        love.graphics.draw(self.canvas, 1, 0)
    else
        for i = -1, 1 do
            for j = -1, 1 do
                love.graphics.draw(self.canvas, i, j)
            end
        end
    end
    love.graphics.setShader(oldShader)
    love.graphics.draw(self.canvas)
end

function GUI:drawPower(power, i)
    local x, y = 16+(i-1)*40, 16
    love.graphics.setColor(128, 128, 128, 255)
    love.graphics.rectangle('line', x, y, 33, 33)
    love.graphics.setColor(255, 255, 255, 255)

    if not power.set then return end

    love.graphics.draw(power.icon, x, y)
    if power.type == 'Reload' then
        local uses = power.quantity
        local fill = power:getIconFill()*32
        love.graphics.setColor(0, 0, 0, 128)
        love.graphics.rectangle('fill', x, y, 32, fill)
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.setFont(GUI.numberFont)
        love.graphics.print(uses, x+2, y+24)
    end
    love.graphics.rectangle('line', x, y, 33, 33)
end

function GUI:drawEnemyHealth(enemy)
    if enemy.healthTimer <= 0 then return end
    if enemy.health == 0 and enemy.healthTimer <= 30 then return end
    local x, y = (enemy.pos + enemy.healthOffset):unpack()
    local cx, cy = self.cam:pos()
    x, y = x-cx + 512/2, y-cy + 360/2
    local w, h = 32, 6
    local damage = enemy.health
    if enemy.healthTimer > 50 then
        damage = enemy.preHealth
    elseif enemy.healthTimer > 40 then
        damage = enemy.health + (enemy.preHealth-enemy.health)*(enemy.healthTimer-40)/(50-40)
    end
    love.graphics.setColor(128, 64, 64)
    love.graphics.rectangle('fill', x-w/2, y-h/2, w, h)
    love.graphics.setColor(255, 255, 255)
    love.graphics.rectangle('fill', x-w/2, y-h/2, w*damage/enemy.maxHealth, h)
    love.graphics.setColor(255, 128, 96)
    love.graphics.rectangle('fill', x-w/2, y-h/2, w*enemy.health/enemy.maxHealth, h)
    love.graphics.setColor(255, 255, 255)
end

return GUI
