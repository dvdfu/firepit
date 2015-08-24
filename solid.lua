local Class = require 'middleclass'
local Object = require 'object'
local Solid = Class('solid', Object)

function Solid:initialize(world, x, y, w, h)
    Object.initialize(self, world, x, y, w, h)
    self.name = 'solid'
end

return Solid
