-- The animation graph. Node structure and blend values are unchanged.

local items = require("scripts.features.items")
local lib = require("scripts.lib.aurianims")
local parts = require("scripts.core.parts")
local constants = require("scripts.features.animation.constants")

local modelAnims = animations["model"]
local walkAnimSpeedMult = constants.walkAnimSpeedMult
local walkBackAnimSpeedMult = constants.walkBackAnimSpeedMult

local tree = {}

function tree.setup(controller)
    local vanillaHandsAnim = lib.stack{
        lib.vanilla({
            parts.leftArm,
            parts.rightArm
        }, function (name, rot)
            local handedness = player:isLeftHanded()
            local offhand = name == "RIGHT_ARM" and handedness or not handedness
            local heldItem = player:getHeldItem(offhand)
            if not items.isHandBusy(heldItem, player:isSprinting(), offhand) then return end

            -- the item is routed to the mouth, but vanilla still sees it in the
            -- hand and puts the arm into a grip pose. Drop that vanilla pose
            -- completely instead of only subtracting its 18 degree tilt: the
            -- remaining rotation still reads as "holding an item" from any view.
            -- Keep the natural walk swing from the matching leg (arms and legs
            -- are in antiphase and the leg has no item pose or idle bob).
            local leg = name == "RIGHT_ARM" and vanilla_model.RIGHT_LEG or vanilla_model.LEFT_LEG
            rot.x = -leg:getOriginRot().x / 2.8
            rot.y = 0
            rot.z = 0
        end),
        modelAnims.handOverride -- override hand animations so that they dont play twice
    }

    local leftArmAnim = lib.switch(
        function (data)
            return data.leftActiveAction
        end,
        {
            NONE = nil,
            BLOCK = modelAnims.blockL, -- shield
            SPEAR = modelAnims.spearL, -- trident
        }
    )

    local rightArmAnim = lib.switch(
        function (data)
            return data.rightActiveAction
        end,
        {
            NONE = nil,
            BLOCK = modelAnims.blockR, -- shield
            SPEAR = modelAnims.spearR, -- trident
        }
    )

    local function usingAction(data, action)
        return (data.leftActive and data.leftActiveAction == action)
            or (data.rightActive and data.rightActiveAction == action)
    end

    local function isCrossbowReady(item)
        local tag = item.tag
        return tag and (tag["Charged"] == 1 or (tag["ChargedProjectiles"] and next(tag["ChargedProjectiles"]) ~= nil)) or false
    end

    local bowAnim = lib.conditional(
        function (data) return usingAction(data, "BOW") end,
        modelAnims.bow
    )

    local crossbowAnim = lib.conditional(
        function (data)
            return usingAction(data, "CROSSBOW") or isCrossbowReady(data.leftItem) or isCrossbowReady(data.rightItem)
        end,
        modelAnims.crossbow
    )

    local eatingAnim = lib.conditional(
        function (data) return usingAction(data, "EAT") end,
        modelAnims.eat
    )

    local drinkingAnim = lib.conditional(
        function (data) return usingAction(data, "DRINK") end,
        modelAnims.drink
    )

    local armsIdleAnim = lib.mix(
        function (data)
            return data.smoothWalkScale
        end,
        modelAnims.armsIdle,
        lib.mix(
            function (data)
                return data.smoothForwardScale / 2 + 0.5
            end,
            modelAnims.armsWalkBack,
            modelAnims.armsWalk
        )
    )

    local armsAnim = lib.stack{
        lib.step(
            function (data)
                return data.leftActive or data.rightActive
            end,
            lib.stack{
                leftArmAnim,
                rightArmAnim,
                bowAnim,
            },
            armsIdleAnim
        ),
        crossbowAnim
    }

    local walkingAnim = lib.mix(
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
        lib.mix(
            function (data)
                return data.smoothForwardScale / 2 + 0.5
            end,
            modelAnims.walkBack,
            modelAnims.walk
        )
    )

    -- the walk cycle is latched when the jump starts, so the jump pose lines up with
    -- the leg that was about to be raised; blend between the two held poses so
    -- changing legs mid-fall doesn't snap either
    local walkJumpAnim = lib.mix(
        function (data)
            return data.jumpDownBlend
        end,
        modelAnims.walkJumpUp,
        modelAnims.walkJumpDown
    )

    local legMovementAnim = lib.mix(
        function (data)
            return data.walkJumpBlend
        end,
        walkingAnim,
        walkJumpAnim
    )

    local twoLeggedAnim = lib.stack{
        modelAnims.tailIdle,
        armsAnim,
        legMovementAnim
    }

    -- push off into the held jump pose, then cross-fade back into the running cycle.
    -- the takeoff animation ends on sprint's first frame, so the return stays seamless.
    local sprintTakeoffBlend = lib.mix(
        function (data)
            local t = math.clamp(data.takeoffBlend, 0, 1)
            return t * t * (3 - 2 * t), false
        end,
        modelAnims.sprint,
        modelAnims.sprintTakeoff
    )

    local fourLeggedAnim = lib.stack{
        sprintTakeoffBlend
    }

    local movementAnim = lib.mix(
        function (data)
            return data.sprintScale, false
        end,
        twoLeggedAnim,
        fourLeggedAnim
    )

    local crouchWalkAnim = lib.mix(
        function (data)
            local speed = math.clamp(math.abs(data.smoothForwardScale) * 5, 0.5, 1.5)
            modelAnims.crouchWalk:setSpeed(data.smoothForwardScale < 0 and -speed or speed)
            return data.smoothWalkScale
        end,
        modelAnims.crouch,
        modelAnims.crouchWalk
    )

    local crouchAnim = lib.mix(
        function (data)
            return data.crouchAirBlend
        end,
        crouchWalkAnim,
        modelAnims.crouchFall2
    )

    local bendKneesToVanilla = lib.func(
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
            parts.leftCalf:setRot(lCalfRot * blend)
            parts.rightCalf:setRot(rCalfRot * blend)
        end
    )

    local directionalFlyAnim = lib.step(
        function (data)
            return data.velocity.y > 0.1
        end,
        modelAnims.tiltUp,
        lib.step(
            function (data)
                return data.velocity.y < -0.1
            end,
            modelAnims.tiltDown,
            modelAnims.fly
        )
    )

    local flightAnim = lib.stack{
        directionalFlyAnim,
        bendKneesToVanilla,
    }

    local standingAnim = lib.stack{
        movementAnim,
        eatingAnim,
        drinkingAnim,
    }

    local groundAnim = lib.mix(
        function (data)
            return data.crouchBlend
        end,
        standingAnim,
        crouchAnim
    )

    local playerAnim = lib.step(
        function (data)
            return data.pose == "FALL_FLYING" or data.pose == "SPIN_ATTACK"
        end,
        flightAnim,
        lib.step(
            function (data)
                return data.pose == "SWIMMING"
            end,
            bendKneesToVanilla,
            lib.switch(
                function (data)
                    -- both ground poses share one fade node, so it must appear
                    -- under a single key or the switch updates it twice
                    if data.pose == "STANDING" or data.pose == "CROUCHING" then return "GROUND" end
                    return data.pose
                end,
                {
                    SLEEPING = modelAnims.sleep,
                    SITTING = modelAnims.sit,
                    CLIMBING = modelAnims.climb,
                    GROUND = groundAnim,
                }
            )
        )
    )

    local headTiltAnim = lib.func(
        function (data, blend)
            if data.pose == "FALL_FLYING" or data.pose == "SWIMMING" or data.pose == "SPIN_ATTACK" or data.pose == "CLIMBING" then return end
            parts.head:offsetRot(vec(data.headTilt * blend, 0, 0))
        end
    )

    -- blend the two pose animations directly, so a swap never drops to the idle pose
    local wheelSwapNode = lib.mix(
        function (data)
            return data.poseSwapBlend
        end,
        nil,
        nil
    )
    local wheelPoseAnim = wheelSwapNode

    local wagBlendAnim = lib.func(
        function (data, blend)
            animations.model.tailWag:blend(data.wagBlend)
        end
    )

    local mainAnim = lib.stack{
        lib.mix(
            function (data)
                return data.wheelBlend
            end,
            lib.stack{
                playerAnim,
                headTiltAnim,
            },
            wheelPoseAnim
        ),
        wagBlendAnim,
    }

    controller:setTree(mainAnim)

    return {
        wheelSwapNode = wheelSwapNode,
        modelAnims = modelAnims,
    }
end

return tree
