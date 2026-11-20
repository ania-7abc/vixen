local blend = 0

local function isBurning()
    return player:isLoaded() and player:isOnFire()
end

local function isActive()
    return blend > 0.01
end

function events.tick()
    if not player:isLoaded() then return end
    blend = math.lerp(blend, isBurning() and 1 or 0, 0.3)
    if blend < 0.001 then blend = 0 end
    if blend > 0.999 then blend = 1 end
end

local leftArm = models.model.root.LeftArm
local rightArm = models.model.root.RightArm

local function swayArm(part, side, time)
    local phase = time * 6 + (side < 0 and 0 or math.pi)
    local sway = math.sin(phase) * 6
    part:offsetRot(vec(140 + sway, 0, -side * 28 + sway) * blend)
end

function events.render(delta)
    if not isActive() then return end
    local time = client:getSystemTime() / 1000
    swayArm(leftArm, -1, time)
    swayArm(rightArm, 1, time)
end

return {
    isActive = isActive,
}
