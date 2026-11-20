-- burning pose: paws raised back with a slow sway

local function isBurning()
    return player:isLoaded() and player:isOnFire()
end

local leftArm = models.model.root.LeftArm
local rightArm = models.model.root.RightArm

local function swayArm(part, side, time)
    local phase = time * 6 + (side < 0 and 0 or math.pi)
    local x = -140 + math.sin(phase) * 8
    local z = side * 25 + math.sin(phase) * 10
    part:offsetRot(vec(x, 0, z))
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
