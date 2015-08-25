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
        float disp = sin(16*texture_coords.x + 4*time);
        texture_coords.y += 4*disp/hs.y;
        return Texel(texture, texture_coords);
    }
    #endif
]]

function Lava:initialize(world)
    Object.initialize(self, world, -64, 360, 480+128, 176)
    self.name = 'lava'
end

function Lava:draw()
    Lava.shader:send('time', os.clock())
    local s = love.graphics.getShader()
    love.graphics.setShader(Lava.shader)
    love.graphics.draw(Lava.sprLava, self.x, self.y-32, 0, self.w/16, self.h/16)
    love.graphics.setShader(s)
    -- love.graphics.rectangle('line', self.x, self.y, self.w, self.h)
end

return Lava
