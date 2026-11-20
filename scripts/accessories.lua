require("scripts.util")

local partNames = {
    collar = "Collar",
    scarf = "Scarf",
    bowTie = "BowTie",
}

local keys = { "collar", "scarf", "bowTie" }
local state = {
    collar = false,
    scarf = false,
    bowTie = false,
}
local actions = {}

local function apply(key, value)
    state[key] = value
    local part = models.model.root.Body[partNames[key]]
    if part then part:setVisible(value) end
    local action = actions[key]
    if action then action:setToggled(value) end
end

function pings.setAccessory(key, value)
    if state[key] == nil then return end
    apply(key, value)
end

local accessories = {}

function events.entity_init()
    for _, key in ipairs(keys) do
        local value = safeConfigLoad(key, false)
        if host:isHost() and value ~= state[key] then
            pings.setAccessory(key, value)
        else
            apply(key, value)
        end
    end
end

function accessories.setAction(key, action)
    actions[key] = action
    action:setToggled(state[key])
end

function accessories.set(key, value)
    if state[key] == nil or state[key] == value then return end
    pings.setAccessory(key, value)
    if host:isHost() then config:save(key, value) end
end

accessories.keys = keys

return accessories
