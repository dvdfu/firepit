local Powerups = {}
local names = {}

names[1] = 'coldFeet'

Powerups['coldFeet'] = {
    id = 1,
    name = 'Cold Feet',
    icon = love.graphics.newImage('assets/power_cold_feet.png')
}

Powerups.getRandom = function()
    local r = math.random(#Powerups)
    return Powerups[names[r]]
end

return Powerups
