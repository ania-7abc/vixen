require("scripts.util")

local options = require("scripts.options")
local sleep = require("scripts.sleep")

-- vanilla particles can't use a custom texture from Lua, so draw the Z out of
-- small pale dust particles instead
local zInterval = 10
local zLifetime = 30
local zTimer = 0

local zPoints = {
    vec(-0.14, 0.18, 0), vec(0, 0.18, 0), vec(0.14, 0.18, 0),
    vec(0.09, 0.06, 0), vec(0, 0, 0), vec(-0.09, -0.06, 0),
    vec(-0.14, -0.18, 0), vec(0, -0.18, 0), vec(0.14, -0.18, 0),
}

local function spawnZ()
    local base = models.model.root.Head:partToWorldMatrix():apply() + vec(0, 0.4, 0)
    for _, offset in ipairs(zPoints) do
        local particle = particles:newParticle("dust 0.85 0.95 1 1", base + offset, vec(0, 0.03, 0))
        particle:setScale(0.4)
        particle:setLifetime(zLifetime)
        particle:setGravity(0)
    end
end

function events.tick()
    if not options.zParticles or not sleep.isSleeping() then
        zTimer = 0
        return
    end
    zTimer = zTimer + 1
    if zTimer >= zInterval then
        zTimer = 0
        spawnZ()
    end
end
