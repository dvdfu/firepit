local Class = require 'middleclass'
local Object = require 'object'
local Lava = Class('lava', Object)

Lava.static.sprLava = love.graphics.newImage('assets/lava.png')

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
        float disp = sin(12.0*texture_coords.x + 4.0*time);
        texture_coords.y += 4.0*disp/hs.y;
        texture_coords.x += 4.0*disp/hs.x;
        return Texel(texture, texture_coords);
    }
    #endif
]]

function Lava:initialize(world)
    Object.initialize(self, world, 0, 360, 480, 176)
    self.name = 'solid'
end

function Lava:draw()
    Lava.shader:send('time', os.clock())
    local s = love.graphics.getShader()
    love.graphics.setShader(Lava.shader)
    love.graphics.draw(Lava.sprLava, self.x, self.y-8, 0, self.w/16, self.h/16)
    love.graphics.setShader(s)
    love.graphics.rectangle('line', self.x, self.y, self.w, self.h)
end

return Lava
