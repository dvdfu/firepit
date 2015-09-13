local Powerups = {}
local names = {}

Powerups.numbered = {}
Powerups.power = {}

Powerups.coldFeet = 'coldFeet' --id = key
Powerups.numbered[1] = 'coldFeet' --index
Powerups.power.coldFeet = {
    name = 'Cold Feet',
    icon = love.graphics.newImage('assets/images/powers/cold_feet.png')
}

Powerups.jumpGlide = 'jumpGlide' --id = key
Powerups.numbered[2] = 'jumpGlide' --index
Powerups.power.jumpGlide = {
    name = 'Jump Glide',
    icon = love.graphics.newImage('assets/images/powers/jump_glide.png')
}

Powerups.getRandom = function()
    local r = math.random(#Powerups.power)
    return Powerups[Powerups.numbered[r]]
end

return Powerups
