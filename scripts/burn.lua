local function isBurning()
    return player:isLoaded() and player:isOnFire()
end

local leftArm = models.model.root.LeftArm
local rightArm = models.model.root.RightArm

local function swayArm(part, side, time)
    local phase = time * 6 + (side < 0 and 0 or math.pi)
    local sway = math.sin(phase) * 6
    part:offsetRot(vec(140 + sway, 0, -side * 28 + sway))
end

function events.render(delta)
    if not isBurning() then return end
    local time = client:getSystemTime() / 1000
    swayArm(leftArm, -1, time)
    swayArm(rightArm, 1, time)
end

return {
    isBurning = isBurning,
}
