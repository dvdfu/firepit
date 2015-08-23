love.graphics.setDefaultFilter('nearest', 'nearest')
love.graphics.setLineWidth(1)
math.randomseed(os.time())

Solid = require 'solid'
Player = require 'player'
Enemy = require 'enemy'
local Bump = require 'bump'
world = Bump.newWorld(64)

sw = love.graphics.getWidth()/2
sh = love.graphics.getHeight()/2

function love.load()
    s0 = Solid:new(world, 64, sh-64, sw-128, 64)
    s1 = Solid:new(world, 0, sh-112, 80, 8)
    s2 = Solid:new(world, sw-80, sh-112, 80, 8)
    s1.name = 'platform'
    s2.name = 'platform'
    sw1 = Solid:new(world, -32, 0, 32, sh)
    sw2 = Solid:new(world, sw, 0, 32, sh)
    p = Player:new(world, 0, 0)
    e1 = Enemy:new(world, sw-64, 0)
    e2 = Enemy:new(world, sw-31.5, 0)

    canvas = love.graphics.newCanvas(sw, sh)
    scaleShader = love.graphics.newShader[[
    #ifdef VERTEX
    vec4 position(mat4 transform_projection, vec4 vertex_position) {
        vertex_position.xy = floor(vertex_position.xy + 0.5) * 2.0;
        return transform_projection * vertex_position;
    }
    #endif

    #ifdef PIXEL
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(texture, texture_coords);
        return pixel * color;
    }
    #endif
    ]]
end

function love.update(dt)
    p:update(dt)
    e1:update(dt)
    e2:update(dt)
end

function love.draw()
    canvas:clear()
    love.graphics.setCanvas(canvas)
    s0:draw()
    s1:draw()
    s2:draw()
    p:draw()
    e1:draw()
    e2:draw()
    love.graphics.setCanvas()
    love.graphics.setShader(scaleShader)
    love.graphics.draw(canvas, 0, 0)
    love.graphics.setShader()
end
