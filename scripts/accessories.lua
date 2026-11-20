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

local function getPart(key)
    local name = partNames[key]
    return models.model.root.Body[name] or models.model.root[name]
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

function events.entity_init()
    -- the accessory cubes live on their own texture; make sure the parts use it
    -- even if the global skin texture is overridden by scripts/skins.lua
    local texture = textures["assets.accessories"] or textures:get("assets.accessories")
    if texture then
        for _, key in ipairs(keys) do
            local part = getPart(key)
            if part then part:setPrimaryTexture("CUSTOM", texture) end
        end
    end

    for _, key in ipairs(keys) do
        apply(key, safeConfigLoad(key, false))
    end

    if host:isHost() then
        for _, key in ipairs(keys) do
            pings.setAccessory(key, state[key])
        end
    end
end

function accessories.setAction(key, action)
    actions[key] = action
    action:setToggled(state[key])
end

function accessories.set(key, value)
    if state[key] == nil or state[key] == value then return end
    -- pings only reach other clients, so always apply locally as well
    pings.setAccessory(key, value)
    apply(key, value)
    if host:isHost() then config:save(key, value) end
end

accessories.keys = keys

return accessories
