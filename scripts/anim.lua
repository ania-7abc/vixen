require("scripts.util")
require("scripts.sleep")

local wheel = require("scripts.wheel")
local items = require("scripts.items")

local aurianims = require("scripts.aurianims")

local modelAnims = animations["model"]
local animController = aurianims.new()

local sprintAnimSpeedMult = 0.8
local walkAnimSpeedMult = 0.9
local walkBackAnimSpeedMult = 1.4

animController:setDriver(function (data)
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

    data.headTilt = math.lerp(data.headTilt, math.clamp(-velocity.y * 15, -25, 25), 0.3)

    data.velocity = velocity
    data.horizontalSpeed = velocity.xz:length()
    data.forwardSpeed = rotatedVelocity.z

    local speedMult = (isCrouching and 16 or 5)
    data.walkScale = math.clamp(data.horizontalSpeed * speedMult, 0, 1)
    data.smoothWalkScale = math.lerp(data.smoothWalkScale, data.walkScale, 0.5)
    data.smoothForwardScale = math.lerp(data.smoothForwardScale, math.clamp(data.forwardSpeed * speedMult, -1, 1), 0.5)

    data.oldOnGround = data.isOnGround
    data.isOnGround = onGround
    data.airTime = data.isOnGround and 0 or data.airTime + 1

    data.jumpTime = data.jumpTime * 0.85
    if not data.isOnGround and data.oldOnGround and velocity.y > 0.1 then
        data.jumpTime = math.min(velocity.y * 8, 2)
    elseif data.isOnGround then
        data.jumpTime = math.lerp(data.jumpTime, 0, 0.6)
    end
end,
{
    wheel = false,
    isOnGround = false,
    airTime = 0,
    jumpTime = 0,
    headTilt = 0,
    sprintScale = 0,
    smoothWalkScale = 0,
    smoothForwardScale = 0,
}
)

local vanillaHandsAnim = aurianims.stack{
    aurianims.vanilla({
        models.model.root.LeftArm,
        models.model.root.RightArm
    }, function (name, rot)
        local handedness = player:isLeftHanded()
        local heldItem = name == "RIGHT_ARM" and player:getHeldItem(handedness) or player:getHeldItem(not handedness)
        if not items.isHandBusy(heldItem, player:isSprinting()) then return end

        -- vanilla halves the walk swing and tilts the arm down 18 degrees for held items.
        -- undo the pose, but take the missing half of the swing from the matching leg:
        -- both use the same walk cycle, while the leg has no item pose or idle bob,
        -- so doubling this way would not double the bob as well
        local leg = name == "RIGHT_ARM" and vanilla_model.RIGHT_LEG or vanilla_model.LEFT_LEG
        rot.x = rot.x - 18 + leg:getOriginRot().x / 2.8
    end),
    modelAnims.handOverride -- override hand animations so that they dont play twice
}

local leftArmAnim = aurianims.switch(
    function (data)
        return data.leftActiveAction
    end,
    {
        NONE = nil,
        BLOCK = modelAnims.blockL, -- shield
        SPEAR = modelAnims.spearL, -- trident
    }
)

local rightArmAnim = aurianims.switch(
    function (data)
        return data.rightActiveAction
    end,
    {
        NONE = nil,
        BLOCK = modelAnims.blockR, -- shield
        SPEAR = modelAnims.spearR, -- trident
    }
)

local bowAnim = aurianims.conditional(
    function (data)
        local bowL = data.leftActive and data.leftActiveAction == "BOW"
        local bowR = data.rightActive and data.rightActiveAction == "BOW"
        return bowL or bowR
    end,
    modelAnims.bow
)

local crossbowAnim = aurianims.conditional(
    function (data)
        local loadL = data.leftActive and data.leftActiveAction == "CROSSBOW"
        local loadR = data.rightActive and data.rightActiveAction == "CROSSBOW"
        local lTag = data.leftItem.tag
        local rTag = data.rightItem.tag
        local crossL = lTag and (lTag["Charged"] == 1 or (lTag["ChargedProjectiles"] and next(lTag["ChargedProjectiles"]) ~= nil)) or false
        local crossR = rTag and (rTag["Charged"] == 1 or (rTag["ChargedProjectiles"] and next(rTag["ChargedProjectiles"]) ~= nil)) or false
        return loadL or loadR or crossL or crossR
    end,
    modelAnims.crossbow
)

local eatingAnim = aurianims.conditional(
    function (data)
        local eatL = data.leftActive and data.leftActiveAction == "EAT"
        local eatR = data.rightActive and data.rightActiveAction == "EAT"
        return eatL or eatR
    end,
    modelAnims.eat
)

local drinkingAnim = aurianims.conditional(
    function (data)
        local drinkL = data.leftActive and data.leftActiveAction == "DRINK"
        local drinkR = data.rightActive and data.rightActiveAction == "DRINK"
        return drinkL or drinkR
    end,
    modelAnims.drink
)

local armsIdleAnim = aurianims.mix(
    function (data)
        return data.smoothWalkScale
    end,
    modelAnims.armsIdle,
    aurianims.mix(
        function (data)
            return data.smoothForwardScale / 2 + 0.5
        end,
        modelAnims.armsWalkBack,
        modelAnims.armsWalk
    )
)

local armsAnim = aurianims.stack{
    aurianims.step(
        function (data)
            return data.leftActive or data.rightActive
        end,
        aurianims.stack{
            leftArmAnim,
            rightArmAnim,
            bowAnim,
        },
        armsIdleAnim
    ),
    crossbowAnim
}

local walkingAnim = aurianims.mix(
    function (data)
        local speed = math.max(0.5, data.walkScale)
        modelAnims.walk:setSpeed(speed * walkAnimSpeedMult)
        modelAnims.armsWalk:setSpeed(speed * walkAnimSpeedMult)
        modelAnims.armsWalk:setTime(modelAnims.walk:getTime())
        modelAnims.walkBack:setSpeed(speed * walkBackAnimSpeedMult)
        modelAnims.armsWalkBack:setSpeed(speed * walkBackAnimSpeedMult)
        modelAnims.armsWalkBack:setTime(modelAnims.walkBack:getTime())
        return data.smoothWalkScale
    end,
    vanillaHandsAnim,
    aurianims.mix(
        function (data)
            return data.smoothForwardScale / 2 + 0.5
        end,
        modelAnims.walkBack,
        modelAnims.walk
    )
)

-- continue the current walk cycle when jumping so the jump pose lines up with
-- the leg that was about to be raised
local walkJumpAnim = aurianims.switch(
    function (data)
        return (modelAnims.walk:getTime() % 1) < 0.5 and "up" or "down"
    end,
    {
        up = modelAnims.walkJumpUp,
        down = modelAnims.walkJumpDown,
    }
)

local legMovementAnim = aurianims.step(
    function (data)
        return data.jumpTime > 0.01 and data.smoothWalkScale > 0.1 and not data.isSprinting
    end,
    walkJumpAnim,
    walkingAnim
)

local twoLeggedAnim = aurianims.stack{
    modelAnims.tailIdle,
    armsAnim,
    legMovementAnim
}

local sprintJumpAnim = aurianims.step(
    function (data)
        return data.velocity.y > 0
    end,
    modelAnims.sprintJumpUp,
    modelAnims.sprintJumpDown
)

local fourLeggedAnim = aurianims.step(
    function (data)
        return data.jumpTime > 0.01
    end,
    sprintJumpAnim,
    modelAnims.sprint
)

local movementAnim = aurianims.mix(
    function (data)
        return data.sprintScale, false
    end,
    twoLeggedAnim,
    fourLeggedAnim
)

local crouchWalkAnim = aurianims.mix(
    function (data)
        local speed = math.clamp(math.abs(data.smoothForwardScale) * 5, 0.5, 1.5)
        modelAnims.crouchWalk:setSpeed(data.smoothForwardScale < 0 and -speed or speed)
        return data.smoothWalkScale
    end,
    modelAnims.crouch,
    modelAnims.crouchWalk
)

local crouchAnim = aurianims.step(
    function (data)
        return not data.isOnGround
    end,
    modelAnims.crouchFall2,
    crouchWalkAnim
)

local bendKneesToVanilla = aurianims.func(
    function (data, blend)
        -- set calves rotation to match the vanilla rotation of the legs making them look less stiff
        local lCalfRot = vec(0, 0, 0)
        local rCalfRot = vec(0, 0, 0)
        if blend > 0 then
            lCalfRot = vanilla_model.LEFT_LEG:getOriginRot()
            rCalfRot = vanilla_model.RIGHT_LEG:getOriginRot()
            lCalfRot.x = math.clamp(lCalfRot.x, -30, 0)
            rCalfRot.x = math.clamp(rCalfRot.x, -30, 0)
        end
        models.model.root.LeftLeg.LeftCalf:setRot(lCalfRot * blend)
        models.model.root.RightLeg.RightCalf:setRot(rCalfRot * blend)
    end
)

local directionalFlyAnim = aurianims.step(
    function (data)
        return data.velocity.y > 0.1
    end,
    modelAnims.tiltUp,
    aurianims.step(
        function (data)
            return data.velocity.y < -0.1
        end,
        modelAnims.tiltDown,
        modelAnims.fly
    )
)

local flightAnim = aurianims.stack{
    directionalFlyAnim,
    bendKneesToVanilla,
}

local playerAnim = aurianims.step(
    function (data)
        return data.pose == "FALL_FLYING" or data.pose == "SPIN_ATTACK"
    end,
    flightAnim,
    aurianims.step(
        function (data)
            return data.pose == "SWIMMING"
        end,
        bendKneesToVanilla,
        aurianims.switch(
            function (data)
                return data.pose
            end,
            {
                SLEEPING = modelAnims.sleep,
                SITTING = modelAnims.sit,
                CLIMBING = modelAnims.climb,
                CROUCHING = crouchAnim,
                STANDING = aurianims.stack{
                    movementAnim,
                    eatingAnim,
                    drinkingAnim,
                }
            }
        )
    )
)

-- the fall pose replaces the pose selected by playerAnim, so it can only be
-- started once per fall instead of being restarted from several branches
-- crouching has its own airborne pose in crouchAnim
local function isFalling(data)
    if data.pose ~= "STANDING" then return false end
    return not data.isOnGround and data.velocity.y < -0.1 and data.jumpTime <= 0.01 and data.airTime > 1
end

local fallingAnim = aurianims.step(
    function (data)
        return data.isSprinting
    end,
    modelAnims.sprintJumpDown,
    modelAnims.walkJumpDown
)

local headTiltAnim = aurianims.func(
    function (data, blend)
        if data.pose == "FALL_FLYING" or data.pose == "SWIMMING" or data.pose == "SPIN_ATTACK" or data.pose == "CLIMBING" then return end
        models.model.root.Head:offsetRot(vec(data.headTilt * blend, 0, 0))
    end
)

local mainAnim = aurianims.step(
    function (data)
        return data.wheel
    end,
    nil,
    aurianims.stack{
        aurianims.step(
            isFalling,
            fallingAnim,
            playerAnim
        ),
        headTiltAnim,
    }
)

animController:setTree(mainAnim)

function events.entity_init()
    animations.model.sprint:setSpeed(sprintAnimSpeedMult)
end

local wheelAnim = nil
local wheelAnimPos = vec(0, 0, 0)
local wAnimStopDistanceSquared = 0.01

function events.tick()
    -- stop wheel anims when moving
    if wheelAnim and (wheelAnimPos - player:getPos()):lengthSquared() > wAnimStopDistanceSquared then pings.stopWheelAnim() end
end

function pings.stopWheelAnim()
    if wheelAnim then
        wheelAnim:stop()
        wheelAnim = nil
    end
    animController.data.wheel = false
    pings.setWheelSleeping(false)
end
function pings.playWheelAnim(animName)
    wheelAnimPos = player:getPos()
    if wheelAnim then wheelAnim:stop() end
    wheelAnim = animations.model[animName]
    animController.data.wheel = true
    wheelAnim:play()
end

function pings.setWag(enabled)
    if enabled then
        sounds:playSound("minecraft:entity.fox.ambient", player:getPos())
        animations.model.tailWag:loop("LOOP")
        forceStartAnim(animations.model.wag)
        animations.model.tailWag:play()
    else
        animations.model.tailWag:loop("ONCE")
    end
end

wheel.animPage:newAction()
:setTitle("sleep")
:setItem("minecraft:red_bed")
:onLeftClick(function (_)
    pings.setWheelSleeping(true)
    pings.playWheelAnim("wSleep")
end)

wheel.animPage:newAction()
:setTitle("sit")
:setItem("minecraft:spruce_stairs")
:onLeftClick(function (_)
    pings.setWheelSleeping(false)
    pings.playWheelAnim("wSit")
end)

wheel.animPage:newAction()
:setTitle("sit alt")
:setItem("minecraft:oak_stairs")
:onLeftClick(function (_)
    pings.setWheelSleeping(false)
    pings.playWheelAnim("wSitAlt")
end)

wheel.animPage:newAction()
:setTitle("wag")
:setToggleTitle("wagging")
:setItem("minecraft:feather")
:setToggleItem("minecraft:sugar")
:onToggle(function (state, _)
    pings.setWag(state)
end)
