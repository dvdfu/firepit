love.graphics.setDefaultFilter('nearest', 'nearest')
love.graphics.setLineWidth(1)
math.randomseed(os.time())

Camera = require 'hump.camera'
Solid = require 'solid'
Player = require 'player'
Enemy = require 'enemy'
local Bump = require 'bump'
world = Bump.newWorld(64)

sw = love.graphics.getWidth()/2
sh = love.graphics.getHeight()/2

function love.load()
    level1 = Solid:new(world, (sw-224)/2, sh-64, 224, 64)
    level2_l = Solid:new(world, 32, sh-128, 112, 128)
    level2_r = Solid:new(world, sw-112-32, sh-128, 112, 128)
    level3 = Solid:new(world, (sw-224)/2, sh-192, 224, 192)
    level2_l.name = 'platform'
    level2_r.name = 'platform'
    level3.name = 'platform'
    wall_l = Solid:new(world, 0, 0, 32, sh)
    wall_r = Solid:new(world, sw-32, 0, 32, sh)
    p = Player:new(world, 32, 0)
    cam = Camera(sw/2, 0)
    e1 = Enemy:new(world, sw-64, 0)
    e2 = Enemy:new(world, sw-112, 0)

    canvas = love.graphics.newCanvas(sw, sh)
    scaleShader = love.graphics.newShader[[
        #ifdef VERTEX
        vec4 position(mat4 transform_projection, vec4 vertex_position) {
            vertex_position.xy *= 2.0;
            return transform_projection * vertex_position;
        }
        #endif

        #ifdef PIXEL
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            return Texel(texture, texture_coords);
        }
        #endif
    ]]

    min_dt = 1/60
    next_time = love.timer.getTime()
end

function love.update(dt)
    next_time = next_time + min_dt

    local dy = p.y+p.h/2 - cam.y
    cam:move(0, dy/20)

    p:update(dt)
    e1:update(dt)
    e2:update(dt)
end

function camDraw(func)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.translate(-sw/2, -sh/2)
    cam:draw(func)
    love.graphics.pop()
end

function love.draw()
    camDraw(function()
        canvas:clear()
        love.graphics.setCanvas(canvas)
        level1:draw()
        level2_l:draw()
        level2_r:draw()
        level3:draw()
        wall_l:draw()
        wall_r:draw()
        p:draw()
        e1:draw()
        e2:draw()
        love.graphics.setCanvas()
    end)
    love.graphics.setShader(scaleShader)
    love.graphics.draw(canvas, 0, 0)
    love.graphics.setShader()

    local cur_time = love.timer.getTime()
    if next_time <= cur_time then
      next_time = cur_time
      return
    end
    love.timer.sleep(next_time - cur_time)
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end
end
