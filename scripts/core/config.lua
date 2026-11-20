-- Config access used by every module that persists state.
-- Keep the version/migration table here so old saves keep working.

local CONFIG_VERSION = 1

local migrations = {
    -- custom skins were removed in this fork, so saves must not point at one
    [1] = function ()
        if config:load("currentSkin") == "Custom" then
            config:save("currentSkin", "Rebecca")
        end
    end,
}

local configUtil = {}

function configUtil.migrate()
    if not host:isHost() then return end
    local version = config:load("configVersion") or 0
    while version < CONFIG_VERSION do
        local migrate = migrations[version + 1]
        if migrate then migrate() end
        version = version + 1
    end
    config:save("configVersion", version)
end

--- Read without persisting a default (used for legacy keys).
---@param key string
---@return any
function configUtil.raw(key)
    if not host:isHost() then return nil end
    return config:load(key)
end

---@param key string
---@param default any
---@return any
function configUtil.load(key, default)
    if not host:isHost() then return default end
    local value = config:load(key)
    if value == nil then
        config:save(key, default)
        return default
    end
    return value
end

---@param key string
---@param value any
function configUtil.save(key, value)
    if host:isHost() then config:save(key, value) end
end

return configUtil
