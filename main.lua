math.randomseed(os.time())
love.graphics.setDefaultFilter('nearest', 'nearest')
love.graphics.setLineStyle('rough')
love.mouse.setVisible(false)

Jupiter = require 'jupiter'
Input = require 'input'
Gamestate = require 'gamestate'
Game = require 'states/game'
scale = 0

function love.load()
    canvas = love.graphics.newCanvas(sw, sh)
    scaleShader = love.graphics.newShader[[
        extern float scale;
        vec4 position(mat4 transform_projection, vec4 vertex_position) {
            vertex_position.xy *= scale;
            return transform_projection * vertex_position;
        }

        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            return Texel(texture, texture_coords);
        }
    ]]
    -- scale = Jupiter.load("settings.lua").scale

    min_dt = 1/60
    next_time = love.timer.getTime()

    Gamestate.switch(Game)
    setScale(2)
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
    if Input:pressed('1') then setScale(1) end
    if Input:pressed('2') then setScale(2) end
    if Input:pressed('3') then setScale(3) end
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
    if next_time > cur_time then
        love.timer.sleep(next_time - cur_time)
    else
        next_time = cur_time
    end
end

function setScale(s)
    if scale == s then return end
    if s <= 0 then return end
    scale = s
    love.window.setMode(480*s, 360*s)
    scaleShader:send('scale', s)
    Gamestate.current():redraw()
end
