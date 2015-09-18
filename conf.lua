package.path = 'modules/?/?.lua;modules/hump/?.lua;modules/love-misc-libs/?/?.lua;'..package.path

function love.conf(t)
    t.window.title = ''
    t.window.fullscreen = false
    t.window.resizable = false
    t.window.vsync = true
end
