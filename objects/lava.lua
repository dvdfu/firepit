local Class = require 'middleclass'
local Object = require 'objects/object'
local Lava = Class('lava', Object)

local Particles = require('objects/particles')
local Vector = require('vector')

Lava.static.sprLava = love.graphics.newImage('assets/images/stage/lava.png')
Lava.static.sprLavaTop = love.graphics.newImage('assets/images/stage/lava_top.png')
Lava.static.sprGlow = love.graphics.newImage('assets/images/stage/lava_glow.png')
Lava.static.sprParticle = love.graphics.newImage('assets/images/particles/dot.png')

Lava.static.lavaShader = love.graphics.newShader[[
    extern float time;
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 hs = love_ScreenSize.xy;
        float disp = sin(24*texture_coords.x + 2*time);
        texture_coords.y -= 8*(1+disp)/hs.y;
        texture_coords.x -= 8*texture_coords.y/hs.x;
        return Texel(texture, texture_coords);
    }
]]

Lava.static.glowShader = love.graphics.newShader[[
    extern float time;
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = vec4(0.6, 0.4, 0.1, 1);

        vec2 hs = love_ScreenSize.xy;
        float disp = sin(24*texture_coords.x + 2*time);
        texture_coords.y -= 16*(1+disp)/hs.y;

        pixel.a = texture_coords.y*texture_coords.y;
        pixel.a = floor(pixel.a*5)/5;
        return pixel;
    }
]]

function Lava:initialize(collider, y)
    self.pos = Vector(-128, y)
    self.size = Vector(512+256, 256)
    self.offset = -self.size / 2
    Object.initialize(self, collider, collider:rectangle(self.pos.x, y, self.size:unpack()))
    self.tags = { 'lava' }
    self.level = y
    self:render()

    self.fire = Particles.newFire()
    self.speck = Particles.newFireSpeck()
    self.speck:setAreaSpread('uniform', self.size.x/2, 0)
    self.speck:setEmissionRate(100)
end

function Lava:update(dt)
    if self.pos.y > self.level + 0.1 then
        local dy = self.level - self.pos.y
        self.pos.y = self.pos.y + dy/30
    else
        self.pos.y = self.level
    end
    Object.update(self, dt)
end

function Lava:draw()
    self.fire:update(1/60)
    love.graphics.draw(self.fire)

    self.speck:setPosition(self.pos.x+self.size.x/2, self.pos.y)
    self.speck:update(1/60)
    love.graphics.draw(self.speck)

    Lava.lavaShader:send('time', os.clock())
    Lava.glowShader:send('time', os.clock())
    local oldShader = love.graphics.getShader()

    love.graphics.setShader(Lava.glowShader)
    love.graphics.setBlendMode('additive')
    love.graphics.draw(Lava.sprGlow, self.pos.x, self.pos.y-96, 0, self.size.x/16, 96/16)
    love.graphics.setBlendMode('alpha')
    love.graphics.setShader(Lava.lavaShader)
    love.graphics.draw(self.image, self.pos.x, self.pos.y-8)
    -- love.graphics.draw(Lava.sprLava, self.pos.x, self.pos.y-13, 0, self.size.x/16, self.size.y/16)
    love.graphics.setShader(oldShader)
end

function Lava:render()
    local image = love.graphics.newCanvas(self.size.x, self.size.y)
    local oldCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas(image)
    for i = 0, self.size.x, Lava.sprLava:getWidth() do
        for j = 0, self.size.y, Lava.sprLava:getHeight() do
            if j == 0 then
                love.graphics.draw(Lava.sprLavaTop, i, j)
            else
                love.graphics.draw(Lava.sprLava, i, j)
            end
        end
    end
    love.graphics.setCanvas(oldCanvas)
    self.image = love.graphics.newImage(image:getImageData())
end

function Lava:touch(x, feed)
    self.fire:setPosition(x, self.pos.y)
    self.fire:emit(16)
    if feed then
        self.level = self.level - 16
    end
end

return Lava
