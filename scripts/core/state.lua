-- Shared runtime state: sleeping, wheel pose and their change listeners.

local state = {
    inBed = false,
    wheel = false,
    wheelPose = nil,
}

local sleepListeners = {}

function state.isSleeping()
    return state.inBed or state.wheel
end

function state.onChange(func)
    table.insert(sleepListeners, func)
end

local function notifySleep()
    for _, func in ipairs(sleepListeners) do func() end
end

function state.setInBed(enabled)
    if state.inBed == enabled then return end
    state.inBed = enabled
    notifySleep()
end

function state.setWheelSleeping(enabled)
    if state.wheel == enabled then return end
    state.wheel = enabled
    notifySleep()
end

function state.activePose()
    return state.wheelPose
end

---@param name string?
function state.setWheelPose(name)
    if state.wheelPose == name then return end
    state.wheelPose = name
end

function pings.setWheelSleeping(enabled)
    state.setWheelSleeping(enabled)
end

return state
