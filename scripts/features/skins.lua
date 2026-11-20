local config = require("scripts.core.config")
local state = require("scripts.core.state")
local settings = require("scripts.core.settings")
local parts = require("scripts.core.parts")
local time = require("scripts.core.time")
local events = require("scripts.core.events")

local skinEntries = {
    Rebecca = {
        title = "Forest Fox",
        texture = "assets.skin_rebecca",
        icon = "minecraft:redstone",
    },
    Mira = {
        title = "End Fox",
        texture = "assets.skin_mira",
        icon = "minecraft:target",
    },
    Eva = {
        title = "Nether Fox",
        texture = "assets.skin_eva",
        icon = "minecraft:crimson_nylium",
    },
    Rue = {
        title = "Desert Fox",
        texture = "assets.skin_rue",
        icon = "minecraft:red_sand",
    },
    Kaya = {
        title = "Winter Fox",
        texture = "assets.skin_kaya",
        icon = "minecraft:snow_block",
    },
    Thea = {
        title = "Shadow Fox",
        texture = "assets.skin_thea",
        icon = "minecraft:coal_block",
    },
}
local skinOrder = { "Rebecca", "Rue", "Kaya", "Thea", "Eva", "Mira" }
for key, skin in pairs(skinEntries) do
    skin.key = key
    if not skin.icon or not skin.title then
        log("[vixen] skin " .. key .. " is missing its icon or title")
    end
    if not skin.texture then
        log("[vixen] skin " .. key .. " is missing its texture")
    elseif not textures[skin.texture] or not textures[skin.texture .. "_sleep"] then
        if not textures[skin.texture] then
            log("[vixen] skin " .. key .. " is missing texture " .. skin.texture)
        end
        if not textures[skin.texture .. "_sleep"] then
            log("[vixen] skin " .. key .. " is missing sleeping texture " .. skin.texture .. "_sleep")
        end
    end
end

local currentSkin = skinEntries.Rebecca

-- automatic skin updated based on the biome
local autoSkinEnabled = false
local skinUpdateTimer = time.newInterval(80)
local function setAutoSkin(enabled)
    autoSkinEnabled = enabled
    config.save("autoSkin", enabled)
end
function pings.setAutoSkin(enabled)
    setAutoSkin(enabled)
end

-- sleeping and blinking
local blinkTimer = time.newTimer(60, 140)
local blinkTicks = 0
local blinkDuration = 3

local appliedClosed = nil
local function updateHeadTexture()
    local closed = state.isSleeping() or blinkTicks > 0
    if appliedClosed == closed then return end
    appliedClosed = closed
    parts.head:setPrimaryTexture("CUSTOM", textures[closed and (currentSkin.texture .. "_sleep") or currentSkin.texture])
end
state.onChange(updateHeadTexture)
settings.onChange("blinking", function (enabled)
    if not enabled then
        blinkTicks = 0
        updateHeadTexture()
    end
end)

local function tickBlink()
    if not settings.blinking then return end
    if blinkTicks > 0 then
        blinkTicks = blinkTicks - 1
        if blinkTicks == 0 then updateHeadTexture() end
    elseif not state.isSleeping() and blinkTimer:down() then
        blinkTimer:reset()
        blinkTicks = blinkDuration
        updateHeadTexture()
    end
end

local function setSkin(skin)
    if currentSkin == skin then return end
    currentSkin = skin
    parts.root:setPrimaryTexture("CUSTOM", textures[skin.texture])
    appliedClosed = nil
    updateHeadTexture()
    config.save("currentSkin", skin.key)
end
function pings.setSkin(skinKey)
    setSkin(skinEntries[skinKey] or currentSkin)
end

local function updateAutoSkin()
    -- nether fox in the nether
    local dimension = world.getDimension()
    if dimension == "minecraft:the_nether" then
        setSkin(skinEntries.Eva)
        return
    end
    -- end fox in the end
    if dimension == "minecraft:the_end" then
        setSkin(skinEntries.Mira)
        return
    end

    local biome = world.getBiome(player:getPos())
    local temperature = biome:getTemperature()

    -- winter fox in cold biomes
    if temperature <= 0.25 then
        setSkin(skinEntries.Kaya)
        return
    end

    -- desert fox in deserts and badlands
    if biome.id and (biome.id:find("desert") or biome.id:find("badlands")) then
        setSkin(skinEntries.Rue)
        return
    end

    -- shadow fox in dark forests
    if biome.id == "minecraft:dark_forest" then
        setSkin(skinEntries.Thea)
        return
    end

    -- forest fox everywhere else
    setSkin(skinEntries.Rebecca)
end

events.on("entity_init", function ()
    if not host:isHost() then return end
    local legacyAuto = config.raw("autoSkinEnabled") or false
    autoSkinEnabled = config.load("autoSkin", legacyAuto)
    pings.setAutoSkin(autoSkinEnabled)
    pings.setSkin(config.load("currentSkin", currentSkin.key))
end)

events.on("tick", function ()
    state.setInBed(player:getPose() == "SLEEPING")
    tickBlink()

    if not autoSkinEnabled then return end
    if not skinUpdateTimer:up() then return end
    updateAutoSkin()
end)

return {
    entries = skinEntries,
    order = skinOrder,
    activeKey = function ()
        return currentSkin.key
    end,
    isAuto = function ()
        return autoSkinEnabled
    end,
    select = function (key)
        pings.setAutoSkin(false)
        pings.setSkin(key)
    end,
    setAuto = function (enabled)
        pings.setAutoSkin(enabled)
        if enabled then skinUpdateTimer:fill() end
    end,
}
