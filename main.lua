love.graphics.setDefaultFilter('nearest', 'nearest')
love.graphics.setLineWidth(2)
love.graphics.setLineStyle('rough')
love.graphics.setBackgroundColor(16, 24, 40)
math.randomseed(os.time())

Camera = require 'hump.camera'
Solid = require 'solid'
Player = require 'player'
Enemy = require 'enemy'
Lava = require 'lava'
local Bump = require 'bump'
world = Bump.newWorld(64)

scale = 1
sw = love.graphics.getWidth()/2
sh = love.graphics.getHeight()/2

function love.load()
    level1 = Solid:new(world, (sw-224)/2, sh-64, 224, 64)
    level2_l = Solid:new(world, 32, sh-128, 112, 128)
    level2_r = Solid:new(world, sw-112-32, sh-128, 112, 128)
    level3 = Solid:new(world, sw/2, sh-192, 112, 192)
    level2_l.name = 'platform'
    level2_r.name = 'platform'
    level3.name = 'platform'
    level3.color = {
        r = 40,
        g = 48,
        b = 80
    }
    level2_l.color = {
        r = 72,
        g = 72,
        b = 128
    }
    level2_r.color = {
        r = 72,
        g = 72,
        b = 128
    }
    wall_l = Solid:new(world, -64, -96, 32+64, sh+96)
    wall_r = Solid:new(world, sw-32, -96, 32+64, sh+96)
    p = Player:new(world, 32, 0)
    l = Lava:new(world)
    cx, cy = sw/2, 0
    cam = Camera(cx, cy)
    e1 = Enemy:new(world, sw-64, 0)
    e2 = Enemy:new(world, sw-112, 0)

    canvas = love.graphics.newCanvas(sw, sh)
    scaleShader = love.graphics.newShader[[
        extern float scale;
        #ifdef VERTEX
        vec4 position(mat4 transform_projection, vec4 vertex_position) {
            vertex_position.xy *= scale;
            return transform_projection * vertex_position;
        }
        #endif

        #ifdef PIXEL
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            return Texel(texture, texture_coords);
        }
        #endif
    ]]
    love.window.setMode(480*scale, 360*scale)
    scaleShader:send('scale', scale)

    min_dt = 1/60
    next_time = love.timer.getTime()
end

function love.update(dt)
    next_time = next_time + min_dt

    cx = cx + (sw/2 + (p.x+p.w/2 - sw/2)/4 - cx)/20
    cy = cy + (p.y+p.h/2 - cy)/20
    cam:lookAt(math.floor(cx+0.5), math.floor(cy+0.5))

    p:update(dt)
    e1:update(dt)
    e2:update(dt)
    l:update(dt)
end

function camDraw(func)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.translate(-sw/2*(scale-1), -sh/2*(scale-1))
    cam:draw(func)
    love.graphics.pop()
end

function love.draw()
    camDraw(function()
        canvas:clear()
        love.graphics.setCanvas(canvas)
        level3:draw()
        level2_l:draw()
        level2_r:draw()
        level1:draw()
        wall_l:draw()
        wall_r:draw()
        p:draw()
        e1:draw()
        e2:draw()
        l:draw()
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
