-- shared sleeping state for the skin texture, snoring and wheel animations
local sleep = {
    inBed = false,
    wheel = false,
}

local listeners = {}

function sleep.isSleeping()
    return sleep.inBed or sleep.wheel
end

function sleep.onChange(func)
    table.insert(listeners, func)
end

local function notify()
    for _, func in ipairs(listeners) do func() end
end

function sleep.setInBed(enabled)
    if sleep.inBed == enabled then return end
    sleep.inBed = enabled
    notify()
end

function pings.setWheelSleeping(enabled)
    if sleep.wheel == enabled then return end
    sleep.wheel = enabled
    notify()
end

return sleep
