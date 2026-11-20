local settings = require("scripts.core.settings")
local parts = require("scripts.core.parts")
local events = require("scripts.core.events")
local time = require("scripts.core.time")

-- each ear has its own spring, driven by movement and occasional twitch impulses
local ears = {
    {
        part = parts.leftEar,
        side = -1,
        rot = vec(0, 0, 0),
        old = vec(0, 0, 0),
        vel = vec(0, 0, 0),
    },
    {
        part = parts.rightEar,
        side = 1,
        rot = vec(0, 0, 0),
        old = vec(0, 0, 0),
        vel = vec(0, 0, 0),
    },
}

local stiffness = 0.09
local damping = 0.8
local twitchTimer = time.newTimer(40, 100)

local function twitch()
    local ear = ears[math.random(1, 2)]
    local dir = math.random(0, 1) == 0 and -1 or 1
    ear.vel:add(vec(-dir * 12, 0, dir * 3))
    twitchTimer:reset()
end

events.on("tick", function ()
    local velocity = player:getVelocity()
    local bodyRot = player:getBodyYaw(1)
    local v = vectors.rotateAroundAxis(bodyRot, velocity, vec(0, 1, 0))
    local pitch = player:getRot().x
    local target = vec(
        math.clamp(-v.z * 40 - v.y * 20 - pitch * 0.25, -35, 35),
        math.clamp(v.x * 28, -30, 30),
        0
    )
    if not settings.earPhysics then target = vec(0, 0, 0) end

    if settings.earTwitch and twitchTimer:down() then twitch() end

    for _, ear in ipairs(ears) do
        ear.old = ear.rot:copy()
        local earTarget = target + vec(0, ear.side * 2, 0)
        ear.vel = ear.vel * damping + (earTarget - ear.rot) * stiffness
        ear.rot = ear.rot + ear.vel
    end
end)

events.on("render", function (delta)
    for _, ear in ipairs(ears) do
        ear.part:offsetRot(math.lerpAngle(ear.old, ear.rot, delta))
    end
end)

function ears.kick(force)
    for _, ear in ipairs(ears) do
        ear.vel:add(force)
    end
end

return ears
