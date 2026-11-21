local config = require("scripts.core.config")
local events = require("scripts.core.events")
local parts = require("scripts.core.parts")

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
-- the collar and the scarf occupy the same place on the neck
local exclusive = {
    collar = "scarf",
    scarf = "collar",
}
local actions = {}

local function getPart(key)
    local name = partNames[key]
    return parts.root.Body[name] or parts.root[name]
end

local function apply(key, value)
    state[key] = value
    local part = getPart(key)
    if part then part:setVisible(value) end
    local action = actions[key]
    if action then action:setToggled(value) end
    -- keep every path (config load, ping, wheel) consistent, and make the
    -- recursion stop on the partner being switched off
    if value then
        local other = exclusive[key]
        if other and state[other] then apply(other, false) end
    end
end

function pings.setAccessory(key, value)
    if state[key] == nil then return end
    apply(key, value)
end

local accessories = {}

events.on("entity_init", function ()
    -- the accessory cubes use the texture embedded in model.bbmodel, while the
    -- skins live in assets/. Re-apply it after the global skin texture override.
    local texture = textures["model.accessories"] or textures:get("model.accessories")
        or textures["assets.accessories"] or textures:get("assets.accessories")
    if texture then
        for _, key in ipairs(keys) do
            local part = getPart(key)
            if part then part:setPrimaryTexture("CUSTOM", texture) end
        end
    end

    for _, key in ipairs(keys) do
        apply(key, config.load(key, false))
    end

    if host:isHost() then
        for _, key in ipairs(keys) do
            pings.setAccessory(key, state[key])
            -- persist the resolved state in case an old config had both the
            -- collar and the scarf enabled at the same time
            config.save(key, state[key])
        end
    end
end)

function accessories.setAction(key, action)
    actions[key] = action
    action:setToggled(state[key])
end

function accessories.set(key, value)
    if state[key] == nil or state[key] == value then return end
    local other = exclusive[key]
    local disableOther = value and other and state[other] or false
    -- pings only reach other clients, so always apply locally as well
    apply(key, value)
    pings.setAccessory(key, value)
    config.save(key, value)
    if disableOther then
        pings.setAccessory(other, false)
        config.save(other, false)
    end
end

accessories.keys = keys

return accessories
