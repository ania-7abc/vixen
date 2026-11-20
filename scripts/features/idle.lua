local settings = require("scripts.core.settings")
local state = require("scripts.core.state")
local anim = require("scripts.features.animation.anim")
local ears = require("scripts.features.ears")
local tail = require("scripts.features.tail")
local parts = require("scripts.core.parts")
local time = require("scripts.core.time")
local events = require("scripts.core.events")

local head = parts.head

local idleTimer = time.newTimer(400, 900)

local animations = {
    sniff = {
        duration = 1.6,
        rot = function (t, duration)
            return vec(math.sin(t * math.pi * 5) * 9 * time.envelope(t, duration), 0, 0)
        end,
    },
    look = {
        duration = 2.4,
        rot = function (t, duration)
            return vec(0, math.sin(t * math.pi * 2 / duration) * 24 * time.envelope(t, duration), 0)
        end,
    },
    shake = {
        duration = 0.8,
        rot = function (t, duration)
            return vec(0, 0, math.sin(t * math.pi * 10 / duration) * 7 * time.envelope(t, duration))
        end,
    },
}
local idleNames = { "sniff", "look", "shake" }

local active = nil

function pings.playIdle(name, startTime)
    local entry = animations[name]
    if not entry or not player:isLoaded() then return end
    active = { name = name, start = startTime or client:getSystemTime(), entry = entry }
    if name == "sniff" then
        sounds:playSound("minecraft:entity.fox.sniff", player:getPos())
    elseif name == "shake" then
        ears.kick(vec(-16, 0, 5))
        tail.flick(18)
    end
end

settings.onChange("idleAnims", function (enabled)
    if not enabled then
        active = nil
        idleTimer:reset()
    end
end)

local function canPlayIdle()
    if not settings.idleAnims then return false end
    if not client:isWindowFocused() or action_wheel:isEnabled() then return false end
    if anim.activePose() ~= nil or state.isSleeping() then return false end
    local pose = player:getPose()
    if pose ~= "STANDING" and pose ~= "CROUCHING" then return false end
    if player:getVehicle() ~= nil or player:isUsingItem() then return false end
    if not player:isOnGround() then return false end
    return player:getVelocity():lengthSquared() < 0.01
end

events.on("tick", function ()
    if not player:isLoaded() then return end

    if active then
        local elapsed = (client:getSystemTime() - active.start) / 1000
        if elapsed >= active.entry.duration then
            active = nil
            idleTimer:reset()
        end
        return
    end

    if not canPlayIdle() then return end
    if idleTimer:down() then
        idleTimer:reset()
        pings.playIdle(idleNames[math.random(#idleNames)], client:getSystemTime())
    end
end)

events.on("render", function (delta)
    if not active then return end
    local t = (client:getSystemTime() - active.start) / 1000
    if t < 0 or t > active.entry.duration then return end
    head:offsetRot(active.entry.rot(t, active.entry.duration))
end)
