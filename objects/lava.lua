local Class = require 'middleclass'
local Object = require 'objects/object'
local Lava = Class('lava', Object)

Lava.static.sprLava = love.graphics.newImage('assets/lava.png')
Lava.static.sprParticle = love.graphics.newImage('assets/particle.png')

Lava.static.shader = love.graphics.newShader[[
    extern float time;

    #ifdef VERTEX
    vec4 position(mat4 transform_projection, vec4 vertex_position) {
        return transform_projection * vertex_position;
    }
    #endif

    #ifdef PIXEL
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 hs = love_ScreenSize.xy;
        float disp = sin(16*texture_coords.x + 2*time);
        texture_coords.y += 4*disp/hs.y;
        return Texel(texture, texture_coords);
    }
    #endif
]]

function Lava:initialize(world)
    Object.initialize(self, world, -64, 360, 480+128, 176)
    self.name = 'lava'
    self.level = self.y

    self.fire = love.graphics.newParticleSystem(Lava.sprParticle)
	self.fire:setParticleLifetime(0.1, 1)
	self.fire:setDirection(-math.pi/2)
    self.fire:setSpread(math.pi/4)
    self.fire:setAreaSpread('normal', 4, 4)
	self.fire:setSpeed(50, 150)
    self.fire:setLinearAcceleration(0, 200)
	self.fire:setColors(255, 255, 0, 255, 255, 182, 0, 255, 255, 73, 73, 255, 146, 36, 36, 255)
	self.fire:setSizes(2, 0)
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

    Lava.shader:send('time', os.clock())
    local s = love.graphics.getShader()
    love.graphics.setShader(Lava.shader)
    love.graphics.draw(Lava.sprLava, self.x, self.y-13, 0, self.w/16, self.h/16)
    love.graphics.setShader(s)
    -- Object.draw(self)
end

function Lava:feed(x)
    self.fire:setPosition(x, self.y)
    self.fire:emit(20)
    self.level = self.level - 16
end

return Lava
