-- Wheel-driven poses and tail wag control.

local state = require("scripts.core.state")
local util = require("scripts.core.util")
local events = require("scripts.core.events")

local poses = {}

local wAnimStopDistanceSquared = 0.01

function poses.setup(controller, wheelSwapNode, modelAnims)
    local wheelAnimPos = vec(0, 0, 0)

    events.on("tick", function ()
        -- stop wheel anims when moving
        local name = state.activePose()
        if name and (wheelAnimPos - player:getPos()):lengthSquared() > wAnimStopDistanceSquared then
            pings.stopWheelAnim()
        end
    end)

    function pings.stopWheelAnim()
        state.setWheelPose(nil)
        controller.data.wheel = false
        pings.setWheelSleeping(false)
    end

    function pings.playWheelAnim(animName)
        wheelAnimPos = player:getPos()
        local current = state.activePose()
        if current then
            if current ~= animName then
                wheelSwapNode.anim1 = modelAnims[current]
                wheelSwapNode.anim2 = modelAnims[animName]
                wheelSwapNode.anim1:play()
                wheelSwapNode.anim2:play()
                wheelSwapNode.anim2:setBlend(0)
                -- start the fade on the old pose, so the new one never replaces an empty frame
                controller.data.poseSwapBlend = 0
                wheelSwapNode.blend = 0
                wheelSwapNode.oldBlend = 0
            end
        else
            wheelSwapNode.anim1 = nil
            wheelSwapNode.anim2 = modelAnims[animName]
            controller.data.poseSwapBlend = 1
            wheelSwapNode.blend = 1
            wheelSwapNode.oldBlend = 1
        end
        state.setWheelPose(animName)
        controller.data.wheel = true
    end

    function pings.setWag(enabled)
        if enabled then
            sounds:playSound("minecraft:entity.fox.ambient", player:getPos())
            animations.model.tailWag:loop("LOOP")
            util.forceStartAnim(animations.model.wag)
            animations.model.tailWag:play()
        else
            animations.model.tailWag:loop("ONCE")
        end
    end

    function pings.setHeadTilt(enabled)
        controller.data.headTiltEnabled = enabled
        if enabled then util.forceStartAnim(modelAnims.headTilt) end
    end

    function poses.activePose()
        return state.activePose()
    end

    function poses.stop()
        pings.stopWheelAnim()
    end

    function poses.sleep()
        pings.setWheelSleeping(true)
        pings.playWheelAnim("wSleep")
    end

    function poses.pose(animName)
        pings.setWheelSleeping(false)
        pings.playWheelAnim(animName)
    end

    function poses.wag(enabled)
        pings.setWag(enabled)
    end

    function poses.headTilt(enabled)
        pings.setHeadTilt(enabled)
    end

    return poses
end

return poses
