local Class = require 'middleclass'
local Stateful = require 'stateful'
local Powerup = Class('powerup')
Powerup:include(Stateful)

Powerup.Constant = Powerup:addState('Constant')
Powerup.Uses = Powerup:addState('Uses')
Powerup.Rapid = Powerup:addState('Rapid')
Powerup.Recharge = Powerup:addState('Recharge')
Powerup.Reload = Powerup:addState('Reload')
Powerup.Refill = Powerup:addState('Refill')
Powerup.Timed = Powerup:addState('Timed')

Powerup.static.names = {
    none = 'None',
    coldFeet = 'Cold Feet',
    jumpGlide = 'Jump Glide',
    apple = 'Apple',
    bubble = 'Bubble Blower',
    star = 'Star Cannon',
    flower = 'Flower Bomb',
    chuckie = 'Chuckie'
}

Powerup.static.info = {
    ['None'] = {},
    ['Cold Feet'] = {
        name = 'Cold Feet',
        icon = love.graphics.newImage('assets/images/powers/cold_feet.png')
    },
    ['Jump Glide'] = {
        name = 'Jump Glide',
        icon = love.graphics.newImage('assets/images/powers/jump_glide.png'),
        type = 'Timed',
        cooldown = 120,
        refill = 3
    },
    ['Apple'] = {
        name = 'Apple',
        active = true,
        icon = love.graphics.newImage('assets/images/powers/apple.png'),
        type = 'Uses',
        quantity = 1
    },
    ['Bubble Blower'] = {
        name = 'Bubble Blower',
        active = true,
        icon = love.graphics.newImage('assets/images/powers/bubble.png'),
        type = 'Rapid',
        cooldown = 3
    },
    ['Star Cannon'] = {
        name = 'Star Cannon',
        active = true,
        icon = love.graphics.newImage('assets/images/powers/star.png'),
        type = 'Reload',
        quantity = 5,
        cooldown = 8,
        refill = 1.5*60
    },
    ['Flower Bomb'] = {
        name = 'Flower Bomb',
        active = true,
        icon = love.graphics.newImage('assets/images/powers/flower.png'),
        type = 'Reload',
        quantity = 10,
        cooldown = 30,
        refill = 10*60
    },
    ['Chuckie'] = {
        name = 'Chuckie',
        active = false,
        icon = love.graphics.newImage('assets/images/powers/flower.png')
    }
}

function Powerup:initialize()
    self:setPower()
end

function Powerup:setPower(name)
    local info = Powerup.info[name] or Powerup.info['None']
    self.name = info.name or ''
    self.active = info.active or false
    self.icon = info.icon or nil
    self.type = info.type or 'Constant'
    self.quantity = info.quantity or 0
    self.cooldown = info.cooldown or 0
    self.refill = info.refill or 0

    self.timer = 0
    self.remaining = self.quantity
    self.set = Powerup.info[name] and true or false
    self.using = false
    self:gotoState(self.type)
end

function Powerup:update()
    if self.timer > 0 then
        self.timer = self.timer - 1
    end
end

function Powerup:use()
    return true
end

function Powerup:getIconFill()
    return 0;
end

--[[======== RAPID STATE ========]]

function Powerup.Rapid:use()
    if self.timer == 0 then
        self.timer = self.cooldown
        return true
    end
    return false
end

function Powerup.Rapid:getIconFill()
    return self.timer / self.cooldown
end

--[[======== RELOAD STATE ========]]

function Powerup.Reload:update()
    if self.timer > 0 then
        self.timer = self.timer - 1
    elseif self.quantity == 0 then
        self.quantity = Powerup.info[self.name].quantity
    end
end

function Powerup.Reload:use()
    if self.quantity > 0 and self.timer == 0 then
        self.quantity = self.quantity - 1
        if self.quantity == 0 then
            self.timer = self.refill
        else
            self.timer = self.cooldown
        end
        return true
    end
    return false
end

function Powerup.Reload:getIconFill()
    if self.quantity == 0 then
        return self.timer / self.refill
    end
    return self.timer / self.cooldown
end

--[[======== TIMED STATE ========]]

function Powerup.Timed:update()
    if not self.using then
        if self.timer > self.refill then
            self.timer = self.timer - self.refill
        else
            self.timer = 0
        end
    end
    self.using = false
end

function Powerup.Timed:use()
    if self.timer < self.cooldown then
        self.using = true
        self.timer = self.timer + 1
        return true
    end
    return false
end

function Powerup.Timed:getIconFill()
    return self.timer / self.cooldown
end

return Powerup
