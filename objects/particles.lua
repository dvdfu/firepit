local Particles = {
    sprDot = love.graphics.newImage('assets/images/particles/dot.png'),
    sprBigDot = love.graphics.newImage('assets/images/particles/big_dot.png'),
    sprDiamond = love.graphics.newImage('assets/images/particles/diamond.png')
}

function Particles.newDust()
    local part = love.graphics.newParticleSystem(Particles.sprDot)
    part:setParticleLifetime(0.1, 0.3)
    part:setDirection(-math.pi/2)
    part:setSpread(math.pi/2)
    part:setAreaSpread('normal', 4, 0)
    part:setSpeed(0, 100)
    part:setColors(208, 190, 209)
    part:setSizes(1, 0)
    return part
end

function Particles.newFire()
    local part = love.graphics.newParticleSystem(Particles.sprDot)
    part:setParticleLifetime(0.1, 0.3)
    part:setDirection(-math.pi/2)
    part:setSpread(math.pi/4)
    part:setAreaSpread('normal', 4, 4)
    part:setSpeed(0, 200)
    part:setColors(255, 255, 0, 255, 255, 182, 0, 255, 255, 73, 73, 255, 146, 36, 36, 255)
    part:setSizes(2, 0)
    return part
end

function Particles.newFireSpeck()
    local part = love.graphics.newParticleSystem(Particles.sprDot)
    part:setParticleLifetime(0, 1)
    part:setDirection(-math.pi/2)
    part:setSpread(math.pi/6)
    part:setSpeed(50, 200)
    part:setColors(255, 255, 0, 255, 255, 182, 0, 255, 255, 73, 73, 255, 146, 36, 36, 255)
    part:setSizes(0.5, 0)
    return part
end

function Particles.newFrost()
    local part = love.graphics.newParticleSystem(Particles.sprDiamond)
    part:setParticleLifetime(0.1, 0.5)
    part:setDirection(-math.pi/2)
    part:setSpread(math.pi/2)
    part:setAreaSpread('normal', 4, 0)
    part:setSpeed(0, 50)
    part:setColors(255, 255, 255, 255, 120, 180, 255, 255)
    part:setSizes(1, 0)
    part:setEmissionRate(2)
    return part
end

function Particles.newSmoke()
    local part = love.graphics.newParticleSystem(Particles.sprBigDot)
    part:setParticleLifetime(0, 3)
    part:setDirection(0)
    part:setSpread(math.pi*2)
    part:setAreaSpread('normal', 6, 6)
    part:setSpeed(0, 30)
    part:setColors(72, 18, 18, 255)
    part:setSizes(1, 0)
    part:setLinearAcceleration(0, -20)
    return part
end

return Particles
