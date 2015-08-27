math.randomseed(os.time())
love.graphics.setDefaultFilter('nearest', 'nearest')
love.graphics.setLineWidth(4)
love.graphics.setLineStyle('rough')

Input = require 'input'
Gamestate = require 'hump.gamestate'
Game = require 'game'
scale = 2

function love.load()
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
            vec4 pixel = Texel(texture, texture_coords);
            return pixel;
        }
        #endif
    ]]
    love.window.setMode(480*scale, 360*scale)
    scaleShader:send('scale', scale)

    min_dt = 1/60
    next_time = love.timer.getTime()

    -- Gamestate.registerEvents()
    Gamestate.switch(Game)
end

function love.update(dt)
    next_time = next_time + min_dt
    Gamestate.current():update(dt)
    if Input:pressed('escape') then
        love.event.quit()
    end
    if Input:pressed('r') then
        Gamestate.switch(Game)
    end
    Input:update()
end

function love.draw()
    canvas:clear()
    love.graphics.setCanvas(canvas)
    Gamestate.current():draw()
    love.graphics.setCanvas()

    love.graphics.setShader(scaleShader)
    love.graphics.draw(canvas)
    love.graphics.setShader()

    local cur_time = love.timer.getTime()
    if next_time <= cur_time then
      next_time = cur_time
      return
    end
    love.timer.sleep(next_time - cur_time)
end
