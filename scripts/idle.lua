local options = require("scripts.options")
local sleep = require("scripts.sleep")
local anim = require("scripts.anim")
local ears = require("scripts.ears")
local tail = require("scripts.tail")

local head = models.model.root.Head

local idleMinDelay = 400
local idleMaxDelay = 900
local idleTimer = math.random(idleMinDelay, idleMaxDelay)

local function envelope(t, duration)
    local phase = math.clamp(t / duration, 0, 1)
    return math.sin(phase * math.pi) ^ 2
end

local animations = {
    sniff = {
        duration = 1.6,
        rot = function (t, duration)
            return vec(math.sin(t * math.pi * 5) * 9 * envelope(t, duration), 0, 0)
        end,
    },
    look = {
        duration = 2.4,
        rot = function (t, duration)
            return vec(0, math.sin(t * math.pi * 2 / duration) * 24 * envelope(t, duration), 0)
        end,
    },
    shake = {
        duration = 0.8,
        rot = function (t, duration)
            return vec(0, 0, math.sin(t * math.pi * 10 / duration) * 7 * envelope(t, duration))
        end,
    },
    flinch = {
        duration = 0.6,
        rot = function (t, duration)
            local e = envelope(t, duration)
            return vec(14 * e, 0, -5 * e)
        end,
    },
}
local idleNames = { "sniff", "look", "shake" }

local active = nil
local lastHealth = nil
local hurtCooldown = 0

function pings.playIdle(name, startTime)
    local entry = animations[name]
    if not entry or not player:isLoaded() then return end
    active = { name = name, start = startTime or client:getSystemTime(), entry = entry }
    if name == "sniff" then
        sounds:playSound("minecraft:entity.fox.sniff", player:getPos())
    elseif name == "shake" then
        ears.kick(vec(-16, 0, 5))
        tail.flick(18)
    elseif name == "flinch" then
        ears.kick(vec(22, 0, 0))
        tail.flick(-14)
    end
end

options.onChange("idleAnims", function (enabled)
    if not enabled then
        active = nil
        idleTimer = math.random(idleMinDelay, idleMaxDelay)
    end
end)
options.onChange("hurtReactions", function (enabled)
    if not enabled and active and active.name == "flinch" then active = nil end
end)

local function tickHurt()
    local health = player:getHealth()
    if lastHealth then
        if options.hurtReactions and health < lastHealth and health > 0 and hurtCooldown <= 0
            and not sleep.isSleeping() and anim.activePose() == nil then
            hurtCooldown = 10
            pings.playIdle("flinch", client:getSystemTime())
        elseif health > lastHealth then
            hurtCooldown = 0
        end
    end
    lastHealth = health
    if hurtCooldown > 0 then hurtCooldown = hurtCooldown - 1 end
end

local function canPlayIdle()
    if not options.idleAnims then return false end
    if not client:isWindowFocused() or action_wheel:isEnabled() then return false end
    if anim.activePose() ~= nil or sleep.isSleeping() then return false end
    local pose = player:getPose()
    if pose ~= "STANDING" and pose ~= "CROUCHING" then return false end
    if player:getVehicle() ~= nil or player:isUsingItem() then return false end
    if not player:isOnGround() then return false end
    return player:getVelocity():lengthSquared() < 0.01
end

function events.entity_init()
    lastHealth = nil
    hurtCooldown = 0
end

function events.tick()
    if not player:isLoaded() then return end
    tickHurt()

    if active then
        local elapsed = (client:getSystemTime() - active.start) / 1000
        if elapsed >= active.entry.duration then
            active = nil
            idleTimer = math.random(idleMinDelay, idleMaxDelay)
        end
        return
    end

    if not canPlayIdle() then return end
    idleTimer = idleTimer - 1
    if idleTimer <= 0 then
        idleTimer = math.random(idleMinDelay, idleMaxDelay)
        pings.playIdle(idleNames[math.random(#idleNames)], client:getSystemTime())
    end
end

function events.render(delta)
    if not active then return end
    local t = (client:getSystemTime() - active.start) / 1000
    if t < 0 or t > active.entry.duration then return end
    head:offsetRot(active.entry.rot(t, active.entry.duration))
end
