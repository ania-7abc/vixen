require("scripts.util")

-- action wheel settings shared by all scripts
local defaults = {
    blinking = true,
    foxSounds = true,
    snoring = true,
    autoSkin = false,
    tailWag = true,
}

local options = {}
local actions = {}
local listeners = {}

for key, default in pairs(defaults) do
    options[key] = default
end

local function notify(key, value)
    local action = actions[key]
    if action then action:setToggled(value) end
    local keyListeners = listeners[key]
    if keyListeners then
        for _, func in ipairs(keyListeners) do func(value) end
    end
end

local function set(key, value)
    if options[key] == value then return end
    options[key] = value
    if host:isHost() then config:save(key, value) end
    notify(key, value)
end

function pings.setBlinking(value)
    set("blinking", value)
end

function pings.setFoxSounds(value)
    set("foxSounds", value)
end

function pings.setSnoring(value)
    set("snoring", value)
end

function pings.setAutoSkin(value)
    set("autoSkin", value)
end

function pings.setTailWag(value)
    set("tailWag", value)
end

local pingSetters = {
    blinking = pings.setBlinking,
    foxSounds = pings.setFoxSounds,
    snoring = pings.setSnoring,
    autoSkin = pings.setAutoSkin,
    tailWag = pings.setTailWag,
}

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
