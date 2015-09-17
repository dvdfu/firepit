local Class = require 'middleclass'
local Powerup = Class('powerup')

Powerup.static.names = {
    coldFeet = 'Cold Feet',
    jumpGlide = 'Jump Glide',
    apple = 'Apple',
    bubble = 'Bubble Blower',
    star = 'Star Cannon'
}

Powerup.static.info = {
    ['Cold Feet'] = {
        name = 'Cold Feet',
        type = 'static',
        icon = love.graphics.newImage('assets/images/powers/cold_feet.png'),
        uses = -1,
        cooldown = -1,
        updates = false
    },
    ['Jump Glide'] = {
        name = 'Jump Glide',
        type = 'static',
        icon = love.graphics.newImage('assets/images/powers/jump_glide.png'),
        uses = -1,
        cooldown = 120,
        updates = false
    },
    ['Apple'] = {
        name = 'Apple',
        type = 'active',
        icon = love.graphics.newImage('assets/images/powers/apple.png'),
        uses = 1,
        cooldown = -1,
        updates = false
    },
    ['Bubble Blower'] = {
        name = 'Bubble Blower',
        type = 'active',
        icon = love.graphics.newImage('assets/images/powers/bubble.png'),
        uses = -1,
        cooldown = 6,
        updates = true
    },
    ['Star Cannon'] = {
        name = 'Star Cannon',
        type = 'active',
        icon = love.graphics.newImage('assets/images/powers/star.png'),
        uses = -1,
        cooldown = 80,
        updates = true
    }
}

function Powerup:initialize()
    self.info = nil
    self.set = false
    self.timer = 0
    self.uses = 0
end

function Powerup:update()
    if self.info and self.info.updates then
        self:tick()
    end
end

function Powerup:tick(frames)
    frames = frames or 1
    self.timer = self.timer - frames
    if self.timer < 0 then self.timer = 0 end
    if self.timer > self.info.cooldown then self:timeout() end
end

function Powerup:timeout()
    if self.info.cooldown > 0 then
        self.timer = self.info.cooldown
    end
end

function Powerup:setPower(name)
    self.set = true
    self.info = Powerup.info[name]
    self.uses = self.info.uses
    self.timer = 0
end

function Powerup:use()
    if self.uses > 0 then
        self.uses = self.uses - 1
    end
    self:timeout()
end

function Powerup:getIconFill()
    if self.info.cooldown > 0 then
        return self.timer / self.info.cooldown
    end
    return 0;
end

return Powerup
