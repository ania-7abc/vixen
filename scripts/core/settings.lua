-- Action wheel settings shared by all scripts.

local config = require("scripts.core.config")
local events = require("scripts.core.events")

local defaults = {
    blinking = true,
    foxSounds = true,
    snoring = true,
    tailWag = true,
    allInMouth = false,
    earTwitch = true,
    earPhysics = true,
    idleAnims = true,
}

local settings = {}
local actions = {}
local listeners = {}
local pingSetters = {}

for key, default in pairs(defaults) do
    settings[key] = default
end

local function notify(key, value)
    local action = actions[key]
    if action then action:setToggled(value) end
    for _, func in ipairs(listeners[key] or {}) do
        func(value)
    end
end

local function set(key, value)
    if settings[key] == value then return end
    settings[key] = value
    config.save(key, value)
    notify(key, value)
end

for key in pairs(defaults) do
    local pingName = "set" .. key:sub(1, 1):upper() .. key:sub(2)
    pings[pingName] = function (value)
        set(key, value)
    end
    pingSetters[key] = pings[pingName]
end

function settings.setAction(key, action)
    actions[key] = action
    action:setToggled(settings[key])
end

function settings.onChange(key, func)
    if not listeners[key] then listeners[key] = {} end
    table.insert(listeners[key], func)
    func(settings[key])
end

function settings.onEntityInit()
    config.migrate()
    for key, default in pairs(defaults) do
        local value = config.load(key, default)
        if host:isHost() and value ~= settings[key] then
            set(key, value)
            pingSetters[key](value)
        end
    end
end

events.on("entity_init", settings.onEntityInit)

return settings
