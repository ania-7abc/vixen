require("scripts.util")

local sleep = require("scripts.sleep")
local options = require("scripts.options")

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
-- generate keys
for key, value in pairs(skinEntries) do
    value["key"] = key
end

local function validateSkinEntries()
    for key, skin in pairs(skinEntries) do
        if not skin.icon or not skin.title then
            log("[vixen] skin " .. key .. " is missing its icon or title")
        end
        if not skin.texture then
            log("[vixen] skin " .. key .. " is missing its texture")
        else
            if not textures[skin.texture] then
                log("[vixen] skin " .. key .. " is missing texture " .. skin.texture)
            end
            if not textures[skin.texture .. "_sleep"] then
                log("[vixen] skin " .. key .. " is missing sleeping texture " .. skin.texture .. "_sleep")
            end
        end
    end
end
validateSkinEntries()

local currentSkin = skinEntries.Rebecca

-- automatic skin updated based on the biome
local autoSkinEnabled = false
local skinUpdateInterval = 80
local skinUpdateTimer = 0
local function setAutoSkin(enabled)
    autoSkinEnabled = enabled
    if host:isHost() then config:save("autoSkin", enabled) end
end
function pings.setAutoSkin(enabled)
    setAutoSkin(enabled)
end

-- sleeping and blinking
local blinkMinDelay = 60
local blinkMaxDelay = 140
local blinkDuration = 3

local appliedClosed = nil
local blinkTimer = math.random(blinkMinDelay, blinkMaxDelay)
local blinkTicks = 0
local function updateHeadTexture()
    local closed = sleep.isSleeping() or blinkTicks > 0
    if appliedClosed == closed then return end
    appliedClosed = closed
    models.model.root.Head:setPrimaryTexture("CUSTOM", textures[closed and (currentSkin.texture .. "_sleep") or currentSkin.texture])
end
sleep.onChange(updateHeadTexture)
options.onChange("blinking", function (enabled)
    if not enabled then
        blinkTicks = 0
        updateHeadTexture()
    end
end)

local function tickBlink()
    if not options.blinking then return end
    if blinkTicks > 0 then
        blinkTicks = blinkTicks - 1
        if blinkTicks == 0 then updateHeadTexture() end
    elseif not sleep.isSleeping() then
        blinkTimer = blinkTimer - 1
        if blinkTimer <= 0 then
            blinkTicks = blinkDuration
            blinkTimer = math.random(blinkMinDelay, blinkMaxDelay)
            updateHeadTexture()
        end
    end
end

local function setSkin(skin)
    if currentSkin == skin then return end
    currentSkin = skin
    models.model.root:setPrimaryTexture("CUSTOM", textures[skin.texture])
    appliedClosed = nil
    updateHeadTexture()
    if host:isHost() then
        config:save("currentSkin", skin.key)
    end
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

function events.entity_init()
    -- load config
    if host:isHost() then
        autoSkinEnabled = safeConfigLoad("autoSkin", config:load("autoSkinEnabled") or false)
        pings.setAutoSkin(autoSkinEnabled)
        pings.setSkin(safeConfigLoad("currentSkin", currentSkin.key))
    end
end

function events.tick()
    sleep.setInBed(player:getPose() == "SLEEPING")
    tickBlink()

    if not autoSkinEnabled then return end
    if skinUpdateTimer < skinUpdateInterval then
        skinUpdateTimer = skinUpdateTimer + 1
        return
    else
        skinUpdateTimer = 0
    end

    updateAutoSkin()
end

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
        if enabled then skinUpdateTimer = skinUpdateInterval end
    end,
}
