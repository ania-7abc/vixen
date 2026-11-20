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
        end
    end
end)

function accessories.setAction(key, action)
    actions[key] = action
    action:setToggled(state[key])
end

function accessories.set(key, value)
    if state[key] == nil or state[key] == value then return end
    -- pings only reach other clients, so always apply locally as well
    apply(key, value)
    pings.setAccessory(key, value)
    config.save(key, value)
end

accessories.keys = keys

return accessories
