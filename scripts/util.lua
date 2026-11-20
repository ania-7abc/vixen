local CONFIG_VERSION = 1

local migrations = {
    -- custom skins were removed in this fork, so saves must not point at one
    [1] = function ()
        if config:load("currentSkin") == "Custom" then
            config:save("currentSkin", "Rebecca")
        end
    end,
}

function migrateConfig()
    if not host:isHost() then return end
    local version = config:load("configVersion") or 0
    while version < CONFIG_VERSION do
        local migrate = migrations[version + 1]
        if migrate then migrate() end
        version = version + 1
    end
    config:save("configVersion", version)
end

---@param tbl table
---@param x any
---@return boolean
function contains(tbl, x)
    for _, v in pairs(tbl) do
        if v == x then 
            return true
        end
    end
    return false
end

---@param sound Minecraft.soundID
function pings.playerSound(sound)
    sounds:playSound(sound, player:getPos())
end

---@param anim Animation
function forceStartAnim(anim) 
    if anim:isPlaying() then
        anim:stop()
    end
    anim:play()
end

---@param key string
---@param default any
---@return any
function safeConfigLoad(key, default)
    if not host:isHost() then return default end
    local value = config:load(key)
    if value == nil then
        config:save(key, default)
        return default
    end
    return value
end
