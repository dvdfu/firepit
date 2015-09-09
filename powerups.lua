local Powerups = {}
local names = {}

Powerups.numbered = {}
Powerups.power = {}

Powerups.coldFeet = 'coldFeet' --id = key
Powerups.numbered[1] = 'coldFeet' --index
Powerups.power.coldFeet = {
    name = 'Cold Feet',
    icon = love.graphics.newImage('assets/power_cold_feet.png')
}

Powerups.getRandom = function()
    local r = math.random(#Powerups.power)
    return Powerups[Powerups.numbered[r]]
end

return Powerups
