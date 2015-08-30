local Class = require 'middleclass'
local Object = require 'objects/object'
local Item = Class('item', Object)

Item.static.sprite = love.graphics.newImage('assets/item.png')

Item.static.powerups = {
    'doublejump',
    'dash'
}

Item.collide_solid = {
    type = 'slide',
    func = function(self, col)
		if col.normal.y ~= 0 then
			self.vy = 0
            self.vx = 0
			if col.normal.y == -1 then
				self.ground = col.other
			end
		end
        if col.normal.x ~= 0 then
            self.vx = -self.vx
        end
    end
}

Item.collide_platform = {
    type = 'cross',
    func = function(self, col)
		if col.normal.y == -1 and self.y+self.h-self.vy <= col.other.y then
			self.vy = 0
            self.vx = 0
            self.y = col.other.y - self.h
            self.world:update(self, self.x, self.y)
			self.ground = col.other
		end
    end
}

function Item:initialize(world, x, y)
    Object.initialize(self, world, x, y, 16, 16)
    self.type = Item.powerups[math.random(1, #Item.powerups)]
    self.vy = -5
    self.vx = math.random(-3, 3)
    self.timer = 0
    self.deadTimer = 0
    self.player = nil
end

function Item:update(dt)
    if self.vy < 5 then
        self.vy = self.vy + 0.3
    else
        self.vy = 5
    end
    self.x = self.x + self.vx
    self.y = self.y + self.vy
    self:collide()
    self.timer = self.timer+dt
    if self.timer > 5 then
        self:gotoState('Flash')
    end
end

function Item:draw()
    local dy = 2*math.sin(self.timer*2*math.pi)
    love.graphics.draw(Item.sprite, self.x, self.y+dy, 0, 1, 1, 8, 8)
end

function Item:grab(player)
    self.player = player
    self:gotoState('Grab')
end

function Item:isDead()
    return false
end

--[[======== GRAB STATE ========]]

Item.Grab = Item:addState('Grab')

function Item.Grab:enteredState()
    self.deadTimer = 0
    self.vx = 0
    self.vy = 0
    self.world:remove(self)
end

function Item.Grab:update()
    self.deadTimer = self.deadTimer+1
    local dx = self.player.x + 12 - self.x
    local dy = self.player.y + 12 - self.y
    self.x = self.x + dx*self.deadTimer/20
    self.y = self.y + dy*self.deadTimer/20
end

-- function Item.Grab:draw()
--     local alpha = 255*(1 - self.deadTimer/20)
--     love.graphics.setColor(255, 255, 255, alpha)
--     love.graphics.draw(Item.sprite, self.x, self.y, 0, 1, 1, 8, 8)
--     love.graphics.setColor(255, 255, 255, 255)
-- end

function Item.Grab:grab() end

function Item.Grab:isDead()
    return self.deadTimer > 20
end

--[[======== FLASH STATE ========]]

Item.Flash = Item:addState('Flash')

function Item.Flash:enteredState()
    self.timer = 0
end

function Item.Flash:update(dt)
    if self.vy < 5 then
        self.vy = self.vy + 0.3
    else
        self.vy = 5
    end
    self.x = self.x + self.vx
    self.y = self.y + self.vy
    self:collide()
    self.timer = self.timer + 1
end

function Item.Flash:draw()
    if self.timer % 4 < 2 then
        Item.draw(self)
    end
end

function Item.Flash:isDead()
    return self.timer > 3*60
end

return Item
