local Sound = {
    burn = love.audio.newSource('assets/audio/burn.wav', 'static'),
    jump = love.audio.newSource('assets/audio/jump.wav', 'static'),
    stomp = love.audio.newSource('assets/audio/stomp.wav', 'static'),
    thud = love.audio.newSource('assets/audio/thud.wav', 'static')
}

Sound.jump:setPitch(0.75)

return Sound
