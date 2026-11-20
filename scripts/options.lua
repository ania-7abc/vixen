require("scripts.util")

-- action wheel settings shared by all scripts
local defaults = {
    blinking = true,
    foxSounds = true,
    snoring = true,
    tailWag = true,
    allInMouth = false,
    earTwitch = true,
    earPhysics = true,
}

local options = {}
local actions = {}
local listeners = {}
local pingSetters = {}

for key, default in pairs(defaults) do
    options[key] = default
end

local function notify(key, value)
    local action = actions[key]
    if action then action:setToggled(value) end
    for _, func in ipairs(listeners[key] or {}) do
        func(value)
    end
end

local function set(key, value)
    if options[key] == value then return end
    options[key] = value
    if host:isHost() then config:save(key, value) end
    notify(key, value)
end

for key in pairs(defaults) do
    local pingName = "set" .. key:sub(1, 1):upper() .. key:sub(2)
    pings[pingName] = function (value)
        set(key, value)
    end
    pingSetters[key] = pings[pingName]
end

function options.setAction(key, action)
    actions[key] = action
    action:setToggled(options[key])
end

function options.onChange(key, func)
    if not listeners[key] then listeners[key] = {} end
    table.insert(listeners[key], func)
    func(options[key])
end

function events.entity_init()
    migrateConfig()
    for key, default in pairs(defaults) do
        local value = safeConfigLoad(key, default)
        if host:isHost() and value ~= options[key] then
            set(key, value)
            pingSetters[key](value)
        end
    end
end

return options
