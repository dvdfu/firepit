local Class = require 'middleclass'
local Object = require 'objects/object'
local Lava = Class('lava', Object)

Lava.static.sprLava = love.graphics.newImage('assets/lava.png')
Lava.static.sprGlow = love.graphics.newImage('assets/lava_glow.png')
Lava.static.sprParticle = love.graphics.newImage('assets/particle.png')

Lava.static.lavaShader = love.graphics.newShader[[
    extern float time;
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 hs = love_ScreenSize.xy;
        float disp = sin(16*texture_coords.x + 2*time);
        texture_coords.y += 4*disp/hs.y;
        return Texel(texture, texture_coords);
    }
]]

Lava.static.glowShader = love.graphics.newShader[[
    extern float time;
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = vec4(0.6, 0.4, 0.1, 1);

        vec2 hs = love_ScreenSize.xy;
        float disp = sin(16*texture_coords.x + 2*time);
        texture_coords.y += 20*disp/hs.y;

        pixel.a = texture_coords.y*texture_coords.y;
        pixel.a = floor(pixel.a*5)/5;
        return pixel;
    }
]]

function Lava:initialize(world)
    Object.initialize(self, world, -64, 360, 480+128, 176)
    self.name = 'lava'
    self.level = self.y

    self.fire = love.graphics.newParticleSystem(Lava.sprParticle)
    self.fire:setParticleLifetime(0.3, 1)
    self.fire:setDirection(-math.pi/2)
    self.fire:setSpread(math.pi/4)
    self.fire:setAreaSpread('normal', 8, 0)
    self.fire:setSpeed(50, 200)
    self.fire:setLinearAcceleration(0, 200)
    self.fire:setColors(255, 255, 0, 255, 255, 182, 0, 255, 255, 73, 73, 255, 146, 36, 36, 255)
    self.fire:setSizes(2, 0)

    self.speck = love.graphics.newParticleSystem(Lava.sprParticle)
    self.speck:setEmissionRate(100)
    self.speck:setParticleLifetime(0, 1)
    self.speck:setDirection(-math.pi/2)
    self.speck:setSpread(math.pi/6)
    self.speck:setAreaSpread('uniform', self.w/2, 0)
    self.speck:setSpeed(50, 200)
    self.speck:setColors(255, 255, 0, 255, 255, 182, 0, 255, 255, 73, 73, 255, 146, 36, 36, 255)
    self.speck:setSizes(0.5, 0)
end

function Lava:update(dt)
    if self.y > self.level + 0.1 then
        local dy = self.level - self.y
        self.y = self.y + dy/30
    else
        self.y = self.level
    end
    Object.update(self, dt)
end

function Lava:draw()
    self.fire:update(1/60)
    love.graphics.draw(self.fire)

    self.speck:setPosition(self.x+self.w/2, self.y)
    self.speck:update(1/60)
    love.graphics.draw(self.speck)

    Lava.lavaShader:send('time', os.clock())
    Lava.glowShader:send('time', os.clock())
    local s = love.graphics.getShader()

    love.graphics.setShader(Lava.glowShader)
    love.graphics.setBlendMode('additive')
    love.graphics.draw(Lava.sprGlow, self.x, self.y-96, 0, self.w/16, 96/16)
    love.graphics.setBlendMode('alpha')
    love.graphics.setShader(Lava.lavaShader)
    love.graphics.draw(Lava.sprLava, self.x, self.y-13, 0, self.w/16, self.h/16)

    love.graphics.setShader(s)
end

function Lava:touch(x, feed)
    self.fire:setPosition(x, self.y)
    self.fire:emit(10)
    if feed then
        self.level = self.level - 16
    end
end

return Lava
