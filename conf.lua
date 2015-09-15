package.path = '.?/?.lua;.hump/?.lua;.lml/?/?.lua;'..package.path
Jupiter = require 'jupiter'

function love.conf(t)
    t.window.title = ''
    t.window.fullscreen = false
    t.window.resizable = false
    t.window.vsync = true

    -- local data = Jupiter.load("settings.lua")
    -- if data then
    --     t.window.width = 480*data.scale
    --     t.window.height = 360*data.scale
    -- else
    --     data = {
    --         _fileName = 'settings.lua',
    --         scale = 2
    --     }
    --     Jupiter.save(data)
    -- end
end
