local Sound = {
    burn = love.audio.newSource('assets/audio/burn.wav', 'static'),
    explode = love.audio.newSource('assets/audio/explode.wav', 'static'),
    jump = love.audio.newSource('assets/audio/jump.wav', 'static'),
    shoot = love.audio.newSource('assets/audio/shoot.wav', 'static'),
    stomp = love.audio.newSource('assets/audio/stomp.wav', 'static'),
    thud = love.audio.newSource('assets/audio/thud.wav', 'static')
}

Sound.jump:setPitch(0.75)

return Sound
