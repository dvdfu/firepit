local Class = require 'middleclass'
local Powerup = Class('powerup')

Powerup.static.names = {
    coldFeet = 'Cold Feet',
    jumpGlide = 'Jump Glide',
    apple = 'Apple'
}

Powerup.static.info = {
    ['Cold Feet'] = {
        name = 'Cold Feet',
        type = 'static',
        icon = love.graphics.newImage('assets/images/powers/cold_feet.png'),
        uses = -1,
        cooldown = -1
    },
    ['Jump Glide'] = {
        name = 'Jump Glide',
        type = 'static',
        icon = love.graphics.newImage('assets/images/powers/jump_glide.png'),
        uses = -1,
        cooldown = 120
    },
    ['Apple'] = {
        name = 'Apple',
        type = 'static',
        icon = love.graphics.newImage('assets/images/powers/apple.png'),
        uses = 1,
        cooldown = -1
    }
}

function Powerup:initialize()
    self.info = nil
    self.set = false
    self.timer = 0
    self.uses = 0
end

function Powerup:update(dt)
    if self.timer > 0 then
        self.timer = self.timer - 1
    end
end

function Powerup:setPower(name)
    self.set = true
    self.info = Powerup.info[name]
    self.uses = self.info.uses
end

function Powerup:use()
    if self.uses > 0 then
        self.uses = self.uses - 1
        self.timer = self.info.cooldown
    end
end

function Powerup:getIconFill()
    if self.info.cooldown > 0 then
        return 1 - self.timer / self.info.cooldown
    end
    return 0;
end

return Powerup
