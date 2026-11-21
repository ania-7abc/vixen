-- Collects player state into the data table used by every animation node.

local modelAnims = animations["model"]
local state = require("scripts.core.state")

local driver = {}

-- creative flying is host-only information in Figura, so the host syncs it
-- to the other clients with a ping whenever the state changes
local creativeFlying = false
local lastSentFlying = false

local function isFalling(data)
    if data.pose ~= "STANDING" or data.creativeFlying then return false end
    return not data.isOnGround and data.velocity.y < -0.1 and data.jumpTime <= 0.01 and data.airTime > 1
end

function driver.setup(controller)
    function pings.setCreativeFlying(value)
        creativeFlying = value
    end

    controller:setDriver(function (data)
        local velocity = player:getVelocity()
        local bodyRot = player:getBodyYaw(1)
        local rotatedVelocity = vectors.rotateAroundAxis(bodyRot, velocity, vec(0, 1, 0))
        local sprinty = player:isSprinting()
        local pose = player:getPose()
        local inLiquid = #world.getBlockState(player:getPos()):getFluidTags() >= 1
        local vehicle = player:getVehicle()
        local isCrouching = player:isCrouching()
        local onGround = player:isOnGround()
        -- getPose() has no climbing value, so use a synthetic one for the tree
        local climbing = player:isClimbing() and not onGround and pose ~= "FALL_FLYING" and pose ~= "SWIMMING"

        if host:isHost() then
            local flying = host:isFlying()
            if flying ~= lastSentFlying then
                lastSentFlying = flying
                creativeFlying = flying
                pings.setCreativeFlying(flying)
            end
        end
        data.creativeFlying = creativeFlying
        -- snap in fast, but never cut to the flight pose in one frame
        local flyTarget = creativeFlying and 1 or 0
        data.flyBlend = math.lerp(data.flyBlend, flyTarget, 0.4)
        if math.abs(data.flyBlend - flyTarget) < 0.01 then data.flyBlend = flyTarget end

        -- hands
        local handedness = player:isLeftHanded()
        local using = player:isUsingItem()
        local activeness = player:getActiveHand()
        local leftItem = player:getHeldItem(not handedness)
        local rightItem = player:getHeldItem(handedness)
        local rightActive = handedness and "OFF_HAND" or "MAIN_HAND"
        local leftActive = not handedness and "OFF_HAND" or "MAIN_HAND"
        data.leftItem = leftItem
        data.rightItem = rightItem
        data.leftActive = using and activeness == leftActive
        data.rightActive = using and activeness == rightActive
        data.leftActiveAction = data.leftActive and leftItem:getUseAction() or "NONE"
        data.rightActiveAction = data.rightActive and rightItem:getUseAction() or "NONE"

        if vehicle ~= nil then
            pose = "SITTING"
        elseif climbing then
            pose = "CLIMBING"
        end
        data.pose = pose

        data.isSprinting = sprinty and not inLiquid
        data.sprintScale = math.lerp(data.sprintScale, data.isSprinting and 1 or 0, 0.6)
        -- cross-fade standing and sneaking instead of cutting between the poses
        data.crouchBlend = math.lerp(data.crouchBlend, data.pose == "CROUCHING" and 1 or 0, 0.25)
        -- sneaking has its own tail motion, so fade out the wagging animation
        data.wagBlend = math.lerp(data.wagBlend, data.pose == "CROUCHING" and 0 or 1, 0.25)

        -- the head tilt pose layers over other poses, but never over sleep
        local sleeping = state.isSleeping() or data.pose == "SLEEPING"
        local headTiltTarget = data.headTiltEnabled and not sleeping and 1 or 0
        data.headTiltBlend = math.lerp(data.headTiltBlend, headTiltTarget, 0.25)

        data.headTilt = math.lerp(data.headTilt, math.clamp(-velocity.y * 15, -25, 25), 0.3)

        data.velocity = velocity
        data.horizontalSpeed = velocity.xz:length()
        data.forwardSpeed = rotatedVelocity.z

        local speedMult = (isCrouching and 16 or 5)
        data.walkScale = math.clamp(data.horizontalSpeed * speedMult, 0, 1)
        data.smoothWalkScale = math.lerp(data.smoothWalkScale, data.walkScale, 0.5)
        data.smoothForwardScale = math.lerp(data.smoothForwardScale, math.clamp(data.forwardSpeed * speedMult, -1, 1), 0.5)

        local oldGroundTime = data.groundTime
        data.oldOnGround = data.isOnGround
        data.isOnGround = onGround
        data.airTime = data.isOnGround and 0 or data.airTime + 1
        data.groundTime = data.isOnGround and data.groundTime + 1 or 0

        data.jumpTime = data.jumpTime * 0.85
        if not data.isOnGround and data.oldOnGround and oldGroundTime > 2 and velocity.y > 0.1
            and not creativeFlying then
            -- creative takeoff is not a jump: the flight pose fades in instead
            data.jumpTime = math.min(velocity.y * 8, 2)
        elseif data.isOnGround then
            -- clear on touchdown: a long cooldown kept the sprint takeoff and
            -- the walk jump alive after landing, making hands jitter on exit
            data.jumpTime = 0
        end

        -- cross-fade to the takeoff pose instead of snapping into it, and back to
        -- the running cycle once the jump cooldown is over
        if data.isSprinting and data.jumpTime > 0.01 then
            data.takeoffBlend = math.min(1, data.takeoffBlend + 0.34)
        else
            data.takeoffBlend = math.max(0, data.takeoffBlend - 0.34)
        end

        -- walking jumps and falls fade in/out instead of switching poses in one tick
        local falling = isFalling(data)
        local walkJumping = falling or (data.jumpTime > 0.01 and data.smoothWalkScale > 0.1 and not data.isSprinting)
        if walkJumping and not data.wasWalkJumping then
            -- latch the leg that was about to step, before the walk cycle stops
            data.jumpPhase = (modelAnims.walk:getTime() % 1) < 0.5 and 0 or 1
            data.jumpDownBlend = data.jumpPhase
        end
        data.wasWalkJumping = walkJumping
        data.walkJumpBlend = math.lerp(data.walkJumpBlend, walkJumping and 1 or 0, 0.5)
        data.jumpDownBlend = math.lerp(data.jumpDownBlend, (falling or data.jumpPhase == 1) and 1 or 0, 0.5)

        data.crouchAirBlend = math.lerp(data.crouchAirBlend, data.isOnGround and 0 or 1, 0.5)

        -- fade wheel poses in and out instead of snapping into them
        data.wheelBlend = math.lerp(data.wheelBlend, data.wheel and 1 or 0, 0.2)
        data.poseSwapBlend = math.lerp(data.poseSwapBlend, 1, 0.2)
    end,
    {
        wheel = false,
        wheelBlend = 0,
        poseSwapBlend = 1,
        isOnGround = false,
        airTime = 0,
        groundTime = 0,
        jumpTime = 0,
        takeoffBlend = 0,
        walkJumpBlend = 0,
        jumpDownBlend = 0,
        jumpPhase = 0,
        wasWalkJumping = false,
        crouchAirBlend = 0,
        creativeFlying = false,
        flyBlend = 0,
        headTilt = 0,
        sprintScale = 0,
        crouchBlend = 0,
        wagBlend = 1,
        headTiltEnabled = false,
        headTiltBlend = 0,
        smoothWalkScale = 0,
        smoothForwardScale = 0,
    }
    )
end

return driver
